"""Seed a few real, published City Reads blogs for one or more cities.

Run from the backend dir:  PYTHONPATH=. .venv/bin/python scripts/seed_blogs.py
Idempotent: skips creating a blog whose title already exists for the city.
"""

from datetime import datetime, timezone
from uuid import uuid4

from app.firebase import init_firebase, get_firestore


# City display name -> a short, on-brand local flavour line used in bodies.
CITIES = {
    "Bengaluru": "filter coffee, craft beer, and live music",
    "Bangalore": "filter coffee, craft beer, and live music",
    "Mumbai": "sea breeze, street food, and late-night trains",
}


def _city_key(city: str) -> str:
    return city.strip().lower()


def _blogs_for(city: str, flavour: str) -> list[dict]:
    return [
        {
            "title": "What to do this weekend",
            "subtitle": "Music, food walks, and low-effort hangs around the city.",
            "read_time": "3 min read",
            "image_url": "https://picsum.photos/seed/fafo-weekend/1200/800",
            "body": f"""# What to do this weekend

{city} weekends move fast — here's a low-effort plan you can actually pull off.

## Friday night: ease in
- **Live music** and an early bite. Most sets start late, so eat first.
- Prefer quiet? A rooftop with a view beats a packed club.

## Saturday: eat your way through
1. **Morning** — {flavour.split(',')[0]} and a proper breakfast.
2. **Afternoon** — a food walk. Go hungry.
3. **Evening** — drinks with a small crew, then a walk.

## Sunday: reset
- A slow morning outdoors, then a bookshop.
- Cap it with a group hang — invite 3–4 people, keep it simple.

> Tip: the best plans are small groups + public spots + shared interests.

Find people doing these on **FAFO** and just show up.
""",
        },
        {
            "title": "How to pick your first FaFo hang",
            "subtitle": "Start with small groups, public venues, and shared interests.",
            "read_time": "2 min read",
            "image_url": "https://picsum.photos/seed/fafo-firsthang/1200/800",
            "body": f"""# How to pick your first FaFo hang

New to {city}? Your first hang sets the tone. Make it easy on yourself.

## Three simple rules
1. **Small groups first.** 4–8 people is the sweet spot.
2. **Public venues.** A café, a park, a gig — easy to join, easy to leave.
3. **Shared interest.** Pick something you'd do anyway.

## What to skip at first
- Late-night, high-commitment events where you know no one.
- Anything that needs a lot of prep or money on day one.

## After the hang
Nudge one person you clicked with. That's how a one-off becomes a regular crew.

You'll **find out** it's easier than it looks. That's the whole point.
""",
        },
        {
            "title": f"A local's guide to {city}",
            "subtitle": f"The {flavour} — and where to actually meet people.",
            "read_time": "4 min read",
            "image_url": "https://picsum.photos/seed/fafo-guide/1200/800",
            "body": f"""# A local's guide to {city}

Skip the tourist list. Here's how locals actually spend their time — {flavour}.

## Mornings
- Start slow. Good coffee, a walk, no rush.
- Weekend markets are the easiest place to bump into people.

## Afternoons
- Museums and galleries when it's hot or wet.
- Parks and open spaces when it's not.

## Nights
- Live music, comedy, and small venues over big clubs.
- The move is a small group and a plan you can bail on.

Open **FAFO**, find something happening near you tonight, and go.
""",
        },
    ]


def main() -> None:
    init_firebase()
    db = get_firestore()
    col = db.collection("blogs")
    now = datetime.now(timezone.utc)
    total = 0

    for city, flavour in CITIES.items():
        city_key = _city_key(city)
        existing = {
            (doc.to_dict() or {}).get("title")
            for doc in col.where("city_key", "==", city_key).stream()
        }
        for i, blog in enumerate(_blogs_for(city, flavour)):
            if blog["title"] in existing:
                print(f"skip (exists): [{city}] {blog['title']}")
                continue
            blog_id = str(uuid4())
            created_at = now.replace(microsecond=i)
            col.document(blog_id).set(
                {
                    "city": city,
                    "city_key": city_key,
                    "title": blog["title"],
                    "subtitle": blog["subtitle"],
                    "body": blog["body"],
                    "image_url": blog["image_url"],
                    "read_time": blog["read_time"],
                    "published": True,
                    "created_at": created_at,
                    "updated_at": created_at,
                }
            )
            total += 1
            print(f"created: [{city}] {blog['title']}  id={blog_id}")

    print(f"\nDone. Created {total} blog(s).")


if __name__ == "__main__":
    main()
