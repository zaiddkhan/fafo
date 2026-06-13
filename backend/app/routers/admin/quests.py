"""Quest Manager: list all quests (published + unpublished) with activation counts.

Create / update / publish-toggle reuse the existing admin-gated endpoints in
app.routers.quests (POST /quests, PUT /quests/{id}). This module adds the
admin-only listing that includes unpublished quests and the activation KPI.
"""

from fastapi import APIRouter, Depends, Query

from app.dependencies import get_admin_user
from app.firebase import get_firestore
from app.routers.quests import _area_from_data
from app.schemas import AdminQuestResponse, QuestDifficulty

router = APIRouter()


@router.get("/quests", response_model=list[AdminQuestResponse])
def list_all_quests(limit: int = Query(default=200, le=500), _: dict = Depends(get_admin_user)):
    db = get_firestore()
    out: list[AdminQuestResponse] = []
    for doc in db.collection("quests").stream():
        data = doc.to_dict() or {}
        out.append(
            AdminQuestResponse(
                id=doc.id,
                title=data.get("title", ""),
                description=data.get("description"),
                difficulty=QuestDifficulty(data.get("difficulty", QuestDifficulty.easy.value)),
                city=data.get("city"),
                area=_area_from_data(data.get("area")),
                published=data.get("published", True),
                activation_count=int(data.get("activation_count", 0)),
                created_at=data["created_at"],
                updated_at=data.get("updated_at") or data["created_at"],
            )
        )
    out.sort(key=lambda q: q.created_at, reverse=True)
    return out[:limit]
