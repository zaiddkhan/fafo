"""Event Seeding: create team events with an internal `seeded` flag, and list
events for internal reporting (seeded flag visible to admins only)."""

from datetime import datetime, timezone
from uuid import uuid4

from fastapi import APIRouter, Depends, HTTPException, Query, status
from google.cloud.firestore import GeoPoint

from app.audit import record_admin_action
from app.dependencies import get_admin_user
from app.firebase import get_firestore
from app.routers.events import build_event_data, _event_to_response
from app.schemas import AdminEventListItem, EventCreateRequest, EventResponse

router = APIRouter()


@router.post("/events", response_model=EventResponse, status_code=status.HTTP_201_CREATED)
def seed_event(body: EventCreateRequest, admin: dict = Depends(get_admin_user)):
    db = get_firestore()
    cat_doc = db.collection("categories").document(body.category_id).get()
    if not cat_doc.exists:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Invalid category_id")

    # Seeded events are owned by the acting admin's uid and flagged internal-only.
    event_data = build_event_data(body, admin["uid"], seeded=True)
    event_id = str(uuid4())
    db.collection("events").document(event_id).set(event_data)
    record_admin_action(db, admin["uid"], "event.seed", target_type="event", target_id=event_id)
    return _event_to_response(event_id, event_data)


@router.get("/events", response_model=list[AdminEventListItem])
def list_events(
    seeded: bool | None = Query(default=None),
    upcoming_only: bool = Query(default=True),
    limit: int = Query(default=200, le=500),
    _: dict = Depends(get_admin_user),
):
    db = get_firestore()
    now = datetime.now(timezone.utc)
    out: list[AdminEventListItem] = []
    for doc in db.collection("events").stream():
        data = doc.to_dict() or {}
        if seeded is not None and bool(data.get("seeded", False)) != seeded:
            continue
        dt = data.get("date_time")
        loc = data.get("location")
        if dt is None or loc is None:
            continue  # skip malformed/incomplete event docs
        if dt.tzinfo is None:
            dt = dt.replace(tzinfo=timezone.utc)
        if upcoming_only and (data.get("cancelled") or dt < now):
            continue
        out.append(
            AdminEventListItem(
                id=doc.id,
                title=data["title"],
                creator_uid=data["creator_uid"],
                category_id=data["category_id"],
                location_name=data["location_name"],
                lat=loc.latitude,
                lng=loc.longitude,
                date_time=dt,
                joinee_count=data.get("joinee_count", 0),
                cancelled=data.get("cancelled", False),
                seeded=bool(data.get("seeded", False)),
                created_at=data["created_at"],
            )
        )
    out.sort(key=lambda e: e.date_time)
    return out[:limit]
