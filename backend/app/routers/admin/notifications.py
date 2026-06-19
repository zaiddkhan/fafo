"""Notification Templates: list, edit (versioned), and roll back notification copy
and trigger behaviour. Send timing stays governed by the event-driven engine; this
module only controls copy, the on/off toggle, and configurable params.
"""

from datetime import datetime, timezone
from uuid import uuid4

from fastapi import APIRouter, Depends, HTTPException, status

from app.audit import record_admin_action
from app.dependencies import get_admin_user, validate_document_id
from app.firebase import get_firestore
from app.notification_catalog import NOTIFICATION_CATALOG, template_id
from app.notifications.service import notifications
from app.schemas import (
    BroadcastTarget,
    NotificationBroadcastRequest,
    NotificationBroadcastResponse,
    NotificationTemplateResponse,
    NotificationTemplateUpdateRequest,
    NotificationTemplateVersion,
)

router = APIRouter()


def _ensure_seeded(db) -> None:
    """Lazily seed templates from the catalog if the collection is empty."""
    col = db.collection("notification_templates")
    existing = {doc.id for doc in col.stream()}
    now = datetime.now(timezone.utc)
    for entry in NOTIFICATION_CATALOG:
        tid = template_id(entry["type"], entry["subtype"])
        if tid in existing:
            continue
        col.document(tid).set(
            {
                "type": entry["type"],
                "subtype": entry["subtype"],
                "body": entry["body"],
                "variables": entry["variables"],
                "sound": entry["sound"],
                "enabled": True,
                "params": entry["params"],
                "version": 1,
                "updated_at": now,
                "updated_by": None,
            }
        )


def _to_response(doc_id: str, data: dict) -> NotificationTemplateResponse:
    return NotificationTemplateResponse(
        id=doc_id,
        type=data.get("type", ""),
        subtype=data.get("subtype", ""),
        body=data.get("body", ""),
        variables=data.get("variables", []),
        sound=data.get("sound"),
        enabled=data.get("enabled", True),
        params=data.get("params", {}),
        version=data.get("version", 1),
        updated_at=data.get("updated_at"),
        updated_by=data.get("updated_by"),
    )


@router.get("/notification-templates", response_model=list[NotificationTemplateResponse])
def list_templates(_: dict = Depends(get_admin_user)):
    db = get_firestore()
    _ensure_seeded(db)
    items = [_to_response(doc.id, doc.to_dict()) for doc in db.collection("notification_templates").stream()]
    # Stable grouping: by type, then subtype.
    items.sort(key=lambda t: (t.type, t.subtype))
    return items


@router.put("/notification-templates/{template_id}", response_model=NotificationTemplateResponse)
def update_template(
    template_id: str,
    body: NotificationTemplateUpdateRequest,
    admin: dict = Depends(get_admin_user),
):
    validate_document_id(template_id)
    db = get_firestore()
    ref = db.collection("notification_templates").document(template_id)
    doc = ref.get()
    if not doc.exists:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Template not found")
    current = doc.to_dict()

    update = {k: v for k, v in body.model_dump(exclude_unset=True).items() if v is not None}
    if not update:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="No fields to update")

    # Snapshot the current state into version history before mutating.
    prior_version = current.get("version", 1)
    ref.collection("versions").document(str(prior_version)).set(
        {
            "version": prior_version,
            "body": current.get("body", ""),
            "sound": current.get("sound"),
            "enabled": current.get("enabled", True),
            "params": current.get("params", {}),
            "updated_at": current.get("updated_at"),
            "updated_by": current.get("updated_by"),
        }
    )

    now = datetime.now(timezone.utc)
    update.update({"version": prior_version + 1, "updated_at": now, "updated_by": admin["uid"]})
    ref.update(update)
    record_admin_action(
        db, admin["uid"], "notification_template.update",
        target_type="notification_template", target_id=template_id,
        metadata={"version": prior_version + 1},
    )
    return _to_response(template_id, ref.get().to_dict())


@router.get("/notification-templates/{template_id}/versions", response_model=list[NotificationTemplateVersion])
def list_versions(template_id: str, _: dict = Depends(get_admin_user)):
    validate_document_id(template_id)
    db = get_firestore()
    ref = db.collection("notification_templates").document(template_id)
    if not ref.get().exists:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Template not found")
    versions = [
        NotificationTemplateVersion(
            version=v.to_dict().get("version", 0),
            body=v.to_dict().get("body", ""),
            sound=v.to_dict().get("sound"),
            enabled=v.to_dict().get("enabled", True),
            params=v.to_dict().get("params", {}),
            updated_at=v.to_dict().get("updated_at"),
            updated_by=v.to_dict().get("updated_by"),
        )
        for v in ref.collection("versions").stream()
    ]
    versions.sort(key=lambda v: v.version, reverse=True)
    return versions


@router.post("/notification-templates/{template_id}/rollback/{version}", response_model=NotificationTemplateResponse)
def rollback_template(template_id: str, version: int, admin: dict = Depends(get_admin_user)):
    validate_document_id(template_id)
    db = get_firestore()
    ref = db.collection("notification_templates").document(template_id)
    doc = ref.get()
    if not doc.exists:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Template not found")
    snap = ref.collection("versions").document(str(version)).get()
    if not snap.exists:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Version not found")
    current = doc.to_dict()
    target = snap.to_dict()

    # Snapshot current before overwriting, then restore target's content.
    prior_version = current.get("version", 1)
    ref.collection("versions").document(str(prior_version)).set(
        {
            "version": prior_version,
            "body": current.get("body", ""),
            "sound": current.get("sound"),
            "enabled": current.get("enabled", True),
            "params": current.get("params", {}),
            "updated_at": current.get("updated_at"),
            "updated_by": current.get("updated_by"),
        }
    )
    now = datetime.now(timezone.utc)
    ref.update(
        {
            "body": target.get("body", ""),
            "sound": target.get("sound"),
            "enabled": target.get("enabled", True),
            "params": target.get("params", {}),
            "version": prior_version + 1,
            "updated_at": now,
            "updated_by": admin["uid"],
        }
    )
    record_admin_action(
        db, admin["uid"], "notification_template.rollback",
        target_type="notification_template", target_id=template_id,
        metadata={"rolled_back_to": version, "new_version": prior_version + 1},
    )
    return _to_response(template_id, ref.get().to_dict())


@router.post("/notifications/broadcast", response_model=NotificationBroadcastResponse)
def broadcast(body: NotificationBroadcastRequest, admin: dict = Depends(get_admin_user)):
    """Admin-initiated push to all users or a specific uid list.

    Enqueues idempotent outbox docs (dedupe key = broadcast:{id}:{uid}) carrying inline
    copy. Delivery is left to the cron dispatcher so a large fan-out never blocks this
    request. Respects quiet hours and the global per-user daily cap.
    """
    db = get_firestore()
    broadcast_id = str(uuid4())

    if body.target == BroadcastTarget.uids:
        uids = [validate_document_id(u) for u in body.uids]
        if not uids:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="No uids provided")
    else:
        uids = [doc.id for doc in db.collection("users").stream()]

    created = notifications.enqueue(
        template_id="admin.broadcast",
        recipient_uids=uids,
        override={"title": body.title, "body": body.body, "sound": body.sound},
        data={"broadcast_id": broadcast_id},
        dedupe_base=f"admin.broadcast:{broadcast_id}",
        deliver_now=False,
    )
    record_admin_action(
        db, admin["uid"], "notification.broadcast",
        target_type="broadcast", target_id=broadcast_id,
        metadata={"target": body.target.value, "enqueued": len(created)},
    )
    return NotificationBroadcastResponse(broadcast_id=broadcast_id, enqueued=len(created))
