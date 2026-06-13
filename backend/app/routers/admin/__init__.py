"""Admin JSON API.

Gated by Firebase ID token + ADMIN_UIDS (see app.dependencies.get_admin_user).
Consumed by the standalone React admin panel. Organised as one module per concern.
"""

from fastapi import APIRouter

from app.routers.admin import (
    core,
    creators,
    quests,
    events,
    density,
    users,
    notifications,
)

router = APIRouter(prefix="/admin", tags=["admin"])
router.include_router(core.router)
router.include_router(creators.router)
router.include_router(quests.router)
router.include_router(events.router)
router.include_router(density.router)
router.include_router(users.router)
router.include_router(notifications.router)
