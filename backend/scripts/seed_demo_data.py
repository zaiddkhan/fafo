from __future__ import annotations

from datetime import datetime, timedelta, timezone
from random import Random
from pathlib import Path
from uuid import UUID, uuid5
import sys

sys.path.append(str(Path(__file__).resolve().parents[1]))

from google.cloud.firestore import GeoPoint

from app.firebase import init_firebase, get_firestore
from app.geo import encode_geohash

DEMO_NAMESPACE = UUID("2f7c8ec6-d0a7-4fd7-b6f3-ef8580f0a7a4")

CATEGORIES = [
    ("live-music", "Live Music", "🎸"),
    ("nightlife", "Nightlife", "🪩"),
    ("food-drink", "Food & Drink", "🍜"),
    ("comedy", "Comedy", "🎤"),
    ("outdoor", "Outdoor", "🌿"),
    ("ai-tech", "AI & Tech", "🤖"),
    ("wellness", "Wellness", "🧘"),
    ("art-culture", "Art & Culture", "🎨"),
]

MUMBAI_AREAS = [
    ("Bandra West", 19.0596, 72.8295),
    ("Andheri West", 19.1363, 72.8277),
    ("Juhu", 19.1075, 72.8263),
    ("Lower Parel", 18.9936, 72.8258),
    ("Powai", 19.1176, 72.9060),
    ("Colaba", 18.9067, 72.8147),
    ("Worli", 19.0176, 72.8176),
    ("Versova", 19.1312, 72.8147),
]

BANGALORE_AREAS = [
    ("Koramangala", 12.9352, 77.6245),
    ("Indiranagar", 12.9784, 77.6408),
    ("Church Street", 12.9752, 77.6046),
    ("HSR Layout", 12.9116, 77.6474),
    ("Whitefield", 12.9698, 77.7500),
    ("JP Nagar", 12.9063, 77.5857),
    ("MG Road", 12.9757, 77.6055),
    ("Jayanagar", 12.9250, 77.5938),
]

EVENT_TEMPLATES = [
    ("live-music", "Indie Night at {area}", "An intimate live set with local artists and a crowd that actually listens.", "normal"),
    ("nightlife", "After Hours Social: {area}", "Late-night music, dancing, and curated tables for meeting new people.", "spotlight"),
    ("food-drink", "Street Food Crawl in {area}", "Hop between hidden food spots with a small group of hungry explorers.", "normal"),
    ("comedy", "Open Mic Laughs: {area}", "Stand-up comics testing sharp new material in a cozy room.", "normal"),
    ("outdoor", "Sunset Walk Club: {area}", "A relaxed city walk for people who want fresh air and good conversation.", "normal"),
    ("ai-tech", "Builders Meetup: {area}", "Demo your side project, meet founders, and swap practical AI workflows.", "spotlight"),
    ("wellness", "Morning Yoga Circle: {area}", "Breathwork, mobility, and a calm start with a beginner-friendly group.", "normal"),
    ("art-culture", "Gallery Hop: {area}", "Explore pop-ups, small galleries, and creative spaces with a guided group.", "normal"),
    ("volunteering", "Community Cleanup: {area}", "Help clean a local public space and meet people who care about the city.", "volunteering"),
]

BANNERS = [
    "https://images.unsplash.com/photo-1492684223066-81342ee5ff30?w=1200",
    "https://images.unsplash.com/photo-1511795409834-ef04bbd61622?w=1200",
    "https://images.unsplash.com/photo-1555939594-58d7cb561ad1?w=1200",
    "https://images.unsplash.com/photo-1527224857830-43a7acc85260?w=1200",
    "https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?w=1200",
    "https://images.unsplash.com/photo-1519389950473-47ba0277781c?w=1200",
    "https://images.unsplash.com/photo-1506126613408-eca07ce68773?w=1200",
    "https://images.unsplash.com/photo-1545987796-200677ee1011?w=1200",
]


def _jitter(rng: Random, value: float, amount: float = 0.018) -> float:
    return value + rng.uniform(-amount, amount)


def _event_docs(city: str, areas: list[tuple[str, float, float]], creator_uid: str, start_index: int):
    rng = Random(42 + start_index)
    now = datetime.now(timezone.utc)
    docs = []
    idx = start_index
    for area, lat, lng in areas:
        for offset, template in enumerate(EVENT_TEMPLATES):
            category_id, title_template, description, event_type = template
            event_lat = _jitter(rng, lat)
            event_lng = _jitter(rng, lng)
            event_time = now + timedelta(days=(idx % 14), hours=3 + (idx % 8), minutes=(idx * 7) % 55)
            capacity = [20, 30, 40, 60, None][idx % 5]
            docs.append(
                {
                    "id": str(uuid5(DEMO_NAMESPACE, f"{city.lower()}-{idx:03d}")),
                    "data": {
                        "creator_uid": creator_uid,
                        "title": title_template.format(area=area),
                        "description": description,
                        "category_id": category_id if category_id != "volunteering" else "outdoor",
                        "event_type": event_type,
                        "custom_emoji": None,
                        "location": GeoPoint(event_lat, event_lng),
                        "location_name": f"{area}, {city}",
                        "geohash": encode_geohash(event_lat, event_lng),
                        "date_time": event_time,
                        "capacity": capacity,
                        "joinee_count": rng.randint(3, 48),
                        "registration_open": True,
                        "cancelled": False,
                        "cancel_reason": None,
                        "banner_url": BANNERS[idx % len(BANNERS)],
                        "organizer_name": "WhatsPopn Demo Creator",
                        "organizer_contact": "hello@whatspopn.local",
                        "organizer_instagram": "whatspopn",
                        "created_at": now,
                        "updated_at": now,
                    },
                }
            )
            idx += 1
    return docs


def main() -> None:
    init_firebase()
    db = get_firestore()

    users = list(db.collection("users").limit(1).stream())
    if not users:
        raise SystemExit("No users found. Sign in once before seeding demo data.")

    creator_uid = users[0].id
    db.collection("users").document(creator_uid).set(
        {"is_creator": True, "onboarding_complete": True}, merge=True
    )
    print(f"Made creator: {creator_uid}")

    batch = db.batch()
    for sort_order, (category_id, name, emoji) in enumerate(CATEGORIES):
        batch.set(
            db.collection("categories").document(category_id),
            {"name": name, "emoji": emoji, "sort_order": sort_order},
            merge=True,
        )
    batch.commit()
    print(f"Upserted {len(CATEGORIES)} categories")

    # Remove old demo/numeric event documents from earlier seed versions so
    # the database only exposes UUID event IDs.
    old_event_ids = []
    for doc in db.collection("events").stream():
        try:
            UUID(doc.id)
        except ValueError:
            old_event_ids.append(doc.id)

    for chunk_start in range(0, len(old_event_ids), 400):
        batch = db.batch()
        for event_id in old_event_ids[chunk_start : chunk_start + 400]:
            batch.delete(db.collection("events").document(event_id))
        batch.commit()
    if old_event_ids:
        print(f"Deleted {len(old_event_ids)} non-UUID events")

    all_events = _event_docs("Mumbai", MUMBAI_AREAS, creator_uid, 0) + _event_docs(
        "Bangalore", BANGALORE_AREAS, creator_uid, 100
    )

    # Firestore batches are capped at 500 writes; keep chunks small anyway.
    for chunk_start in range(0, len(all_events), 400):
        batch = db.batch()
        for event in all_events[chunk_start : chunk_start + 400]:
            batch.set(db.collection("events").document(event["id"]), event["data"])
        batch.commit()

    print(f"Seeded {len(all_events)} events across Mumbai and Bangalore")


if __name__ == "__main__":
    main()
