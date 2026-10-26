"""V3 nudge pushes (brief 7.1).

Kept: nudge received (quest invites use the same one), answer received, go time,
and expiry for the sender. For group nudges the sender gets one push on the first
yes and one with the final tally, not one per answer; go time goes to the sender
and everyone who said yes.

Every send carries an occurrence-scoped dedupe base, so the same event fired from
two places (a request handler and the sweep cron) still delivers once.
"""

from __future__ import annotations

from datetime import datetime

from app.notifications.triggers import _send

_LEVELS = {"easy": "Easy", "medium": "Medium", "hard": "Hard"}


def _iso(value) -> str | None:
    return value.isoformat() if isinstance(value, datetime) else None


def _payload(nudge_id: str, data: dict) -> dict:
    """Push data: enough for the app to open the card and drive a live bar."""
    payload = {
        "nudge_id": nudge_id,
        "feed_type": data.get("feed_type", "friend"),
        "target_id": data.get("target_id", ""),
        "title": data.get("title", ""),
    }
    if data.get("feed_type") == "group":
        payload["group_id"] = data.get("target_id", "")
    for key in ("answer_by", "go_at"):
        if _iso(data.get(key)):
            payload[key] = _iso(data[key])
    if data.get("quest_difficulty"):
        payload["quest_difficulty"] = data["quest_difficulty"]
    if data.get("response_window_minutes"):
        # The sender's countdown after yes: sizes the green bar.
        payload["countdown_minutes"] = data["response_window_minutes"]
    return payload


def _tag(data: dict) -> str:
    level = _LEVELS.get(data.get("quest_difficulty") or "")
    return f"Side quest · {level}. " if data.get("quest_id") and level else ""


def received(background_tasks, *, nudge_id: str, data: dict, recipient_uids: list[str]) -> None:
    if not recipient_uids:
        return
    is_group = data.get("feed_type") == "group"
    _send(
        background_tasks,
        template_id="nudge.group_received" if is_group else "nudge.received",
        recipient_uids=recipient_uids,
        variables={
            "sender_name": data.get("sender_name") or "Someone",
            "group_name": data.get("target_name") or "your group",
            "title": data.get("title", ""),
            "tag": _tag(data),
        },
        data=_payload(nudge_id, data),
        dedupe_base=f"nudge.received:{nudge_id}",
    )


def answered(background_tasks, *, nudge_id: str, data: dict, voter_name: str, vote: str, first_yes: bool) -> None:
    """Tell the sender. One-to-one: every answer. Group: only the first yes."""
    sender = data.get("sender_uid")
    if not sender:
        return
    if data.get("feed_type") == "group":
        if not first_yes:
            return
        template, base = "nudge.group_first_yes", f"nudge.group_first_yes:{nudge_id}"
    else:
        template = "nudge.said_yes" if vote == "yes" else "nudge.said_no"
        base = f"nudge.answered:{nudge_id}"
    _send(
        background_tasks,
        template_id=template,
        recipient_uids=[sender],
        variables={"name": voter_name, "title": data.get("title", "")},
        data=_payload(nudge_id, data),
        dedupe_base=base,
    )


def group_final(background_tasks, *, nudge_id: str, data: dict, yes_count: int, size: int) -> None:
    """The group's answer window closed: one push to the sender with the tally."""
    sender = data.get("sender_uid")
    if not sender:
        return
    tally = f"{yes_count}/{size} in" if yes_count else "No one’s in"
    _send(
        background_tasks,
        template_id="nudge.group_final",
        recipient_uids=[sender],
        variables={"tally": tally, "title": data.get("title", "")},
        data=_payload(nudge_id, data),
        dedupe_base=f"nudge.group_final:{nudge_id}",
    )


def expired(background_tasks, *, nudge_id: str, data: dict) -> None:
    """Both sides: the sender learns nobody answered, and the receiver's red
    bar is replaced by a lasting "Expired" notification (brief 7.3)."""
    sender = data.get("sender_uid")
    if not sender:
        return
    votes = data.get("votes") or {}
    unanswered = [u for u in data.get("participant_uids", []) if u != sender and u not in votes]
    _send(
        background_tasks,
        template_id="nudge.expired",
        recipient_uids=[sender, *unanswered],
        variables={"title": data.get("title", "")},
        data=_payload(nudge_id, data),
        dedupe_base=f"nudge.expired:{nudge_id}",
    )


def schedule_go_time(*, nudge_id: str, data: dict, recipient_uids: list[str], go_at: datetime) -> None:
    """Queue the go-time push for the moment the countdown ends. Delivered by the
    dispatch cron. Re-calling for a later yes in a group only adds that member
    (dedupe is per recipient)."""
    _send(
        None,
        template_id="nudge.go_time",
        recipient_uids=recipient_uids,
        variables={"title": data.get("title", ""), "who": "Your plan starts now."},
        data=_payload(nudge_id, {**data, "go_at": go_at}),
        dedupe_base=f"nudge.go_time:{nudge_id}",
        scheduled_for=go_at,
    )
