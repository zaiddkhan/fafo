from fastapi import APIRouter, HTTPException, Request, status
from firebase_admin import auth
from google.cloud.firestore import SERVER_TIMESTAMP
from slowapi import Limiter
from slowapi.util import get_remote_address

from app.config import RATE_LIMIT_AUTH
from app.firebase import get_firestore
from app.schemas import SessionRequest, SessionResponse

router = APIRouter(prefix="/auth", tags=["auth"])
limiter = Limiter(key_func=get_remote_address)


@router.post("/session", response_model=SessionResponse)
@limiter.limit(RATE_LIMIT_AUTH)
def create_session(body: SessionRequest, request: Request):
    try:
        decoded = auth.verify_id_token(body.id_token)
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token",
        )

    uid = decoded["uid"]
    phone = decoded.get("phone_number", "")

    db = get_firestore()
    user_ref = db.collection("users").document(uid)
    user_doc = user_ref.get()

    if not user_doc.exists:
        user_ref.set(
            {
                "phone": phone,
                "display_name": "",
                "display_name_lower": "",
                "username": "",
                "photo_url": "",
                "area": None,
                "is_creator": False,
                "onboarding_complete": False,
                "first_launch_tooltip_complete": False,
                "created_at": SERVER_TIMESTAMP,
            }
        )
        return SessionResponse(
            uid=uid,
            phone=phone,
            is_new=True,
            onboarding_complete=False,
            is_creator=False,
        )

    user_data = user_doc.to_dict()
    return SessionResponse(
        uid=uid,
        phone=phone,
        is_new=False,
        onboarding_complete=user_data.get("onboarding_complete", False),
        is_creator=user_data.get("is_creator", False),
    )
