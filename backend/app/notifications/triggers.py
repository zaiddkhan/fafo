"""Typed trigger helpers — one per PRD notification, mapping app events to templates.

Each helper builds the correct template id, occurrence-scoped dedupe base, and variables,
then hands off to the fire-and-forget engine. Pass a FastAPI `background_tasks` from a
request handler (so nothing blocks the response); omit it in cron/background contexts to
enqueue synchronously.

Keeping this mapping in one module means the routers stay clean ("notify X happened")
and the dedupe-key conventions live in exactly one place.
"""

from __future__ import annotations

from datetime import datetime, timedelta, timezone

from app.notifications.service import notifications, queue


def _send(background_tasks, **kwargs) -> None:
    if background_tasks is not None:
        queue(background_tasks, **kwargs)
    else:
        notifications.enqueue(**kwargs)


def _now() -> datetime:
    return datetime.now(timezone.utc)


def _ensure_utc(dt: datetime) -> datetime:
    if dt.tzinfo is None:
        return dt.replace(tzinfo=timezone.utc)
    return dt.astimezone(timezone.utc)


# --- Social pull (friend nudges) -----------------------------------------------

def nudge_received(background_tasks, *, nudge_id, recipient_uids, sender_name):
    _send(
        background_tasks,
        template_id="social_pull.nudge_received",
        recipient_uids=recipient_uids,
        variables={"sender_name": sender_name},
        data={"nudge_id": nudge_id},
        dedupe_base=f"social_pull.nudge_received:{nudge_id}",
    )


def nudge_accepted(background_tasks, *, nudge_id, recipient_uids, friend_name):
    _send(
        background_tasks,
        template_id="social_pull.nudge_accepted",
        recipient_uids=recipient_uids,
        variables={"friend_name": friend_name},
        data={"nudge_id": nudge_id},
        # Occurrence includes the accepting friend so multiple acceptances each notify once.
        dedupe_base=f"social_pull.nudge_accepted:{nudge_id}:{friend_name}",
    )


# --- Group nudges --------------------------------------------------------------

def group_nudge_received(background_tasks, *, nudge_id, group_id, recipient_uids, group_name):
    _send(
        background_tasks,
        template_id="groups.group_nudge_received",
        recipient_uids=recipient_uids,
        variables={"group_name": group_name},
        data={"nudge_id": nudge_id, "group_id": group_id},
        dedupe_base=f"groups.group_nudge_received:{nudge_id}",
    )


# --- Groups lifecycle ----------------------------------------------------------

def group_invite_received(background_tasks, *, invite_id, group_id, recipient_uid, inviter_name, group_name):
    _send(
        background_tasks,
        template_id="groups.invite_received",
        recipient_uids=[recipient_uid],
        variables={"inviter_name": inviter_name, "group_name": group_name},
        data={"invite_id": invite_id, "group_id": group_id},
        dedupe_base=f"groups.invite_received:{invite_id}",
    )


def group_invite_accepted(background_tasks, *, group_id, recipient_uids, member_name, group_name):
    _send(
        background_tasks,
        template_id="groups.invite_accepted",
        recipient_uids=recipient_uids,
        variables={"member_name": member_name, "group_name": group_name},
        data={"group_id": group_id},
        dedupe_base=f"groups.invite_accepted:{group_id}:{member_name}",
    )


def group_member_removed(background_tasks, *, group_id, recipient_uid, group_name):
    _send(
        background_tasks,
        template_id="groups.member_removed",
        recipient_uids=[recipient_uid],
        variables={"group_name": group_name},
        data={"group_id": group_id},
        dedupe_base=f"groups.member_removed:{group_id}:{recipient_uid}",
    )


def group_dissolved(background_tasks, *, group_id, recipient_uids, group_name):
    _send(
        background_tasks,
        template_id="groups.group_dissolved",
        recipient_uids=recipient_uids,
        variables={"group_name": group_name},
        data={"group_id": group_id},
        dedupe_base=f"groups.group_dissolved:{group_id}",
    )


# --- Map FOMO ------------------------------------------------------------------

def new_event_nearby(background_tasks, *, event_id, recipient_uids, event_title):
    _send(
        background_tasks,
        template_id="map_fomo.new_event_nearby",
        recipient_uids=recipient_uids,
        variables={"event_title": event_title},
        data={"event_id": event_id},
        dedupe_base=f"map_fomo.new_event_nearby:{event_id}",
    )


# --- Event updates -------------------------------------------------------------

def event_edited(background_tasks, *, event_id, recipient_uids, event_title):
    _send(
        background_tasks,
        template_id="event_updates.event_edited",
        recipient_uids=recipient_uids,
        variables={"event_title": event_title},
        data={"event_id": event_id},
        # Cooldown handled by occurrence bucket: at most one edit notice per 10 min.
        dedupe_base=f"event_updates.event_edited:{event_id}:{_edit_bucket()}",
    )


def event_cancelled(background_tasks, *, event_id, recipient_uids, event_title):
    _send(
        background_tasks,
        template_id="event_updates.event_cancelled",
        recipient_uids=recipient_uids,
        variables={"event_title": event_title},
        data={"event_id": event_id},
        dedupe_base=f"event_updates.event_cancelled:{event_id}",
    )


def _edit_bucket() -> str:
    # 10-minute buckets implement the catalog's event_edited cooldown_minutes=10 cheaply.
    now = _now()
    return f"{now.strftime('%Y%m%d%H')}{now.minute // 10}"


# --- Time pressure (event reminders, scheduled at join time) -------------------

# (template_id, timedelta-before-start)
_EVENT_REMINDERS = [
    ("time_pressure.event_24h", timedelta(hours=24)),
    ("time_pressure.event_2h", timedelta(hours=2)),
    ("time_pressure.event_30m", timedelta(minutes=30)),
]


def schedule_event_reminders(*, event_id, uid, event_title, start_dt):
    """Schedule 24h/2h/30m reminders for one joinee. Idempotent per (event, offset, uid).

    Only offsets still in the future are scheduled. Always synchronous-enqueue (no
    background_tasks) — these are future-dated, so nothing is delivered now.
    """
    start = _ensure_utc(start_dt)
    now = _now()
    for template_id, before in _EVENT_REMINDERS:
        send_at = start - before
        if send_at <= now:
            continue
        notifications.enqueue(
            template_id=template_id,
            recipient_uids=[uid],
            variables={"event_title": event_title},
            data={"event_id": event_id},
            dedupe_base=f"{template_id}:{event_id}",
            scheduled_for=send_at,
            deliver_now=False,
        )


def cancel_event_reminders(*, event_id, uid):
    """Best-effort cancel of a joinee's pending event reminders (on unjoin/cancel)."""
    from app.firebase import get_firestore
    from app.notifications import outbox
    from app.notifications.keys import dedupe_key

    db = get_firestore()
    for template_id, _ in _EVENT_REMINDERS:
        key = dedupe_key(f"{template_id}:{event_id}", uid)
        ref = db.collection(outbox.COLLECTION).document(key)
        snap = ref.get()
        if snap.exists and snap.to_dict().get("status") == outbox.PENDING:
            outbox.mark_skipped(db, key, "event_or_join_cancelled")
