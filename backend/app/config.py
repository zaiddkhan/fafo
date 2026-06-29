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

RATE_LIMIT_DEFAULT = os.getenv("RATE_LIMIT_DEFAULT", "60/minute")
RATE_LIMIT_AUTH = os.getenv("RATE_LIMIT_AUTH", "10/minute")
FRIEND_INVITE_BASE_URL = os.getenv(
    "FRIEND_INVITE_BASE_URL", "https://getfafo.app/invite"
)

# --- Push notifications ---
# Shared secret guarding the /internal/cron/* endpoints (Cloud Scheduler sends it
# in the X-Cron-Secret header). Cron endpoints are disabled if this is unset.
CRON_SHARED_SECRET = os.getenv("CRON_SHARED_SECRET", "")

# Per-user daily caps. Types not listed are uncapped (urgent/real-time).
NOTIFICATION_GLOBAL_DAILY_CAP = int(os.getenv("NOTIFICATION_GLOBAL_DAILY_CAP", "10"))
NOTIFICATION_PER_TYPE_DAILY_CAP = {"map_fomo": 3, "inactivity": 1}

# Notification types that bypass quiet hours and per-type/global caps. These are
# the real-time, user-anticipated notifications where silence would feel broken.
NOTIFICATION_URGENT_TYPES = {"social_pull", "time_pressure", "groups", "event_updates"}

# Quiet hours window in the user's local time (start_hour inclusive .. end_hour exclusive).
# Non-urgent notifications during this window are deferred to end_hour, not dropped.
QUIET_HOURS_START = int(os.getenv("QUIET_HOURS_START", "23"))
QUIET_HOURS_END = int(os.getenv("QUIET_HOURS_END", "8"))

# Dispatcher retry behaviour.
DISPATCH_MAX_ATTEMPTS = int(os.getenv("DISPATCH_MAX_ATTEMPTS", "5"))
DISPATCH_BATCH_SIZE = int(os.getenv("DISPATCH_BATCH_SIZE", "200"))

# Inactivity stage thresholds (days since last activity).
INACTIVITY_WARM_DAYS = 1
INACTIVITY_COLD_DAYS_MIN = 2
INACTIVITY_COLD_DAYS_MAX = 3
INACTIVITY_DORMANT_DAYS = 4
