from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, Query, status
from google.api_core.exceptions import FailedPrecondition
from google.cloud import firestore

from app.activity import record_meaningful_action
from app.dependencies import get_current_user, validate_document_id
from app.firebase import get_firestore
from app.notifications import nudge_events, triggers
from app.schemas import NudgeCreateRequest, NudgeFeedType, NudgeRespondRequest, NudgeResponse, NudgeStatus, NudgeVote

router = APIRouter(prefix="/nudges", tags=["nudges"])
MAX_LIMIT = 100
REMINDER_LIMITS = {5: 0, 10: 1, 15: 2, 20: 3}
# V3: the receiver always has 10 minutes to answer (brief 4.2).
ANSWER_WINDOW = timedelta(minutes=10)


def _now():
    return datetime.now(timezone.utc)


def _ensure_utc(dt: datetime):
    if dt.tzinfo is None:
        return dt.replace(tzinfo=timezone.utc)
    return dt.astimezone(timezone.utc)


def _friend_feed_id(a: str, b: str) -> str:
    first, second = sorted([a, b])
    return f"friend_{first}_{second}"


def _group_feed_id(group_id: str) -> str:
    return f"group_{group_id}"


def _member_ids(db, group_id: str) -> list[str]:
    return [doc.id for doc in db.collection("groups").document(group_id).collection("members").stream()]


def _display_name(db, uid: str) -> str:
    doc = db.collection("users").document(uid).get()
    return (doc.to_dict() or {}).get("display_name", "Someone") if doc.exists else "Someone"


def _allows_quests(db, uid: str) -> bool:
    doc = db.collection("users").document(uid).get()
    return bool((doc.to_dict() or {}).get("side_quest_invites", True)) if doc.exists else False


def _group_name(db, group_id: str) -> str:
    doc = db.collection("groups").document(group_id).get()
    return (doc.to_dict() or {}).get("name", "your group") if doc.exists else "your group"


def _expected_voters(db, data: dict) -> list[str]:
    """Everyone who can answer: the participants snapshotted at send time, minus
    the sender. A member added mid-nudge doesn't receive it; one who leaves keeps
    their answer in the tally (V3 brief 4.9)."""
    sender = data["sender_uid"]
    participants = data.get("participant_uids")
    if participants is None and data["feed_type"] == NudgeFeedType.group.value:
        participants = _member_ids(db, data["target_id"])
    return [uid for uid in (participants or []) if uid != sender]


def _answer_by(data: dict) -> datetime:
    """End of the fixed 10-minute answer window. Pre-V3 docs fall back to their
    response-window expiry."""
    if data.get("answer_by"):
        return _ensure_utc(data["answer_by"])
    return _ensure_utc(data["expires_at"])


def _go_at(data: dict) -> datetime:
    if data.get("go_at"):
        return _ensure_utc(data["go_at"])
    return _ensure_utc(data["expires_at"])


def _settle(data: dict, expected: list[str], now: datetime) -> dict:
    """Pure state transition. Returns the fields to write (empty if none).

    pending (active)        -> expired at answer_by with no yes
                            -> resolved/no once everyone answered no
    accepted (accepted_timer) -> resolved/yes at go_at
    """
    current = data.get("status")
    if current in (NudgeStatus.resolved.value, NudgeStatus.expired.value):
        return {}
    votes = data.get("votes", {}) or {}
    if current == NudgeStatus.accepted_timer.value:
        if now >= _go_at(data):
            return {"status": NudgeStatus.resolved.value, "outcome": "yes", "resolved_at": now}
        return {}
    if now >= _answer_by(data):
        return {"status": NudgeStatus.expired.value, "outcome": "expired", "resolved_at": now}
    if expected and all(uid in votes for uid in expected):
        # Nobody said yes (a yes moves the nudge to accepted immediately).
        return {"status": NudgeStatus.resolved.value, "outcome": "no", "resolved_at": now}
    return {}


def _expire_or_resolve(ref, data: dict) -> dict:
    db = get_firestore()
    update = _settle(data, _expected_voters(db, data), _now())
    if update:
        ref.update(update)
        data = {**data, **update}
    return data


def _outcome(data: dict) -> str | None:
    if data.get("outcome"):
        return data["outcome"]
    current = data.get("status")
    if current == NudgeStatus.expired.value:
        return "expired"
    if current == NudgeStatus.resolved.value:
        votes = (data.get("votes") or {}).values()
        return "yes" if any(v == NudgeVote.yes.value for v in votes) else "no"
    return None


def _to_response(doc_id: str, data: dict, *, sender_name: str | None = None, target_name: str | None = None, name_of=None) -> NudgeResponse:
    db = get_firestore()
    expected = _expected_voters(db, data)
    votes = data.get("votes", {}) or {}
    yes_names = []
    if data["feed_type"] == NudgeFeedType.group.value:
        lookup = name_of or (lambda u: _display_name(db, u))
        yes_names = [lookup(u) for u, v in votes.items() if v == NudgeVote.yes.value]
    return NudgeResponse(
        id=doc_id,
        feed_type=NudgeFeedType(data["feed_type"]),
        feed_id=data["feed_id"],
        sender_uid=data["sender_uid"],
        title=data["title"],
        location=data.get("location"),
        response_window_minutes=data["response_window_minutes"],
        status=NudgeStatus(data.get("status", NudgeStatus.active.value)),
        expires_at=data["expires_at"],
        accepted_timer_started_at=data.get("accepted_timer_started_at"),
        reminder_count=data.get("reminder_count", 0),
        reminder_limit=data.get("reminder_limit", 0),
        next_reminder_available_at=data.get("next_reminder_available_at"),
        votes=votes,
        yes_count=sum(1 for v in votes.values() if v == NudgeVote.yes.value),
        voter_count=len(votes),
        expected_voter_count=len(expected),
        created_at=data["created_at"],
        resolved_at=data.get("resolved_at"),
        answer_by=_answer_by(data),
        go_at=data.get("go_at") or (data["expires_at"] if data.get("status") == NudgeStatus.accepted_timer.value else None),
        outcome=_outcome(data),
        description=data.get("description"),
        quest_id=data.get("quest_id"),
        quest_difficulty=data.get("quest_difficulty"),
        target_id=data.get("target_id"),
        sender_name=sender_name or data.get("sender_name"),
        target_name=target_name or data.get("target_name"),
        yes_names=yes_names,
    )


def _require_feed_access(db, uid: str, feed_type: NudgeFeedType, target_id: str) -> tuple[str, list[str]]:
    validate_document_id(target_id)
    if feed_type == NudgeFeedType.friend:
        if not db.collection("users").document(uid).collection("friends").document(target_id).get().exists:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Friend feed unavailable")
        return _friend_feed_id(uid, target_id), sorted([uid, target_id])
    group_doc = db.collection("groups").document(target_id).get()
    if not group_doc.exists or group_doc.to_dict().get("dissolved", False):
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Group not found")
    members = _member_ids(db, target_id)
    if uid not in members:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Group not found")
    return _group_feed_id(target_id), members


@router.get("", response_model=list[NudgeResponse])
def list_feed(feed_type: NudgeFeedType, target_id: str, limit: int = Query(default=50, le=MAX_LIMIT), current_user: dict = Depends(get_current_user)):
    uid = current_user["uid"]
    db = get_firestore()
    feed_id, _ = _require_feed_access(db, uid, feed_type, target_id)

    # For group feeds, a newly added member only sees nudges created at/after they
    # joined — never the history from before (PRD: "sees only future nudges").
    joined_at = None
    if feed_type == NudgeFeedType.group:
        member_doc = db.collection("groups").document(target_id).collection("members").document(uid).get()
        if member_doc.exists:
            raw_joined = member_doc.to_dict().get("joined_at")
            joined_at = _ensure_utc(raw_joined) if raw_joined else None

    docs = db.collection("nudges").where("feed_id", "==", feed_id).limit(MAX_LIMIT).stream()
    responses = []
    for doc in docs:
        data = _expire_or_resolve(doc.reference, doc.to_dict())
        if joined_at is not None:
            created = data.get("created_at")
            if created is not None and _ensure_utc(created) < joined_at:
                continue
        responses.append(_to_response(doc.id, data))
    responses.sort(key=lambda n: n.created_at, reverse=True)
    return responses[:limit]


@router.post("", response_model=NudgeResponse, status_code=status.HTTP_201_CREATED)
def create_nudge(body: NudgeCreateRequest, background_tasks: BackgroundTasks, current_user: dict = Depends(get_current_user)):
    uid = current_user["uid"]
    db = get_firestore()
    feed_id, participants = _require_feed_access(db, uid, body.feed_type, body.target_id)
    existing = db.collection("nudges").where("feed_id", "==", feed_id).limit(MAX_LIMIT).stream()
    for doc in existing:
        data = _expire_or_resolve(doc.reference, doc.to_dict())
        if data.get("status") in (NudgeStatus.active.value, NudgeStatus.accepted_timer.value):
            raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Resolve the active nudge before creating another")
    quest_difficulty = None
    description = body.description
    if body.quest_id:
        validate_document_id(body.quest_id)
        quest_doc = db.collection("quests").document(body.quest_id).get()
        if not quest_doc.exists or not quest_doc.to_dict().get("published", True):
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Quest not found")
        quest = quest_doc.to_dict()
        quest_difficulty = quest.get("difficulty")
        # Quests go out as the admin wrote them.
        description = quest.get("description")
        # Only people who allow side quest invites receive one (V3 brief 5.4).
        receivers = [u for u in participants if u != uid]
        allowed = [u for u in receivers if _allows_quests(db, u)]
        if not allowed:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="They've turned off side quest invites")
        participants = [uid, *allowed]
    sender_name = _display_name(db, uid)
    if body.feed_type == NudgeFeedType.friend:
        target_name = _display_name(db, body.target_id)
    else:
        target_name = _group_name(db, body.target_id)
    now = _now()
    ref = db.collection("nudges").document()
    reminder_limit = REMINDER_LIMITS[body.response_window_minutes]
    answer_by = now + ANSWER_WINDOW
    ref.set({
        "feed_type": body.feed_type.value,
        "feed_id": feed_id,
        "target_id": body.target_id,
        "participant_uids": participants,
        "sender_uid": uid,
        "title": body.title,
        "location": body.location,
        # The sender's countdown after yes (5, 10 or 15).
        "response_window_minutes": body.response_window_minutes,
        "status": NudgeStatus.active.value,
        # expires_at mirrors whichever timer is running: answer_by while
        # pending, go_at once accepted. Kept for pre-V3 clients.
        "expires_at": answer_by,
        "answer_by": answer_by,
        "go_at": None,
        "outcome": None,
        "description": description,
        "quest_id": body.quest_id,
        "quest_difficulty": quest_difficulty,
        "sender_name": sender_name,
        "target_name": target_name,
        # Cleared by the sweep cron once the closing pushes (expiry, group
        # tally) have gone out.
        "final_pushed": False,
        "accepted_timer_started_at": None,
        "reminder_count": 0,
        "reminder_limit": reminder_limit,
        # First reminder is available immediately; a short cooldown is applied
        # only after each reminder is sent (see send_reminder).
        "next_reminder_available_at": None,
        "votes": {},
        "created_at": now,
        "resolved_at": None,
    })
    record_meaningful_action(db, uid, "send_nudge", {"nudge_id": ref.id})

    # Fire-and-forget push to everyone expected to respond.
    recipients = [u for u in participants if u != uid]
    created = ref.get().to_dict()
    nudge_events.received(background_tasks, nudge_id=ref.id, data=created, recipient_uids=recipients)
    return _to_response(ref.id, created)


@router.get("/mine", response_model=list[NudgeResponse])
def list_mine(limit: int = Query(default=30, le=MAX_LIMIT), current_user: dict = Depends(get_current_user)):
    """Every nudge the user sent or received, newest first, across friends and
    groups. Feeds home: the live card and the Recent list."""
    uid = current_user["uid"]
    db = get_firestore()
    base = db.collection("nudges").where("participant_uids", "array_contains", uid)
    try:
        docs = list(base.order_by("created_at", direction=firestore.Query.DESCENDING).limit(limit).stream())
    except FailedPrecondition:
        # Composite index not deployed yet: fall back to an unordered scan.
        docs = list(base.limit(MAX_LIMIT).stream())
    names: dict[str, str] = {}

    def name_of(user_uid: str) -> str:
        if user_uid not in names:
            names[user_uid] = _display_name(db, user_uid)
        return names[user_uid]

    responses = []
    for doc in docs:
        data = _expire_or_resolve(doc.reference, doc.to_dict())
        sender_name = data.get("sender_name") or name_of(data["sender_uid"])
        target_name = data.get("target_name")
        if not target_name:
            if data["feed_type"] == NudgeFeedType.group.value:
                target_name = _group_name(db, data["target_id"])
            else:
                others = [u for u in data.get("participant_uids", []) if u != data["sender_uid"]]
                target_name = name_of(others[0]) if others else "your friend"
        responses.append(_to_response(doc.id, data, sender_name=sender_name, target_name=target_name, name_of=name_of))
    responses.sort(key=lambda n: n.created_at, reverse=True)
    return responses[:limit]


@router.get("/{nudge_id}", response_model=NudgeResponse)
def get_nudge(nudge_id: str, current_user: dict = Depends(get_current_user)):
    validate_document_id(nudge_id)
    uid = current_user["uid"]
    db = get_firestore()
    ref = db.collection("nudges").document(nudge_id)
    doc = ref.get()
    if not doc.exists or uid not in (doc.to_dict().get("participant_uids") or []):
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Nudge not found")
    return _to_response(nudge_id, _expire_or_resolve(ref, doc.to_dict()))


@router.post("/{nudge_id}/respond", response_model=NudgeResponse)
def respond_nudge(nudge_id: str, body: NudgeRespondRequest, background_tasks: BackgroundTasks, current_user: dict = Depends(get_current_user)):
    validate_document_id(nudge_id)
    uid = current_user["uid"]
    db = get_firestore()
    ref = db.collection("nudges").document(nudge_id)

    # A transaction so two yeses in the same second can't create two go times.
    @firestore.transactional
    def apply(transaction):
        snap = ref.get(transaction=transaction)
        if not snap.exists:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Nudge not found")
        data = snap.to_dict()
        expected = _expected_voters(db, data)
        now = _now()
        settled = _settle(data, expected, now)
        data = {**data, **settled}
        if data.get("status") not in (NudgeStatus.active.value, NudgeStatus.accepted_timer.value):
            if settled:
                transaction.update(ref, settled)
            return data, False, True
        if uid not in expected:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Cannot vote on this nudge")
        votes = dict(data.get("votes", {}) or {})
        if uid in votes:
            raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="You already answered")
        # Once accepted, the rest of a group can still answer until the
        # 10-minute window closes.
        if now >= _answer_by(data):
            raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Answer window closed")
        votes[uid] = body.vote.value
        update = {"votes": votes}
        first_yes = body.vote == NudgeVote.yes and data.get("status") == NudgeStatus.active.value
        if first_yes:
            go_at = now + timedelta(minutes=data["response_window_minutes"])
            update.update({
                "status": NudgeStatus.accepted_timer.value,
                "accepted_timer_started_at": now,
                "go_at": go_at,
                "expires_at": go_at,
            })
        merged = {**data, **update}
        update.update(_settle(merged, expected, now))
        transaction.update(ref, {**settled, **update})
        return {**merged, **update}, first_yes, False

    data, first_yes, closed = apply(db.transaction())
    if closed:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Nudge already resolved")
    if first_yes:
        record_meaningful_action(db, uid, "accept_nudge", {"nudge_id": nudge_id})
    nudge_events.answered(
        background_tasks, nudge_id=nudge_id, data=data,
        voter_name=_display_name(db, uid), vote=body.vote.value, first_yes=first_yes,
    )
    if body.vote == NudgeVote.yes and data.get("go_at"):
        # Go time reaches the sender and everyone who said yes. A later yes in a
        # group joins the same go time.
        recipients = [uid] + ([data["sender_uid"]] if first_yes else [])
        nudge_events.schedule_go_time(nudge_id=nudge_id, data=data, recipient_uids=recipients, go_at=_go_at(data))
    if data.get("feed_type") == NudgeFeedType.group.value:
        _maybe_group_final(background_tasks, db, nudge_id, data)
    return _to_response(nudge_id, data)


@router.post("/{nudge_id}/remind", response_model=NudgeResponse)
def send_reminder(nudge_id: str, background_tasks: BackgroundTasks, current_user: dict = Depends(get_current_user)):
    validate_document_id(nudge_id)
    uid = current_user["uid"]
    db = get_firestore()
    ref = db.collection("nudges").document(nudge_id)
    doc = ref.get()
    if not doc.exists:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Nudge not found")
    data = _expire_or_resolve(ref, doc.to_dict())
    if data["sender_uid"] != uid:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Only sender can remind")
    if data.get("status") not in (NudgeStatus.active.value, NudgeStatus.accepted_timer.value):
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Nudge already resolved")
    count = data.get("reminder_count", 0)
    limit = data.get("reminder_limit", 0)
    if count >= limit:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="No reminders left")
    available_at = data.get("next_reminder_available_at")
    if available_at and _now() < _ensure_utc(available_at):
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Reminder cooldown active")
    new_count = count + 1
    update = {
        "reminder_count": new_count,
        "next_reminder_available_at": _now() + timedelta(minutes=1) if new_count < limit else None,
    }
    ref.update(update)

    # Re-ping everyone still expected to respond. Fire-and-forget; never blocks.
    recipients = _expected_voters(db, data)
    if recipients:
        if data["feed_type"] == NudgeFeedType.friend.value:
            triggers.nudge_reminder(
                background_tasks,
                nudge_id=nudge_id,
                recipient_uids=recipients,
                reminder_count=new_count,
                sender_name=_display_name(db, uid),
                sender_uid=uid,
            )
        else:
            triggers.nudge_reminder(
                background_tasks,
                nudge_id=nudge_id,
                recipient_uids=recipients,
                reminder_count=new_count,
                group_id=data["target_id"],
                group_name=_group_name(db, data["target_id"]),
            )

    return _to_response(nudge_id, {**data, **update})


@router.post("/{nudge_id}/expire", response_model=NudgeResponse)
def expire_nudge(nudge_id: str, current_user: dict = Depends(get_current_user)):
    validate_document_id(nudge_id)
    uid = current_user["uid"]
    db = get_firestore()
    ref = db.collection("nudges").document(nudge_id)
    doc = ref.get()
    if not doc.exists:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Nudge not found")
    data = doc.to_dict()
    if uid not in data.get("participant_uids", []) and uid != data.get("sender_uid"):
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Nudge not found")
    if data.get("status") not in (NudgeStatus.active.value, None):
        return _to_response(nudge_id, _expire_or_resolve(ref, data))
    now = _now()
    update = {"status": NudgeStatus.expired.value, "outcome": "expired", "resolved_at": now}
    ref.update(update)
    return _to_response(nudge_id, {**data, **update})


def _maybe_group_final(background_tasks, db, nudge_id: str, data: dict, now: datetime | None = None) -> None:
    """One tally push to the sender once a group's answers are in: everyone
    answered, the 10-minute window closed, or the nudge resolved."""
    now = now or _now()
    expected = _expected_voters(db, data)
    votes = data.get("votes", {}) or {}
    closed = (
        data.get("status") in (NudgeStatus.resolved.value, NudgeStatus.expired.value)
        or now >= _answer_by(data)
        or (expected and all(u in votes for u in expected))
    )
    if closed:
        yes = sum(1 for v in votes.values() if v == NudgeVote.yes.value)
        nudge_events.group_final(background_tasks, nudge_id=nudge_id, data=data, yes_count=yes, size=len(expected))


def sweep_nudges(limit: int = 500) -> dict:
    """Cron: settle nudges whose timers ran out and send the closing pushes, so
    expiry and go time happen even when both apps are closed (brief 4.5)."""
    db = get_firestore()
    now = _now()
    summary = {"checked": 0, "settled": 0, "finished": 0}
    for doc in db.collection("nudges").where("final_pushed", "==", False).limit(limit).stream():
        summary["checked"] += 1
        before = doc.to_dict()
        data = _expire_or_resolve(doc.reference, before)
        if data.get("status") != before.get("status"):
            summary["settled"] += 1
        if data.get("feed_type") == NudgeFeedType.group.value:
            _maybe_group_final(None, db, doc.id, data, now)
        if data.get("status") == NudgeStatus.expired.value and data.get("feed_type") != NudgeFeedType.group.value:
            nudge_events.expired(None, nudge_id=doc.id, data=data)
        if data.get("status") in (NudgeStatus.resolved.value, NudgeStatus.expired.value):
            doc.reference.update({"final_pushed": True})
            summary["finished"] += 1
    return summary
