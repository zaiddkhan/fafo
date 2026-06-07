import os

from dotenv import load_dotenv

# Load variables from a local .env file (no-op if it doesn't exist). Real
# environment variables always take precedence over .env values.
load_dotenv()

FIREBASE_CREDENTIALS_PATH = os.getenv(
    "FIREBASE_CREDENTIALS_PATH", "firebase-service-account.json"
)
FIREBASE_DATABASE_URL = os.getenv("FIREBASE_DATABASE_URL", "")
FIREBASE_STORAGE_BUCKET = os.getenv("FIREBASE_STORAGE_BUCKET", "")
ADMIN_UIDS = [
    uid.strip()
    for uid in os.getenv("ADMIN_UIDS", "").split(",")
    if uid.strip()
]
CORS_ORIGINS = [
    origin.strip()
    for origin in os.getenv("CORS_ORIGINS", "").split(",")
    if origin.strip()
]
# Admin web console (email + password protected, server-rendered).
ADMIN_EMAIL = os.getenv("ADMIN_EMAIL", "")
ADMIN_PASSWORD = os.getenv("ADMIN_PASSWORD", "")
ADMIN_SESSION_SECRET = os.getenv("ADMIN_SESSION_SECRET", "")
ADMIN_COOKIE_SECURE = os.getenv("ADMIN_COOKIE_SECURE", "false").lower() == "true"

RATE_LIMIT_DEFAULT = os.getenv("RATE_LIMIT_DEFAULT", "60/minute")
RATE_LIMIT_AUTH = os.getenv("RATE_LIMIT_AUTH", "10/minute")
FRIEND_INVITE_BASE_URL = os.getenv(
    "FRIEND_INVITE_BASE_URL", "https://whatspopn.app/invite"
)
