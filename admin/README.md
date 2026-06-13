# WhatsPopn Admin Panel

Standalone React admin panel for the WhatsPopn (Fafu) team. Reuses the existing
FastAPI + Firestore backend (`../backend`). The Flutter app is untouched.

## Modules

1. **Creator Queue** — vet creator applications (approve / revoke), reapplication history.
2. **Quest Manager** — publish Side Quests (citywide / area-specific), activation counts.
3. **Event Seeding** — create team events with an internal `seeded` flag.
4. **Density View** — active events per launch area, <3 threshold flags, 24h expiry list, launch-area CRUD.
5. **User Management** — search, account view, and three logged actions (revoke creator, force username, deactivate).
6. **Notification Templates** — edit notification copy/triggers, lock-screen preview, version history + rollback.
7. **Analytics** — PostHog integration reference + dashboard link.

## Stack

Vite + React + TypeScript · Tailwind v4 · TanStack Query · React Router · Firebase JS SDK · PostHog.

## Setup

```bash
cp .env.example .env   # fill in Firebase web config + API base URL (+ PostHog optional)
npm install
npm run dev            # http://localhost:5174
```

### Auth

Admins sign in with **Firebase Email/Password**. A user is an admin iff their Firebase
UID is listed in the backend's `ADMIN_UIDS` env var.

1. Enable the Email/Password provider in Firebase Auth.
2. Create the admin user(s) in Firebase.
3. Add each admin UID to `ADMIN_UIDS` in the backend `.env`.

The app calls `GET /admin/me` after login to confirm admin status; non-admins see a
"Not authorized" screen.

## Build & deploy

```bash
npm run build          # outputs dist/ (static SPA)
```

Host `dist/` on any static host (Firebase Hosting / Vercel / Netlify). Restrict the
backend `CORS_ORIGINS` to the deployed admin origin.

## Notes

- Notification templates lazy-seed from the PRD taxonomy on first load of the
  Notifications module (`GET /admin/notification-templates`).
- Density View is the only in-panel data visualization (launch-area radius logic is
  proprietary and not replicable in third-party analytics).
