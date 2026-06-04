from datetime import datetime, timezone
from uuid import uuid4

from fastapi import APIRouter, Depends, HTTPException, Query, status

from app.dependencies import get_admin_user, get_current_user, validate_document_id
from app.firebase import get_firestore
from app.schemas import BlogCreateRequest, BlogResponse, BlogUpdateRequest

router = APIRouter(prefix="/blogs", tags=["blogs"])


def _normalize_city(city: str) -> str:
    return city.strip().lower()


def _blog_to_response(doc_id: str, data: dict) -> BlogResponse:
    return BlogResponse(
        id=doc_id,
        city=data["city"],
        title=data["title"],
        subtitle=data.get("subtitle"),
        body=data["body"],
        image_url=data.get("image_url"),
        read_time=data.get("read_time"),
        published=data.get("published", True),
        created_at=data["created_at"],
        updated_at=data["updated_at"],
    )


@router.get("", response_model=list[BlogResponse])
def list_blogs(
    city: str = Query(..., min_length=1, max_length=80),
    limit: int = Query(default=10, ge=1, le=50),
    _: dict = Depends(get_current_user),
):
    db = get_firestore()
    city_key = _normalize_city(city)
    query = (
        db.collection("blogs")
        .where("city_key", "==", city_key)
        .where("published", "==", True)
        .limit(limit)
    )
    blogs = [_blog_to_response(doc.id, doc.to_dict()) for doc in query.stream()]
    blogs.sort(key=lambda b: b.created_at, reverse=True)
    return blogs


@router.post("/admin", response_model=BlogResponse, status_code=status.HTTP_201_CREATED)
def create_blog(body: BlogCreateRequest, _: dict = Depends(get_admin_user)):
    db = get_firestore()
    now = datetime.now(timezone.utc)
    blog_id = str(uuid4())
    data = {
        "city": body.city.strip(),
        "city_key": _normalize_city(body.city),
        "title": body.title,
        "subtitle": body.subtitle,
        "body": body.body,
        "image_url": body.image_url,
        "read_time": body.read_time,
        "published": body.published,
        "created_at": now,
        "updated_at": now,
    }
    db.collection("blogs").document(blog_id).set(data)
    return _blog_to_response(blog_id, data)


@router.put("/admin/{blog_id}", response_model=BlogResponse)
def update_blog(
    blog_id: str,
    body: BlogUpdateRequest,
    _: dict = Depends(get_admin_user),
):
    validate_document_id(blog_id)
    db = get_firestore()
    ref = db.collection("blogs").document(blog_id)
    doc = ref.get()
    if not doc.exists:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Blog not found")

    update = {k: v for k, v in body.model_dump(exclude_unset=True).items() if v is not None}
    if "city" in update:
        update["city"] = update["city"].strip()
        update["city_key"] = _normalize_city(update["city"])
    if not update:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="No fields to update")
    update["updated_at"] = datetime.now(timezone.utc)
    ref.update(update)
    return _blog_to_response(blog_id, ref.get().to_dict())


@router.delete("/admin/{blog_id}", status_code=status.HTTP_200_OK)
def delete_blog(blog_id: str, _: dict = Depends(get_admin_user)):
    validate_document_id(blog_id)
    db = get_firestore()
    ref = db.collection("blogs").document(blog_id)
    if not ref.get().exists:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Blog not found")
    ref.delete()
    return {"detail": "Blog deleted"}
