"""Deterministic dedupe keys — the backbone of idempotency.

The outbox doc id IS the dedupe key, written create-if-absent, so the same logical
action can only ever produce one notification per recipient. A key is scoped to:
trigger (template id) + entity + recipient + occurrence.

Keys must be valid Firestore document ids: no "/", non-empty, < 1500 bytes. We use
":" separators (allowed) and assume entity/uid ids are already validated elsewhere.
"""


def _clean(part: str) -> str:
    # Firestore forbids "/" in document ids; collapse any stray ones defensively.
    return str(part).replace("/", "_")


def dedupe_key(template_id: str, *parts: str) -> str:
    """Build a dedupe key from a template id and identifying parts.

    Example: dedupe_key("social_pull.nudge_received", nudge_id, uid)
             -> "social_pull.nudge_received:abc:uid123"
    """
    segments = [template_id, *[_clean(p) for p in parts if p is not None]]
    return ":".join(segments)
