"""V3 nudge timing and pushes: the state machine, push copy, and the sweep cron."""

from datetime import datetime, timedelta, timezone

import pytest

from app.notifications import nudge_events, outbox
from app.routers import nudges
from app.routers.nudges import _settle, sweep_nudges

UTC = timezone.utc
T0 = datetime(2026, 1, 1, tzinfo=UTC)


@pytest.fixture
def nudge_db(db, monkeypatch):
    monkeypatch.setattr(nudges, "get_firestore", lambda: db)
    return db


def _device(db, uid):
    db.collection("users").document(uid).collection("devices").document(f"tok-{uid}").set(
        {"token": f"tok-{uid}", "platform": "ios"}
    )


def _pending(**extra):
    return {
        "status": "active",
        "answer_by": T0 + timedelta(minutes=10),
        "expires_at": T0 + timedelta(minutes=10),
        "votes": {},
        **extra,
    }


# --- State machine ---------------------------------------------------------------


def test_pending_stays_pending_inside_window():
    assert _settle(_pending(), ["b"], T0 + timedelta(minutes=9)) == {}


def test_pending_expires_at_ten_minutes():
    update = _settle(_pending(), ["b"], T0 + timedelta(minutes=10))
    assert update["status"] == "expired"
    assert update["outcome"] == "expired"


def test_friend_no_resolves_as_no():
    update = _settle(_pending(votes={"b": "no"}), ["b"], T0 + timedelta(minutes=1))
    assert update["status"] == "resolved"
    assert update["outcome"] == "no"


def test_group_waits_for_everyone():
    assert _settle(_pending(votes={"b": "no"}), ["b", "c"], T0 + timedelta(minutes=1)) == {}


def test_accepted_resolves_yes_at_go_time():
    data = _pending(status="accepted_timer", go_at=T0 + timedelta(minutes=16))
    assert _settle(data, ["b"], T0 + timedelta(minutes=15)) == {}
    assert _settle(data, ["b"], T0 + timedelta(minutes=16))["outcome"] == "yes"


# --- Push copy -------------------------------------------------------------------


def test_quest_nudge_push_leads_with_plan_title_and_tags(db, captured_fcm):
    _device(db, "b")
    nudge_events.received(
        None,
        nudge_id="n1",
        data={
            "feed_type": "friend",
            "target_id": "b",
            "sender_uid": "a",
            "sender_name": "Maya",
            "title": "Walk one block",
            "quest_id": "walk-one-block",
            "quest_difficulty": "easy",
            "answer_by": T0,
        },
        recipient_uids=["b"],
    )
    call = captured_fcm["calls"][0]
    assert call["title"] == "Maya: Walk one block"
    assert call["body"] == "Side quest · Easy. You have 10 minutes."
    assert call["data"]["quest_difficulty"] == "easy"
    assert call["data"]["answer_by"] == T0.isoformat()


def test_go_time_is_scheduled_not_sent_now(db, captured_fcm):
    _device(db, "a")
    go_at = datetime.now(UTC) + timedelta(minutes=10)
    nudge_events.schedule_go_time(
        nudge_id="n1", data={"title": "Coffee?", "feed_type": "friend"}, recipient_uids=["a"], go_at=go_at
    )
    assert captured_fcm["calls"] == []
    pending = [d for d in db.collection(outbox.COLLECTION).stream()]
    assert len(pending) == 1


# --- Sweep cron ------------------------------------------------------------------


def _nudge_doc(db, doc_id, **data):
    base = {
        "feed_type": "friend",
        "feed_id": "friend_a_b",
        "target_id": "b",
        "participant_uids": ["a", "b"],
        "sender_uid": "a",
        "title": "Coffee downstairs?",
        "response_window_minutes": 10,
        "created_at": datetime.now(UTC) - timedelta(minutes=11),
        "final_pushed": False,
        **data,
    }
    db.collection("nudges").document(doc_id).set(base)
    return base


def test_sweep_expires_and_tells_the_sender_once(nudge_db, captured_fcm):
    _device(nudge_db, "a")
    past = datetime.now(UTC) - timedelta(minutes=1)
    _nudge_doc(nudge_db, "n1", status="active", answer_by=past, expires_at=past, votes={})

    sweep_nudges()
    sweep_nudges()

    doc = nudge_db.collection("nudges").document("n1").get().to_dict()
    assert doc["status"] == "expired"
    assert doc["final_pushed"] is True
    titles = [c["title"] for c in captured_fcm["calls"]]
    assert titles == ["Expired: Coffee downstairs?"]


def test_sweep_sends_one_group_tally_when_window_closes(nudge_db, captured_fcm):
    _device(nudge_db, "a")
    now = datetime.now(UTC)
    _nudge_doc(
        nudge_db,
        "g1",
        feed_type="group",
        feed_id="group_g",
        target_id="g",
        participant_uids=["a", "b", "c", "d"],
        status="accepted_timer",
        answer_by=now - timedelta(seconds=5),
        go_at=now + timedelta(minutes=3),
        expires_at=now + timedelta(minutes=3),
        votes={"b": "yes", "c": "no"},
    )

    sweep_nudges()
    sweep_nudges()

    titles = [c["title"] for c in captured_fcm["calls"]]
    assert titles == ["1/3 in: Coffee downstairs?"]
    # Still counting down to go time, so not finished yet.
    assert nudge_db.collection("nudges").document("g1").get().to_dict()["final_pushed"] is False


# --- Events parked ---------------------------------------------------------------


def test_queued_event_pushes_are_skipped_while_events_are_parked(db, captured_fcm, monkeypatch):
    from app.notifications.service import notifications

    monkeypatch.setattr("app.notifications.service.EVENTS_ENABLED", False)
    _device(db, "u1")
    key = notifications.enqueue(
        template_id="time_pressure.event_2h",
        recipient_uids=["u1"],
        variables={"event_title": "Rooftop set"},
        dedupe_base="time_pressure.event_2h:evt1",
        deliver_now=False,
    )[0]
    assert notifications.dispatch_one(key) == "skipped"
    assert captured_fcm["calls"] == []
