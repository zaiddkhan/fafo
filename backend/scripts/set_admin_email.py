"""Change an admin user's email (keeps the same UID + password).

Usage (from backend/, venv active):
    python scripts/set_admin_email.py <uid> <new_email>
"""

import sys
from pathlib import Path

import firebase_admin
from firebase_admin import auth, credentials

BACKEND_ROOT = Path(__file__).resolve().parent.parent
CRED_PATH = BACKEND_ROOT / "firebase-service-account.json"


def main() -> None:
    if len(sys.argv) != 3:
        sys.exit("Usage: python scripts/set_admin_email.py <uid> <new_email>")
    uid, new_email = sys.argv[1], sys.argv[2]

    firebase_admin.initialize_app(credentials.Certificate(str(CRED_PATH)))

    before = auth.get_user(uid)
    try:
        auth.update_user(uid, email=new_email, email_verified=True)
    except auth.EmailAlreadyExistsError:
        sys.exit(
            f"{new_email} is already used by another Firebase user. "
            "Delete/rename that account first, or pick a different email."
        )

    after = auth.get_user(uid)
    print(f"Email changed: {before.email}  ->  {after.email}")
    print(f"UID unchanged: {after.uid}")


if __name__ == "__main__":
    main()
