"""Seed a starter set of Fafo Side Quests into Firestore.

Idempotent: each quest uses a deterministic document id (its slug), so running
this multiple times updates the same docs rather than creating duplicates.

Usage (from backend/ with the venv active):
    python seed_quests.py
"""

from datetime import datetime, timezone

from app.firebase import init_firebase, get_firestore

# V3 brief (SB-125): six admin-curated 15-minute quests, grouped by difficulty.
# Each prompt is written as an invite, because sharing a quest sends it as a
# nudge (title -> nudge title, description -> nudge description).
# `order` sets the position within a difficulty group.
QUESTS = [
    {
        "slug": "walk-one-block",
        "title": "Walk one block",
        "description": "Meet outside and walk one block with me?",
        "difficulty": "easy",
        "order": 1,
    },
    {
        "slug": "snack-run",
        "title": "Snack run",
        "description": "Pick a snack spot and meet me there?",
        "difficulty": "easy",
        "order": 2,
    },
    {
        "slug": "photo-hunt",
        "title": "Photo hunt",
        "description": "Find the weirdest thing nearby and take a photo together?",
        "difficulty": "medium",
        "order": 1,
    },
    {
        "slug": "take-a-new-route",
        "title": "Take a new route",
        "description": "Meet me and take a route neither of us usually walks?",
        "difficulty": "medium",
        "order": 2,
    },
    {
        "slug": "phone-free-lap",
        "title": "Phone-free lap",
        "description": "Leave our phones away and take a 15-minute lap?",
        "difficulty": "hard",
        "order": 1,
    },
    {
        "slug": "tiny-performance",
        "title": "Tiny performance",
        "description": "Meet me outside and perform a 30-second made-up song?",
        "difficulty": "hard",
        "order": 2,
    },
]

# Pre-V3 quests. Retired (published=False), not deleted, so they can come back.
RETIRED_SLUGS = [
    "first-sip-mystery-order",
    "say-hi-to-a-stranger",
    "oldest-thing-on-your-street",
    "rooftop-sunset",
    "solo-movie-date",
    "wander-a-new-neighbourhood",
    "day-trip-nearest-escape",
    "reunion-potluck",
    "morning-of-giving-back",
]


def main():
    init_firebase()
    db = get_firestore()
    now = datetime.now(timezone.utc)

    written = 0
    for quest in QUESTS:
        ref = db.collection("quests").document(quest["slug"])
        existing = ref.get()
        created_at = existing.to_dict().get("created_at", now) if existing.exists else now
        ref.set(
            {
                "title": quest["title"],
                "description": quest["description"],
                "difficulty": quest["difficulty"],
                "order": quest["order"],
                "city": None,  # citywide
                "area": None,  # not geo-targeted
                "published": True,
                "created_at": created_at,
                "updated_at": now,
            }
        )
        written += 1
        print(f"  ✓ {quest['difficulty']:<6} {quest['title']}")

    for slug in RETIRED_SLUGS:
        ref = db.collection("quests").document(slug)
        if ref.get().exists:
            ref.update({"published": False, "updated_at": now})
            print(f"  - retired {slug}")

    print(f"\nSeeded {written} side quests into the 'quests' collection.")


if __name__ == "__main__":
    main()
