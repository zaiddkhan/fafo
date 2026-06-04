from datetime import datetime, timedelta, timezone
from math import radians, cos, sin, asin, sqrt
from uuid import uuid4

from fastapi import (
    APIRouter,
    Depends,
    File,
    HTTPException,
    Query,
    UploadFile,
    status,
)
from firebase_admin import storage
from google.cloud import firestore
from google.cloud.firestore import GeoPoint

from app.dependencies import get_current_user, get_creator_user, validate_document_id
from app.firebase import get_firestore
from app.geo import encode_geohash, geohash_bounds_for_radius
from app.schemas import (
    EventCreateRequest,
    EventUpdateRequest,
    EventResponse,
    EventBannerUploadResponse,
    EventCancelRequest,
    EventJoinResponse,
    EventUnjoinRequest,
    EventType,
    JoineeResponse,
)

ALLOWED_BANNER_TYPES = {"image/jpeg", "image/png", "image/webp"}
MAX_BANNER_BYTES = 5 * 1024 * 1024

router = APIRouter(prefix="/events", tags=["events"])

VISIBILITY_WINDOW_MINUTES = 10
DEFAULT_PAGE_LIMIT = 50
MAX_PAGE_LIMIT = 100


def _haversine_km(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    lat1, lng1, lat2, lng2 = map(radians, [lat1, lng1, lat2, lng2])
    dlat = lat2 - lat1
    dlng = lng2 - lng1
    a = sin(dlat / 2) ** 2 + cos(lat1) * cos(lat2) * sin(dlng / 2) ** 2
    return 6371 * 2 * asin(sqrt(a))


def _ensure_utc(dt: datetime) -> datetime:
    if dt.tzinfo is None:
        return dt.replace(tzinfo=timezone.utc)
    return dt.astimezone(timezone.utc)


def _is_spotlight_today(date_time: datetime) -> bool:
    return _ensure_utc(date_time).date() == datetime.now(timezone.utc).date()


def _stored_event_type_to_response(data: dict) -> EventType:
    if _is_spotlight_today(data["date_time"]):
        return EventType.spotlight
    stored = data.get("event_type", EventType.normal.value)
    if stored == EventType.spotlight.value:
        return EventType.normal
    return EventType(stored)


def _event_to_response(doc_id: str, data: dict, current_uid: str | None = None) -> EventResponse:
    location: GeoPoint = data["location"]
    is_joined = False
    if current_uid is not None:
        is_joined = (
            get_firestore()
            .collection("events")
            .document(doc_id)
            .collection("joinees")
            .document(current_uid)
            .get()
            .exists
        )
    return EventResponse(
        id=doc_id,
        creator_uid=data["creator_uid"],
        title=data["title"],
        description=data.get("description"),
        category_id=data["category_id"],
        event_type=_stored_event_type_to_response(data),
        custom_emoji=data.get("custom_emoji"),
        lat=location.latitude,
        lng=location.longitude,
        location_name=data["location_name"],
        date_time=_ensure_utc(data["date_time"]),
        capacity=data.get("capacity"),
        joinee_count=data.get("joinee_count", 0),
        registration_open=data.get("registration_open", True),
        cancelled=data.get("cancelled", False),
        banner_url=data.get("banner_url"),
        organizer_name=data.get("organizer_name"),
        organizer_contact=data.get("organizer_contact"),
        organizer_instagram=data.get("organizer_instagram"),
        is_joined=is_joined,
        created_at=_ensure_utc(data["created_at"]),
        updated_at=_ensure_utc(data["updated_at"]),
    )


@router.post("", response_model=EventResponse, status_code=status.HTTP_201_CREATED)
def create_event(
    body: EventCreateRequest, current_user: dict = Depends(get_creator_user)
):
    uid = current_user["uid"]
    db = get_firestore()

    cat_doc = db.collection("categories").document(body.category_id).get()
    if not cat_doc.exists:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid category_id",
        )

    now = datetime.now(timezone.utc)
    gh = encode_geohash(body.lat, body.lng)

    event_data = {
        "creator_uid": uid,
        "title": body.title,
        "description": body.description,
        "category_id": body.category_id,
        "event_type": EventType.normal.value if body.event_type == EventType.spotlight else body.event_type.value,
        "custom_emoji": body.custom_emoji,
        "location": GeoPoint(body.lat, body.lng),
        "location_name": body.location_name,
        "geohash": gh,
        "date_time": body.date_time,
        "capacity": body.capacity,
        "joinee_count": 0,
        "registration_open": True,
        "cancelled": False,
        "cancel_reason": None,
        "banner_url": None,
        "organizer_name": body.organizer_name,
        "organizer_contact": body.organizer_contact,
        "organizer_instagram": body.organizer_instagram,
        "created_at": now,
        "updated_at": now,
    }

    event_id = str(uuid4())
    doc_ref = db.collection("events").document(event_id)
    doc_ref.set(event_data)

    return _event_to_response(event_id, event_data)


@router.post(
    "/{event_id}/banner",
    response_model=EventBannerUploadResponse,
)
async def upload_event_banner(
    event_id: str,
    file: UploadFile = File(...),
    current_user: dict = Depends(get_creator_user),
):
    validate_document_id(event_id)
    uid = current_user["uid"]
    db = get_firestore()

    doc_ref = db.collection("events").document(event_id)
    doc = doc_ref.get()
    if not doc.exists or doc.to_dict()["creator_uid"] != uid:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Event not found"
        )

    if file.content_type not in ALLOWED_BANNER_TYPES:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Banner must be a JPEG, PNG, or WebP image",
        )

    contents = await file.read()
    if len(contents) > MAX_BANNER_BYTES:
        raise HTTPException(
            status_code=status.HTTP_413_REQUEST_ENTITY_TOO_LARGE,
            detail="Banner exceeds the 5MB limit",
        )

    ext = "png" if file.content_type == "image/png" else (
        "webp" if file.content_type == "image/webp" else "jpg"
    )
    blob_path = f"events/{event_id}/banner.{ext}"
    bucket = storage.bucket()
    blob = bucket.blob(blob_path)
    blob.upload_from_string(contents, content_type=file.content_type)
    blob.make_public()
    banner_url = blob.public_url

    doc_ref.update(
        {"banner_url": banner_url, "updated_at": datetime.now(timezone.utc)}
    )

    return EventBannerUploadResponse(event_id=event_id, banner_url=banner_url)


@router.get("", response_model=list[EventResponse])
def list_events(
    lat: float = Query(...),
    lng: float = Query(...),
    radius_km: float = Query(default=15.0),
    category_id: str | None = Query(default=None),
    event_type: EventType | None = Query(default=None),
    limit: int = Query(default=DEFAULT_PAGE_LIMIT, le=MAX_PAGE_LIMIT),
    cursor: str | None = Query(default=None),
    current_user: dict = Depends(get_current_user),
):
    db = get_firestore()
    uid = current_user["uid"]
    now = datetime.now(timezone.utc)
    cutoff = now - timedelta(minutes=VISIBILITY_WINDOW_MINUTES)

    geohash_ranges = geohash_bounds_for_radius(lat, lng, radius_km)

    results = []
    for gh_start, gh_end in geohash_ranges:
        query = db.collection("events").where("cancelled", "==", False)
        if category_id:
            query = query.where("category_id", "==", category_id)
        if event_type and event_type != EventType.spotlight:
            query = query.where("event_type", "==", event_type.value)
        query = query.where("geohash", ">=", gh_start).where("geohash", "<=", gh_end)

        for doc in query.stream():
            data = doc.to_dict()

            event_time = _ensure_utc(data["date_time"])
            if event_time < cutoff:
                continue

            if event_type and _stored_event_type_to_response(data) != event_type:
                continue

            loc: GeoPoint = data["location"]
            distance = _haversine_km(lat, lng, loc.latitude, loc.longitude)
            if distance <= radius_km:
                results.append(_event_to_response(doc.id, data, uid))

    results.sort(key=lambda e: e.date_time)

    if cursor:
        cursor_idx = next(
            (i for i, e in enumerate(results) if e.id == cursor), -1
        )
        if cursor_idx >= 0:
            results = results[cursor_idx + 1:]

    return results[:limit]


@router.get("/mine", response_model=list[EventResponse])
def list_my_events(
    include_archived: bool = Query(default=False),
    limit: int = Query(default=DEFAULT_PAGE_LIMIT, le=MAX_PAGE_LIMIT),
    current_user: dict = Depends(get_creator_user),
):
    uid = current_user["uid"]
    db = get_firestore()
    now = datetime.now(timezone.utc)
    cutoff = now - timedelta(minutes=VISIBILITY_WINDOW_MINUTES)

    query = db.collection("events").where("creator_uid", "==", uid).limit(limit)
    results = []
    for doc in query.stream():
        data = doc.to_dict()
        if not include_archived and _ensure_utc(data["date_time"]) < cutoff:
            continue
        results.append(_event_to_response(doc.id, data))
    results.sort(key=lambda e: e.date_time)
    return results


@router.get("/joined", response_model=list[EventResponse])
def list_joined_events(
    limit: int = Query(default=DEFAULT_PAGE_LIMIT, le=MAX_PAGE_LIMIT),
    current_user: dict = Depends(get_current_user),
):
    uid = current_user["uid"]
    db = get_firestore()
    now = datetime.now(timezone.utc)
    cutoff = now - timedelta(minutes=VISIBILITY_WINDOW_MINUTES)

    joined_docs = (
        db.collection_group("joinees")
        .where("uid", "==", uid)
        .order_by("joined_at", direction=firestore.Query.DESCENDING)
        .limit(limit)
        .stream()
    )

    event_refs = []
    for joined_doc in joined_docs:
        event_ref = joined_doc.reference.parent.parent
        if event_ref is not None:
            event_refs.append(event_ref)

    if not event_refs:
        return []

    results = []
    for doc in db.get_all(event_refs):
        if not doc.exists:
            continue
        data = doc.to_dict()
        if data.get("cancelled") or _ensure_utc(data["date_time"]) < cutoff:
            continue
        results.append(_event_to_response(doc.id, data, uid))

    results.sort(key=lambda e: e.date_time)
    return results[:limit]


@router.get("/{event_id}", response_model=EventResponse)
def get_event(event_id: str, current_user: dict = Depends(get_current_user)):
    validate_document_id(event_id)
    db = get_firestore()
    doc = db.collection("events").document(event_id).get()

    if not doc.exists:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Event not found"
        )

    data = doc.to_dict()
    now = datetime.now(timezone.utc)
    cutoff = now - timedelta(minutes=VISIBILITY_WINDOW_MINUTES)

    if data.get("cancelled") or _ensure_utc(data["date_time"]) < cutoff:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Event not found"
        )

    return _event_to_response(doc.id, data, current_user["uid"])


@router.put("/{event_id}", response_model=EventResponse)
def update_event(
    event_id: str,
    body: EventUpdateRequest,
    current_user: dict = Depends(get_creator_user),
):
    validate_document_id(event_id)
    uid = current_user["uid"]
    db = get_firestore()

    doc_ref = db.collection("events").document(event_id)
    doc = doc_ref.get()

    if not doc.exists:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Event not found"
        )

    data = doc.to_dict()
    if data["creator_uid"] != uid:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Event not found"
        )

    update = {}
    for field, value in body.model_dump(exclude_unset=True).items():
        if field in ("lat", "lng"):
            continue
        if field == "event_type" and value is not None:
            normalized_type = value.value if hasattr(value, "value") else value
            update["event_type"] = EventType.normal.value if normalized_type == EventType.spotlight.value else normalized_type
        else:
            update[field] = value

    if body.lat is not None and body.lng is not None:
        update["location"] = GeoPoint(body.lat, body.lng)
        update["geohash"] = encode_geohash(body.lat, body.lng)
    elif body.lat is not None or body.lng is not None:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Both lat and lng must be provided together",
        )

    if not update:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="No fields to update",
        )

    update["updated_at"] = datetime.now(timezone.utc)
    doc_ref.update(update)

    updated = doc_ref.get().to_dict()
    return _event_to_response(event_id, updated)


@router.post("/{event_id}/cancel")
def cancel_event(
    event_id: str,
    body: EventCancelRequest,
    current_user: dict = Depends(get_creator_user),
):
    validate_document_id(event_id)
    uid = current_user["uid"]
    db = get_firestore()

    doc_ref = db.collection("events").document(event_id)
    doc = doc_ref.get()

    if not doc.exists:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Event not found"
        )

    data = doc.to_dict()
    if data["creator_uid"] != uid:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Event not found"
        )

    if data.get("cancelled"):
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Event already cancelled",
        )

    doc_ref.update(
        {
            "cancelled": True,
            "cancel_reason": body.reason,
            "updated_at": datetime.now(timezone.utc),
        }
    )

    return {"detail": "Event cancelled"}


@firestore.transactional
def _join_event_txn(transaction, doc_ref, joinee_ref):
    doc = doc_ref.get(transaction=transaction)

    if not doc.exists:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Event not found"
        )

    data = doc.to_dict()

    if data.get("cancelled"):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail="Event is cancelled"
        )

    if not data.get("registration_open", True):
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST, detail="Registration is closed"
        )

    now = datetime.now(timezone.utc)
    event_time = _ensure_utc(data["date_time"])
    join_cutoff = event_time + timedelta(minutes=VISIBILITY_WINDOW_MINUTES)

    if now > join_cutoff:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Join window has closed",
        )

    capacity = data.get("capacity")
    current_count = data.get("joinee_count", 0)
    if capacity is not None and current_count >= capacity:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Event is full",
        )

    joinee_doc = joinee_ref.get(transaction=transaction)
    if joinee_doc.exists:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Already joined this event",
        )

    joined_at = now
    transaction.set(joinee_ref, {"uid": joinee_ref.id, "joined_at": joined_at})
    transaction.update(doc_ref, {"joinee_count": current_count + 1})

    return joined_at


@router.post("/{event_id}/join", response_model=EventJoinResponse)
def join_event(event_id: str, current_user: dict = Depends(get_current_user)):
    validate_document_id(event_id)
    uid = current_user["uid"]
    db = get_firestore()

    doc_ref = db.collection("events").document(event_id)
    joinee_ref = doc_ref.collection("joinees").document(uid)

    transaction = db.transaction()
    joined_at = _join_event_txn(transaction, doc_ref, joinee_ref)

    return EventJoinResponse(event_id=event_id, joined_at=joined_at)


@firestore.transactional
def _unjoin_event_txn(transaction, doc_ref, joinee_ref):
    event_doc = doc_ref.get(transaction=transaction)
    if not event_doc.exists:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Event not found"
        )

    joinee_doc = joinee_ref.get(transaction=transaction)
    if not joinee_doc.exists:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Not joined this event",
        )

    current_count = event_doc.to_dict().get("joinee_count", 0)
    new_count = max(0, current_count - 1)

    transaction.delete(joinee_ref)
    transaction.update(doc_ref, {"joinee_count": new_count})


@router.delete("/{event_id}/join", status_code=status.HTTP_200_OK)
def unjoin_event(
    event_id: str,
    body: EventUnjoinRequest,
    current_user: dict = Depends(get_current_user),
):
    validate_document_id(event_id)
    uid = current_user["uid"]
    db = get_firestore()

    doc_ref = db.collection("events").document(event_id)
    joinee_ref = doc_ref.collection("joinees").document(uid)

    transaction = db.transaction()
    _unjoin_event_txn(transaction, doc_ref, joinee_ref)

    return {"detail": "Unjoined successfully", "reason": body.reason.value}


@router.get("/{event_id}/joinees", response_model=list[JoineeResponse])
def list_joinees(
    event_id: str,
    limit: int = Query(default=DEFAULT_PAGE_LIMIT, le=MAX_PAGE_LIMIT),
    cursor: str | None = Query(default=None),
    current_user: dict = Depends(get_creator_user),
):
    validate_document_id(event_id)
    uid = current_user["uid"]
    db = get_firestore()

    doc = db.collection("events").document(event_id).get()
    if not doc.exists:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Event not found"
        )

    if doc.to_dict()["creator_uid"] != uid:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND, detail="Event not found"
        )

    joinees_query = (
        db.collection("events")
        .document(event_id)
        .collection("joinees")
        .order_by("joined_at")
        .limit(limit)
    )

    if cursor:
        cursor_doc = (
            db.collection("events")
            .document(event_id)
            .collection("joinees")
            .document(cursor)
            .get()
        )
        if cursor_doc.exists:
            joinees_query = joinees_query.start_after(cursor_doc)

    joinee_docs = list(joinees_query.stream())

    if not joinee_docs:
        return []

    user_refs = [db.collection("users").document(j.id) for j in joinee_docs]
    user_docs = db.get_all(user_refs)
    user_map = {}
    for user_doc in user_docs:
        if user_doc.exists:
            user_map[user_doc.id] = user_doc.to_dict()

    joinees = []
    for joinee_doc in joinee_docs:
        joinee_uid = joinee_doc.id
        joinee_data = joinee_doc.to_dict()
        user_data = user_map.get(joinee_uid, {})

        joinees.append(
            JoineeResponse(
                uid=joinee_uid,
                username=user_data.get("username", ""),
                display_name=user_data.get("display_name", ""),
                photo_url=user_data.get("photo_url") or None,
                joined_at=joinee_data["joined_at"],
            )
        )

    return joinees
