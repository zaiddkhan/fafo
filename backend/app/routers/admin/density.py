"""Density View: launch-area CRUD and the density dashboard.

Density counts active (future, non-cancelled) events whose location falls within a
launch area's radius, flags areas below the 3-event threshold, and lists events
expiring within the next 24h for same-day intervention.
"""

from datetime import datetime, timedelta, timezone
from uuid import uuid4

from fastapi import APIRouter, Depends, HTTPException, status

from app.audit import record_admin_action
from app.dependencies import get_admin_user, validate_document_id
from app.firebase import get_firestore
from app.routers.events import _haversine_km
from app.schemas import (
    DensityAreaResponse,
    DensityResponse,
    ExpiringEventItem,
    LaunchAreaCreateRequest,
    LaunchAreaResponse,
    LaunchAreaUpdateRequest,
)

router = APIRouter()

DENSITY_THRESHOLD = 3


def _area_response(doc_id: str, data: dict) -> LaunchAreaResponse:
    return LaunchAreaResponse(
        id=doc_id,
        name=data["name"],
        center_lat=data["center_lat"],
        center_lng=data["center_lng"],
        radius_km=data["radius_km"],
        created_at=data["created_at"],
    )


@router.get("/launch-areas", response_model=list[LaunchAreaResponse])
def list_launch_areas(_: dict = Depends(get_admin_user)):
    db = get_firestore()
    return [
        _area_response(doc.id, doc.to_dict())
        for doc in db.collection("launch_areas").stream()
    ]


@router.post("/launch-areas", response_model=LaunchAreaResponse, status_code=status.HTTP_201_CREATED)
def create_launch_area(body: LaunchAreaCreateRequest, admin: dict = Depends(get_admin_user)):
    db = get_firestore()
    data = {
        "name": body.name,
        "center_lat": body.center_lat,
        "center_lng": body.center_lng,
        "radius_km": body.radius_km,
        "created_at": datetime.now(timezone.utc),
    }
    ref = db.collection("launch_areas").document()
    ref.set(data)
    record_admin_action(db, admin["uid"], "launch_area.create", target_type="launch_area", target_id=ref.id)
    return _area_response(ref.id, data)


@router.put("/launch-areas/{area_id}", response_model=LaunchAreaResponse)
def update_launch_area(area_id: str, body: LaunchAreaUpdateRequest, _: dict = Depends(get_admin_user)):
    validate_document_id(area_id)
    db = get_firestore()
    ref = db.collection("launch_areas").document(area_id)
    if not ref.get().exists:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Launch area not found")
    update = {k: v for k, v in body.model_dump(exclude_unset=True).items() if v is not None}
    if not update:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="No fields to update")
    ref.update(update)
    return _area_response(area_id, ref.get().to_dict())


@router.delete("/launch-areas/{area_id}", status_code=status.HTTP_200_OK)
def delete_launch_area(area_id: str, admin: dict = Depends(get_admin_user)):
    validate_document_id(area_id)
    db = get_firestore()
    ref = db.collection("launch_areas").document(area_id)
    if not ref.get().exists:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Launch area not found")
    ref.delete()
    record_admin_action(db, admin["uid"], "launch_area.delete", target_type="launch_area", target_id=area_id)
    return {"detail": "Launch area deleted"}


@router.get("/density", response_model=DensityResponse)
def density(_: dict = Depends(get_admin_user)):
    db = get_firestore()
    now = datetime.now(timezone.utc)
    soon = now + timedelta(hours=24)

    # Load active (future, non-cancelled) events once.
    active = []
    for doc in db.collection("events").stream():
        data = doc.to_dict() or {}
        if data.get("cancelled"):
            continue
        dt = data["date_time"]
        if dt.tzinfo is None:
            dt = dt.replace(tzinfo=timezone.utc)
        if dt < now:
            continue
        loc = data["location"]
        active.append(
            {
                "id": doc.id,
                "title": data["title"],
                "location_name": data["location_name"],
                "lat": loc.latitude,
                "lng": loc.longitude,
                "date_time": dt,
                "seeded": bool(data.get("seeded", False)),
            }
        )

    areas: list[DensityAreaResponse] = []
    for doc in db.collection("launch_areas").stream():
        adata = doc.to_dict()
        in_area = [
            e
            for e in active
            if _haversine_km(adata["center_lat"], adata["center_lng"], e["lat"], e["lng"])
            <= adata["radius_km"]
        ]
        expiring = [
            ExpiringEventItem(
                id=e["id"],
                title=e["title"],
                location_name=e["location_name"],
                date_time=e["date_time"],
                seeded=e["seeded"],
            )
            for e in in_area
            if e["date_time"] <= soon
        ]
        expiring.sort(key=lambda e: e.date_time)
        areas.append(
            DensityAreaResponse(
                area=_area_response(doc.id, adata),
                active_event_count=len(in_area),
                below_threshold=len(in_area) < DENSITY_THRESHOLD,
                expiring_24h=expiring,
            )
        )

    areas.sort(key=lambda a: a.active_event_count)
    return DensityResponse(threshold=DENSITY_THRESHOLD, areas=areas, generated_at=now)
