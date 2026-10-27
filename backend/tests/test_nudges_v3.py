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


# --- Review fixes ----------------------------------------------------------------


def test_group_stays_open_to_answers_past_go_time():
    data = _pending(
        status="accepted_timer",
        feed_type="group",
        go_at=T0 + timedelta(minutes=5, seconds=30),
        votes={"b": "yes"},
    )
    at_six = T0 + timedelta(minutes=6)
    assert _settle(data, ["b", "c", "d"], at_six) == {}
    assert _settle(data, ["b", "c", "d"], T0 + timedelta(minutes=10))["outcome"] == "yes"
    everyone = {**data, "votes": {"b": "yes", "c": "no", "d": "no"}}
    assert _settle(everyone, ["b", "c", "d"], at_six)["outcome"] == "yes"


def test_late_settle_stamps_the_real_deadline():
    hours_later = T0 + timedelta(hours=3)
    assert _settle(_pending(), ["b"], hours_later)["resolved_at"] == T0 + timedelta(minutes=10)
    accepted = _pending(status="accepted_timer", go_at=T0 + timedelta(minutes=16))
    assert _settle(accepted, ["b"], hours_later)["resolved_at"] == T0 + timedelta(minutes=16)


def test_referral_attempts_are_capped_per_day(db, monkeypatch):
    from fastapi import HTTPException

    from app.routers import friends

    monkeypatch.setattr(friends, "get_firestore", lambda: db)
    for _ in range(friends.REFERRAL_DAILY_ATTEMPTS):
        friends._consume_referral_attempt(db, "u1")
    with pytest.raises(HTTPException) as exc:
        friends._consume_referral_attempt(db, "u1")
    assert exc.value.status_code == 429


def test_free_status_is_only_shown_to_friends(monkeypatch):
    from app.routers import friends
    from app.schemas import FriendshipStatus

    data = {"display_name": "Maya", "username": "maya", "free_now": True, "side_quest_invites": False}
    monkeypatch.setattr(friends, "_friendship_status", lambda viewer, uid: FriendshipStatus.none)
    stranger_view = friends.public_user_from_doc("maya", data, "stranger")
    assert stranger_view.free_now is False
    assert stranger_view.side_quest_invites is True
    monkeypatch.setattr(friends, "_friendship_status", lambda viewer, uid: FriendshipStatus.friends)
    friend_view = friends.public_user_from_doc("maya", data, "friend")
    assert friend_view.free_now is True
    assert friend_view.side_quest_invites is False


def test_nudges_go_data_only_only_to_capable_builds(db, captured_fcm):
    users = db.collection("users").document("b").collection("devices")
    users.document("new").set({"token": "new", "platform": "android", "capabilities": ["live_nudges"]})
    users.document("old").set({"token": "old", "platform": "android"})
    nudge_events.received(
        None,
        nudge_id="n2",
        data={"feed_type": "friend", "target_id": "b", "sender_uid": "a", "sender_name": "Maya", "title": "Coffee?"},
        recipient_uids=["b"],
    )
    by_token = {c["tokens"][0]: c["android_data_only"] for c in captured_fcm["calls"]}
    assert by_token == {"new": True, "old": False}


def test_receiver_push_points_old_clients_at_the_senders_feed(db, captured_fcm):
    _device(db, "b")
    nudge_events.received(
        None,
        nudge_id="n3",
        data={"feed_type": "friend", "target_id": "b", "sender_uid": "a", "sender_name": "Maya", "title": "Coffee?"},
        recipient_uids=["b"],
    )
    payload = captured_fcm["calls"][0]["data"]
    assert payload["target_id"] == "a"
    assert payload["title"] == "Maya"


def test_malformed_copy_is_sent_as_is():
    from app.notifications.service import _fill

    assert _fill("Use code {", {}) == "Use code {"
    assert _fill("{name} said yes", {"name": "Leo"}) == "Leo said yes"


# --- Cancel ----------------------------------------------------------------------


def _live_doc(db, doc_id, **data):
    soon = datetime.now(UTC) + timedelta(minutes=8)
    return _nudge_doc(db, doc_id, **{"status": "active", "answer_by": soon, "expires_at": soon, "votes": {}, **data})


def test_sender_cancels_and_can_send_again(nudge_db, captured_fcm):
    _live_doc(nudge_db, "n1")
    res = nudges.cancel_nudge("n1", None, {"uid": "a"})
    assert res.outcome == "cancelled"
    doc = nudge_db.collection("nudges").document("n1").get().to_dict()
    assert doc["status"] == "resolved" and doc["final_pushed"] is True
    # The sweep has nothing more to say about it.
    sweep_nudges()
    assert all("Expired" not in c["title"] for c in captured_fcm["calls"])


def test_only_the_sender_can_cancel(nudge_db):
    _live_doc(nudge_db, "n1")
    with pytest.raises(nudges.HTTPException) as e:
        nudges.cancel_nudge("n1", None, {"uid": "b"})
    assert e.value.status_code == 403


def test_cannot_cancel_a_finished_plan(nudge_db):
    past = datetime.now(UTC) - timedelta(minutes=1)
    _nudge_doc(nudge_db, "n1", status="active", answer_by=past, expires_at=past, votes={})
    with pytest.raises(nudges.HTTPException) as e:
        nudges.cancel_nudge("n1", None, {"uid": "a"})
    assert e.value.status_code == 409


def test_cancel_pushes_yes_voters_and_quietly_clears_the_rest(nudge_db, captured_fcm):
    for uid in ("b", "c", "d"):
        _device(nudge_db, uid)
    _live_doc(nudge_db, "n1", feed_type="group", participant_uids=["a", "b", "c", "d"], votes={"b": "yes", "c": "no"})
    nudges.cancel_nudge("n1", None, {"uid": "a"})
    by_token = {c["tokens"][0]: c for c in captured_fcm["calls"]}
    assert set(by_token) == {"tok-b", "tok-d"}  # c already said no: nothing to tell
    assert by_token["tok-b"]["title"] == "Cancelled: Coffee downstairs?"
    assert "silent_remove" not in by_token["tok-b"]["data"]
    assert by_token["tok-d"]["data"]["silent_remove"] == "1"


def test_go_time_push_is_dropped_after_cancel(nudge_db, captured_fcm):
    _device(nudge_db, "a")
    _live_doc(nudge_db, "n1", status="accepted_timer", votes={"b": "yes"})
    nudge_events.schedule_go_time(
        nudge_id="n1", data={"title": "Coffee?", "feed_type": "friend", "sender_uid": "a"},
        recipient_uids=["a"], go_at=datetime.now(UTC) + timedelta(minutes=5),
    )
    nudges.cancel_nudge("n1", None, {"uid": "a"})
    from app.notifications.service import NotificationService

    svc = NotificationService()
    go = [d for d in nudge_db.collection(outbox.COLLECTION).stream() if d.id.startswith("nudge.go_time")]
    assert go
    for doc in go:
        # Go time arrives: the dispatch cron picks it up.
        doc.reference.update({"scheduled_for": datetime.now(UTC) - timedelta(seconds=1)})
        assert svc.dispatch_one(doc.id) == "skipped"
    assert all(not c["title"].startswith("Go time") for c in captured_fcm["calls"])
