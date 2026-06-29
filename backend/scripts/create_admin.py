"""Create (or password-reset) an admin user for the /admin panel.

Run this YOURSELF in a real terminal — the password is read with getpass so it
is never echoed, logged, or passed through any chat transcript.

Usage (from the backend/ directory, venv active):
    python scripts/create_admin.py admin@whatspopn.app

If the user already exists, its password is updated. Otherwise a new user is
created. The script prints the Firebase UID at the end — add that UID to the
backend `ADMIN_UIDS` env var so the account is authorized by /admin/me.
"""

import getpass
import os
import sys
from pathlib import Path

import firebase_admin
from firebase_admin import auth, credentials

# Resolve the service-account file relative to the backend root (parent of this
# scripts/ folder) so the script works regardless of the current directory.
BACKEND_ROOT = Path(__file__).resolve().parent.parent
CRED_PATH = os.getenv("FIREBASE_CREDENTIALS_PATH") or str(
    BACKEND_ROOT / "firebase-service-account.json"
)


def main() -> None:
    if not Path(CRED_PATH).exists():
        sys.exit(f"Service account file not found at: {CRED_PATH}")

    email = sys.argv[1] if len(sys.argv) > 1 else input("Admin email: ").strip()
    if not email:
        sys.exit("No email provided.")

    password = getpass.getpass(f"New password for {email}: ")
    confirm = getpass.getpass("Confirm password: ")
    if password != confirm:
        sys.exit("Passwords did not match.")
    if len(password) < 6:
        sys.exit("Firebase requires passwords of at least 6 characters.")

    firebase_admin.initialize_app(credentials.Certificate(CRED_PATH))

    try:
        user = auth.get_user_by_email(email)
        auth.update_user(user.uid, password=password, email_verified=True)
        action = "Updated password for existing user"
    except auth.UserNotFoundError:
        user = auth.create_user(email=email, password=password, email_verified=True)
        action = "Created new user"

    print(f"\n{action}.")
    print(f"UID: {user.uid}")
    print(
        "\nNext: make sure this UID is in the backend ADMIN_UIDS env var "
        "(comma-separated), then sign in at /admin."
    )


if __name__ == "__main__":
    main()
