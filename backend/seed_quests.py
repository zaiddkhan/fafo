"""Seed a starter set of Fafo Side Quests into Firestore.

Idempotent: each quest uses a deterministic document id (its slug), so running
this multiple times updates the same docs rather than creating duplicates.

Usage (from backend/ with the venv active):
    python seed_quests.py
"""

from datetime import datetime, timezone

from app.firebase import init_firebase, get_firestore

# difficulty: easy = under 30 mins, medium = a few hours, hard = full day / group effort.
# city = None means citywide (shown to everyone). area = None means not geo-targeted.
QUESTS = [
    # --- Easy (under 30 mins) ---
    {
        "slug": "first-sip-mystery-order",
        "title": "Order something you can't pronounce",
        "description": "Walk into the nearest café and order a drink you've never tried. No Googling it first.",
        "difficulty": "easy",
    },
    {
        "slug": "say-hi-to-a-stranger",
        "title": "Make one stranger smile",
        "description": "Pay a genuine compliment to someone you don't know. A barista, a shopkeeper, anyone.",
        "difficulty": "easy",
    },
    {
        "slug": "oldest-thing-on-your-street",
        "title": "Find the oldest building on your street",
        "description": "Take a 10-minute walk and spot the oldest building near you. Snap a photo for yourself.",
        "difficulty": "easy",
    },
    # --- Medium (a few hours) ---
    {
        "slug": "rooftop-sunset",
        "title": "Catch a rooftop sunset",
        "description": "Find a rooftop café or terrace and watch the sun go down. Phone in your pocket for the last 10 minutes.",
        "difficulty": "medium",
    },
    {
        "slug": "solo-movie-date",
        "title": "Take yourself on a solo movie date",
        "description": "Book one ticket, buy the popcorn, and enjoy a film entirely on your own terms.",
        "difficulty": "medium",
    },
    {
        "slug": "wander-a-new-neighbourhood",
        "title": "Get lost in a new neighbourhood",
        "description": "Pick an area of your city you've never walked and explore it on foot for an afternoon.",
        "difficulty": "medium",
    },
    # --- Hard (full day or group effort) ---
    {
        "slug": "day-trip-nearest-escape",
        "title": "Day trip to the nearest escape",
        "description": "Round up a friend or two and head to the closest hill, lake, or beach for the day.",
        "difficulty": "hard",
    },
    {
        "slug": "reunion-potluck",
        "title": "Host a tiny reunion",
        "description": "Throw a potluck with three people you haven't seen in months. Everyone brings one dish.",
        "difficulty": "hard",
    },
    {
        "slug": "morning-of-giving-back",
        "title": "Give back for a morning",
        "description": "Volunteer a half-day at a local shelter, kitchen, or clean-up drive near you.",
        "difficulty": "hard",
    },
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
                "city": None,  # citywide
                "area": None,  # not geo-targeted
                "published": True,
                "created_at": created_at,
                "updated_at": now,
            }
        )
        written += 1
        print(f"  ✓ {quest['difficulty']:<6} {quest['title']}")

    print(f"\nSeeded {written} side quests into the 'quests' collection.")


if __name__ == "__main__":
    main()
