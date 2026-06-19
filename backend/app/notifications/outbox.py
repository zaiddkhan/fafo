"""Outbox persistence + idempotency primitives.

The outbox doc id is the dedupe key. `create_if_absent` guarantees a logical action
maps to exactly one doc. `claim` flips pending -> sending inside a transaction so that
inline dispatch and the cron dispatcher can never both send the same doc.
"""

from __future__ import annotations

from datetime import datetime, timezone

from google.cloud import firestore

COLLECTION = "notification_outbox"

# Statuses
PENDING = "pending"
SENDING = "sending"
SENT = "sent"
FAILED = "failed"
SKIPPED = "skipped"


def _ensure_utc(dt: datetime) -> datetime:
    if dt.tzinfo is None:
        return dt.replace(tzinfo=timezone.utc)
    return dt.astimezone(timezone.utc)


def create_if_absent(
    db,
    dedupe_key: str,
    *,
    template_id: str,
    recipient_uid: str,
    variables: dict,
    data: dict,
    scheduled_for: datetime,
    now: datetime,
    override: dict | None = None,
) -> bool:
    """Create the outbox doc only if it does not already exist.

    Returns True if a new doc was written, False if it already existed (deduped).
    Uses a create-only transaction so concurrent triggers can't both win.
    """
    ref = db.collection(COLLECTION).document(dedupe_key)

    @firestore.transactional
    def _txn(transaction):
        snap = ref.get(transaction=transaction)
        if snap.exists:
            return False
        transaction.set(
            ref,
            {
                "template_id": template_id,
                "recipient_uid": recipient_uid,
                "variables": variables,
                "data": data,
                "override": override,
                "status": PENDING,
                "attempts": 0,
                "scheduled_for": _ensure_utc(scheduled_for),
                "created_at": _ensure_utc(now),
                "sent_at": None,
                "error": None,
            },
        )
        return True

    return _txn(db.transaction())


def claim(db, dedupe_key: str, now: datetime) -> dict | None:
    """Atomically claim a due pending doc for sending.

    Flips PENDING -> SENDING so inline and cron dispatch can't both send the same doc.
    Returns the doc data if this caller won the claim, else None (already claimed, not
    due, or terminal). Does NOT touch `attempts` — that counts real send failures only.
    """
    ref = db.collection(COLLECTION).document(dedupe_key)

    @firestore.transactional
    def _txn(transaction):
        snap = ref.get(transaction=transaction)
        if not snap.exists:
            return None
        data = snap.to_dict()
        if data.get("status") != PENDING:
            return None
        if _ensure_utc(data["scheduled_for"]) > _ensure_utc(now):
            return None
        transaction.update(ref, {"status": SENDING})
        data["status"] = SENDING
        return data

    return _txn(db.transaction())


def defer(db, dedupe_key: str, scheduled_for: datetime) -> None:
    """Return a claimed doc to PENDING at a later time (e.g. quiet-hours deferral).

    Not a failure: `attempts` is untouched.
    """
    db.collection(COLLECTION).document(dedupe_key).update(
        {"status": PENDING, "scheduled_for": _ensure_utc(scheduled_for)}
    )


def mark_sent(db, dedupe_key: str, now: datetime) -> None:
    db.collection(COLLECTION).document(dedupe_key).update(
        {"status": SENT, "sent_at": _ensure_utc(now), "error": None}
    )


def mark_skipped(db, dedupe_key: str, reason: str) -> None:
    db.collection(COLLECTION).document(dedupe_key).update(
        {"status": SKIPPED, "error": reason}
    )


def reschedule_failed(
    db, dedupe_key: str, *, attempts: int, error: str, next_attempt_at: datetime | None
) -> None:
    """Record a send failure: back to PENDING for retry, or terminal FAILED.

    `attempts` is the new (incremented) failure count. If next_attempt_at is None
    (max attempts reached) the doc is left FAILED.
    """
    if next_attempt_at is None:
        db.collection(COLLECTION).document(dedupe_key).update(
            {"status": FAILED, "attempts": attempts, "error": error}
        )
    else:
        db.collection(COLLECTION).document(dedupe_key).update(
            {
                "status": PENDING,
                "attempts": attempts,
                "error": error,
                "scheduled_for": _ensure_utc(next_attempt_at),
            }
        )


def due_pending_keys(db, now: datetime, limit: int) -> list[str]:
    """Return dedupe keys of pending docs whose scheduled_for is due.

    Queries by status only (no composite index needed) and filters scheduled_for in
    Python — consistent with the rest of this codebase's index-light approach.
    """
    now = _ensure_utc(now)
    keys: list[str] = []
    for doc in db.collection(COLLECTION).where("status", "==", PENDING).limit(limit * 4).stream():
        data = doc.to_dict()
        sched = data.get("scheduled_for")
        if sched is not None and _ensure_utc(sched) <= now:
            keys.append(doc.id)
        if len(keys) >= limit:
            break
    return keys
