from datetime import datetime, timedelta, timezone
from uuid import uuid4
import hashlib
import secrets
import re

from fastapi import APIRouter, Depends, HTTPException, Query, status
from google.cloud import firestore
from google.cloud.firestore import SERVER_TIMESTAMP

from app.config import FRIEND_INVITE_BASE_URL
from app.dependencies import get_current_user, validate_document_id
from app.firebase import get_firestore
from app.schemas import (
    BlockedUserResponse,
    ContactMatchResponse,
    ContactSyncRequest,
    ContactSyncResponse,
    FriendInviteCreateResponse,
    FriendInviteResolveResponse,
    FriendRequestCreateRequest,
    FriendRequestResponse,
    FriendRequestStatus,
    FriendResponse,
    FriendStatsResponse,
    FriendshipStatus,
    NegativeActionAnswers,
    PublicUserResponse,
    UserSearchResponse,
)

router = APIRouter(prefix="/friends", tags=["friends"])

DEFAULT_LIMIT = 50
MAX_LIMIT = 100
ONLINE_WINDOW_SECONDS = 90


def _now() -> datetime:
    return datetime.now(timezone.utc)


def _normalize_phone(phone: str) -> str:
    digits = re.sub(r"\D+", "", phone)
    if len(digits) == 10:
        return f"+91{digits}"
    if digits.startswith("91") and len(digits) == 12:
        return f"+{digits}"
    if phone.strip().startswith("+") and digits:
        return f"+{digits}"
    return digits or phone.strip()


def _is_online(data: dict) -> bool:
    last_seen = data.get("last_seen_at")
    if last_seen is None:
        return False
    if last_seen.tzinfo is None:
        last_seen = last_seen.replace(tzinfo=timezone.utc)
    return last_seen >= _now() - timedelta(seconds=ONLINE_WINDOW_SECONDS)


def _pair_request_id(uid_a: str, uid_b: str) -> str:
    first, second = sorted([uid_a, uid_b])
    return hashlib.sha256(f"{first}:{second}".encode()).hexdigest()


def _friendship_status(viewer_uid: str, target_uid: str) -> FriendshipStatus:
    if viewer_uid == target_uid:
        return FriendshipStatus.none

    db = get_firestore()
    if db.collection("users").document(viewer_uid).collection("blocks").document(target_uid).get().exists:
        return FriendshipStatus.blocked
    if db.collection("users").document(target_uid).collection("blocks").document(viewer_uid).get().exists:
        return FriendshipStatus.blocked_by
    if db.collection("users").document(viewer_uid).collection("friends").document(target_uid).get().exists:
        return FriendshipStatus.friends

    req = db.collection("friend_requests").document(_pair_request_id(viewer_uid, target_uid)).get()
    if req.exists:
        data = req.to_dict()
        if data.get("status") == FriendRequestStatus.pending.value:
            if data.get("requester_uid") == viewer_uid:
                return FriendshipStatus.request_sent
            return FriendshipStatus.request_received

    return FriendshipStatus.none


def public_user_from_doc(uid: str, data: dict, viewer_uid: str | None = None) -> PublicUserResponse:
    return PublicUserResponse(
        uid=uid,
        display_name=data.get("display_name", ""),
        username=data.get("username", ""),
        photo_url=data.get("photo_url") or None,
        online=_is_online(data),
        friendship_status=_friendship_status(viewer_uid, uid) if viewer_uid else FriendshipStatus.none,
    )


def _get_user_or_404(uid: str):
    validate_document_id(uid)
    db = get_firestore()
    doc = db.collection("users").document(uid).get()
    if not doc.exists:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
    return doc


def _resolve_recipient(body: FriendRequestCreateRequest, current_uid: str) -> str:
    db = get_firestore()
    identifiers = [body.recipient_uid, body.username, body.phone]
    if sum(1 for value in identifiers if value) != 1:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Provide exactly one of recipient_uid, username, or phone",
        )

    if body.recipient_uid:
        validate_document_id(body.recipient_uid)
        recipient_uid = body.recipient_uid
    elif body.username:
        username_doc = db.collection("usernames").document(body.username.lower()).get()
        if not username_doc.exists:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
        recipient_uid = username_doc.to_dict()["uid"]
    else:
        phone = _normalize_phone(body.phone or "")
        matches = list(db.collection("users").where("phone", "==", phone).limit(1).stream())
        if not matches:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
        recipient_uid = matches[0].id

    if recipient_uid == current_uid:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Cannot friend yourself")
    _get_user_or_404(recipient_uid)
    return recipient_uid


def _request_response(request_id: str, data: dict, viewer_uid: str) -> FriendRequestResponse:
    db = get_firestore()
    requester_doc = db.collection("users").document(data["requester_uid"]).get()
    recipient_doc = db.collection("users").document(data["recipient_uid"]).get()
    return FriendRequestResponse(
        id=request_id,
        requester=public_user_from_doc(requester_doc.id, requester_doc.to_dict() or {}, viewer_uid),
        recipient=public_user_from_doc(recipient_doc.id, recipient_doc.to_dict() or {}, viewer_uid),
        status=FriendRequestStatus(data.get("status", FriendRequestStatus.pending.value)),
        created_at=data["created_at"],
        responded_at=data.get("responded_at"),
    )


@router.post("/presence", status_code=status.HTTP_200_OK)
def update_presence(current_user: dict = Depends(get_current_user)):
    db = get_firestore()
    db.collection("users").document(current_user["uid"]).update({"last_seen_at": SERVER_TIMESTAMP})
    return {"detail": "Presence updated"}


@router.get("/search", response_model=UserSearchResponse)
def search_users(
    query: str = Query(min_length=2, max_length=50),
    limit: int = Query(default=20, le=MAX_LIMIT),
    current_user: dict = Depends(get_current_user),
):
    uid = current_user["uid"]
    db = get_firestore()
    q = query.strip().lower()
    users: dict[str, dict] = {}

    username_matches = db.collection("users").order_by("username").start_at([q]).end_at([q + "\uf8ff"]).limit(limit).stream()
    for doc in username_matches:
        if doc.id != uid:
            users[doc.id] = doc.to_dict()

    name_matches = db.collection("users").order_by("display_name_lower").start_at([q]).end_at([q + "\uf8ff"]).limit(limit).stream()
    for doc in name_matches:
        if doc.id != uid:
            users[doc.id] = doc.to_dict()

    phone = _normalize_phone(query)
    if len(phone) >= 5:
        for doc in db.collection("users").where("phone", "==", phone).limit(limit).stream():
            if doc.id != uid:
                users[doc.id] = doc.to_dict()

    return UserSearchResponse(
        users=[public_user_from_doc(user_uid, data, uid) for user_uid, data in list(users.items())[:limit]]
    )


@router.post("/contacts/sync", response_model=ContactSyncResponse)
def sync_contacts(body: ContactSyncRequest, current_user: dict = Depends(get_current_user)):
    uid = current_user["uid"]
    db = get_firestore()
    normalized = []
    seen = set()
    for phone in body.phone_numbers:
        value = _normalize_phone(phone)
        if value and value not in seen:
            seen.add(value)
            normalized.append(value)

    matches: list[ContactMatchResponse] = []
    for i in range(0, len(normalized), 10):
        chunk = normalized[i : i + 10]
        for doc in db.collection("users").where("phone", "in", chunk).stream():
            if doc.id == uid:
                continue
            data = doc.to_dict()
            matches.append(
                ContactMatchResponse(
                    phone=data.get("phone", ""),
                    user=public_user_from_doc(doc.id, data, uid),
                )
            )
    return ContactSyncResponse(matches=matches)


@router.post("/requests", response_model=FriendRequestResponse, status_code=status.HTTP_201_CREATED)
def send_friend_request(body: FriendRequestCreateRequest, current_user: dict = Depends(get_current_user)):
    requester_uid = current_user["uid"]
    recipient_uid = _resolve_recipient(body, requester_uid)
    db = get_firestore()

    if _friendship_status(requester_uid, recipient_uid) == FriendshipStatus.friends:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Already friends")
    if _friendship_status(requester_uid, recipient_uid) in (FriendshipStatus.blocked, FriendshipStatus.blocked_by):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Friend request unavailable")

    request_id = _pair_request_id(requester_uid, recipient_uid)
    request_ref = db.collection("friend_requests").document(request_id)
    existing = request_ref.get()
    if existing.exists and existing.to_dict().get("status") == FriendRequestStatus.pending.value:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Friend request already pending")

    data = {
        "requester_uid": requester_uid,
        "recipient_uid": recipient_uid,
        "status": FriendRequestStatus.pending.value,
        "created_at": SERVER_TIMESTAMP,
        "responded_at": None,
    }
    request_ref.set(data)
    saved = request_ref.get().to_dict()
    return _request_response(request_id, saved, requester_uid)


@router.get("/requests/incoming", response_model=list[FriendRequestResponse])
def incoming_requests(
    limit: int = Query(default=DEFAULT_LIMIT, le=MAX_LIMIT),
    current_user: dict = Depends(get_current_user),
):
    uid = current_user["uid"]
    db = get_firestore()
    # Query only by recipient to avoid requiring a composite Firestore index in local/dev.
    docs = db.collection("friend_requests").where("recipient_uid", "==", uid).limit(MAX_LIMIT).stream()
    responses = []
    for doc in docs:
        data = doc.to_dict()
        if data.get("status") != FriendRequestStatus.pending.value:
            continue
        if _friendship_status(uid, data["requester_uid"]) in (FriendshipStatus.blocked, FriendshipStatus.blocked_by):
            continue
        responses.append(_request_response(doc.id, data, uid))
    responses.sort(key=lambda item: item.created_at, reverse=True)
    return responses[:limit]


@router.get("/requests/outgoing", response_model=list[FriendRequestResponse])
def outgoing_requests(
    limit: int = Query(default=DEFAULT_LIMIT, le=MAX_LIMIT),
    current_user: dict = Depends(get_current_user),
):
    uid = current_user["uid"]
    db = get_firestore()
    # Query only by requester to avoid requiring a composite Firestore index in local/dev.
    docs = db.collection("friend_requests").where("requester_uid", "==", uid).limit(MAX_LIMIT).stream()
    responses = []
    for doc in docs:
        data = doc.to_dict()
        if data.get("status") == FriendRequestStatus.pending.value:
            responses.append(_request_response(doc.id, data, uid))
    responses.sort(key=lambda item: item.created_at, reverse=True)
    return responses[:limit]


@firestore.transactional
def _accept_request_txn(transaction, db, request_ref, uid: str):
    request_doc = request_ref.get(transaction=transaction)
    if not request_doc.exists:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Friend request not found")
    data = request_doc.to_dict()
    if data["recipient_uid"] != uid:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Friend request not found")
    if data.get("status") != FriendRequestStatus.pending.value:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Friend request already resolved")

    requester_uid = data["requester_uid"]
    now = _now()
    transaction.update(request_ref, {"status": FriendRequestStatus.accepted.value, "responded_at": now})
    transaction.set(db.collection("users").document(uid).collection("friends").document(requester_uid), {"uid": requester_uid, "friends_since": now})
    transaction.set(db.collection("users").document(requester_uid).collection("friends").document(uid), {"uid": uid, "friends_since": now})
    return {**data, "status": FriendRequestStatus.accepted.value, "responded_at": now}


@router.post("/requests/{request_id}/accept", response_model=FriendRequestResponse)
def accept_request(request_id: str, current_user: dict = Depends(get_current_user)):
    validate_document_id(request_id)
    uid = current_user["uid"]
    db = get_firestore()
    request_ref = db.collection("friend_requests").document(request_id)
    doc = request_ref.get()
    if doc.exists and _friendship_status(uid, doc.to_dict()["requester_uid"]) in (FriendshipStatus.blocked, FriendshipStatus.blocked_by):
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Friend request unavailable")
    data = _accept_request_txn(db.transaction(), db, request_ref, uid)
    return _request_response(request_id, data, uid)


@router.post("/requests/{request_id}/decline", response_model=FriendRequestResponse)
def decline_request(request_id: str, current_user: dict = Depends(get_current_user)):
    validate_document_id(request_id)
    uid = current_user["uid"]
    db = get_firestore()
    request_ref = db.collection("friend_requests").document(request_id)
    doc = request_ref.get()
    if not doc.exists or doc.to_dict().get("recipient_uid") != uid:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Friend request not found")
    data = doc.to_dict()
    if data.get("status") != FriendRequestStatus.pending.value:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Friend request already resolved")
    request_ref.update({"status": FriendRequestStatus.declined.value, "responded_at": SERVER_TIMESTAMP})
    updated = request_ref.get().to_dict()
    return _request_response(request_id, updated, uid)


@router.get("/stats", response_model=FriendStatsResponse)
def friend_stats(current_user: dict = Depends(get_current_user)):
    uid = current_user["uid"]
    db = get_firestore()
    friends_count = len(list(db.collection("users").document(uid).collection("friends").stream()))
    incoming_count = sum(
        1
        for doc in db.collection("friend_requests").where("recipient_uid", "==", uid).stream()
        if doc.to_dict().get("status") == FriendRequestStatus.pending.value
    )
    outgoing_count = sum(
        1
        for doc in db.collection("friend_requests").where("requester_uid", "==", uid).stream()
        if doc.to_dict().get("status") == FriendRequestStatus.pending.value
    )
    return FriendStatsResponse(
        friends_count=friends_count,
        incoming_request_count=incoming_count,
        outgoing_request_count=outgoing_count,
    )


@router.get("", response_model=list[FriendResponse])
def list_friends(
    limit: int = Query(default=DEFAULT_LIMIT, le=MAX_LIMIT),
    current_user: dict = Depends(get_current_user),
):
    uid = current_user["uid"]
    db = get_firestore()
    friend_docs = db.collection("users").document(uid).collection("friends").order_by("friends_since", direction=firestore.Query.DESCENDING).limit(limit).stream()
    responses = []
    for friend_doc in friend_docs:
        user_doc = db.collection("users").document(friend_doc.id).get()
        if not user_doc.exists:
            continue
        responses.append(
            FriendResponse(
                user=public_user_from_doc(user_doc.id, user_doc.to_dict(), uid),
                friends_since=friend_doc.to_dict()["friends_since"],
            )
        )
    return responses


@router.delete("/{friend_uid}", status_code=status.HTTP_200_OK)
def unfriend(friend_uid: str, body: NegativeActionAnswers, current_user: dict = Depends(get_current_user)):
    validate_document_id(friend_uid)
    uid = current_user["uid"]
    db = get_firestore()
    if not db.collection("users").document(uid).collection("friends").document(friend_uid).get().exists:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Friend not found")
    db.collection("users").document(uid).collection("friends").document(friend_uid).delete()
    db.collection("users").document(friend_uid).collection("friends").document(uid).delete()
    db.collection("negative_action_responses").document(str(uuid4())).set({
        "actor_uid": uid,
        "target_uid": friend_uid,
        "action_type": "unfriend_user",
        "answers": body.answers,
        "created_at": SERVER_TIMESTAMP,
    })
    return {"detail": "Unfriended successfully"}


@router.post("/blocks/{target_uid}", response_model=BlockedUserResponse, status_code=status.HTTP_201_CREATED)
def block_user(target_uid: str, body: NegativeActionAnswers, current_user: dict = Depends(get_current_user)):
    validate_document_id(target_uid)
    uid = current_user["uid"]
    if target_uid == uid:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Cannot block yourself")
    user_doc = _get_user_or_404(target_uid)
    db = get_firestore()
    now = _now()
    db.collection("users").document(uid).collection("blocks").document(target_uid).set({"uid": target_uid, "blocked_at": now})
    request_ref = db.collection("friend_requests").document(_pair_request_id(uid, target_uid))
    if request_ref.get().exists and request_ref.get().to_dict().get("status") == FriendRequestStatus.pending.value:
        request_ref.update({"status": FriendRequestStatus.declined.value, "responded_at": SERVER_TIMESTAMP})
    db.collection("negative_action_responses").document(str(uuid4())).set({
        "actor_uid": uid,
        "target_uid": target_uid,
        "action_type": "block_user",
        "answers": body.answers,
        "created_at": SERVER_TIMESTAMP,
    })
    return BlockedUserResponse(user=public_user_from_doc(target_uid, user_doc.to_dict(), uid), blocked_at=now)


@router.get("/blocks", response_model=list[BlockedUserResponse])
def list_blocks(current_user: dict = Depends(get_current_user)):
    uid = current_user["uid"]
    db = get_firestore()
    responses = []
    for block_doc in db.collection("users").document(uid).collection("blocks").order_by("blocked_at", direction=firestore.Query.DESCENDING).stream():
        user_doc = db.collection("users").document(block_doc.id).get()
        if not user_doc.exists:
            continue
        responses.append(BlockedUserResponse(
            user=public_user_from_doc(user_doc.id, user_doc.to_dict() or {}, uid),
            blocked_at=block_doc.to_dict()["blocked_at"],
        ))
    return responses


@router.delete("/blocks/{target_uid}", status_code=status.HTTP_200_OK)
def unblock_user(target_uid: str, body: NegativeActionAnswers, current_user: dict = Depends(get_current_user)):
    validate_document_id(target_uid)
    uid = current_user["uid"]
    db = get_firestore()
    block_ref = db.collection("users").document(uid).collection("blocks").document(target_uid)
    if not block_ref.get().exists:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Blocked user not found")
    block_ref.delete()
    db.collection("negative_action_responses").document(str(uuid4())).set({
        "actor_uid": uid,
        "target_uid": target_uid,
        "action_type": "unblock_user",
        "answers": body.answers,
        "created_at": SERVER_TIMESTAMP,
    })
    return {"detail": "Unblocked successfully"}


@router.post("/invites", response_model=FriendInviteCreateResponse, status_code=status.HTTP_201_CREATED)
def create_invite(current_user: dict = Depends(get_current_user)):
    uid = current_user["uid"]
    db = get_firestore()
    token = secrets.token_urlsafe(18)
    now = _now()
    db.collection("friend_invites").document(token).set({"creator_uid": uid, "created_at": now})
    return FriendInviteCreateResponse(token=token, invite_url=f"{FRIEND_INVITE_BASE_URL}/{token}", created_at=now)


@router.get("/invites/{token}", response_model=FriendInviteResolveResponse)
def resolve_invite(token: str, current_user: dict = Depends(get_current_user)):
    validate_document_id(token)
    uid = current_user["uid"]
    db = get_firestore()
    invite_doc = db.collection("friend_invites").document(token).get()
    if not invite_doc.exists:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Invite not found")
    inviter_uid = invite_doc.to_dict()["creator_uid"]
    inviter_doc = _get_user_or_404(inviter_uid)
    return FriendInviteResolveResponse(inviter=public_user_from_doc(inviter_uid, inviter_doc.to_dict(), uid), token=token)


@router.post("/invites/{token}/request", response_model=FriendRequestResponse, status_code=status.HTTP_201_CREATED)
def request_from_invite(token: str, current_user: dict = Depends(get_current_user)):
    validate_document_id(token)
    db = get_firestore()
    invite_doc = db.collection("friend_invites").document(token).get()
    if not invite_doc.exists:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Invite not found")
    inviter_uid = invite_doc.to_dict()["creator_uid"]
    return send_friend_request(FriendRequestCreateRequest(recipient_uid=inviter_uid), current_user)
