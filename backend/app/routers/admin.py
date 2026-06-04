from fastapi import APIRouter, Depends, HTTPException, status
from google.cloud.firestore import SERVER_TIMESTAMP

from app.dependencies import get_admin_user, validate_document_id
from app.firebase import get_firestore
from app.schemas import CategoryCreateRequest, CategoryUpdateRequest, CategoryResponse

router = APIRouter(prefix="/admin", tags=["admin"])


# --- Creator Management ---


@router.post("/creators/{uid}/approve", status_code=status.HTTP_200_OK)
def approve_creator(uid: str, _: dict = Depends(get_admin_user)):
    validate_document_id(uid)
    db = get_firestore()

    app_ref = db.collection("creator_applications").document(uid)
    app_doc = app_ref.get()
    if not app_doc.exists:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No application found for this user",
        )

    if app_doc.to_dict()["status"] == "approved":
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Already approved",
        )

    app_ref.update({"status": "approved", "reviewed_at": SERVER_TIMESTAMP})
    db.collection("users").document(uid).update({"is_creator": True})

    return {"detail": "Creator approved"}


@router.post("/creators/{uid}/reject", status_code=status.HTTP_200_OK)
def reject_creator(uid: str, _: dict = Depends(get_admin_user)):
    validate_document_id(uid)
    db = get_firestore()

    app_ref = db.collection("creator_applications").document(uid)
    app_doc = app_ref.get()
    if not app_doc.exists:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No application found for this user",
        )

    app_ref.update({"status": "rejected", "reviewed_at": SERVER_TIMESTAMP})

    return {"detail": "Creator rejected"}


@router.post("/creators/{uid}/revoke", status_code=status.HTTP_200_OK)
def revoke_creator(uid: str, _: dict = Depends(get_admin_user)):
    validate_document_id(uid)
    db = get_firestore()

    user_ref = db.collection("users").document(uid)
    user_doc = user_ref.get()
    if not user_doc.exists:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found",
        )

    user_ref.update({"is_creator": False})
    app_ref = db.collection("creator_applications").document(uid)
    if app_ref.get().exists:
        app_ref.update({"status": "revoked", "reviewed_at": SERVER_TIMESTAMP})

    return {"detail": "Creator access revoked"}


# --- Category Management ---


@router.post("/categories", response_model=CategoryResponse, status_code=status.HTTP_201_CREATED)
def create_category(
    body: CategoryCreateRequest, _: dict = Depends(get_admin_user)
):
    db = get_firestore()
    doc_ref = db.collection("categories").document()
    doc_ref.set(
        {
            "name": body.name,
            "emoji": body.emoji,
            "sort_order": body.sort_order,
        }
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
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Category not found",
        )

    update = {k: v for k, v in body.model_dump(exclude_unset=True).items() if v is not None}
    if not update:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No fields to update",
        )

    doc_ref.update(update)
    updated = doc_ref.get().to_dict()
    return CategoryResponse(
        id=category_id,
        name=updated["name"],
        emoji=updated["emoji"],
        sort_order=updated["sort_order"],
    )
