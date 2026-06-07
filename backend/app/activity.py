from datetime import datetime, timedelta, timezone

from google.cloud.firestore import SERVER_TIMESTAMP


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

    user_ref.update({
        "last_activity_date": today,
        "current_streak": new_streak,
        "activity_stats.current_streak": new_streak,
        "activity_stats.last_activity_date": today,
        "updated_at": SERVER_TIMESTAMP,
    })
    db.collection("users").document(uid).collection("activity_log").document().set({
        "action_type": action_type,
        "metadata": metadata or {},
        "created_at": SERVER_TIMESTAMP,
    })
