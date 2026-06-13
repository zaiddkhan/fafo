"""Creator Queue: list, detail (with reapplication history), approve, revoke."""

from fastapi import APIRouter, Depends, HTTPException, status
from google.cloud.firestore import SERVER_TIMESTAMP

from app.audit import record_admin_action
from app.dependencies import get_admin_user, validate_document_id
from app.firebase import get_firestore
from app.schemas import (
    CreatorDetailResponse,
    CreatorHistoryEntry,
    CreatorListItem,
)

router = APIRouter()

# Pending / reapplied first, then approved, revoked, rejected.
_STATUS_ORDER = {"reapplied": 0, "pending": 1, "approved": 2, "revoked": 3, "rejected": 4}


def _epoch(value) -> float:
    try:
        return value.timestamp()
    except Exception:
        return 0.0


@router.get("/creators", response_model=list[CreatorListItem])
def list_creators(_: dict = Depends(get_admin_user)):
    db = get_firestore()
    items: list[CreatorListItem] = []
    for doc in db.collection("creator_applications").stream():
        data = doc.to_dict() or {}
        uid = doc.id
        user_doc = db.collection("users").document(uid).get()
        user = user_doc.to_dict() if user_doc.exists else {}
        items.append(
            CreatorListItem(
                uid=uid,
                display_name=user.get("display_name") or "(no name)",
                username=user.get("username") or "",
                photo_url=user.get("photo_url"),
                status=data.get("status", "pending"),
                is_creator=bool(user.get("is_creator")),
                reapplied=bool(data.get("reapplied")),
                submitted_at=data.get("submitted_at"),
                reviewed_at=data.get("reviewed_at"),
            )
        )
    items.sort(
        key=lambda i: (_STATUS_ORDER.get(i.status, 9), -_epoch(i.submitted_at))
    )
    return items


@router.get("/creators/{uid}", response_model=CreatorDetailResponse)
def get_creator(uid: str, _: dict = Depends(get_admin_user)):
    validate_document_id(uid)
    db = get_firestore()
    app_doc = db.collection("creator_applications").document(uid).get()
    if not app_doc.exists:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="No application found")
    data = app_doc.to_dict()
    user_doc = db.collection("users").document(uid).get()
    user = user_doc.to_dict() if user_doc.exists else {}

    history = [
        CreatorHistoryEntry(
            status=h.get("status", ""),
            at=h.get("reviewed_at") or h.get("submitted_at"),
            note=h.get("purpose"),
        )
        for h in data.get("history", [])
        if (h.get("reviewed_at") or h.get("submitted_at"))
    ]

    return CreatorDetailResponse(
        uid=uid,
        display_name=user.get("display_name") or "(no name)",
        username=user.get("username") or "",
        photo_url=user.get("photo_url"),
        status=data.get("status", "pending"),
        is_creator=bool(user.get("is_creator")),
        reapplied=bool(data.get("reapplied")),
        submitted_at=data.get("submitted_at"),
        reviewed_at=data.get("reviewed_at"),
        purpose=data.get("purpose", ""),
        social_links=data.get("social_links", []),
        relevant_links=data.get("relevant_links", []),
        phone=data.get("phone", ""),
        history=history,
    )


@router.post("/creators/{uid}/approve", status_code=status.HTTP_200_OK)
def approve_creator(uid: str, admin: dict = Depends(get_admin_user)):
    validate_document_id(uid)
    db = get_firestore()
    app_ref = db.collection("creator_applications").document(uid)
    app_doc = app_ref.get()
    if not app_doc.exists:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="No application found for this user")
    if app_doc.to_dict().get("status") == "approved":
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Already approved")

    app_ref.update({"status": "approved", "reapplied": False, "reviewed_at": SERVER_TIMESTAMP})
    db.collection("users").document(uid).update({"is_creator": True})
    record_admin_action(db, admin["uid"], "creator.approve", target_type="user", target_id=uid)
    return {"detail": "Creator approved"}


@router.post("/creators/{uid}/reject", status_code=status.HTTP_200_OK)
def reject_creator(uid: str, admin: dict = Depends(get_admin_user)):
    validate_document_id(uid)
    db = get_firestore()
    app_ref = db.collection("creator_applications").document(uid)
    if not app_ref.get().exists:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="No application found for this user")
    app_ref.update({"status": "rejected", "reviewed_at": SERVER_TIMESTAMP})
    record_admin_action(db, admin["uid"], "creator.reject", target_type="user", target_id=uid)
    return {"detail": "Creator rejected"}


@router.post("/creators/{uid}/revoke", status_code=status.HTTP_200_OK)
def revoke_creator(uid: str, admin: dict = Depends(get_admin_user)):
    validate_document_id(uid)
    db = get_firestore()
    user_ref = db.collection("users").document(uid)
    if not user_ref.get().exists:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")

    user_ref.update({"is_creator": False})
    app_ref = db.collection("creator_applications").document(uid)
    if app_ref.get().exists:
        app_ref.update({"status": "revoked", "reviewed_at": SERVER_TIMESTAMP})
    record_admin_action(db, admin["uid"], "creator.revoke", target_type="user", target_id=uid)
    return {"detail": "Creator access revoked"}
