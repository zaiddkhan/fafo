from datetime import datetime, timezone
from uuid import uuid4

from fastapi import APIRouter, Depends, HTTPException, Query, status
from google.cloud import firestore
from google.cloud.firestore import GeoPoint

from app.dependencies import get_current_user
from app.firebase import get_firestore
from app.schemas import (
    Area,
    NegativeActionAnswers,
    PhotoUploadResponse,
    ProfileResponse,
    ProfileSetupRequest,
    ProfileStatsResponse,
    PublicUserResponse,
    TooltipCompleteResponse,
    UsernameCheckResponse,
)
from app.config import FIREBASE_STORAGE_BUCKET

router = APIRouter(prefix="/users", tags=["users"])


def _profile_from_doc(uid: str, data: dict) -> ProfileResponse:
    area_data = data.get("area")
    if area_data:
        area = Area(
            lat=area_data["geopoint"].latitude,
            lng=area_data["geopoint"].longitude,
            radius_km=area_data.get("radius_km", 15.0),
        )
    else:
        area = None
    return ProfileResponse(
        uid=uid,
        phone=data.get("phone", ""),
        display_name=data.get("display_name", ""),
        username=data.get("username", ""),
        photo_url=data.get("photo_url") or None,
        area=area,
        onboarding_complete=data.get("onboarding_complete", False),
        first_launch_tooltip_complete=data.get(
            "first_launch_tooltip_complete", False
        ),
        is_creator=data.get("is_creator", False),
    )


@router.get("/me", response_model=ProfileResponse)
def get_me(current_user: dict = Depends(get_current_user)):
    uid = current_user["uid"]
    db = get_firestore()
    doc = db.collection("users").document(uid).get()
    if not doc.exists:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User record not found. Call /auth/session first.",
        )
    return _profile_from_doc(uid, doc.to_dict())


@router.get("/username/check", response_model=UsernameCheckResponse)
def check_username(
    username: str = Query(min_length=3, max_length=30, pattern=r"^[a-z0-9._]+$"),
    _: dict = Depends(get_current_user),
):
    db = get_firestore()
    doc = db.collection("usernames").document(username).get()
    return UsernameCheckResponse(username=username, available=not doc.exists)


@firestore.transactional
def _reserve_username_txn(transaction, db, uid, body):
    username_ref = db.collection("usernames").document(body.username)
    username_doc = username_ref.get(transaction=transaction)

    if username_doc.exists and username_doc.to_dict().get("uid") != uid:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Username already taken",
        )

    user_ref = db.collection("users").document(uid)
    user_doc = user_ref.get(transaction=transaction)

    if not user_doc.exists:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User record not found. Call /auth/session first.",
        )

    user_data = user_doc.to_dict()
    old_username = user_data.get("username", "")
    if old_username and old_username != body.username:
        old_ref = db.collection("usernames").document(old_username)
        transaction.delete(old_ref)

    update_data = {
        "display_name": body.display_name,
        "display_name_lower": body.display_name.lower(),
        "username": body.username,
        "onboarding_complete": True,
    }
    if body.area is not None:
        update_data["area"] = {
            "geopoint": GeoPoint(body.area.lat, body.area.lng),
            "radius_km": body.area.radius_km,
        }

    transaction.set(username_ref, {"uid": uid})
    transaction.update(user_ref, update_data)

    return {**user_data, **update_data}


@router.put("/profile", response_model=ProfileResponse)
def setup_profile(
    body: ProfileSetupRequest, current_user: dict = Depends(get_current_user)
):
    uid = current_user["uid"]
    db = get_firestore()
    transaction = db.transaction()

    updated = _reserve_username_txn(transaction, db, uid, body)

    return _profile_from_doc(uid, updated)


@router.post("/onboarding/first-launch-tooltip/complete", response_model=TooltipCompleteResponse)
def complete_first_launch_tooltip(
    current_user: dict = Depends(get_current_user),
):
    uid = current_user["uid"]
    db = get_firestore()
    db.collection("users").document(uid).update(
        {"first_launch_tooltip_complete": True}
    )
    return TooltipCompleteResponse(first_launch_tooltip_complete=True)


@router.get("/{uid}/public", response_model=PublicUserResponse)
def get_public_profile(uid: str, current_user: dict = Depends(get_current_user)):
    from app.routers.friends import public_user_from_doc

    db = get_firestore()
    doc = db.collection("users").document(uid).get()
    if not doc.exists:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found",
        )
    return public_user_from_doc(uid, doc.to_dict(), current_user["uid"])


@router.get("/me/stats", response_model=ProfileStatsResponse)
def get_my_stats(current_user: dict = Depends(get_current_user)):
    uid = current_user["uid"]
    db = get_firestore()
    user_doc = db.collection("users").document(uid).get()
    user_data = user_doc.to_dict() if user_doc.exists else {}
    friends_count = len(list(db.collection("users").document(uid).collection("friends").stream()))
    # Avoid collection-group uid index dependency while Firestore indexes build.
    events_joined = sum(
        1
        for event_doc in db.collection("events").limit(500).stream()
        if event_doc.reference.collection("joinees").document(uid).get().exists
    )
    side_quests_activated = len(list(db.collection("users").document(uid).collection("quest_activations").stream()))
    current_streak = int(user_data.get("current_streak", 0) or 0)
    last_activity_date = user_data.get("last_activity_date")
    today = datetime.now(timezone.utc).date()
    if last_activity_date:
        last_date = datetime.fromisoformat(last_activity_date).date()
        if (today - last_date).days > 1:
            current_streak = 0
    return ProfileStatsResponse(
        upcoming_events=events_joined,
        events_joined=events_joined,
        side_quests_activated=side_quests_activated,
        friends_count=friends_count,
        current_streak=current_streak,
    )


@router.delete("/me", status_code=status.HTTP_200_OK)
def delete_account(body: NegativeActionAnswers, current_user: dict = Depends(get_current_user)):
    uid = current_user["uid"]
    db = get_firestore()
    user_ref = db.collection("users").document(uid)
    for friend_doc in user_ref.collection("friends").stream():
        db.collection("users").document(friend_doc.id).collection("friends").document(uid).delete()
        friend_doc.reference.delete()
    for member_doc in db.collection_group("members").where("uid", "==", uid).stream():
        group_ref = member_doc.reference.parent.parent
        if group_ref is not None:
            group_data = group_ref.get().to_dict() or {}
            member_doc.reference.delete()
            if group_data.get("admin_uid") == uid:
                remaining = list(group_ref.collection("members").order_by("joined_at").stream())
                if remaining:
                    next_uid = remaining[0].id
                    group_ref.update({"admin_uid": next_uid, "updated_at": datetime.now(timezone.utc)})
                    remaining[0].reference.update({"is_admin": True})
                else:
                    group_ref.update({"dissolved": True, "dissolved_at": datetime.now(timezone.utc), "updated_at": datetime.now(timezone.utc)})
        else:
            member_doc.reference.delete()
    for event_doc in db.collection("events").limit(500).stream():
        joinee_ref = event_doc.reference.collection("joinees").document(uid)
        if joinee_ref.get().exists:
            joinee_ref.delete()
            event_doc.reference.update({"joinee_count": max(0, (event_doc.to_dict() or {}).get("joinee_count", 1) - 1)})
    for nudge_doc in db.collection("nudges").where("participant_uids", "array_contains", uid).stream():
        nudge_doc.reference.update({"status": "expired", "resolved_at": datetime.now(timezone.utc)})
    db.collection("negative_action_responses").document(str(uuid4())).set({
        "actor_uid": uid,
        "action_type": "delete_account",
        "answers": body.answers,
        "created_at": datetime.now(timezone.utc),
    })
    user_ref.update({"deleted": True, "display_name": "", "username": "", "photo_url": None, "deleted_at": datetime.now(timezone.utc)})
    return {"detail": "Account deleted"}


@router.post("/profile/photo", response_model=PhotoUploadResponse)
def get_photo_upload_path(current_user: dict = Depends(get_current_user)):
    uid = current_user["uid"]
    upload_path = f"users/{uid}/profile.jpg"
    photo_url = f"https://firebasestorage.googleapis.com/v0/b/{FIREBASE_STORAGE_BUCKET}/o/users%2F{uid}%2Fprofile.jpg?alt=media"

    db = get_firestore()
    db.collection("users").document(uid).update({"photo_url": photo_url})

    return PhotoUploadResponse(upload_path=upload_path, photo_url=photo_url)
