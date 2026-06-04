from pydantic import BaseModel, Field, field_validator
from typing import Optional
from datetime import datetime, timezone
from enum import Enum


class FriendshipStatus(str, Enum):
    none = "none"
    friends = "friends"
    request_sent = "request_sent"
    request_received = "request_received"
    blocked = "blocked"
    blocked_by = "blocked_by"


class FriendRequestStatus(str, Enum):
    pending = "pending"
    accepted = "accepted"
    declined = "declined"


# --- Auth ---


class SessionRequest(BaseModel):
    id_token: str


class SessionResponse(BaseModel):
    uid: str
    phone: str
    is_new: bool
    onboarding_complete: bool
    is_creator: bool = False


# --- Users ---


class UsernameCheckResponse(BaseModel):
    username: str
    available: bool


class Area(BaseModel):
    lat: float
    lng: float
    radius_km: float = Field(default=15.0)


class ProfileSetupRequest(BaseModel):
    display_name: str = Field(min_length=1, max_length=50)
    username: str = Field(min_length=3, max_length=30, pattern=r"^[a-z0-9._]+$")
    area: Optional[Area] = None


class ProfileResponse(BaseModel):
    uid: str
    phone: str
    display_name: str
    username: str
    photo_url: Optional[str]
    area: Optional[Area]
    onboarding_complete: bool
    first_launch_tooltip_complete: bool = False
    is_creator: bool = False


class PhotoUploadResponse(BaseModel):
    upload_path: str
    photo_url: str


class TooltipCompleteResponse(BaseModel):
    first_launch_tooltip_complete: bool


class PublicUserResponse(BaseModel):
    uid: str
    display_name: str
    username: str
    photo_url: Optional[str]
    online: bool = False
    friendship_status: FriendshipStatus = FriendshipStatus.none


# --- Friends ---


class FriendRequestCreateRequest(BaseModel):
    recipient_uid: Optional[str] = None
    username: Optional[str] = Field(default=None, min_length=3, max_length=30)
    phone: Optional[str] = Field(default=None, min_length=5, max_length=20)


class FriendRequestResponse(BaseModel):
    id: str
    requester: PublicUserResponse
    recipient: PublicUserResponse
    status: FriendRequestStatus
    created_at: datetime
    responded_at: Optional[datetime] = None


class FriendResponse(BaseModel):
    user: PublicUserResponse
    friends_since: datetime


class FriendStatsResponse(BaseModel):
    friends_count: int
    incoming_request_count: int
    outgoing_request_count: int


class UserSearchResponse(BaseModel):
    users: list[PublicUserResponse]


class ContactSyncRequest(BaseModel):
    phone_numbers: list[str] = Field(min_length=1, max_length=500)


class ContactMatchResponse(BaseModel):
    phone: str
    user: PublicUserResponse


class ContactSyncResponse(BaseModel):
    matches: list[ContactMatchResponse]


class FriendInviteCreateResponse(BaseModel):
    token: str
    invite_url: str
    created_at: datetime


class FriendInviteResolveResponse(BaseModel):
    inviter: PublicUserResponse
    token: str


class NegativeActionAnswers(BaseModel):
    answers: list[str] = Field(min_length=3, max_length=5)


class BlockedUserResponse(BaseModel):
    user: PublicUserResponse
    blocked_at: datetime


# --- Creators ---


class CreatorApplicationRequest(BaseModel):
    purpose: str = Field(min_length=10, max_length=500)
    social_links: list[str] = Field(default_factory=list)
    phone: str = Field(min_length=10, max_length=15)
    relevant_links: list[str] = Field(default_factory=list)


class CreatorApplicationResponse(BaseModel):
    uid: str
    purpose: str
    social_links: list[str]
    phone: str
    relevant_links: list[str]
    status: str
    submitted_at: datetime


# --- Categories ---


class CategoryCreateRequest(BaseModel):
    name: str = Field(min_length=1, max_length=50)
    emoji: str = Field(min_length=1, max_length=10)
    sort_order: int = Field(default=0)


class CategoryUpdateRequest(BaseModel):
    name: Optional[str] = Field(default=None, min_length=1, max_length=50)
    emoji: Optional[str] = Field(default=None, min_length=1, max_length=10)
    sort_order: Optional[int] = None


class CategoryResponse(BaseModel):
    id: str
    name: str
    emoji: str
    sort_order: int


# --- Events ---


class EventType(str, Enum):
    normal = "normal"
    spotlight = "spotlight"
    volunteering = "volunteering"


# --- Blogs ---


class BlogCreateRequest(BaseModel):
    city: str = Field(min_length=1, max_length=80)
    title: str = Field(min_length=1, max_length=160)
    subtitle: Optional[str] = Field(default=None, max_length=240)
    body: str = Field(min_length=1, max_length=10000)
    image_url: Optional[str] = Field(default=None, max_length=500)
    read_time: Optional[str] = Field(default=None, max_length=40)
    published: bool = True


class BlogUpdateRequest(BaseModel):
    city: Optional[str] = Field(default=None, min_length=1, max_length=80)
    title: Optional[str] = Field(default=None, min_length=1, max_length=160)
    subtitle: Optional[str] = Field(default=None, max_length=240)
    body: Optional[str] = Field(default=None, min_length=1, max_length=10000)
    image_url: Optional[str] = Field(default=None, max_length=500)
    read_time: Optional[str] = Field(default=None, max_length=40)
    published: Optional[bool] = None


class BlogResponse(BaseModel):
    id: str
    city: str
    title: str
    subtitle: Optional[str]
    body: str
    image_url: Optional[str]
    read_time: Optional[str]
    published: bool
    created_at: datetime
    updated_at: datetime


class EventCreateRequest(BaseModel):
    title: str = Field(min_length=1, max_length=100)
    description: Optional[str] = Field(default=None, max_length=1000)
    category_id: str
    event_type: EventType = EventType.normal
    custom_emoji: Optional[str] = Field(default=None, max_length=10)
    lat: float
    lng: float
    location_name: str = Field(min_length=1, max_length=200)
    date_time: datetime
    capacity: Optional[int] = Field(default=None, gt=0)
    organizer_name: Optional[str] = Field(default=None, max_length=100)
    organizer_contact: Optional[str] = Field(default=None, max_length=200)
    organizer_instagram: Optional[str] = Field(default=None, max_length=100)

    @field_validator("date_time")
    @classmethod
    def must_be_future(cls, v: datetime) -> datetime:
        now = datetime.now(timezone.utc)
        if v.tzinfo is None:
            v = v.replace(tzinfo=timezone.utc)
        if v < now:
            raise ValueError("Event date must be in the future")
        return v


class EventUpdateRequest(BaseModel):
    title: Optional[str] = Field(default=None, min_length=1, max_length=100)
    description: Optional[str] = Field(default=None, max_length=1000)
    category_id: Optional[str] = None
    event_type: Optional[EventType] = None
    custom_emoji: Optional[str] = Field(default=None, max_length=10)
    lat: Optional[float] = None
    lng: Optional[float] = None
    location_name: Optional[str] = Field(default=None, min_length=1, max_length=200)
    date_time: Optional[datetime] = None
    capacity: Optional[int] = Field(default=None, gt=0)
    registration_open: Optional[bool] = None
    organizer_name: Optional[str] = Field(default=None, max_length=100)
    organizer_contact: Optional[str] = Field(default=None, max_length=200)
    organizer_instagram: Optional[str] = Field(default=None, max_length=100)


class EventResponse(BaseModel):
    id: str
    creator_uid: str
    title: str
    description: Optional[str]
    category_id: str
    event_type: EventType
    custom_emoji: Optional[str]
    lat: float
    lng: float
    location_name: str
    date_time: datetime
    capacity: Optional[int]
    joinee_count: int
    registration_open: bool
    cancelled: bool
    banner_url: Optional[str] = None
    organizer_name: Optional[str] = None
    organizer_contact: Optional[str] = None
    organizer_instagram: Optional[str] = None
    is_joined: bool = False
    created_at: datetime
    updated_at: datetime


class EventBannerUploadResponse(BaseModel):
    event_id: str
    banner_url: str


class EventCancelRequest(BaseModel):
    reason: str = Field(min_length=1, max_length=200)


class EventJoinResponse(BaseModel):
    event_id: str
    joined_at: datetime


class UnjoinReason(str, Enum):
    change_of_plans = "change_of_plans"
    scheduling_conflict = "scheduling_conflict"
    no_longer_interested = "no_longer_interested"
    other = "other"


class EventUnjoinRequest(BaseModel):
    reason: UnjoinReason


class JoineeResponse(BaseModel):
    uid: str
    username: str
    display_name: str
    photo_url: Optional[str]
    joined_at: datetime


class EventListQuery(BaseModel):
    lat: float
    lng: float
    radius_km: float = Field(default=15.0)
    category_id: Optional[str] = None
    event_type: Optional[EventType] = None
