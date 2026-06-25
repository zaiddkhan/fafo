"""Seed a test creator account plus Mumbai/Bengaluru events for late June + July 2026.

Run from backend:
    source .venv/bin/activate
    python scripts/seed_test_creator_july_events.py
"""

from __future__ import annotations

import random
import sys
from datetime import datetime, time, timedelta, timezone
from pathlib import Path
from uuid import uuid5, NAMESPACE_URL

sys.path.append(str(Path(__file__).resolve().parents[1]))

from firebase_admin import auth
from google.cloud.firestore import GeoPoint

from app.firebase import init_firebase, get_firestore
from app.geo import encode_geohash

CREATOR_UID = "test_creator_july_events"
CREATOR_PHONE = "+15555550123"
CREATOR_NAME = "Whatspoppn Test Creator"
CREATOR_USERNAME = "testcreatorjuly"

IST = timezone(timedelta(hours=5, minutes=30))
UTC = timezone.utc

CATEGORIES = [
    "live-music",
    "nightlife",
    "food-drink",
    "comedy",
    "outdoor",
    "ai-tech",
    "wellness",
    "art-culture",
]

CITY_CONFIG = {
    "Mumbai": {
        "count": 30,
        "center": (19.0760, 72.8777),
        "venues": [
            ("Bandra Social", 19.0607, 72.8362, "Bandra West"),
            ("AntiSocial Lower Parel", 18.9934, 72.8258, "Lower Parel"),
            ("Prithvi Courtyard", 19.1060, 72.8258, "Juhu"),
            ("Versova Beach Steps", 19.1351, 72.8146, "Versova"),
            ("Kala Ghoda Cafe Lane", 18.9285, 72.8328, "Fort"),
            ("Carter Road Amphitheatre", 19.0700, 72.8220, "Bandra"),
            ("Powai Lake Promenade", 19.1197, 72.9052, "Powai"),
            ("Jio World Drive", 19.0544, 72.8507, "BKC"),
        ],
    },
    "Bengaluru": {
        "count": 40,
        "center": (12.9716, 77.5946),
        "venues": [
            ("Indiranagar Social", 12.9784, 77.6408, "Indiranagar"),
            ("Church Street Social", 12.9756, 77.6011, "Church Street"),
            ("Koramangala Forum Courtyard", 12.9346, 77.6113, "Koramangala"),
            ("Cubbon Park Bandstand", 12.9763, 77.5929, "Cubbon Park"),
            ("Lalbagh Glass House", 12.9507, 77.5848, "Lalbagh"),
            ("JP Nagar Culture Yard", 12.9063, 77.5857, "JP Nagar"),
            ("Whitefield Art Street", 12.9698, 77.7500, "Whitefield"),
            ("MG Road Rooftop", 12.9758, 77.6068, "MG Road"),
        ],
    },
}

TITLE_PARTS = [
    ("Sunset Jam", "live-music", "Acoustic sets, casual singalongs, and a relaxed crowd."),
    ("Coffee Crawl", "food-drink", "Try tiny menus, meet new people, and vote for the best bite."),
    ("Creator Mixer", "art-culture", "A low-pressure meetup for makers, photographers, and storytellers."),
    ("Open Mic Night", "comedy", "Short comedy spots and chaotic audience prompts."),
    ("Rooftop Social", "nightlife", "Music, mocktails, and easy icebreakers after work."),
    ("Morning Walk Club", "outdoor", "A friendly walk with optional breakfast after."),
    ("AI Builders Hang", "ai-tech", "Demos, ideas, and founder-style conversations."),
    ("Stretch & Chai", "wellness", "Gentle movement followed by chai and conversation."),
    ("Photo Walk", "art-culture", "Explore corners of the city with a camera or phone."),
    ("Board Game Bash", "nightlife", "Beginner-friendly games and quick team rotations."),
]

LOCAL_TIMES = [
    time(8, 0), time(10, 30), time(16, 0), time(18, 30), time(19, 30), time(20, 30)
]

START_DATE = datetime(2026, 6, 26).date()
END_DATE = datetime(2026, 7, 31).date()
ALL_DAYS = [START_DATE + timedelta(days=i) for i in range((END_DATE - START_DATE).days + 1)]


def ensure_auth_user() -> None:
    try:
        auth.get_user(CREATOR_UID)
        print(f"Auth user exists: {CREATOR_UID}")
        return
    except auth.UserNotFoundError:
        pass

    try:
        auth.create_user(
            uid=CREATOR_UID,
            phone_number=CREATOR_PHONE,
            display_name=CREATOR_NAME,
        )
        print(f"Created Firebase Auth user: {CREATOR_UID} / {CREATOR_PHONE}")
    except Exception as exc:
        # If the phone already exists under another uid, keep going with Firestore seeding.
        print(f"Could not create Auth user ({exc}); continuing with Firestore seed.")


def ensure_creator_doc(db) -> None:
    now = datetime.now(UTC)
    db.collection("users").document(CREATOR_UID).set(
        {
            "phone": CREATOR_PHONE,
            "display_name": CREATOR_NAME,
            "display_name_lower": CREATOR_NAME.lower(),
            "username": CREATOR_USERNAME,
            "photo_url": "",
            "area": {"label": "Mumbai, India", "lat": 19.0760, "lng": 72.8777, "radius_km": 15},
            "is_creator": True,
            "onboarding_complete": True,
            "first_launch_tooltip_complete": True,
            "created_at": now,
            "updated_at": now,
        },
        merge=True,
    )
    print(f"Upserted creator Firestore user: {CREATOR_UID}")


def event_doc_id(city: str, index: int) -> str:
    slug = city.lower().replace(" ", "-")
    return f"seed-{slug}-july-2026-{index:02d}"


def build_events_for_city(city: str, count: int) -> list[dict]:
    rng = random.Random(f"{city}-july-2026")
    chosen_days = [ALL_DAYS[round(i * (len(ALL_DAYS) - 1) / max(count - 1, 1))] for i in range(count)]
    events = []
    venues = CITY_CONFIG[city]["venues"]

    for i in range(count):
        day = chosen_days[i]
        local_time = LOCAL_TIMES[(i + (0 if city == "Mumbai" else 2)) % len(LOCAL_TIMES)]
        dt_local = datetime.combine(day, local_time, tzinfo=IST)
        dt_utc = dt_local.astimezone(UTC)

        title_base, category_id, description = TITLE_PARTS[(i + (1 if city == "Bengaluru" else 0)) % len(TITLE_PARTS)]
        venue_name, lat, lng, area = venues[i % len(venues)]
        lat += rng.uniform(-0.006, 0.006)
        lng += rng.uniform(-0.006, 0.006)
        title = f"{title_base} — {area}"

        events.append(
            {
                "title": title,
                "description": description,
                "category_id": category_id,
                "event_type": "normal",
                "custom_emoji": None,
                "location": GeoPoint(lat, lng),
                "location_name": venue_name,
                "address": f"{area}, {city}",
                "location_details": "Look for the Whatspoppn table near the entrance.",
                "geohash": encode_geohash(lat, lng),
                "date_time": dt_utc,
                "capacity": [20, 25, 30, 40, 50][i % 5],
                "joinee_count": 0,
                "registration_open": True,
                "cancelled": False,
                "cancel_reason": None,
                "banner_url": f"https://picsum.photos/seed/{uuid5(NAMESPACE_URL, city + str(i))}/900/600",
                "organizer_name": CREATOR_NAME,
                "organizer_contact": CREATOR_PHONE,
                "organizer_instagram": "@whatspoppn_test",
                "creator_uid": CREATOR_UID,
                "seeded": True,
                "seed_batch": "late-june-july-2026-mumbai-bengaluru",
                "created_at": datetime.now(UTC),
                "updated_at": datetime.now(UTC),
            }
        )
    return events


def seed_events(db) -> None:
    created = 0
    overwritten = 0
    for city, cfg in CITY_CONFIG.items():
        events = build_events_for_city(city, cfg["count"])
        for i, data in enumerate(events, start=1):
            doc_id = event_doc_id(city, i)
            ref = db.collection("events").document(doc_id)
            if ref.get().exists:
                overwritten += 1
            else:
                created += 1
            ref.set(data)
    print(f"Seeded events: {created} created, {overwritten} overwritten")


def main() -> None:
    init_firebase()
    db = get_firestore()
    ensure_auth_user()
    ensure_creator_doc(db)
    seed_events(db)
    print("Done.")
    print(f"Creator uid: {CREATOR_UID}")
    print(f"Dummy phone: {CREATOR_PHONE}")
    print("Events: 30 Mumbai, 40 Bengaluru, spread from 2026-06-26 through 2026-07-31")


if __name__ == "__main__":
    main()
