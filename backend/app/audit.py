"""Admin audit logging.

Every state-changing admin action that requires accountability is recorded in the
`admin_audit_log` collection with the acting admin, the action, the target, and a
mandatory reason (where the action demands one).
"""

from datetime import datetime, timezone
from uuid import uuid4


def record_admin_action(
    db,
    admin_uid: str,
    action: str,
    *,
    target_type: str | None = None,
    target_id: str | None = None,
    reason: str | None = None,
    metadata: dict | None = None,
) -> None:
    db.collection("admin_audit_log").document(str(uuid4())).set(
        {
            "admin_uid": admin_uid,
            "action": action,
            "target_type": target_type,
            "target_id": target_id,
            "reason": reason,
            "metadata": metadata or {},
            "created_at": datetime.now(timezone.utc),
        }
    )
