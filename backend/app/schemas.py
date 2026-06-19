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
    # IANA timezone (e.g. "Asia/Kolkata") used for notification quiet hours.
    timezone: Optional[str] = Field(default=None, max_length=64)


class TimezoneUpdateRequest(BaseModel):
    timezone: str = Field(min_length=1, max_length=64)


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
    normalized_phone: str
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


# --- Groups ---


class GroupInviteStatus(str, Enum):
    pending = "pending"
    accepted = "accepted"
    declined = "declined"


class GroupCreateRequest(BaseModel):
    name: str = Field(min_length=1, max_length=60)


class GroupUpdateRequest(BaseModel):
    name: str = Field(min_length=1, max_length=60)


class GroupMemberResponse(BaseModel):
    user: PublicUserResponse
    joined_at: datetime
    is_admin: bool = False


class GroupResponse(BaseModel):
    id: str
    name: str
    admin_uid: str
    created_at: datetime
    updated_at: datetime
    members: list[GroupMemberResponse] = Field(default_factory=list)


class GroupInviteCreateRequest(BaseModel):
    recipient_uid: str


class GroupInviteResponse(BaseModel):
    id: str
    group_id: str
    group_name: str
    inviter: PublicUserResponse
    recipient: PublicUserResponse
    status: GroupInviteStatus
    created_at: datetime
    responded_at: Optional[datetime] = None


class GroupTransferRequest(BaseModel):
    new_admin_uid: str


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
    address: Optional[str] = Field(default=None, max_length=300)
    location_details: Optional[str] = Field(default=None, max_length=200)
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
    address: Optional[str] = Field(default=None, max_length=300)
    location_details: Optional[str] = Field(default=None, max_length=200)
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
    address: Optional[str] = None
    location_details: Optional[str] = None
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
    answers: list[str] = Field(default_factory=list, max_length=5)


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
    answers: list[str] = Field(default_factory=list, max_length=5)


class JoineeResponse(BaseModel):
    uid: str
    username: str
    display_name: str
    photo_url: Optional[str]
    online: bool = False
    joined_at: datetime


class EventListQuery(BaseModel):
    lat: float
    lng: float
    radius_km: float = Field(default=15.0)
    category_id: Optional[str] = None
    event_type: Optional[EventType] = None


# --- Side Quests ---


class QuestDifficulty(str, Enum):
    easy = "easy"
    medium = "medium"
    hard = "hard"


class QuestCreateRequest(BaseModel):
    title: str = Field(min_length=1, max_length=100)
    description: Optional[str] = Field(default=None, max_length=500)
    difficulty: QuestDifficulty
    city: Optional[str] = Field(default=None, max_length=80)
    area: Optional[Area] = None
    published: bool = True


class QuestUpdateRequest(BaseModel):
    title: Optional[str] = Field(default=None, min_length=1, max_length=100)
    description: Optional[str] = Field(default=None, max_length=500)
    difficulty: Optional[QuestDifficulty] = None
    city: Optional[str] = Field(default=None, max_length=80)
    area: Optional[Area] = None
    published: Optional[bool] = None


class QuestResponse(BaseModel):
    id: str
    title: str
    description: Optional[str]
    difficulty: QuestDifficulty
    city: Optional[str]
    area: Optional[Area]
    published: bool
    created_at: datetime
    updated_at: datetime


class QuestActivationStatus(str, Enum):
    active = "active"
    completed = "completed"


class QuestActivationResponse(BaseModel):
    quest: QuestResponse
    status: QuestActivationStatus
    activated_at: datetime
    completed_at: Optional[datetime] = None


# --- Nudge Cards ---


class NudgeFeedType(str, Enum):
    friend = "friend"
    group = "group"


class NudgeStatus(str, Enum):
    active = "active"
    accepted_timer = "accepted_timer"
    resolved = "resolved"
    expired = "expired"


class NudgeVote(str, Enum):
    yes = "yes"
    no = "no"


class NudgeCreateRequest(BaseModel):
    feed_type: NudgeFeedType
    target_id: str
    title: str = Field(min_length=1, max_length=100)
    location: Optional[str] = Field(default=None, max_length=500)
    response_window_minutes: int

    @field_validator("response_window_minutes")
    @classmethod
    def valid_window(cls, v: int) -> int:
        if v not in (5, 10, 15, 20):
            raise ValueError("Response window must be 5, 10, 15, or 20 minutes")
        return v


class NudgeRespondRequest(BaseModel):
    vote: NudgeVote


class NudgeResponse(BaseModel):
    id: str
    feed_type: NudgeFeedType
    feed_id: str
    sender_uid: str
    title: str
    location: Optional[str]
    response_window_minutes: int
    status: NudgeStatus
    expires_at: datetime
    accepted_timer_started_at: Optional[datetime] = None
    reminder_count: int
    reminder_limit: int
    next_reminder_available_at: Optional[datetime] = None
    votes: dict[str, NudgeVote | str] = Field(default_factory=dict)
    yes_count: int = 0
    voter_count: int = 0
    expected_voter_count: int = 0
    created_at: datetime
    resolved_at: Optional[datetime] = None


class ProfileStatsResponse(BaseModel):
    upcoming_events: int = 0
    events_joined: int = 0
    side_quests_activated: int = 0
    friends_count: int = 0
    current_streak: int = 0


# --- Admin: shared ---


class AdminMeResponse(BaseModel):
    uid: str
    is_admin: bool


class ReasonRequest(BaseModel):
    reason: str = Field(min_length=3, max_length=500)


class AuditLogResponse(BaseModel):
    id: str
    admin_uid: str
    action: str
    target_type: Optional[str] = None
    target_id: Optional[str] = None
    reason: Optional[str] = None
    metadata: dict = Field(default_factory=dict)
    created_at: datetime


# --- Admin: Creator Queue ---


class CreatorHistoryEntry(BaseModel):
    status: str
    at: datetime
    note: Optional[str] = None


class CreatorListItem(BaseModel):
    uid: str
    display_name: str
    username: str
    photo_url: Optional[str] = None
    status: str
    is_creator: bool
    reapplied: bool = False
    submitted_at: Optional[datetime] = None
    reviewed_at: Optional[datetime] = None


class CreatorDetailResponse(CreatorListItem):
    purpose: str = ""
    social_links: list[str] = Field(default_factory=list)
    relevant_links: list[str] = Field(default_factory=list)
    phone: str = ""
    history: list[CreatorHistoryEntry] = Field(default_factory=list)


# --- Admin: Quest Manager ---


class AdminQuestResponse(QuestResponse):
    activation_count: int = 0


# --- Admin: Event Seeding ---


class AdminEventListItem(BaseModel):
    id: str
    title: str
    creator_uid: str
    category_id: str
    location_name: str
    lat: float
    lng: float
    date_time: datetime
    joinee_count: int
    cancelled: bool
    seeded: bool
    created_at: datetime


# --- Admin: Density View ---


class LaunchAreaCreateRequest(BaseModel):
    name: str = Field(min_length=1, max_length=80)
    center_lat: float = Field(ge=-90, le=90)
    center_lng: float = Field(ge=-180, le=180)
    radius_km: float = Field(default=15.0, gt=0, le=200)


class LaunchAreaUpdateRequest(BaseModel):
    name: Optional[str] = Field(default=None, min_length=1, max_length=80)
    center_lat: Optional[float] = Field(default=None, ge=-90, le=90)
    center_lng: Optional[float] = Field(default=None, ge=-180, le=180)
    radius_km: Optional[float] = Field(default=None, gt=0, le=200)


class LaunchAreaResponse(BaseModel):
    id: str
    name: str
    center_lat: float
    center_lng: float
    radius_km: float
    created_at: datetime


class ExpiringEventItem(BaseModel):
    id: str
    title: str
    location_name: str
    date_time: datetime
    seeded: bool


class DensityAreaResponse(BaseModel):
    area: LaunchAreaResponse
    active_event_count: int
    below_threshold: bool
    expiring_24h: list[ExpiringEventItem] = Field(default_factory=list)


class DensityResponse(BaseModel):
    threshold: int = 3
    areas: list[DensityAreaResponse] = Field(default_factory=list)
    generated_at: datetime


# --- Admin: User Management ---


class AdminUserListItem(BaseModel):
    uid: str
    display_name: str
    username: str
    phone: Optional[str] = None
    photo_url: Optional[str] = None
    is_creator: bool = False
    deactivated: bool = False


class AdminUserGroup(BaseModel):
    id: str
    name: str
    is_admin: bool = False


class AdminUserDetailResponse(AdminUserListItem):
    friends_count: int = 0
    events_joined: int = 0
    current_streak: int = 0
    groups: list[AdminUserGroup] = Field(default_factory=list)


class ForceUsernameRequest(ReasonRequest):
    new_username: str = Field(min_length=3, max_length=30, pattern=r"^[a-z0-9._]+$")


# --- Admin: Notification Templates ---


class NotificationTemplateUpdateRequest(BaseModel):
    body: Optional[str] = Field(default=None, min_length=1, max_length=500)
    sound: Optional[str] = Field(default=None, max_length=60)
    enabled: Optional[bool] = None
    params: Optional[dict] = None


class NotificationTemplateVersion(BaseModel):
    version: int
    body: str
    sound: Optional[str] = None
    enabled: bool
    params: dict = Field(default_factory=dict)
    updated_at: datetime
    updated_by: Optional[str] = None


class NotificationTemplateResponse(BaseModel):
    id: str
    type: str
    subtype: str
    body: str
    variables: list[str] = Field(default_factory=list)
    sound: Optional[str] = None
    enabled: bool = True
    params: dict = Field(default_factory=dict)
    version: int = 1
    updated_at: Optional[datetime] = None
    updated_by: Optional[str] = None


# --- Push: device registration ---


class DevicePlatform(str, Enum):
    ios = "ios"
    android = "android"


class DeviceRegisterRequest(BaseModel):
    token: str = Field(min_length=1, max_length=512)
    platform: DevicePlatform


class DeviceRegisterResponse(BaseModel):
    registered: bool = True


# --- Admin: broadcast push ---


class BroadcastTarget(str, Enum):
    all = "all"
    uids = "uids"


class NotificationBroadcastRequest(BaseModel):
    title: str = Field(min_length=1, max_length=100)
    body: str = Field(min_length=1, max_length=500)
    sound: Optional[str] = Field(default=None, max_length=60)
    target: BroadcastTarget = BroadcastTarget.all
    uids: list[str] = Field(default_factory=list, max_length=5000)


class NotificationBroadcastResponse(BaseModel):
    broadcast_id: str
    enqueued: int


# --- Internal cron ---


class CronRunResponse(BaseModel):
    job: str
    summary: dict = Field(default_factory=dict)


# --- In-app notification inbox ---


class NotificationResponse(BaseModel):
    id: str
    type: str
    template_id: str
    title: str
    body: str
    data: dict = Field(default_factory=dict)
    read: bool = False
    created_at: datetime


class NotificationListResponse(BaseModel):
    items: list[NotificationResponse] = Field(default_factory=list)
    unread_count: int = 0


class NotificationUnreadCountResponse(BaseModel):
    unread_count: int = 0
