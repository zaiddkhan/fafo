from datetime import datetime, timezone
from uuid import uuid4

from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, Query, status
from google.cloud import firestore
from google.cloud.firestore import SERVER_TIMESTAMP

from app.dependencies import get_current_user, validate_document_id
from app.firebase import get_firestore
from app.notifications import triggers
from app.routers.friends import public_user_from_doc
from app.schemas import (
    GroupCreateRequest,
    GroupInviteCreateRequest,
    GroupInviteResponse,
    GroupInviteStatus,
    GroupMembersAddRequest,
    GroupMemberResponse,
    GroupResponse,
    GroupTransferRequest,
    GroupUpdateRequest,
    NegativeActionAnswers,
)

router = APIRouter(prefix="/groups", tags=["groups"])

DEFAULT_LIMIT = 50
MAX_LIMIT = 100
# V3 brief 6.5: groups are capped at a fixed size, creator included.
MAX_GROUP_SIZE = 15


def _now() -> datetime:
    return datetime.now(timezone.utc)


def _group_ref(db, group_id: str):
    validate_document_id(group_id)
    return db.collection("groups").document(group_id)


def _is_member(db, group_id: str, uid: str) -> bool:
    return db.collection("groups").document(group_id).collection("members").document(uid).get().exists


def _member_ids(db, group_id: str) -> list[str]:
    return [doc.id for doc in db.collection("groups").document(group_id).collection("members").stream()]


def _require_group(db, group_id: str):
    ref = _group_ref(db, group_id)
    doc = ref.get()
    if not doc.exists or doc.to_dict().get("dissolved", False):
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Group not found")
    return ref, doc.to_dict()


def _require_member(db, group_id: str, uid: str):
    ref, data = _require_group(db, group_id)
    if not ref.collection("members").document(uid).get().exists:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Group not found")
    return ref, data


def _require_admin(db, group_id: str, uid: str):
    ref, data = _require_member(db, group_id, uid)
    if data.get("admin_uid") != uid:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Group admin access required")
    return ref, data


# Inbox-only group-lifecycle notifications (no push). Events that also warrant a
# push go through the generic pipeline (triggers.* -> NotificationService), which
# writes a content-rich inbox entry itself. These lower-priority events are inbox
# only, but must still carry a real title/body and a `data.group_id` so the app
# renders them with content and taps them through to the group — never an empty
# card or a dead route.
_GROUP_INBOX_COPY = {
    "group_admin_promoted": lambda c: ("You're now an admin", f"You're now an admin of {c['group_name']}."),
    "group_admin_changed": lambda c: ("New group admin", f"{c['group_name']} has a new admin."),
    "group_joined": lambda c: ("Joined group", f"You joined {c['group_name']}."),
    "group_member_left": lambda c: ("Someone left", f"{c['member_name']} left {c['group_name']}."),
}


def _notify(db, uid: str, notification_type: str, payload: dict):
    """Write a well-formed inbox entry for an inbox-only group event.

    Unknown/content-less types are ignored rather than written, so the inbox never
    contains an empty notification (which the app would render as a blank card with
    no navigation target).
    """
    builder = _GROUP_INBOX_COPY.get(notification_type)
    if builder is None:
        return
    group_id = payload.get("group_id", "")
    ctx = {
        "group_id": group_id,
        "group_name": payload.get("group_name") or _group_name(db, group_id),
    }
    if payload.get("uid"):
        ctx["member_name"] = _display_name(db, payload["uid"])
    title, body = builder(ctx)
    db.collection("users").document(uid).collection("notifications").document(str(uuid4())).set({
        "type": "groups",
        "template_id": f"groups.{notification_type}",
        "title": title,
        "body": body,
        "data": {"group_id": group_id},
        "read": False,
        "created_at": SERVER_TIMESTAMP,
    })


def _save_negative_action(db, actor_uid: str, action_type: str, answers: list[str], **extra):
    db.collection("negative_action_responses").document(str(uuid4())).set({
        "actor_uid": actor_uid,
        "action_type": action_type,
        "answers": answers,
        "created_at": SERVER_TIMESTAMP,
        **extra,
    })


def _display_name(db, uid: str) -> str:
    doc = db.collection("users").document(uid).get()
    return (doc.to_dict() or {}).get("display_name", "Someone") if doc.exists else "Someone"


def _group_name(db, group_id: str) -> str:
    if not group_id:
        return "your group"
    doc = db.collection("groups").document(group_id).get()
    return (doc.to_dict() or {}).get("name", "your group") if doc.exists else "your group"


def _member_responses(db, group_id: str, viewer_uid: str) -> list[GroupMemberResponse]:
    members = []
    for member_doc in db.collection("groups").document(group_id).collection("members").order_by("joined_at").stream():
        user_doc = db.collection("users").document(member_doc.id).get()
        if not user_doc.exists:
            continue
        data = member_doc.to_dict()
        members.append(GroupMemberResponse(
            user=public_user_from_doc(user_doc.id, user_doc.to_dict() or {}, viewer_uid),
            joined_at=data["joined_at"],
            is_admin=data.get("is_admin", False),
        ))
    return members


def _group_response(group_id: str, data: dict, viewer_uid: str) -> GroupResponse:
    db = get_firestore()
    return GroupResponse(
        id=group_id,
        name=data.get("name", ""),
        admin_uid=data.get("admin_uid", ""),
        created_at=data["created_at"],
        updated_at=data.get("updated_at") or data["created_at"],
        members=_member_responses(db, group_id, viewer_uid),
    )


def _invite_response(invite_id: str, data: dict, viewer_uid: str) -> GroupInviteResponse:
    db = get_firestore()
    group_doc = db.collection("groups").document(data["group_id"]).get()
    inviter_doc = db.collection("users").document(data["inviter_uid"]).get()
    recipient_doc = db.collection("users").document(data["recipient_uid"]).get()
    return GroupInviteResponse(
        id=invite_id,
        group_id=data["group_id"],
        group_name=(group_doc.to_dict() or {}).get("name", ""),
        inviter=public_user_from_doc(inviter_doc.id, inviter_doc.to_dict() or {}, viewer_uid),
        recipient=public_user_from_doc(recipient_doc.id, recipient_doc.to_dict() or {}, viewer_uid),
        status=GroupInviteStatus(data.get("status", GroupInviteStatus.pending.value)),
        created_at=data["created_at"],
        responded_at=data.get("responded_at"),
    )


def _promote_next_or_dissolve(db, group_ref, group_id: str, leaving_uid: str):
    candidates = [m for m in group_ref.collection("members").order_by("joined_at").stream() if m.id != leaving_uid]
    if not candidates:
        group_ref.update({"dissolved": True, "dissolved_at": SERVER_TIMESTAMP, "updated_at": SERVER_TIMESTAMP})
        return None
    next_doc = candidates[0]
    next_uid = next_doc.id
    group_ref.update({"admin_uid": next_uid, "updated_at": SERVER_TIMESTAMP})
    next_doc.reference.update({"is_admin": True})
    group_name = _group_name(db, group_id)
    _notify(db, next_uid, "group_admin_promoted", {"group_id": group_id, "group_name": group_name})
    for member_doc in candidates[1:]:
        _notify(db, member_doc.id, "group_admin_changed",
                {"group_id": group_id, "admin_uid": next_uid, "group_name": group_name})
    return next_uid


def _add_members_direct(db, group_ref, group_id: str, adder_uid: str, member_uids: list[str], background_tasks, group_name: str) -> None:
    """Add the adder's friends straight in (V3 brief 6.5). Already-members are
    skipped; anyone who isn't a friend is rejected."""
    wanted = []
    for member_uid in dict.fromkeys(member_uids):
        validate_document_id(member_uid)
        if member_uid == adder_uid or _is_member(db, group_id, member_uid):
            continue
        if not db.collection("users").document(adder_uid).collection("friends").document(member_uid).get().exists:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Groups can only contain your friends")
        wanted.append(member_uid)
    if not wanted:
        return
    if len(_member_ids(db, group_id)) + len(wanted) > MAX_GROUP_SIZE:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=f"Groups max out at {MAX_GROUP_SIZE} people")
    now = _now()
    batch = db.batch()
    for member_uid in wanted:
        batch.set(group_ref.collection("members").document(member_uid), {"uid": member_uid, "joined_at": now, "is_admin": False})
    batch.update(group_ref, {"updated_at": now})
    batch.commit()
    triggers.group_member_added(
        background_tasks, group_id=group_id, recipient_uids=wanted,
        group_name=group_name, adder_name=_display_name(db, adder_uid), added_at=now,
    )


@router.post("", response_model=GroupResponse, status_code=status.HTTP_201_CREATED)
def create_group(body: GroupCreateRequest, background_tasks: BackgroundTasks, current_user: dict = Depends(get_current_user)):
    uid = current_user["uid"]
    db = get_firestore()
    # Validate members before creating anything, so a bad pick can't leave an
    # empty group behind.
    members = [m for m in dict.fromkeys(body.member_uids) if m != uid]
    if len(members) + 1 > MAX_GROUP_SIZE:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=f"Groups max out at {MAX_GROUP_SIZE} people")
    for member_uid in members:
        validate_document_id(member_uid)
        if not db.collection("users").document(uid).collection("friends").document(member_uid).get().exists:
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Groups can only contain your friends")
    group_ref = db.collection("groups").document()
    now = _now()
    group_ref.set({
        "name": body.name,
        "admin_uid": uid,
        "created_at": now,
        "updated_at": now,
        "dissolved": False,
    })
    group_ref.collection("members").document(uid).set({"uid": uid, "joined_at": now, "is_admin": True})
    if body.member_uids:
        _add_members_direct(db, group_ref, group_ref.id, uid, body.member_uids, background_tasks, body.name)
    return _group_response(group_ref.id, group_ref.get().to_dict(), uid)


@router.post("/{group_id}/members", response_model=GroupResponse)
def add_members(group_id: str, body: GroupMembersAddRequest, background_tasks: BackgroundTasks, current_user: dict = Depends(get_current_user)):
    """Creator adds friends directly; no accept step (V3 brief 6.5)."""
    uid = current_user["uid"]
    db = get_firestore()
    group_ref, data = _require_admin(db, group_id, uid)
    _add_members_direct(db, group_ref, group_id, uid, body.member_uids, background_tasks, data.get("name", "your group"))
    return _group_response(group_id, group_ref.get().to_dict(), uid)


@router.get("", response_model=list[GroupResponse])
def list_groups(limit: int = Query(default=DEFAULT_LIMIT, le=MAX_LIMIT), current_user: dict = Depends(get_current_user)):
    uid = current_user["uid"]
    db = get_firestore()
    results = []
    for member_doc in db.collection_group("members").where("uid", "==", uid).limit(limit).stream():
        group_ref = member_doc.reference.parent.parent
        if group_ref is None:
            continue
        group_doc = group_ref.get()
        if group_doc.exists and not group_doc.to_dict().get("dissolved", False):
            results.append(_group_response(group_doc.id, group_doc.to_dict(), uid))
    return results


@router.get("/invites/incoming", response_model=list[GroupInviteResponse])
def incoming_invites(limit: int = Query(default=DEFAULT_LIMIT, le=MAX_LIMIT), current_user: dict = Depends(get_current_user)):
    uid = current_user["uid"]
    db = get_firestore()
    # Query only by recipient to avoid requiring a composite Firestore index in local/dev.
    docs = db.collection("group_invites").where("recipient_uid", "==", uid).limit(MAX_LIMIT).stream()
    responses = []
    for doc in docs:
        data = doc.to_dict()
        if data.get("status") == GroupInviteStatus.pending.value:
            responses.append(_invite_response(doc.id, data, uid))
    responses.sort(key=lambda item: item.created_at, reverse=True)
    return responses[:limit]


@router.get("/{group_id}", response_model=GroupResponse)
def get_group(group_id: str, current_user: dict = Depends(get_current_user)):
    uid = current_user["uid"]
    db = get_firestore()
    _, data = _require_member(db, group_id, uid)
    return _group_response(group_id, data, uid)


@router.put("/{group_id}", response_model=GroupResponse)
def update_group(group_id: str, body: GroupUpdateRequest, current_user: dict = Depends(get_current_user)):
    uid = current_user["uid"]
    db = get_firestore()
    group_ref, _ = _require_admin(db, group_id, uid)
    group_ref.update({"name": body.name, "updated_at": SERVER_TIMESTAMP})
    return _group_response(group_id, group_ref.get().to_dict(), uid)


@router.post("/{group_id}/invites", response_model=GroupInviteResponse, status_code=status.HTTP_201_CREATED)
def invite_member(group_id: str, body: GroupInviteCreateRequest, background_tasks: BackgroundTasks, current_user: dict = Depends(get_current_user)):
    uid = current_user["uid"]
    recipient_uid = validate_document_id(body.recipient_uid)
    if recipient_uid == uid:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Cannot invite yourself")
    db = get_firestore()
    group_ref, data = _require_admin(db, group_id, uid)
    if not db.collection("users").document(uid).collection("friends").document(recipient_uid).get().exists:
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Groups can only contain friends")
    if _is_member(db, group_id, recipient_uid):
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="User is already a member")
    existing = db.collection("group_invites").where("recipient_uid", "==", recipient_uid).limit(MAX_LIMIT).stream()
    if any(
        doc.to_dict().get("group_id") == group_id
        and doc.to_dict().get("status") == GroupInviteStatus.pending.value
        for doc in existing
    ):
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Group invite already pending")
    invite_ref = db.collection("group_invites").document()
    invite_ref.set({
        "group_id": group_id,
        "inviter_uid": uid,
        "recipient_uid": recipient_uid,
        "status": GroupInviteStatus.pending.value,
        "created_at": SERVER_TIMESTAMP,
        "responded_at": None,
    })
    triggers.group_invite_received(
        background_tasks, invite_id=invite_ref.id, group_id=group_id, recipient_uid=recipient_uid,
        inviter_name=_display_name(db, uid), group_name=data.get("name", "your group"),
    )
    return _invite_response(invite_ref.id, invite_ref.get().to_dict(), uid)


@router.post("/invites/{invite_id}/accept", response_model=GroupInviteResponse)
def accept_invite(invite_id: str, background_tasks: BackgroundTasks, current_user: dict = Depends(get_current_user)):
    validate_document_id(invite_id)
    uid = current_user["uid"]
    db = get_firestore()
    invite_ref = db.collection("group_invites").document(invite_id)
    invite_doc = invite_ref.get()
    if not invite_doc.exists or invite_doc.to_dict().get("recipient_uid") != uid:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Group invite not found")
    data = invite_doc.to_dict()
    if data.get("status") != GroupInviteStatus.pending.value:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Group invite already resolved")
    group_ref, group_data = _require_group(db, data["group_id"])
    now = _now()
    invite_ref.update({"status": GroupInviteStatus.accepted.value, "responded_at": now})
    group_ref.collection("members").document(uid).set({"uid": uid, "joined_at": now, "is_admin": False})
    group_ref.update({"updated_at": SERVER_TIMESTAMP})
    _notify(db, uid, "group_joined", {"group_id": data["group_id"], "group_name": group_data.get("name", "")})
    # Notify existing members (everyone but the new joiner) that someone joined.
    others = [m for m in _member_ids(db, data["group_id"]) if m != uid]
    if others:
        triggers.group_invite_accepted(
            background_tasks, group_id=data["group_id"], recipient_uids=others,
            member_name=_display_name(db, uid), group_name=group_data.get("name", "your group"),
        )
    return _invite_response(invite_id, invite_ref.get().to_dict(), uid)


@router.post("/invites/{invite_id}/decline", response_model=GroupInviteResponse)
def decline_invite(invite_id: str, current_user: dict = Depends(get_current_user)):
    validate_document_id(invite_id)
    uid = current_user["uid"]
    db = get_firestore()
    invite_ref = db.collection("group_invites").document(invite_id)
    invite_doc = invite_ref.get()
    if not invite_doc.exists or invite_doc.to_dict().get("recipient_uid") != uid:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Group invite not found")
    if invite_doc.to_dict().get("status") != GroupInviteStatus.pending.value:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Group invite already resolved")
    invite_ref.update({"status": GroupInviteStatus.declined.value, "responded_at": SERVER_TIMESTAMP})
    return _invite_response(invite_id, invite_ref.get().to_dict(), uid)


@router.post("/{group_id}/transfer", response_model=GroupResponse)
def transfer_ownership(group_id: str, body: GroupTransferRequest, current_user: dict = Depends(get_current_user)):
    uid = current_user["uid"]
    new_admin_uid = validate_document_id(body.new_admin_uid)
    db = get_firestore()
    group_ref, _ = _require_admin(db, group_id, uid)
    if not _is_member(db, group_id, new_admin_uid):
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Member not found")
    group_ref.update({"admin_uid": new_admin_uid, "updated_at": SERVER_TIMESTAMP})
    group_ref.collection("members").document(uid).update({"is_admin": False})
    group_ref.collection("members").document(new_admin_uid).update({"is_admin": True})
    _notify(db, new_admin_uid, "group_admin_promoted", {"group_id": group_id})
    return _group_response(group_id, group_ref.get().to_dict(), uid)


@router.delete("/{group_id}/members/{member_uid}", status_code=status.HTTP_200_OK)
def remove_member(group_id: str, member_uid: str, body: NegativeActionAnswers, background_tasks: BackgroundTasks, current_user: dict = Depends(get_current_user)):
    uid = current_user["uid"]
    member_uid = validate_document_id(member_uid)
    if member_uid == uid:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Use leave group instead")
    db = get_firestore()
    group_ref, group_data = _require_admin(db, group_id, uid)
    member_ref = group_ref.collection("members").document(member_uid)
    if not member_ref.get().exists:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Member not found")
    member_ref.delete()
    group_ref.update({"updated_at": SERVER_TIMESTAMP})
    _save_negative_action(db, uid, "remove_group_member", body.answers, group_id=group_id, target_uid=member_uid)
    triggers.group_member_removed(
        background_tasks, group_id=group_id, recipient_uid=member_uid,
        group_name=group_data.get("name", "your group"),
    )
    return {"detail": "Member removed"}


@router.delete("/{group_id}/leave", status_code=status.HTTP_200_OK)
def leave_group(group_id: str, body: NegativeActionAnswers, current_user: dict = Depends(get_current_user)):
    uid = current_user["uid"]
    db = get_firestore()
    group_ref, group_data = _require_member(db, group_id, uid)
    was_admin = group_data.get("admin_uid") == uid
    group_ref.collection("members").document(uid).delete()
    if was_admin:
        _promote_next_or_dissolve(db, group_ref, group_id, uid)
    else:
        group_ref.update({"updated_at": SERVER_TIMESTAMP})
    _save_negative_action(db, uid, "leave_group", body.answers, group_id=group_id)
    group_name = group_data.get("name", "")
    for member_doc in group_ref.collection("members").stream():
        _notify(db, member_doc.id, "group_member_left",
                {"group_id": group_id, "uid": uid, "group_name": group_name})
    return {"detail": "Left group"}


@router.delete("/{group_id}", status_code=status.HTTP_200_OK)
def dissolve_group(group_id: str, body: NegativeActionAnswers, background_tasks: BackgroundTasks, current_user: dict = Depends(get_current_user)):
    uid = current_user["uid"]
    db = get_firestore()
    group_ref, group_data = _require_admin(db, group_id, uid)
    member_ids = [doc.id for doc in group_ref.collection("members").stream()]
    for member_uid in member_ids:
        group_ref.collection("members").document(member_uid).delete()
        # group_dissolved push + inbox is handled below via triggers.group_dissolved.
    # Delete all nudge card history for this group's feed (PRD: deleted for everyone).
    for nudge_doc in db.collection("nudges").where("feed_id", "==", f"group_{group_id}").stream():
        nudge_doc.reference.delete()
    group_ref.update({"dissolved": True, "dissolved_at": SERVER_TIMESTAMP, "updated_at": SERVER_TIMESTAMP})
    _save_negative_action(db, uid, "dissolve_group", body.answers, group_id=group_id)
    recipients = [m for m in member_ids if m != uid]
    if recipients:
        triggers.group_dissolved(
            background_tasks, group_id=group_id, recipient_uids=recipients,
            group_name=group_data.get("name", "your group"),
        )
    return {"detail": "Group dissolved"}
