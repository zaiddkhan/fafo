"""Archive event data for the V3 build (brief 1.4): copy, never delete.

Copies `events` (with each event's subcollections, e.g. joinees), `blogs` and
`categories` into `archived_events`, `archived_blogs` and `archived_categories`,
stamping each copy with `archived_at`. The originals are left untouched, so
events can come back by flipping EVENTS_ENABLED; clients already can't read
them (firestore.rules) and the endpoints are unmounted.

Dry run by default. Run from backend/:
    source .venv/bin/activate
    python scripts/archive_events.py           # counts only
    python scripts/archive_events.py --apply   # writes the copies

Idempotent: re-running overwrites the copies with the current originals.
"""

from __future__ import annotations

import argparse
import sys
from datetime import datetime, timezone
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parents[1]))

from app.firebase import get_firestore, init_firebase

COLLECTIONS = ["events", "blogs", "categories"]
BATCH_LIMIT = 400  # Firestore caps a batch at 500 writes.


class _Writer:
    """Batches writes, or just counts them on a dry run."""

    def __init__(self, db, apply: bool):
        self.db = db
        self.apply = apply
        self.batch = db.batch() if apply else None
        self.pending = 0
        self.total = 0

    def set(self, ref, data: dict) -> None:
        self.total += 1
        if not self.apply:
            return
        self.batch.set(ref, data)
        self.pending += 1
        if self.pending >= BATCH_LIMIT:
            self.flush()

    def flush(self) -> None:
        if self.apply and self.pending:
            self.batch.commit()
            self.batch = self.db.batch()
            self.pending = 0


def _copy_doc(writer: _Writer, src_ref, dst_ref, stamp: datetime) -> None:
    snap = src_ref.get()
    if not snap.exists:
        return
    writer.set(dst_ref, {**(snap.to_dict() or {}), "archived_at": stamp})
    for sub in src_ref.collections():
        for child in sub.stream():
            _copy_doc(writer, child.reference, dst_ref.collection(sub.id).document(child.id), stamp)


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--apply", action="store_true", help="write the archive copies (default: dry run)")
    args = parser.parse_args()

    init_firebase()
    db = get_firestore()
    stamp = datetime.now(timezone.utc)

    for name in COLLECTIONS:
        writer = _Writer(db, args.apply)
        docs = 0
        for doc in db.collection(name).stream():
            docs += 1
            _copy_doc(writer, doc.reference, db.collection(f"archived_{name}").document(doc.id), stamp)
        writer.flush()
        verb = "Archived" if args.apply else "Would archive"
        print(f"{verb} {docs} {name} ({writer.total} documents incl. subcollections) -> archived_{name}")

    if not args.apply:
        print("\nDry run. Re-run with --apply to write the copies. Originals are never deleted.")


if __name__ == "__main__":
    main()
