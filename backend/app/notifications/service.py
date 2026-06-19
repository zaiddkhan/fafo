"""NotificationService — the generic, call-from-anywhere notification engine.

Two responsibilities:

  * enqueue(...)         — write idempotent outbox docs (fast, never raises).
  * dispatch_pending(...) — drain the outbox to FCM with rate limits, quiet hours,
                            retries and token pruning.

Triggers should use the fire-and-forget `queue(background_tasks, ...)` helper so nothing
in the notification path can block or break the user's request. A module-level singleton
`notifications` is exported for convenience.
"""

from __future__ import annotations

import logging
from datetime import datetime, timedelta, timezone

from app.config import (
    DISPATCH_BATCH_SIZE,
    DISPATCH_MAX_ATTEMPTS,
    NOTIFICATION_URGENT_TYPES,
)
from app.firebase import get_firestore
from app.notification_catalog import NOTIFICATION_CATALOG
from app.notifications import fcm, outbox
from app.notifications.keys import dedupe_key
from app.notifications.rate_limit import defer_for_quiet_hours, try_consume_quota

logger = logging.getLogger(__name__)

_CATALOG_BY_ID = {f'{e["type"]}.{e["subtype"]}': e for e in NOTIFICATION_CATALOG}


class _SafeDict(dict):
    """str.format_map helper: leave unknown {placeholders} blank rather than raising."""

    def __missing__(self, key):  # noqa: D401
        return ""


def _now() -> datetime:
    return datetime.now(timezone.utc)


def _type_of(template_id: str) -> str:
    return template_id.split(".", 1)[0]


def _backoff_seconds(attempts: int) -> int:
    # 1->60s, 2->120s, 3->240s ... capped at 30 min.
    return min(60 * (2 ** (attempts - 1)), 1800)


class NotificationService:
    """Stateless engine; resolves Firestore lazily so tests can patch it."""

    # ---- enqueue -------------------------------------------------------------

    def enqueue(
        self,
        *,
        template_id: str,
        recipient_uids,
        variables: dict | None = None,
        data: dict | None = None,
        dedupe_base: str | None = None,
        scheduled_for: datetime | None = None,
        override: dict | None = None,
        deliver_now: bool = True,
    ) -> list[str]:
        """Write one idempotent outbox doc per recipient. Returns keys actually created.

        `dedupe_base` is the occurrence-scoped prefix (e.g. "social_pull.nudge_received:n1");
        the recipient uid is appended automatically. If omitted, the template id is used
        (only safe when the recipient + a unique data field already make it unique).
        Never raises — failures are logged and swallowed (fire-and-forget contract).
        """
        try:
            db = get_firestore()
            now = _now()
            sched = scheduled_for or now
            base = dedupe_base or template_id
            variables = variables or {}
            data = data or {}
            created: list[str] = []
            for uid in dict.fromkeys(recipient_uids):  # de-dupe recipients, keep order
                if not uid:
                    continue
                key = dedupe_key(base, uid)
                if outbox.create_if_absent(
                    db,
                    key,
                    template_id=template_id,
                    recipient_uid=uid,
                    variables=variables,
                    data=data,
                    scheduled_for=sched,
                    now=now,
                    override=override,
                ):
                    created.append(key)
            # Deliver immediately for real-time notifications that are due now.
            if deliver_now and created and sched <= now:
                for key in created:
                    self.dispatch_one(key)
            return created
        except Exception:  # noqa: BLE001 — enqueue must never break the caller.
            logger.exception("notification enqueue failed (template=%s)", template_id)
            return []

    # ---- dispatch ------------------------------------------------------------

    def dispatch_pending(self, *, limit: int | None = None) -> dict:
        """Drain due pending outbox docs. Returns a small summary for the cron caller."""
        db = get_firestore()
        now = _now()
        limit = limit or DISPATCH_BATCH_SIZE
        keys = outbox.due_pending_keys(db, now, limit)
        summary = {"claimed": 0, "sent": 0, "skipped": 0, "deferred": 0, "failed": 0}
        for key in keys:
            outcome = self.dispatch_one(key)
            if outcome in summary:
                summary[outcome] += 1
        return summary

    def dispatch_one(self, dedupe_key_: str) -> str:
        """Claim and attempt delivery of a single outbox doc. Returns the outcome label.

        Outcomes: "noop" (not claimable), "sent", "skipped", "deferred", "failed".
        Never raises.
        """
        try:
            db = get_firestore()
            now = _now()
            data = outbox.claim(db, dedupe_key_, now)
            if data is None:
                return "noop"

            template_id = data["template_id"]
            uid = data["recipient_uid"]
            type_ = _type_of(template_id)
            urgent = type_ in NOTIFICATION_URGENT_TYPES

            # Admin broadcasts carry inline copy (override) instead of a catalog template.
            override = data.get("override")
            if override:
                template = {
                    "title": override.get("title"),
                    "body": override.get("body", ""),
                    "sound": override.get("sound"),
                    "enabled": True,
                }
            else:
                template = self._load_template(db, template_id)
            if template is None or not template.get("enabled", True):
                outbox.mark_skipped(db, dedupe_key_, "template_missing_or_disabled")
                return "skipped"

            user = self._load_user(db, uid)

            # Quiet hours (non-urgent only): defer rather than drop.
            if not urgent:
                defer_to = defer_for_quiet_hours(now, user.get("timezone"))
                if defer_to is not None:
                    outbox.defer(db, dedupe_key_, defer_to)
                    return "deferred"

            # Daily caps (non-urgent only).
            if not urgent:
                day = now.date().isoformat()
                if not try_consume_quota(db, uid, type_, day):
                    outbox.mark_skipped(db, dedupe_key_, "rate_limited")
                    return "skipped"

            tokens = self._device_tokens(db, uid)
            if not tokens:
                outbox.mark_skipped(db, dedupe_key_, "no_devices")
                return "skipped"

            body = template.get("body", "").format_map(_SafeDict(data.get("variables", {})))
            result = fcm.send_to_tokens(
                tokens,
                title=template.get("title") or "Fafu",
                body=body,
                data={**data.get("data", {}), "template_id": template_id, "type": type_},
                sound=template.get("sound"),
            )

            # Prune dead tokens regardless of overall outcome.
            for bad in result.invalid_tokens:
                self._prune_token(db, uid, bad)

            if result.success_count > 0:
                outbox.mark_sent(db, dedupe_key_, now)
                return "sent"

            if result.retryable:
                attempts = data.get("attempts", 0) + 1
                if attempts >= DISPATCH_MAX_ATTEMPTS:
                    outbox.reschedule_failed(
                        db, dedupe_key_, attempts=attempts, error="max_attempts", next_attempt_at=None
                    )
                    return "failed"
                next_at = now + timedelta(seconds=_backoff_seconds(attempts))
                outbox.reschedule_failed(
                    db, dedupe_key_, attempts=attempts, error="transient", next_attempt_at=next_at
                )
                return "failed"

            # All failures were invalid tokens (now pruned) — nothing to retry.
            outbox.mark_skipped(db, dedupe_key_, "all_tokens_invalid")
            return "skipped"
        except Exception:  # noqa: BLE001 — dispatch must never break a cron tick.
            logger.exception("notification dispatch_one failed (key=%s)", dedupe_key_)
            return "failed"

    # ---- helpers -------------------------------------------------------------

    def _load_template(self, db, template_id: str) -> dict | None:
        doc = db.collection("notification_templates").document(template_id).get()
        if doc.exists:
            return doc.to_dict()
        # Fall back to the static catalog so sends work even before admin seeding ran.
        return _CATALOG_BY_ID.get(template_id)

    def _load_user(self, db, uid: str) -> dict:
        doc = db.collection("users").document(uid).get()
        return doc.to_dict() or {} if doc.exists else {}

    def _device_tokens(self, db, uid: str) -> list[str]:
        return [
            d.to_dict().get("token", d.id)
            for d in db.collection("users").document(uid).collection("devices").stream()
        ]

    def _prune_token(self, db, uid: str, token: str) -> None:
        try:
            db.collection("users").document(uid).collection("devices").document(token).delete()
        except Exception:  # noqa: BLE001
            logger.warning("failed to prune dead token for uid=%s", uid)


notifications = NotificationService()


def queue(
    background_tasks,
    *,
    template_id: str,
    recipient_uids,
    variables: dict | None = None,
    data: dict | None = None,
    dedupe_base: str | None = None,
    scheduled_for: datetime | None = None,
) -> None:
    """Fire-and-forget enqueue from a request handler.

    Schedules the outbox write (and inline delivery) on FastAPI's background task runner
    so it happens *after* the response is returned — the user is never blocked, and any
    failure is contained inside the task. Call this from route handlers.
    """
    background_tasks.add_task(
        notifications.enqueue,
        template_id=template_id,
        recipient_uids=list(recipient_uids),
        variables=variables,
        data=data,
        dedupe_base=dedupe_base,
        scheduled_for=scheduled_for,
    )
