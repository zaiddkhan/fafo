from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException, Query, status
from google.cloud.firestore import SERVER_TIMESTAMP

from app.activity import record_meaningful_action
from app.dependencies import get_current_user, validate_document_id
from app.firebase import get_firestore
from app.schemas import NudgeCreateRequest, NudgeFeedType, NudgeRespondRequest, NudgeResponse, NudgeStatus, NudgeVote

router = APIRouter(prefix="/nudges", tags=["nudges"])
MAX_LIMIT = 100
REMINDER_LIMITS = {5: 0, 10: 1, 15: 2, 20: 3}


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


def _expected_voters(db, data: dict) -> list[str]:
    sender = data["sender_uid"]
    if data["feed_type"] == NudgeFeedType.friend.value:
        return [uid for uid in data.get("participant_uids", []) if uid != sender]
    return [uid for uid in _member_ids(db, data["target_id"]) if uid != sender]


def _expire_or_resolve(ref, data: dict) -> dict:
    db = get_firestore()
    now = _now()
    expires_at = _ensure_utc(data["expires_at"])
    votes = data.get("votes", {}) or {}
    expected = _expected_voters(db, data)
    current_status = data.get("status")
    if current_status in (NudgeStatus.resolved.value, NudgeStatus.expired.value):
        return data

    # Accepted nudges enter a second red timer phase. Do not resolve merely
    # because everyone has voted; keep the card active until that timer closes.
    if current_status == NudgeStatus.accepted_timer.value:
        if now >= expires_at:
            data = {**data, "status": NudgeStatus.resolved.value, "resolved_at": now}
            ref.update({"status": NudgeStatus.resolved.value, "resolved_at": now})
        return data

    if now >= expires_at:
        for uid in expected:
            votes.setdefault(uid, NudgeVote.no.value)
        data = {**data, "status": NudgeStatus.expired.value, "votes": votes, "resolved_at": now}
        ref.update({"status": NudgeStatus.expired.value, "votes": votes, "resolved_at": now})
    elif expected and len(votes) >= len(expected):
        if any(vote == NudgeVote.yes.value for vote in votes.values()):
            # A Yes restarts the timer in the red accepted phase — reset
            # expires_at so the red countdown runs the full window.
            new_expiry = now + timedelta(minutes=data["response_window_minutes"])
            update = {
                "status": NudgeStatus.accepted_timer.value,
                "accepted_timer_started_at": now,
                "expires_at": new_expiry,
            }
            data = {**data, **update}
            ref.update(update)
        else:
            data = {**data, "status": NudgeStatus.resolved.value, "resolved_at": now}
            ref.update({"status": NudgeStatus.resolved.value, "resolved_at": now})
    return data


def _to_response(doc_id: str, data: dict) -> NudgeResponse:
    db = get_firestore()
    expected = _expected_voters(db, data)
    votes = data.get("votes", {}) or {}
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
def create_nudge(body: NudgeCreateRequest, current_user: dict = Depends(get_current_user)):
    uid = current_user["uid"]
    db = get_firestore()
    feed_id, participants = _require_feed_access(db, uid, body.feed_type, body.target_id)
    existing = db.collection("nudges").where("feed_id", "==", feed_id).limit(MAX_LIMIT).stream()
    for doc in existing:
        data = _expire_or_resolve(doc.reference, doc.to_dict())
        if data.get("status") in (NudgeStatus.active.value, NudgeStatus.accepted_timer.value):
            raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Resolve the active nudge before creating another")
    now = _now()
    ref = db.collection("nudges").document()
    reminder_limit = REMINDER_LIMITS[body.response_window_minutes]
    ref.set({
        "feed_type": body.feed_type.value,
        "feed_id": feed_id,
        "target_id": body.target_id,
        "participant_uids": participants,
        "sender_uid": uid,
        "title": body.title,
        "location": body.location,
        "response_window_minutes": body.response_window_minutes,
        "status": NudgeStatus.active.value,
        "expires_at": now + timedelta(minutes=body.response_window_minutes),
        "accepted_timer_started_at": None,
        "reminder_count": 0,
        "reminder_limit": reminder_limit,
        "next_reminder_available_at": now + timedelta(minutes=5) if reminder_limit else None,
        "votes": {},
        "created_at": now,
        "resolved_at": None,
    })
    record_meaningful_action(db, uid, "send_nudge", {"nudge_id": ref.id})
    return _to_response(ref.id, ref.get().to_dict())


@router.post("/{nudge_id}/respond", response_model=NudgeResponse)
def respond_nudge(nudge_id: str, body: NudgeRespondRequest, current_user: dict = Depends(get_current_user)):
    validate_document_id(nudge_id)
    uid = current_user["uid"]
    db = get_firestore()
    ref = db.collection("nudges").document(nudge_id)
    doc = ref.get()
    if not doc.exists:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Nudge not found")
    data = _expire_or_resolve(ref, doc.to_dict())
    if data.get("status") not in (NudgeStatus.active.value, NudgeStatus.accepted_timer.value):
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Nudge already resolved")
    expected = _expected_voters(db, data)
    if uid not in expected:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Cannot vote on this nudge")
    votes = data.get("votes", {}) or {}
    votes[uid] = body.vote.value
    update = {"votes": votes}
    if body.vote == NudgeVote.yes and data.get("status") != NudgeStatus.accepted_timer.value:
        now = _now()
        update["status"] = NudgeStatus.accepted_timer.value
        update["accepted_timer_started_at"] = now
        update["expires_at"] = now + timedelta(minutes=data["response_window_minutes"])
        record_meaningful_action(db, uid, "accept_nudge", {"nudge_id": nudge_id})
    ref.update(update)
    data = {**data, **update}
    data = _expire_or_resolve(ref, data)
    return _to_response(nudge_id, data)


@router.post("/{nudge_id}/remind", response_model=NudgeResponse)
def send_reminder(nudge_id: str, current_user: dict = Depends(get_current_user)):
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
        "next_reminder_available_at": _now() + timedelta(minutes=5) if new_count < limit else None,
    }
    ref.update(update)
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
    expected = _expected_voters(db, data)
    votes = data.get("votes", {}) or {}
    for voter in expected:
        votes.setdefault(voter, NudgeVote.no.value)
    now = _now()
    update = {"status": NudgeStatus.expired.value, "votes": votes, "resolved_at": now}
    ref.update(update)
    return _to_response(nudge_id, {**data, **update})
