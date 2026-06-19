"""Send a one-off nudge-reminder notification to a single user, by username.

Looks the user up, reports their registered devices, then enqueues the
`time_pressure.nudge_reminder` template. That type is "urgent", so it bypasses
quiet hours / daily caps and dispatches inline immediately (no cron needed).

Run from the backend dir so the relative service-account path resolves:
    .venv/bin/python scripts/send_test_nudge.py [username] [minutes]
"""

import sys
import time

# Allow running as `python scripts/send_test_nudge.py` from the backend root.
sys.path.insert(0, ".")

from app.firebase import init_firebase, get_firestore  # noqa: E402
from app.notifications.service import notifications  # noqa: E402

DEFAULT_USERNAME = "zaiddkhhan"
TEMPLATE_ID = "time_pressure.nudge_reminder"


def resolve_uid(db, username: str) -> str | None:
    # Primary path: the `usernames` index (doc id = lowercased username).
    doc = db.collection("usernames").document(username.lower()).get()
    if doc.exists:
        return (doc.to_dict() or {}).get("uid")
    # Fallback: scan users by the `username` field.
    matches = list(db.collection("users").where("username", "==", username).limit(1).stream())
    return matches[0].id if matches else None


def main() -> int:
    username = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_USERNAME
    minutes = sys.argv[2] if len(sys.argv) > 2 else "15"

    init_firebase()
    db = get_firestore()

    uid = resolve_uid(db, username)
    if not uid:
        print(f"❌ No user found for username '{username}'.")
        return 1
    print(f"✓ Resolved '{username}' → uid={uid}")

    devices = list(db.collection("users").document(uid).collection("devices").stream())
    print(f"  Registered devices: {len(devices)}")
    for d in devices:
        data = d.to_dict() or {}
        print(f"    - {data.get('platform', '?')}  …{d.id[-12:]}")
    if not devices:
        print("  ⚠ No devices registered — the push can't be delivered, but an")
        print("    in-app inbox entry will still be written.")

    keys = notifications.enqueue(
        template_id=TEMPLATE_ID,
        recipient_uids=[uid],
        variables={"minutes": minutes},
        data={"source": "manual_test"},
        # Unique per run so re-running actually re-sends (dedupe won't swallow it).
        dedupe_base=f"manual_test.nudge_reminder:{int(time.time())}",
    )
    if keys:
        print(f"✓ Enqueued + dispatched inline. Outbox keys: {keys}")
        print(f'  Body sent: "You have {minutes} minutes to decide."')
    else:
        print("⚠ Nothing enqueued (already deduped, or enqueue swallowed an error).")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
