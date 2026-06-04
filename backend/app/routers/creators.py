from fastapi import APIRouter, Depends, HTTPException, status
from google.cloud.firestore import SERVER_TIMESTAMP

from app.dependencies import get_current_user
from app.firebase import get_firestore
from app.schemas import CreatorApplicationRequest, CreatorApplicationResponse

router = APIRouter(prefix="/creators", tags=["creators"])


@router.post("/apply", response_model=CreatorApplicationResponse, status_code=status.HTTP_201_CREATED)
def apply_for_creator(
    body: CreatorApplicationRequest, current_user: dict = Depends(get_current_user)
):
    uid = current_user["uid"]
    db = get_firestore()

    existing = db.collection("creator_applications").document(uid).get()
    if existing.exists:
        existing_data = existing.to_dict()
        if existing_data["status"] == "pending":
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Application already pending",
            )
        if existing_data["status"] == "approved":
            raise HTTPException(
                status_code=status.HTTP_409_CONFLICT,
                detail="Already an approved creator",
            )

    application = {
        "purpose": body.purpose,
        "social_links": body.social_links,
        "phone": body.phone,
        "relevant_links": body.relevant_links,
        "status": "pending",
        "submitted_at": SERVER_TIMESTAMP,
    }
    db.collection("creator_applications").document(uid).set(application)

    doc = db.collection("creator_applications").document(uid).get()
    data = doc.to_dict()
    return CreatorApplicationResponse(
        uid=uid,
        purpose=data["purpose"],
        social_links=data["social_links"],
        phone=data["phone"],
        relevant_links=data["relevant_links"],
        status=data["status"],
        submitted_at=data["submitted_at"],
    )


@router.get("/application", response_model=CreatorApplicationResponse)
def get_application_status(current_user: dict = Depends(get_current_user)):
    uid = current_user["uid"]
    db = get_firestore()

    doc = db.collection("creator_applications").document(uid).get()
    if not doc.exists:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="No application found",
        )

    data = doc.to_dict()
    return CreatorApplicationResponse(
        uid=uid,
        purpose=data["purpose"],
        social_links=data["social_links"],
        phone=data["phone"],
        relevant_links=data["relevant_links"],
        status=data["status"],
        submitted_at=data["submitted_at"],
    )
