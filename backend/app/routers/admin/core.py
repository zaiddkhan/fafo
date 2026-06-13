"""Shared admin endpoints: identity check, category management, audit log."""

from fastapi import APIRouter, Depends, HTTPException, Query, status

from app.audit import record_admin_action
from app.dependencies import get_admin_user, validate_document_id
from app.firebase import get_firestore
from app.schemas import (
    AdminMeResponse,
    AuditLogResponse,
    CategoryCreateRequest,
    CategoryUpdateRequest,
    CategoryResponse,
)

router = APIRouter()


@router.get("/me", response_model=AdminMeResponse)
def admin_me(current_user: dict = Depends(get_admin_user)):
    # get_admin_user already enforces ADMIN_UIDS membership; reaching here means admin.
    return AdminMeResponse(uid=current_user["uid"], is_admin=True)


@router.get("/audit-log", response_model=list[AuditLogResponse])
def list_audit_log(
    limit: int = Query(default=100, le=500),
    _: dict = Depends(get_admin_user),
):
    db = get_firestore()
    docs = (
        db.collection("admin_audit_log")
        .order_by("created_at", direction="DESCENDING")
        .limit(limit)
        .stream()
    )
    out = []
    for doc in docs:
        data = doc.to_dict() or {}
        out.append(
            AuditLogResponse(
                id=doc.id,
                admin_uid=data.get("admin_uid", ""),
                action=data.get("action", ""),
                target_type=data.get("target_type"),
                target_id=data.get("target_id"),
                reason=data.get("reason"),
                metadata=data.get("metadata", {}),
                created_at=data["created_at"],
            )
        )
    return out


# --- Category Management (moved from the original admin router) ---


@router.post("/categories", response_model=CategoryResponse, status_code=status.HTTP_201_CREATED)
def create_category(body: CategoryCreateRequest, admin: dict = Depends(get_admin_user)):
    db = get_firestore()
    doc_ref = db.collection("categories").document()
    doc_ref.set({"name": body.name, "emoji": body.emoji, "sort_order": body.sort_order})
    record_admin_action(
        db, admin["uid"], "category.create", target_type="category", target_id=doc_ref.id
    )
    return CategoryResponse(
        id=doc_ref.id, name=body.name, emoji=body.emoji, sort_order=body.sort_order
    )


@router.put("/categories/{category_id}", response_model=CategoryResponse)
def update_category(
    category_id: str,
    body: CategoryUpdateRequest,
    _: dict = Depends(get_admin_user),
):
    validate_document_id(category_id)
    db = get_firestore()
    doc_ref = db.collection("categories").document(category_id)
    doc = doc_ref.get()
    if not doc.exists:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Category not found")

    update = {k: v for k, v in body.model_dump(exclude_unset=True).items() if v is not None}
    if not update:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="No fields to update")

    doc_ref.update(update)
    updated = doc_ref.get().to_dict()
    return CategoryResponse(
        id=category_id,
        name=updated["name"],
        emoji=updated["emoji"],
        sort_order=updated["sort_order"],
    )
