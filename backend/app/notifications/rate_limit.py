"""Per-user rate limiting and quiet hours.

Two independent guards applied in the dispatcher right before send:

  * Quiet hours — non-urgent notifications inside the user's local night window are
    *deferred* (rescheduled to the window end), never dropped.
  * Daily caps — a per-type and a global per-user ceiling, counted per calendar day.

The pure decision functions (quiet-hours math, cap math) are separated from Firestore
so they can be unit-tested without a database.
"""

from __future__ import annotations

import logging
from datetime import datetime, time, timedelta, timezone

try:
    from zoneinfo import ZoneInfo
except ImportError:  # pragma: no cover
    ZoneInfo = None

from google.cloud import firestore

from app.config import (
    NOTIFICATION_GLOBAL_DAILY_CAP,
    NOTIFICATION_PER_TYPE_DAILY_CAP,
    QUIET_HOURS_END,
    QUIET_HOURS_START,
)

logger = logging.getLogger(__name__)


def resolve_tz(tz_name: str | None):
    """Return a tzinfo for the user, falling back to UTC on anything unusable."""
    if not tz_name or ZoneInfo is None:
        return timezone.utc
    try:
        return ZoneInfo(tz_name)
    except Exception:  # noqa: BLE001 — bad/unknown tz string -> UTC.
        return timezone.utc


def is_within_quiet_hours(local_dt: datetime, start: int, end: int) -> bool:
    """True if local_dt falls in the quiet window. Handles windows crossing midnight."""
    h = local_dt.hour
    if start == end:
        return False
    if start < end:
        return start <= h < end
    # Crosses midnight (e.g. 23 -> 8): quiet if at/after start OR before end.
    return h >= start or h < end


def quiet_window_end_utc(now_utc: datetime, tz, start: int, end: int) -> datetime:
    """Given we're inside quiet hours, return the next end-of-window instant in UTC."""
    local = now_utc.astimezone(tz)
    end_today = datetime.combine(local.date(), time(hour=end), tzinfo=tz)
    # If the end hour has already passed today (i.e. we're in the post-midnight tail
    # before `end`), the window ends today; otherwise it ends tomorrow.
    if local.hour >= start and start > end:
        end_local = end_today + timedelta(days=1)
    elif local.hour < end:
        end_local = end_today
    else:
        end_local = end_today + timedelta(days=1)
    return end_local.astimezone(timezone.utc)


def defer_for_quiet_hours(
    now_utc: datetime, tz_name: str | None
) -> datetime | None:
    """Return the UTC instant to defer to if now is quiet, else None (send now)."""
    tz = resolve_tz(tz_name)
    local = now_utc.astimezone(tz)
    if not is_within_quiet_hours(local, QUIET_HOURS_START, QUIET_HOURS_END):
        return None
    return quiet_window_end_utc(now_utc, tz, QUIET_HOURS_START, QUIET_HOURS_END)


def try_consume_quota(db, uid: str, type_: str, day: str) -> bool:
    """Atomically check + increment the user's daily counters.

    Returns True if within caps (and the counters were incremented), False if a cap
    would be exceeded (nothing incremented). Types without a per-type cap only count
    against the global cap.
    """
    per_type_cap = NOTIFICATION_PER_TYPE_DAILY_CAP.get(type_)
    ref = db.collection("users").document(uid).collection("notification_counters").document(day)

    @firestore.transactional
    def _txn(transaction):
        snap = ref.get(transaction=transaction)
        data = snap.to_dict() if snap.exists else {}
        global_count = int(data.get("global", 0))
        type_count = int(data.get("by_type", {}).get(type_, 0))

        if global_count >= NOTIFICATION_GLOBAL_DAILY_CAP:
            return False
        if per_type_cap is not None and type_count >= per_type_cap:
            return False

        transaction.set(
            ref,
            {
                "global": global_count + 1,
                "by_type": {**data.get("by_type", {}), type_: type_count + 1},
            },
            merge=True,
        )
        return True

    return _txn(db.transaction())
