"""Device (FCM token) registration.

The Flutter app registers its FCM token here after obtaining notification permission, and
unregisters on logout. Tokens are stored at users/{uid}/devices/{token}; the dispatcher
reads them at send time and prunes any the FCM backend reports as invalid.
"""

from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, status

from app.dependencies import get_current_user
from app.firebase import get_firestore
from app.schemas import DeviceRegisterRequest, DeviceRegisterResponse

router = APIRouter(prefix="/devices", tags=["devices"])


@router.post("", response_model=DeviceRegisterResponse, status_code=status.HTTP_201_CREATED)
def register_device(body: DeviceRegisterRequest, current_user: dict = Depends(get_current_user)):
    uid = current_user["uid"]
    db = get_firestore()
    # Token is the doc id, so re-registering the same token is naturally idempotent.
    db.collection("users").document(uid).collection("devices").document(body.token).set(
        {
            "token": body.token,
            "platform": body.platform.value,
            "last_seen": datetime.now(timezone.utc),
        }
    )
    return DeviceRegisterResponse(registered=True)


@router.delete("/{token}", status_code=status.HTTP_200_OK)
def unregister_device(token: str, current_user: dict = Depends(get_current_user)):
    # FCM tokens are long and contain ":"/"-", so the strict doc-id validator doesn't
    # apply; we only need to reject the Firestore path separator.
    if not token or "/" in token:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid token")
    uid = current_user["uid"]
    db = get_firestore()
    db.collection("users").document(uid).collection("devices").document(token).delete()
    return {"detail": "Device unregistered"}
