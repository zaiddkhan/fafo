"""Internal cron endpoints, driven by Cloud Scheduler.

Protected by a shared secret in the X-Cron-Secret header (CRON_SHARED_SECRET). If the
secret is unset, the endpoints return 503 — they are never open. These wrap pure logic
functions so the same jobs can also be invoked directly in tests or a local loop.

Suggested Cloud Scheduler jobs:
  * dispatch    — POST /internal/cron/dispatch   every 1 minute
  * inactivity  — POST /internal/cron/inactivity every 1 hour (parked in V3)
  * nudges      — POST /internal/cron/nudges     every 1 minute
"""

import hmac

from fastapi import APIRouter, Header, HTTPException, status

from app.config import CRON_SHARED_SECRET, INACTIVITY_NOTIFICATIONS_ENABLED
from app.notifications.scheduler import inactivity_sweep
from app.notifications.service import notifications
from app.routers.nudges import sweep_nudges
from app.schemas import CronRunResponse

router = APIRouter(prefix="/internal/cron", tags=["internal"])


def _authorize(secret: str | None) -> None:
    if not CRON_SHARED_SECRET:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail="Cron endpoints are disabled (CRON_SHARED_SECRET not set)",
        )
    if not secret or not hmac.compare_digest(secret, CRON_SHARED_SECRET):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid cron secret")


@router.post("/dispatch", response_model=CronRunResponse)
def cron_dispatch(x_cron_secret: str | None = Header(default=None)):
    _authorize(x_cron_secret)
    summary = notifications.dispatch_pending()
    return CronRunResponse(job="dispatch", summary=summary)


@router.post("/inactivity", response_model=CronRunResponse)
def cron_inactivity(x_cron_secret: str | None = Header(default=None)):
    _authorize(x_cron_secret)
    # V3 brief 7.1: inactivity nudges are parked, not deleted.
    if not INACTIVITY_NOTIFICATIONS_ENABLED:
        return CronRunResponse(job="inactivity", summary={"skipped": "parked"})
    summary = inactivity_sweep()
    return CronRunResponse(job="inactivity", summary=summary)


@router.post("/nudges", response_model=CronRunResponse)
def cron_nudges(x_cron_secret: str | None = Header(default=None)):
    """Settle expired nudges and send expiry / group tally pushes."""
    _authorize(x_cron_secret)
    return CronRunResponse(job="nudges", summary=sweep_nudges())
