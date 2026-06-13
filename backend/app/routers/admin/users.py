"""User Management: search, account view, and three logged administrative actions
(revoke creator, force username change, deactivate)."""

from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Query, status
from google.cloud import firestore

from app.audit import record_admin_action
from app.dependencies import get_admin_user, validate_document_id
from app.firebase import get_firestore
from app.schemas import (
    AdminUserDetailResponse,
    AdminUserGroup,
    AdminUserListItem,
    ForceUsernameRequest,
    ReasonRequest,
)

router = APIRouter()


def _list_item(uid: str, data: dict) -> AdminUserListItem:
    return AdminUserListItem(
        uid=uid,
        display_name=data.get("display_name") or "(no name)",
        username=data.get("username") or "",
        phone=data.get("phone"),
        photo_url=data.get("photo_url"),
        is_creator=bool(data.get("is_creator")),
        deactivated=bool(data.get("deactivated")),
    )


@router.get("/users/search", response_model=list[AdminUserListItem])
def search_users(q: str = Query(min_length=1, max_length=80), _: dict = Depends(get_admin_user)):
    """Search by username, display name, or phone. Case-insensitive substring match
    over a bounded scan (admin tool, low volume)."""
    db = get_firestore()
    needle = q.strip().lower()
    out: list[AdminUserListItem] = []
    for doc in db.collection("users").limit(1000).stream():
        data = doc.to_dict() or {}
        haystack = " ".join(
            str(data.get(f, "")).lower()
            for f in ("username", "display_name", "phone")
        )
        if needle in haystack:
            out.append(_list_item(doc.id, data))
        if len(out) >= 50:
            break
    return out


@router.get("/users/{uid}", response_model=AdminUserDetailResponse)
def get_user(uid: str, _: dict = Depends(get_admin_user)):
    validate_document_id(uid)
    db = get_firestore()
    doc = db.collection("users").document(uid).get()
    if not doc.exists:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
    data = doc.to_dict()

    friends_count = len(list(db.collection("users").document(uid).collection("friends").stream()))
    quests_activated = len(list(db.collection("users").document(uid).collection("quest_activations").stream()))
    events_joined = sum(
        1
        for ev in db.collection("events").limit(500).stream()
        if ev.reference.collection("joinees").document(uid).get().exists
    )

    groups: list[AdminUserGroup] = []
    for member_doc in db.collection_group("members").where("uid", "==", uid).stream():
        group_ref = member_doc.reference.parent.parent
        if group_ref is None:
            continue
        gdata = group_ref.get().to_dict() or {}
        if gdata.get("dissolved"):
            continue
        groups.append(
            AdminUserGroup(
                id=group_ref.id,
                name=gdata.get("name", ""),
                is_admin=gdata.get("admin_uid") == uid,
            )
        )

    base = _list_item(uid, data)
    return AdminUserDetailResponse(
        **base.model_dump(),
        friends_count=friends_count,
        events_joined=events_joined,
        current_streak=int(data.get("current_streak", 0) or 0),
        groups=groups,
    )


@router.post("/users/{uid}/revoke-creator", status_code=status.HTTP_200_OK)
def revoke_creator(uid: str, body: ReasonRequest, admin: dict = Depends(get_admin_user)):
    validate_document_id(uid)
    db = get_firestore()
    user_ref = db.collection("users").document(uid)
    if not user_ref.get().exists:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
    user_ref.update({"is_creator": False})
    app_ref = db.collection("creator_applications").document(uid)
    if app_ref.get().exists:
        app_ref.update({"status": "revoked", "reviewed_at": datetime.now(timezone.utc)})
    record_admin_action(db, admin["uid"], "user.revoke_creator", target_type="user", target_id=uid, reason=body.reason)
    return {"detail": "Creator status revoked"}


@firestore.transactional
def _force_username_txn(transaction, db, uid, new_username):
    username_ref = db.collection("usernames").document(new_username)
    username_doc = username_ref.get(transaction=transaction)
    if username_doc.exists and username_doc.to_dict().get("uid") != uid:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Username already taken")

    user_ref = db.collection("users").document(uid)
    user_doc = user_ref.get(transaction=transaction)
    if not user_doc.exists:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")

    old_username = (user_doc.to_dict() or {}).get("username", "")
    if old_username and old_username != new_username:
        transaction.delete(db.collection("usernames").document(old_username))
    transaction.set(username_ref, {"uid": uid})
    transaction.update(user_ref, {"username": new_username})


@router.post("/users/{uid}/force-username", status_code=status.HTTP_200_OK)
def force_username(uid: str, body: ForceUsernameRequest, admin: dict = Depends(get_admin_user)):
    validate_document_id(uid)
    db = get_firestore()
    _force_username_txn(db.transaction(), db, uid, body.new_username)
    record_admin_action(
        db, admin["uid"], "user.force_username",
        target_type="user", target_id=uid, reason=body.reason,
        metadata={"new_username": body.new_username},
    )
    return {"detail": "Username changed", "new_username": body.new_username}


@router.post("/users/{uid}/deactivate", status_code=status.HTTP_200_OK)
def deactivate_user(uid: str, body: ReasonRequest, admin: dict = Depends(get_admin_user)):
    """Hide the profile and expire active nudge cards without deleting data."""
    validate_document_id(uid)
    db = get_firestore()
    user_ref = db.collection("users").document(uid)
    if not user_ref.get().exists:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")

    now = datetime.now(timezone.utc)
    user_ref.update({"deactivated": True, "deactivated_at": now})
    # Expire active nudge cards involving this user.
    for nudge_doc in db.collection("nudges").where("participant_uids", "array_contains", uid).stream():
        ndata = nudge_doc.to_dict() or {}
        if ndata.get("status") in ("active", "accepted_timer"):
            nudge_doc.reference.update({"status": "expired", "resolved_at": now})

    record_admin_action(db, admin["uid"], "user.deactivate", target_type="user", target_id=uid, reason=body.reason)
    return {"detail": "Account deactivated"}
