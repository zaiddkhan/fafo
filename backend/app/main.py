from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from slowapi import Limiter, _rate_limit_exceeded_handler
from slowapi.util import get_remote_address
from slowapi.errors import RateLimitExceeded

from app.config import CORS_ORIGINS, RATE_LIMIT_DEFAULT
from app.firebase import init_firebase
from app.routers import admin, auth, blogs, categories, creators, events, friends, users

limiter = Limiter(key_func=get_remote_address, default_limits=[RATE_LIMIT_DEFAULT])


@asynccontextmanager
async def lifespan(app: FastAPI):
    init_firebase()
    yield


app = FastAPI(title="WhatsPopn API", lifespan=lifespan)
app.state.limiter = limiter
app.add_exception_handler(RateLimitExceeded, _rate_limit_exceeded_handler)

app.add_middleware(
    CORSMiddleware,
    allow_origins=CORS_ORIGINS or ["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router)
app.include_router(users.router)
app.include_router(creators.router)
app.include_router(admin.router)
app.include_router(categories.router)
app.include_router(blogs.router)
app.include_router(events.router)
app.include_router(friends.router)


@app.get("/health")
def health():
    return {"status": "ok"}
