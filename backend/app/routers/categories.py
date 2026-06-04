from fastapi import APIRouter

from app.firebase import get_firestore
from app.schemas import CategoryResponse

router = APIRouter(prefix="/categories", tags=["categories"])


@router.get("", response_model=list[CategoryResponse])
def list_categories():
    db = get_firestore()
    docs = db.collection("categories").order_by("sort_order").stream()
    return [
        CategoryResponse(
            id=doc.id,
            name=(data := doc.to_dict())["name"],
            emoji=data["emoji"],
            sort_order=data["sort_order"],
        )
        for doc in docs
    ]
