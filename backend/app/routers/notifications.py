"""In-app notification inbox.

The dispatcher mirrors every dispatched notification into
users/{uid}/notifications/{key} (see NotificationService._write_inbox). These
endpoints expose that feed to the app: list, unread count, and read-state
updates. Push delivery is the alert channel; this is the durable history.
"""

from google.cloud import firestore

from fastapi import APIRouter, Depends, HTTPException, Query, status

from app.dependencies import get_current_user
from app.firebase import get_firestore
from app.schemas import (
    NotificationListResponse,
    NotificationResponse,
    NotificationUnreadCountResponse,
)

router = APIRouter(prefix="/notifications", tags=["notifications"])

# Cap how many unread we count for the badge — anything past this shows as "99+".
UNREAD_COUNT_CAP = 100
DEFAULT_LIMIT = 30
MAX_LIMIT = 100


def _collection(db, uid: str):
    return db.collection("users").document(uid).collection("notifications")


def _to_response(doc) -> NotificationResponse:
    data = doc.to_dict() or {}
    return NotificationResponse(
        id=doc.id,
        type=data.get("type", ""),
        template_id=data.get("template_id", ""),
        title=data.get("title", ""),
        body=data.get("body", ""),
        data=data.get("data", {}) or {},
        read=data.get("read", False),
        created_at=data["created_at"],
    )


def _unread_count(db, uid: str) -> int:
    docs = (
        _collection(db, uid)
        .where("read", "==", False)
        .limit(UNREAD_COUNT_CAP)
        .stream()
    )
    return sum(1 for _ in docs)


@router.get("", response_model=NotificationListResponse)
def list_notifications(
    limit: int = Query(DEFAULT_LIMIT, ge=1, le=MAX_LIMIT),
    current_user: dict = Depends(get_current_user),
):
    uid = current_user["uid"]
    db = get_firestore()
    docs = (
        _collection(db, uid)
        .order_by("created_at", direction=firestore.Query.DESCENDING)
        .limit(limit)
        .stream()
    )
    items = [_to_response(d) for d in docs]
    return NotificationListResponse(items=items, unread_count=_unread_count(db, uid))


@router.get("/unread-count", response_model=NotificationUnreadCountResponse)
def unread_count(current_user: dict = Depends(get_current_user)):
    db = get_firestore()
    return NotificationUnreadCountResponse(unread_count=_unread_count(db, current_user["uid"]))


@router.post("/read-all", status_code=status.HTTP_200_OK)
def mark_all_read(current_user: dict = Depends(get_current_user)):
    uid = current_user["uid"]
    db = get_firestore()
    batch = db.batch()
    count = 0
    for doc in _collection(db, uid).where("read", "==", False).limit(500).stream():
        batch.update(doc.reference, {"read": True})
        count += 1
    if count:
        batch.commit()
    return {"updated": count}


@router.post("/{notification_id}/read", status_code=status.HTTP_200_OK)
def mark_read(notification_id: str, current_user: dict = Depends(get_current_user)):
    if not notification_id or "/" in notification_id:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid id")
    uid = current_user["uid"]
    db = get_firestore()
    ref = _collection(db, uid).document(notification_id)
    if not ref.get().exists:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Notification not found")
    ref.update({"read": True})
    return {"detail": "Marked read"}
