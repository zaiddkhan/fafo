"""Push notification infrastructure.

Durable outbox + dispatcher. Triggers call `notifications.queue(...)` (fire-and-forget)
or `notifications.enqueue(...)`; the dispatcher drains the outbox to FCM. A single action
fires exactly one notification (idempotent via deterministic outbox doc ids).

Public surface:
    from app.notifications import notifications, queue
    from app.notifications import triggers
"""

from app.notifications.service import NotificationService, notifications, queue

__all__ = ["NotificationService", "notifications", "queue"]
