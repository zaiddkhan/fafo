from datetime import datetime, timezone

from fastapi import APIRouter, Depends, Query, status
from google.cloud.firestore import GeoPoint, SERVER_TIMESTAMP

from fastapi import HTTPException

from app.activity import record_meaningful_action
from app.dependencies import get_admin_user, get_current_user, validate_document_id
from app.firebase import get_firestore
from app.schemas import Area, QuestCreateRequest, QuestDifficulty, QuestResponse, QuestUpdateRequest

router = APIRouter(prefix="/quests", tags=["quests"])
MAX_LIMIT = 100


def _area_from_data(data: dict | None) -> Area | None:
    if not data:
        return None
    gp = data.get("geopoint")
    if not gp:
        return None
    return Area(lat=gp.latitude, lng=gp.longitude, radius_km=data.get("radius_km", 15.0))


def _area_to_data(area: Area | None):
    if area is None:
        return None
    return {"geopoint": GeoPoint(area.lat, area.lng), "radius_km": area.radius_km}


def _quest_response(doc_id: str, data: dict) -> QuestResponse:
    return QuestResponse(
        id=doc_id,
        title=data.get("title", ""),
        description=data.get("description"),
        difficulty=QuestDifficulty(data.get("difficulty", QuestDifficulty.easy.value)),
        city=data.get("city"),
        area=_area_from_data(data.get("area")),
        published=data.get("published", True),
        created_at=data["created_at"],
        updated_at=data.get("updated_at") or data["created_at"],
    )


@router.get("", response_model=list[QuestResponse])
def list_quests(
    city: str | None = Query(default=None),
    difficulty: QuestDifficulty | None = Query(default=None),
    limit: int = Query(default=50, le=MAX_LIMIT),
    _: dict = Depends(get_current_user),
):
    db = get_firestore()
    query = db.collection("quests").where("published", "==", True).limit(MAX_LIMIT)
    results = []
    for doc in query.stream():
        data = doc.to_dict()
        if city and data.get("city") not in (None, city):
            continue
        if difficulty and data.get("difficulty") != difficulty.value:
            continue
        results.append(_quest_response(doc.id, data))
    results.sort(key=lambda q: (q.difficulty.value, q.created_at), reverse=False)
    return results[:limit]


@router.post("/{quest_id}/activate", status_code=status.HTTP_200_OK)
def activate_quest(quest_id: str, current_user: dict = Depends(get_current_user)):
    """Mark a Side Quest as activated by the current user.

    Activating a quest is a "meaningful action" that feeds the activity streak and
    the "Side Quests activated" profile stat. Idempotent: re-activating the same
    quest does not double-count.
    """
    validate_document_id(quest_id)
    uid = current_user["uid"]
    db = get_firestore()

    quest_ref = db.collection("quests").document(quest_id)
    quest_doc = quest_ref.get()
    if not quest_doc.exists or not quest_doc.to_dict().get("published", True):
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Quest not found")

    activation_ref = db.collection("users").document(uid).collection("quest_activations").document(quest_id)
    already_active = activation_ref.get().exists
    activation_ref.set({"quest_id": quest_id, "activated_at": datetime.now(timezone.utc)})
    if not already_active:
        record_meaningful_action(db, uid, "activate_quest", {"quest_id": quest_id})

    return {"detail": "Quest activated", "quest_id": quest_id}


@router.post("", response_model=QuestResponse, status_code=status.HTTP_201_CREATED)
def create_quest(body: QuestCreateRequest, _: dict = Depends(get_admin_user)):
    db = get_firestore()
    now = datetime.now(timezone.utc)
    ref = db.collection("quests").document()
    ref.set({
        "title": body.title,
        "description": body.description,
        "difficulty": body.difficulty.value,
        "city": body.city,
        "area": _area_to_data(body.area),
        "published": body.published,
        "created_at": now,
        "updated_at": now,
    })
    return _quest_response(ref.id, ref.get().to_dict())


@router.put("/{quest_id}", response_model=QuestResponse)
def update_quest(quest_id: str, body: QuestUpdateRequest, _: dict = Depends(get_admin_user)):
    validate_document_id(quest_id)
    db = get_firestore()
    ref = db.collection("quests").document(quest_id)
    update = {}
    for key, value in body.model_dump(exclude_unset=True).items():
        if key == "area":
            update[key] = _area_to_data(body.area)
        elif hasattr(value, "value"):
            update[key] = value.value
        else:
            update[key] = value
    update["updated_at"] = SERVER_TIMESTAMP
    ref.update(update)
    return _quest_response(ref.id, ref.get().to_dict())
