"""Server-rendered admin console for managing creator applications.

Protected by a single email + password (set via ADMIN_EMAIL / ADMIN_PASSWORD
env vars). On success an HMAC-signed session cookie is issued. This is separate
from the JSON `/admin/*` API (which is gated by Firebase + ADMIN_UIDS); the
console is meant to be opened in a browser by the WhatsPopn team.
"""

import base64
import hashlib
import hmac
import html
import json
import time

from fastapi import APIRouter, Form, Request, status
from fastapi.responses import HTMLResponse, RedirectResponse
from google.cloud.firestore import SERVER_TIMESTAMP

from app.config import (
    ADMIN_COOKIE_SECURE,
    ADMIN_EMAIL,
    ADMIN_PASSWORD,
    ADMIN_SESSION_SECRET,
)
from app.firebase import get_firestore

router = APIRouter(prefix="/console", tags=["console"])

_COOKIE_NAME = "wpn_admin_session"
_SESSION_TTL = 60 * 60 * 8  # 8 hours


# --- Auth helpers -----------------------------------------------------------

def _configured() -> bool:
    return bool(ADMIN_EMAIL and ADMIN_PASSWORD)


def _secret() -> bytes:
    # A dedicated secret is preferred; otherwise derive a stable one from the
    # password so cookies can't be forged without knowing it.
    return (ADMIN_SESSION_SECRET or f"{ADMIN_PASSWORD}:wpn-console").encode()


def _sign_session(email: str) -> str:
    payload = {"email": email, "exp": int(time.time()) + _SESSION_TTL}
    raw = base64.urlsafe_b64encode(json.dumps(payload).encode()).decode()
    sig = hmac.new(_secret(), raw.encode(), hashlib.sha256).hexdigest()
    return f"{raw}.{sig}"


def _valid_session(token: str | None) -> bool:
    if not token:
        return False
    try:
        raw, sig = token.rsplit(".", 1)
        expected = hmac.new(_secret(), raw.encode(), hashlib.sha256).hexdigest()
        if not hmac.compare_digest(sig, expected):
            return False
        payload = json.loads(base64.urlsafe_b64decode(raw.encode()))
        return int(payload.get("exp", 0)) > int(time.time())
    except Exception:
        return False


def _credentials_ok(email: str, password: str) -> bool:
    if not _configured():
        return False
    email_ok = hmac.compare_digest(email.strip().lower(), ADMIN_EMAIL.strip().lower())
    password_ok = hmac.compare_digest(password, ADMIN_PASSWORD)
    return email_ok and password_ok


def _is_authed(request: Request) -> bool:
    return _valid_session(request.cookies.get(_COOKIE_NAME))


# --- HTML rendering ---------------------------------------------------------

_STYLE = """
<style>
  :root { color-scheme: light; }
  * { box-sizing: border-box; }
  body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
         background: #f4f6fa; margin: 0; color: #1b1b1f; }
  .topbar { background: #1A87DA; color: #fff; padding: 16px 28px; display: flex;
            align-items: center; justify-content: space-between; }
  .topbar h1 { font-size: 18px; margin: 0; font-weight: 800; letter-spacing: .3px; }
  .topbar a { color: #fff; text-decoration: none; font-weight: 700; font-size: 14px; opacity: .9; }
  .wrap { max-width: 1040px; margin: 28px auto; padding: 0 20px; }
  .card { background: #fff; border: 1px solid #e3e6ee; border-radius: 14px; padding: 22px; }
  .login { max-width: 380px; margin: 9vh auto; }
  .login h2 { margin: 0 0 4px; font-size: 22px; }
  .muted { color: #6d6d78; font-size: 14px; }
  label { display: block; font-weight: 700; font-size: 13px; margin: 16px 0 6px; }
  input[type=email], input[type=password] { width: 100%; padding: 11px 12px; border: 1px solid #cfd4e0;
            border-radius: 9px; font-size: 15px; }
  .btn { display: inline-block; border: none; cursor: pointer; border-radius: 8px;
         font-weight: 700; font-size: 13px; padding: 9px 14px; }
  .btn-primary { background: #1A87DA; color: #fff; width: 100%; padding: 12px; font-size: 15px; margin-top: 20px; }
  .btn-approve { background: #2e9d52; color: #fff; }
  .btn-reject  { background: #e5484d; color: #fff; }
  .btn-revoke  { background: #21232b; color: #fff; }
  .err { background: #fdecec; color: #b42318; padding: 10px 12px; border-radius: 8px; font-size: 14px; margin-top: 14px; }
  table { width: 100%; border-collapse: collapse; }
  th, td { text-align: left; padding: 12px 10px; border-bottom: 1px solid #eef0f5; vertical-align: top; font-size: 14px; }
  th { font-size: 12px; text-transform: uppercase; letter-spacing: .4px; color: #6d6d78; }
  .pill { display: inline-block; padding: 3px 10px; border-radius: 999px; font-size: 11px; font-weight: 800; }
  .pill-pending  { background: #fff3d6; color: #946200; }
  .pill-approved { background: #def3e3; color: #1f7a3d; }
  .pill-rejected { background: #fde2e2; color: #b42318; }
  .pill-revoked  { background: #e7e9ef; color: #4a4d57; }
  .links a { display: block; color: #1A87DA; font-size: 13px; }
  .actions form { display: inline; }
  .name { font-weight: 700; }
  .sub { color: #6d6d78; font-size: 12px; }
  .empty { text-align: center; color: #6d6d78; padding: 40px 0; }
  .count { font-weight: 800; }
</style>
"""


def _page(body: str) -> HTMLResponse:
    return HTMLResponse(
        f"<!doctype html><html><head><meta charset='utf-8'>"
        f"<meta name='viewport' content='width=device-width, initial-scale=1'>"
        f"<title>WhatsPopn Console</title>{_STYLE}</head><body>{body}</body></html>"
    )


def _login_page(error: str | None = None) -> HTMLResponse:
    if not _configured():
        return _page(
            "<div class='login'><div class='card'><h2>Console unavailable</h2>"
            "<p class='muted'>Set <code>ADMIN_EMAIL</code> and <code>ADMIN_PASSWORD</code> "
            "environment variables on the backend to enable the admin console.</p></div></div>"
        )
    err_html = f"<div class='err'>{html.escape(error)}</div>" if error else ""
    return _page(
        "<div class='login'><div class='card'>"
        "<h2>WhatsPopn Console</h2>"
        "<p class='muted'>Sign in to manage creator requests.</p>"
        f"{err_html}"
        "<form method='post' action='/console/login'>"
        "<label>Email</label><input type='email' name='email' autofocus required>"
        "<label>Password</label><input type='password' name='password' required>"
        "<button class='btn btn-primary' type='submit'>Sign in</button>"
        "</form></div></div>"
    )


def _fmt_ts(value) -> str:
    try:
        return value.strftime("%b %d, %Y %H:%M")
    except Exception:
        return "—"


def _links_html(items) -> str:
    if not items:
        return "<span class='sub'>—</span>"
    if isinstance(items, str):
        items = [items]
    out = []
    for link in items:
        safe = html.escape(str(link))
        out.append(f"<a href='{safe}' target='_blank' rel='noreferrer'>{safe}</a>")
    return f"<div class='links'>{''.join(out)}</div>"


def _status_pill(status_value: str) -> str:
    cls = {
        "pending": "pill-pending",
        "approved": "pill-approved",
        "rejected": "pill-rejected",
        "revoked": "pill-revoked",
    }.get(status_value, "pill-revoked")
    return f"<span class='pill {cls}'>{html.escape(status_value)}</span>"


def _dashboard_page() -> HTMLResponse:
    db = get_firestore()
    rows = []
    for doc in db.collection("creator_applications").stream():
        data = doc.to_dict() or {}
        uid = doc.id
        user_doc = db.collection("users").document(uid).get()
        user = user_doc.to_dict() if user_doc.exists else {}
        rows.append({
            "uid": uid,
            "status": data.get("status", "pending"),
            "purpose": data.get("purpose", ""),
            "phone": data.get("phone", ""),
            "social_links": data.get("social_links"),
            "relevant_links": data.get("relevant_links"),
            "submitted_at": data.get("submitted_at"),
            "display_name": user.get("display_name") or "(no name)",
            "username": user.get("username") or "",
            "is_creator": bool(user.get("is_creator")),
        })

    # Pending first, then most recent.
    order = {"pending": 0, "approved": 1, "revoked": 2, "rejected": 3}
    rows.sort(key=lambda r: (order.get(r["status"], 9), -(_epoch(r["submitted_at"]))))

    pending_count = sum(1 for r in rows if r["status"] == "pending")

    if not rows:
        table = "<div class='empty'>No creator applications yet.</div>"
    else:
        body_rows = "".join(_row_html(r) for r in rows)
        table = (
            "<table><thead><tr>"
            "<th>Applicant</th><th>Purpose</th><th>Contact</th><th>Links</th>"
            "<th>Submitted</th><th>Status</th><th>Actions</th>"
            "</tr></thead><tbody>" + body_rows + "</tbody></table>"
        )

    return _page(
        "<div class='topbar'><h1>WhatsPopn Console</h1>"
        "<a href='/console/logout'>Sign out</a></div>"
        "<div class='wrap'><div class='card'>"
        f"<p class='muted'>Creator requests &middot; <span class='count'>{pending_count}</span> pending</p>"
        f"{table}</div></div>"
    )


def _epoch(value) -> float:
    try:
        return value.timestamp()
    except Exception:
        return 0.0


def _row_html(r: dict) -> str:
    uid = html.escape(r["uid"])
    name = html.escape(r["display_name"])
    username = html.escape(f"@{r['username']}") if r["username"] else ""
    purpose = html.escape(r["purpose"]) or "<span class='sub'>—</span>"
    phone = html.escape(r["phone"]) or "—"
    links = _links_html(r["social_links"]) + _links_html(r["relevant_links"])
    submitted = _fmt_ts(r["submitted_at"])
    status_pill = _status_pill(r["status"])

    def form(action: str, label: str, cls: str) -> str:
        return (
            f"<form method='post' action='/console/creators/{uid}/{action}'>"
            f"<button class='btn {cls}' type='submit'>{label}</button></form> "
        )

    actions = ""
    if r["status"] != "approved":
        actions += form("approve", "Approve", "btn-approve")
    if r["status"] == "pending":
        actions += form("reject", "Reject", "btn-reject")
    if r["is_creator"]:
        actions += form("revoke", "Revoke", "btn-revoke")
    if not actions:
        actions = "<span class='sub'>—</span>"

    return (
        "<tr>"
        f"<td><div class='name'>{name}</div><div class='sub'>{username}</div></td>"
        f"<td>{purpose}</td>"
        f"<td>{phone}</td>"
        f"<td>{links}</td>"
        f"<td class='sub'>{submitted}</td>"
        f"<td>{status_pill}</td>"
        f"<td class='actions'>{actions}</td>"
        "</tr>"
    )


# --- Routes -----------------------------------------------------------------

@router.get("", response_class=HTMLResponse)
def console_home(request: Request):
    if not _is_authed(request):
        return RedirectResponse("/console/login", status_code=status.HTTP_303_SEE_OTHER)
    return _dashboard_page()


@router.get("/login", response_class=HTMLResponse)
def login_form(request: Request):
    if _is_authed(request):
        return RedirectResponse("/console", status_code=status.HTTP_303_SEE_OTHER)
    return _login_page()


@router.post("/login")
def login_submit(email: str = Form(...), password: str = Form(...)):
    if not _credentials_ok(email, password):
        return _login_page("Invalid email or password.")
    response = RedirectResponse("/console", status_code=status.HTTP_303_SEE_OTHER)
    response.set_cookie(
        _COOKIE_NAME,
        _sign_session(email.strip().lower()),
        max_age=_SESSION_TTL,
        httponly=True,
        samesite="lax",
        secure=ADMIN_COOKIE_SECURE,
        path="/console",
    )
    return response


@router.get("/logout")
def logout():
    response = RedirectResponse("/console/login", status_code=status.HTTP_303_SEE_OTHER)
    response.delete_cookie(_COOKIE_NAME, path="/console")
    return response


@router.post("/creators/{uid}/{action}")
def creator_action(uid: str, action: str, request: Request):
    if not _is_authed(request):
        return RedirectResponse("/console/login", status_code=status.HTTP_303_SEE_OTHER)
    if action in ("approve", "reject", "revoke"):
        _apply_action(uid, action)
    return RedirectResponse("/console", status_code=status.HTTP_303_SEE_OTHER)


def _apply_action(uid: str, action: str) -> None:
    db = get_firestore()
    app_ref = db.collection("creator_applications").document(uid)
    if action == "approve":
        if app_ref.get().exists:
            app_ref.update({"status": "approved", "reviewed_at": SERVER_TIMESTAMP})
        db.collection("users").document(uid).update({"is_creator": True})
    elif action == "reject":
        if app_ref.get().exists:
            app_ref.update({"status": "rejected", "reviewed_at": SERVER_TIMESTAMP})
    elif action == "revoke":
        db.collection("users").document(uid).update({"is_creator": False})
        if app_ref.get().exists:
            app_ref.update({"status": "revoked", "reviewed_at": SERVER_TIMESTAMP})
