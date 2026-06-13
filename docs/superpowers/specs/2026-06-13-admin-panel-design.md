# Admin Panel — Design Spec

**Date:** 2026-06-13
**Status:** Approved to build (user fast-tracked; spec is source-of-truth, reviewable in parallel)
**Owner:** Zaid · Client: Abhiraj

## 1. Goal

A standalone React admin panel for the WhatsPopn (Fafu) team to operate the live app:
vet creators, publish Side Quests, seed events, monitor map density, manage users,
control notification copy/triggers, and view product analytics. It **reuses the existing
FastAPI + Firestore backend**, extending it where new capabilities are required. The
Flutter app is untouched.

## 2. Architecture

### 2.1 Repo layout
```
whatspoppn/
  backend/   # FastAPI (extended)
  frontend/  # Flutter (untouched)
  admin/     # NEW — Vite + React + TypeScript SPA
```

### 2.2 Stack (Option A)
- Vite + React + TypeScript
- Tailwind CSS + shadcn/ui (owned, themeable primitives: tables, dialogs, forms)
- TanStack Query for all server state (cache / loading / refetch)
- React Router (sidebar shell, 7 module routes)
- Firebase JS SDK (email/password auth → ID token)
- PostHog (analytics, see §10)
- Brand accent `#1A87DA`

### 2.3 Auth
1. Login page → Firebase `signInWithEmailAndPassword`.
2. ID token attached as `Authorization: Bearer <token>` on every API call via a typed `apiClient`.
3. Backend `get_admin_user` already gates on `uid ∈ ADMIN_UIDS`. An admin = a Firebase user whose UID is in `ADMIN_UIDS`.
4. `<RequireAdmin>` guard calls `GET /admin/me`; non-admins see a clean "not authorized" screen.

**Setup requirement:** enable Email/Password provider in Firebase Auth; add each admin UID to `ADMIN_UIDS`. Phone-auth app users unaffected.

### 2.4 Shared backend additions
- `GET /admin/me` → `{uid, is_admin}`.
- `admin_audit_log` Firestore collection: `{admin_uid, action, target_type, target_id, reason, created_at, metadata}`. Written by every state-changing User Management action and any other action requiring a reason.
- Tighten `CORS_ORIGINS` to the deployed admin origin (currently `*`).
- Existing `/console` (email+password HMAC) left intact as fallback; SPA supersedes it.

## 3. Module — Creator Queue

Consolidated list of creator applications with status: `pending`, `approved`, `revoked`,
`reapplied`. Detail view shows full submission (purpose, social links, phone, relevant links).

- **Actions:** Approve (grants creation rights immediately — `is_creator=true`), Revoke
  (blocks future event creation; existing live/upcoming events unaffected, per PRD).
- **Reapplications:** flagged with prior history visible to reviewer.
- **No bulk actions, no auto-approval** (manual vetting preserved).

**Backend:** mostly exists (`/admin/creators/{uid}/approve|reject|revoke`). Add:
- `GET /admin/creators` — list all applications + joined user info + status, sorted (pending first).
- `GET /admin/creators/{uid}` — full detail incl. prior application history (track via `reapplied` status + a `history` array or `creator_application_events` subcollection appended on each (re)submission).
- "reapplied" state: when a previously rejected/revoked user resubmits, status becomes `reapplied` and prior record is preserved.

## 4. Module — Quest Manager

Publishing interface for Side Quests (FuFa-team only). Creation form: title, description,
difficulty tier, targeting scope (citywide or area-specific). List view of all quests.
Publish → live in Side Quests tab in real time; unpublish → removed. **No timer/reminder/
completion logic** (v1 scope). Each quest shows its **activation count** as the single KPI.

**Backend:** CRUD exists (`get_admin_user` gated). Add:
- `GET /admin/quests` — list ALL quests (incl. unpublished) for the manager (the public `GET /quests` only returns published).
- Activation count: aggregate from per-user `quest_activations`. Maintain a denormalized `activation_count` on the quest doc, incremented in `activate_quest` (atomic increment), backfilled once. Expose in admin list/detail.

## 5. Module — Event Seeding

Create events directly from the panel, marked with an internal `seeded` flag (invisible to
users). Separates organic vs team activity in internal reporting. Seeded events are
functionally identical to creator events on every user-facing surface.

**Backend:**
- Add `seeded: bool` (default `false`) to the event document. NOT included in user-facing `EventResponse` (or included only for admin endpoints).
- `POST /admin/events` — admin-gated event creation reusing `EventCreateRequest` + `seeded=true`. Sets `creator_uid` to a configured team/system UID (or the acting admin's UID).
- `GET /admin/events` — list with seeded flag visible, filters (area, seeded, expiring).
- Reuse existing geohash/location logic from `events.py`.

## 6. Module — Density View

Operational dashboard monitoring the empty-map risk.
- Active event counts per **launch area**.
- Flags any area below the **3-event threshold**.
- Lists events **expiring within next 24h**.
- Designed for same-day intervention (seed / publish quest).
- Only data visualisation in the panel (radius logic is proprietary, can't be replicated in 3rd-party tools).

**Backend (new launch-area model):**
- New `launch_areas` collection: `{name, center_lat, center_lng, radius_km, created_at}`. Admin-managed.
- `GET /admin/launch-areas`, `POST`, `PUT`, `DELETE` — CRUD.
- `GET /admin/density` — for each launch area: count of active (future, non-cancelled) events whose location falls within radius (reuse haversine/geohash), `below_threshold` flag (<3), and list of events expiring in next 24h. Returns per-area + global expiring list.

## 7. Module — User Management

Search by username, display name, or phone. Account view: profile details, creator status,
friend count, events joined, streak, Group memberships.

**Admin actions (exactly three), all logged with acting admin + mandatory reason:**
1. Revoke creator status.
2. Force username change.
3. Deactivate account — hides profile and expires active nudge cards, without deleting underlying data.

**Backend:**
- `GET /admin/users/search?q=` — search by username / display_name / phone.
- `GET /admin/users/{uid}` — full account view (profile, is_creator, friends_count, events_joined, streak, groups).
- `POST /admin/users/{uid}/revoke-creator` (reuses creator revoke) — requires reason.
- `POST /admin/users/{uid}/force-username` `{new_username, reason}` — validates availability/format.
- `POST /admin/users/{uid}/deactivate` `{reason}` — sets `deactivated=true`, hides profile from user-facing queries, expires active nudge cards (`status=expired`). Underlying data retained.
- Every action writes to `admin_audit_log` with mandatory `reason`.

**Ship gate:** a written usage policy for account deactivation is required before this module ships (in-app reporting arrives v2). Tracked as a non-code deliverable.

## 8. Module — Notification Templates

Management layer for all notification copy + trigger behaviour. FCM push is planned, so
templates cover push payloads. Every notification type/subtype is an editable template with
defined variables, a lock-screen preview, and version history with rollback. Each trigger has
an on/off toggle and its configurable parameter where one exists. No ad-hoc composition;
send timing stays governed by the event-driven engine.

**Notification taxonomy (from PRD):**
| Type | Subtypes | Configurable param |
|---|---|---|
| Social Pull | nudge_received, nudge_accepted | — |
| Groups | invite_received, invite_accepted, member_left, member_removed, group_nudge_received, reminder_received, nudge_accepted, nudge_declined, nudge_expired, group_dissolved | — |
| Map FOMO | new_event_nearby | radius_km (default 15) |
| Time Pressure | event_24h, event_2h, event_30m, quest_halfway, quest_3h, nudge_reminder | offsets (per-subtype) |
| Event Updates | event_edited, event_cancelled | cooldown_minutes (default 10) |
| Inactivity | warm (1d), cold (2–3d), dormant (4d+) | segment thresholds |

Each template carries: type, subtype, copy (with `{variables}`), distinct sound id, variables list.

**Backend (new):**
- `notification_templates` collection: `{type, subtype, body, variables[], sound, enabled, params{}, version, updated_at, updated_by}`.
- `notification_template_versions` subcollection per template (full snapshots for rollback).
- `GET /admin/notification-templates` (list grouped by type), `PUT /admin/notification-templates/{id}` (edit copy/params/enabled → bumps version, snapshots prior), `POST .../{id}/rollback/{version}`.
- Seed templates from the PRD taxonomy + tone examples on first deploy (seed script, like `seed_quests.py`).
- The notification engine reads copy/enabled/params from these templates at send time (engine wiring is part of this module's backend; if FCM dispatch isn't built yet, templates still govern in-app copy and store the params the engine will consume).

## 9. Lock-screen preview

Notification editor renders a phone lock-screen mock that interpolates sample variable values
into the template body so the team sees the real rendered copy before saving.

## 10. Module — Analytics (PostHog)

- PostHog integrated into the **Flutter app** (`posthog_flutter`) for product events, and into the **admin SPA** (`posthog-js`) for admin usage.
- Define a core event taxonomy (event_created, event_joined, quest_activated, nudge_sent, creator_applied, app_open, etc.).
- Admin panel does NOT rebuild dashboards (Density View is the only in-panel viz); PostHog's own dashboards serve general product analytics. Admin panel links out to PostHog.
- Distinguish `seeded` events in analytics via an event property.

## 11. Cross-cutting

- **Audit log viewer** (optional surface): a read-only list of `admin_audit_log` entries.
- **Error/loading/empty states** for every list and detail view.
- **Real-time-ish:** TanStack Query invalidation on mutations (publish/approve/seed reflect immediately).

## 12. Deployment

- Admin SPA: static build, hosted on Firebase Hosting (separate site) or Vercel.
- Restrict backend `CORS_ORIGINS` to the admin origin.
- Env: Firebase web config + API base URL + PostHog key via Vite env vars.

## 13. Out of scope (v1)

Bulk creator actions, auto-approval, quest timers/reminders/completion, ad-hoc notification
composition, in-panel analytics dashboards beyond Density, Android-specific concerns,
in-app reporting (v2).

## 14. Build order

1. Backend shared additions (`/admin/me`, audit log, CORS) + admin app scaffold + auth shell.
2. Creator Queue (least new backend).
3. Quest Manager + activation count.
4. Event Seeding (`seeded` flag).
5. User Management (+ audit log, deactivation; gated on written policy).
6. Density View (+ launch_areas model).
7. Notification Templates (+ taxonomy seed, versioning).
8. Analytics (PostHog) instrumentation.
