# Events + Creators API Design

## Overview

Add creator verification, event CRUD, geo-based discovery, join/unjoin, and joinee management to the WhatsPopn backend. Simultaneously migrate all existing endpoints from Firebase RTDB to Firestore.

## Decisions

- **Database**: Full migration to Firestore (from RTDB) for native GeoPoint queries
- **Architecture**: Approach A — flat router expansion in existing `app/routers/` structure
- **Geo-filtering**: Firestore native geo-point range queries on event `location` field
- **Admin auth**: UID allowlist from `ADMIN_UIDS` env var
- **Categories**: Firestore collection (admin-managed, not hardcoded enum)
- **Event types**: `event_type` field (normal/spotlight/volunteering) with no behavioral differences yet
- **Emoji pins**: Category default emoji + optional `custom_emoji` override per event

## Firestore Collections

### `users/{uid}`

| Field | Type | Notes |
|-------|------|-------|
| phone | string | |
| display_name | string | |
| username | string | |
| photo_url | string | optional |
| area | map: {geopoint, radius_km} | GeoPoint + radius |
| is_creator | bool | default false |
| onboarding_complete | bool | |
| created_at | timestamp | |

### `usernames/{username}`

Single-field document: `{uid: string}`. Used for uniqueness check.

### `creator_applications/{uid}`

| Field | Type | Notes |
|-------|------|-------|
| purpose | string | |
| social_links | array[string] | |
| phone | string | |
| relevant_links | array[string] | |
| status | string | pending / approved / rejected |
| submitted_at | timestamp | |
| reviewed_at | timestamp | optional |

### `categories/{auto_id}`

| Field | Type | Notes |
|-------|------|-------|
| name | string | e.g. "music", "food", "art" |
| emoji | string | e.g. "🎵", "🍜", "🎨" |
| sort_order | int | display ordering |

### `events/{auto_id}`

| Field | Type | Notes |
|-------|------|-------|
| creator_uid | string | |
| title | string | |
| description | string | optional |
| category_id | string | references categories collection |
| event_type | string | normal / spotlight / volunteering |
| custom_emoji | string | optional, overrides category emoji |
| location | GeoPoint | Firestore native GeoPoint |
| location_name | string | human-readable address |
| date_time | timestamp | event start time |
| capacity | int | optional, null = unlimited |
| joinee_count | int | denormalized counter |
| registration_open | bool | default true |
| cancelled | bool | default false |
| cancel_reason | string | optional |
| created_at | timestamp | |
| updated_at | timestamp | |

### `events/{event_id}/joinees/{uid}`

| Field | Type | Notes |
|-------|------|-------|
| joined_at | timestamp | |

## API Endpoints

### Auth (migrated to Firestore)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | /auth/session | None (validates id_token in body) | Verify Firebase token, create/return user |

### Users (migrated to Firestore)

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | /users/username/check?username=x | None | Check username availability |
| PUT | /users/profile | Bearer | Set display_name, username, area |
| POST | /users/profile/photo | Bearer | Get upload path, set photo_url |

### Creators

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | /creators/apply | Bearer | Submit creator verification form |
| GET | /creators/application | Bearer | Check own application status |

### Admin

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | /admin/creators/{uid}/approve | Bearer + admin | Approve creator application |
| POST | /admin/creators/{uid}/reject | Bearer + admin | Reject creator application |
| POST | /admin/creators/{uid}/revoke | Bearer + admin | Revoke creator status |
| POST | /admin/categories | Bearer + admin | Create a category |
| PUT | /admin/categories/{id} | Bearer + admin | Update a category |

### Categories

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | /categories | None | List all categories |

### Events

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | /events | Bearer + creator | Create event |
| GET | /events | Bearer | List events (geo-filter, category, type) |
| GET | /events/{id} | Bearer | Event detail |
| PUT | /events/{id} | Bearer + owner | Edit event |
| POST | /events/{id}/cancel | Bearer + owner | Cancel event with reason |
| POST | /events/{id}/join | Bearer | Join event |
| DELETE | /events/{id}/join | Bearer | Unjoin event with reason |
| GET | /events/{id}/joinees | Bearer + owner | List joinees |

## Business Rules

### Creator Verification
- Any authenticated user can submit once (resubmit allowed after rejection or revocation)
- Admin approves/rejects via admin endpoint
- Approval sets `is_creator=true` on user doc
- Revocation sets `is_creator=false`; existing live events remain unaffected

### Event Visibility
- Events are visible (returned by list/detail) only when: `date_time + 10 minutes > now` AND `cancelled=false`
- Past events are simply excluded from query results (auto-archived)

### Join Rules
- Users can join until `date_time + 10 minutes`
- If capacity is set: reject join when `joinee_count >= capacity`
- If `registration_open=false`: reject join
- Unjoin: user provides a reason from predefined list; `joinee_count` decremented; spot reopens

### Geo-Query (Event Discovery)
- Client sends lat/lng/radius_km (from user's area setting)
- Backend uses Firestore geo-point range query to find events within radius
- Additional filters: category_id, event_type

### Admin Authorization
- `ADMIN_UIDS` env var contains comma-separated UIDs
- Admin dependency checks `current_user["uid"] in admin_uids`

## File Structure (new/modified)

```
backend/app/
├── config.py              # add ADMIN_UIDS
├── dependencies.py        # add get_admin_user, get_creator_user
├── firebase.py            # replace RTDB init with Firestore client
├── schemas.py             # add creator, event, category schemas
├── main.py                # register new routers
└── routers/
    ├── auth.py            # rewrite for Firestore
    ├── users.py           # rewrite for Firestore
    ├── creators.py        # new
    ├── events.py          # new
    ├── categories.py      # new (GET only)
    └── admin.py           # new (creator approval + category mgmt)
```

## Migration Notes

- Replace `firebase_admin.db` (RTDB) with `google.cloud.firestore` client
- The Firestore client is initialized in `firebase.py` and accessed via a dependency or module-level client
- `usernames` collection replaces the RTDB `usernames/{username}` node pattern
- Area stored as `{geopoint: GeoPoint, radius_km: float}` map on user doc

## Dependencies to Add

- `google-cloud-firestore` (Firestore Python SDK)
- Remove reliance on `firebase_admin.db` module (RTDB)
