"""Scheduled (cron-driven) notification logic.

Time-pressure event reminders are scheduled at join time (see triggers.schedule_event_reminders),
so the only periodic *scan* needed is inactivity: walk users by last-activity date and
nudge dormant ones through warm -> cold -> dormant exactly once per stage per day.
"""

from __future__ import annotations

import logging
from datetime import date, datetime, timezone

from app.config import (
    INACTIVITY_COLD_DAYS_MAX,
    INACTIVITY_COLD_DAYS_MIN,
    INACTIVITY_DORMANT_DAYS,
    INACTIVITY_WARM_DAYS,
)
from app.firebase import get_firestore
from app.notifications.service import notifications

logger = logging.getLogger(__name__)


def stage_for_days(days: int) -> str | None:
    """Map days-since-activity to an inactivity stage, or None for no notification."""
    if days == INACTIVITY_WARM_DAYS:
        return "warm"
    if INACTIVITY_COLD_DAYS_MIN <= days <= INACTIVITY_COLD_DAYS_MAX:
        return "cold"
    if days == INACTIVITY_DORMANT_DAYS:
        return "dormant"
    # Day 0 (active) and day 5+ (already dormant, PRD says stop) -> nothing.
    return None


def _parse_date(value) -> date | None:
    if isinstance(value, str):
        try:
            return date.fromisoformat(value)
        except ValueError:
            return None
    if isinstance(value, datetime):
        return value.date()
    return None


def inactivity_sweep(*, now: datetime | None = None, limit: int = 1000) -> dict:
    """Enqueue inactivity notifications for users at a stage boundary.

    Idempotent: the dedupe key includes the stage and today's date, and the inactivity
    daily cap (1/day) is a second guard, so re-running the sweep within a day is a no-op.
    """
    db = get_firestore()
    now = now or datetime.now(timezone.utc)
    today = now.date()
    today_iso = today.isoformat()
    summary = {"scanned": 0, "warm": 0, "cold": 0, "dormant": 0}

    for doc in db.collection("users").limit(limit).stream():
        data = doc.to_dict() or {}
        last = _parse_date(data.get("last_activity_date"))
        if last is None:
            continue
        summary["scanned"] += 1
        days = (today - last).days
        stage = stage_for_days(days)
        if stage is None:
            continue
        created = notifications.enqueue(
            template_id=f"inactivity.{stage}",
            recipient_uids=[doc.id],
            variables={},
            data={"stage": stage, "days_inactive": days},
            # date in the base => one per user per stage per day.
            dedupe_base=f"inactivity.{stage}:{today_iso}",
            deliver_now=True,
        )
        # Count only docs actually created — re-running the sweep dedupes to zero.
        if created:
            summary[stage] += 1
    return summary
