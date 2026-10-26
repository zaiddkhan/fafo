from datetime import date, datetime, timedelta, timezone

from google.cloud.firestore import SERVER_TIMESTAMP

from app.config import STREAKS_ENABLED


def parse_activity_date(value) -> date | None:
    """Best-effort parse of a stored ``last_activity_date``.

    Tolerates the two shapes the field can take across historical writes: an
    ISO date string (``"2026-07-04"``) or a Firestore ``Timestamp`` (surfaced as
    a ``datetime``). Returns ``None`` for anything unparseable so callers never
    crash on legacy or malformed data.
    """
    if isinstance(value, str):
        try:
            return date.fromisoformat(value)
        except ValueError:
            return None
    if isinstance(value, datetime):
        return value.date()
    return None


def record_meaningful_action(db, uid: str, action_type: str, metadata: dict | None = None):
    """Record activity and update the user's daily streak.

    Streak increments once per calendar day when activity happens on consecutive days.
    If the previous activity day was missed, the streak resets to 1. Profile responses can
    show 0 after a missed day by comparing last_activity_date to today/yesterday.
    """
    now = datetime.now(timezone.utc)
    today = now.date().isoformat()
    user_ref = db.collection("users").document(uid)
    user_doc = user_ref.get()
    data = user_doc.to_dict() if user_doc.exists else {}
    last_date = data.get("last_activity_date")
    streak = int(data.get("current_streak", 0) or 0)

    if last_date == today:
        new_streak = streak or 1
    else:
        yesterday = (now.date() - timedelta(days=1)).isoformat()
        new_streak = streak + 1 if last_date == yesterday else 1

    update = {"last_activity_date": today, "updated_at": SERVER_TIMESTAMP}
    # Streaks are parked (V3 brief 1.6): stored counts are left as they were so
    # they can return; only the last-activity date keeps moving.
    if STREAKS_ENABLED:
        update.update({
            "current_streak": new_streak,
            "activity_stats.current_streak": new_streak,
            "activity_stats.last_activity_date": today,
        })
    user_ref.update(update)
    db.collection("users").document(uid).collection("activity_log").document().set({
        "action_type": action_type,
        "metadata": metadata or {},
        "created_at": SERVER_TIMESTAMP,
    })
