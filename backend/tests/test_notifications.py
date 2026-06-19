"""Tests for the core notification guarantees: idempotency, rate limits, quiet hours,
dispatcher retry/backoff, token pruning, and the inactivity sweep."""

from datetime import datetime, timedelta, timezone

import pytest

from app.config import DISPATCH_MAX_ATTEMPTS
from app.notifications import fcm, outbox, triggers
from app.notifications.keys import dedupe_key
from app.notifications.rate_limit import (
    defer_for_quiet_hours,
    is_within_quiet_hours,
    try_consume_quota,
)
from app.notifications.scheduler import inactivity_sweep, stage_for_days
from app.notifications.service import notifications

UTC = timezone.utc


def _register_device(db, uid, token="tok-1"):
    db.collection("users").document(uid).collection("devices").document(token).set(
        {"token": token, "platform": "ios"}
    )


def _outbox(db, key):
    return db.collection(outbox.COLLECTION).document(key).get().to_dict()


# --- Idempotency ---------------------------------------------------------------


def test_enqueue_is_idempotent(db):
    args = dict(
        template_id="map_fomo.new_event_nearby",
        recipient_uids=["u1"],
        dedupe_base="map_fomo.new_event_nearby:evt1",
        deliver_now=False,
    )
    first = notifications.enqueue(**args)
    second = notifications.enqueue(**args)

    assert first == ["map_fomo.new_event_nearby:evt1:u1"]
    assert second == []  # deduped — no second doc
    # Exactly one outbox doc exists.
    keys = [s.id for s in db.collection(outbox.COLLECTION).stream()]
    assert keys == ["map_fomo.new_event_nearby:evt1:u1"]


def test_enqueue_dedupes_repeated_recipients(db):
    created = notifications.enqueue(
        template_id="social_pull.nudge_received",
        recipient_uids=["u1", "u1", "u2"],
        dedupe_base="social_pull.nudge_received:n1",
        deliver_now=False,
    )
    assert len(created) == 2


# --- Quiet hours ---------------------------------------------------------------


def test_quiet_hours_window_crosses_midnight():
    assert is_within_quiet_hours(datetime(2026, 1, 1, 23, 30, tzinfo=UTC), 23, 8)
    assert is_within_quiet_hours(datetime(2026, 1, 1, 2, 0, tzinfo=UTC), 23, 8)
    assert not is_within_quiet_hours(datetime(2026, 1, 1, 12, 0, tzinfo=UTC), 23, 8)


def test_defer_for_quiet_hours_returns_window_end():
    now = datetime(2026, 1, 1, 23, 30, tzinfo=UTC)
    deferred = defer_for_quiet_hours(now, None)
    assert deferred is not None and deferred > now
    assert deferred.hour == 8

    assert defer_for_quiet_hours(datetime(2026, 1, 1, 12, 0, tzinfo=UTC), None) is None


# --- Rate limits ---------------------------------------------------------------


def test_per_type_cap_enforced(db):
    # map_fomo cap is 3/day.
    day = "2026-01-01"
    results = [try_consume_quota(db, "u1", "map_fomo", day) for _ in range(4)]
    assert results == [True, True, True, False]


def test_global_cap_enforced(db, monkeypatch):
    monkeypatch.setattr("app.notifications.rate_limit.NOTIFICATION_GLOBAL_DAILY_CAP", 2)
    day = "2026-01-01"
    # Use a type with no per-type cap so only the global cap applies.
    results = [try_consume_quota(db, "u1", "social_pull", day) for _ in range(3)]
    assert results == [True, True, False]


# --- Dispatch happy path -------------------------------------------------------


def test_dispatch_sends_and_counts(db, captured_fcm):
    _register_device(db, "u1")
    key = notifications.enqueue(
        template_id="map_fomo.new_event_nearby",
        recipient_uids=["u1"],
        variables={"event_title": "Rooftop set"},
        dedupe_base="map_fomo.new_event_nearby:evt1",
        deliver_now=False,
    )[0]

    assert notifications.dispatch_one(key) == "sent"
    assert _outbox(db, key)["status"] == outbox.SENT
    assert len(captured_fcm["calls"]) == 1
    # Non-urgent send consumed quota.
    counters = db.collection("users").document("u1").collection("notification_counters")
    today = datetime.now(UTC).date().isoformat()
    assert counters.document(today).get().to_dict()["by_type"]["map_fomo"] == 1


def test_dispatch_skips_when_no_devices(db, captured_fcm):
    key = notifications.enqueue(
        template_id="map_fomo.new_event_nearby",
        recipient_uids=["u1"],
        dedupe_base="map_fomo.new_event_nearby:evt1",
        deliver_now=False,
    )[0]
    assert notifications.dispatch_one(key) == "skipped"
    assert _outbox(db, key)["error"] == "no_devices"
    assert captured_fcm["calls"] == []


def test_urgent_type_bypasses_quota(db, captured_fcm, monkeypatch):
    monkeypatch.setattr("app.notifications.rate_limit.NOTIFICATION_GLOBAL_DAILY_CAP", 0)
    _register_device(db, "u1")
    key = notifications.enqueue(
        template_id="social_pull.nudge_received",
        recipient_uids=["u1"],
        variables={"sender_name": "Sam"},
        dedupe_base="social_pull.nudge_received:n1",
        deliver_now=False,
    )[0]
    # Global cap is 0, but social_pull is urgent -> still sends.
    assert notifications.dispatch_one(key) == "sent"


def test_double_dispatch_sends_once(db, captured_fcm):
    _register_device(db, "u1")
    key = notifications.enqueue(
        template_id="social_pull.nudge_received",
        recipient_uids=["u1"],
        dedupe_base="social_pull.nudge_received:n1",
        deliver_now=False,
    )[0]
    assert notifications.dispatch_one(key) == "sent"
    # Second dispatch (e.g. cron after inline) is a no-op — already claimed/sent.
    assert notifications.dispatch_one(key) == "noop"
    assert len(captured_fcm["calls"]) == 1


# --- Retry / failure -----------------------------------------------------------


def test_transient_failure_reschedules(db, captured_fcm):
    captured_fcm["box"]["result"] = fcm.SendResult(failure_count=1, retryable=True)
    _register_device(db, "u1")
    key = notifications.enqueue(
        template_id="social_pull.nudge_received",
        recipient_uids=["u1"],
        dedupe_base="social_pull.nudge_received:n1",
        deliver_now=False,
    )[0]
    assert notifications.dispatch_one(key) == "failed"
    doc = _outbox(db, key)
    assert doc["status"] == outbox.PENDING  # back in queue for retry
    assert doc["attempts"] == 1
    assert doc["scheduled_for"] > datetime.now(UTC)  # backoff applied


def test_max_attempts_terminal(db, captured_fcm):
    captured_fcm["box"]["result"] = fcm.SendResult(failure_count=1, retryable=True)
    _register_device(db, "u1")
    key = dedupe_key("social_pull.nudge_received:n1", "u1")
    db.collection(outbox.COLLECTION).document(key).set(
        {
            "template_id": "social_pull.nudge_received",
            "recipient_uid": "u1",
            "variables": {},
            "data": {},
            "override": None,
            "status": outbox.PENDING,
            "attempts": DISPATCH_MAX_ATTEMPTS - 1,
            "scheduled_for": datetime.now(UTC) - timedelta(minutes=1),
            "created_at": datetime.now(UTC),
            "sent_at": None,
            "error": None,
        }
    )
    assert notifications.dispatch_one(key) == "failed"
    doc = _outbox(db, key)
    assert doc["status"] == outbox.FAILED
    assert doc["attempts"] == DISPATCH_MAX_ATTEMPTS


# --- Token pruning -------------------------------------------------------------


def test_invalid_token_is_pruned(db, captured_fcm):
    captured_fcm["box"]["result"] = fcm.SendResult(
        failure_count=1, invalid_tokens=["tok-1"], retryable=False
    )
    _register_device(db, "u1", token="tok-1")
    key = notifications.enqueue(
        template_id="social_pull.nudge_received",
        recipient_uids=["u1"],
        dedupe_base="social_pull.nudge_received:n1",
        deliver_now=False,
    )[0]
    assert notifications.dispatch_one(key) == "skipped"
    assert _outbox(db, key)["error"] == "all_tokens_invalid"
    # Device removed.
    devices = db.collection("users").document("u1").collection("devices").stream()
    assert [s.id for s in devices] == []


# --- Inactivity ----------------------------------------------------------------


def test_stage_for_days():
    assert stage_for_days(0) is None
    assert stage_for_days(1) == "warm"
    assert stage_for_days(2) == "cold"
    assert stage_for_days(3) == "cold"
    assert stage_for_days(4) == "dormant"
    assert stage_for_days(7) is None  # already dormant -> stop


def test_inactivity_sweep_enqueues_once(db, captured_fcm):
    now = datetime(2026, 1, 10, 12, 0, tzinfo=UTC)
    _register_device(db, "u1")
    db.collection("users").document("u1").set({"last_activity_date": "2026-01-09"})  # 1 day -> warm

    summary = inactivity_sweep(now=now)
    assert summary["warm"] == 1
    key = "inactivity.warm:2026-01-10:u1"
    assert _outbox(db, key)["template_id"] == "inactivity.warm"

    # Re-running the same day is a no-op (idempotent).
    summary2 = inactivity_sweep(now=now)
    assert summary2["warm"] == 0


# --- Nudge reminders -----------------------------------------------------------


def test_nudge_reminder_friend_sends_and_writes_inbox(db, captured_fcm):
    _register_device(db, "friend1")
    # background_tasks=None → synchronous enqueue + inline dispatch.
    triggers.nudge_reminder(
        None,
        nudge_id="n1",
        recipient_uids=["friend1"],
        reminder_count=1,
        sender_name="Sam",
    )
    assert len(captured_fcm["calls"]) == 1
    assert captured_fcm["calls"][0]["body"] == "Plans are forming. Are you in or not?"

    key = dedupe_key("social_pull.nudge_received:n1:reminder:1", "friend1")
    inbox = (
        db.collection("users").document("friend1").collection("notifications").document(key).get()
    )
    assert inbox.exists
    assert inbox.to_dict()["data"]["nudge_id"] == "n1"


def test_nudge_reminders_are_distinct_per_count(db, captured_fcm):
    _register_device(db, "friend1")
    triggers.nudge_reminder(
        None, nudge_id="n1", recipient_uids=["friend1"], reminder_count=1, sender_name="Sam"
    )
    triggers.nudge_reminder(
        None, nudge_id="n1", recipient_uids=["friend1"], reminder_count=2, sender_name="Sam"
    )
    # Each reminder is a distinct occurrence → two separate sends, not deduped.
    assert len(captured_fcm["calls"]) == 2


def test_group_nudge_reminder_uses_reminder_template(db, captured_fcm):
    _register_device(db, "member1")
    triggers.nudge_reminder(
        None,
        nudge_id="gn1",
        recipient_uids=["member1"],
        reminder_count=1,
        group_id="grp1",
        group_name="Squad",
    )
    assert len(captured_fcm["calls"]) == 1
    assert captured_fcm["calls"][0]["body"] == "Reminder: the plan in Squad is still open."
