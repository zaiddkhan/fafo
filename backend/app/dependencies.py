import re
import logging

from fastapi import Depends, Header, HTTPException, status
from firebase_admin import auth

from app.config import ADMIN_UIDS
from app.firebase import get_firestore

logger = logging.getLogger(__name__)

SAFE_ID_PATTERN = re.compile(r"^[a-zA-Z0-9_\-]+$")


def validate_document_id(doc_id: str) -> str:
    if not SAFE_ID_PATTERN.match(doc_id) or len(doc_id) > 128:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid document ID format",
        )
    return doc_id


def get_current_user(authorization: str | None = Header(default=None)) -> dict:
    if authorization is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing authorization header",
        )

    if not authorization.startswith("Bearer "):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid authorization header",
        )

    token = authorization.removeprefix("Bearer ")

    try:
        decoded = auth.verify_id_token(token, check_revoked=True)
    except auth.RevokedIdTokenError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token has been revoked",
        )
    except auth.InvalidIdTokenError as e:
        logger.warning("Invalid token: %s", e)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token",
        )
    except Exception as e:
        logger.error("Token verification error: %s", e)
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired token",
        )

    return decoded


def get_admin_user(current_user: dict = Depends(get_current_user)) -> dict:
    if current_user["uid"] not in ADMIN_UIDS:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin access required",
        )
    return current_user


def get_creator_user(current_user: dict = Depends(get_current_user)) -> dict:
    db = get_firestore()
    user_doc = db.collection("users").document(current_user["uid"]).get()

    if not user_doc.exists or not user_doc.to_dict().get("is_creator", False):
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Creator access required",
        )
    return current_user
