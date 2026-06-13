"""Canonical notification taxonomy (from the PRD).

Each entry defines a template's identity (type/subtype), default copy with
`{variables}`, the variables available for interpolation, a distinct sound id, and
any configurable parameter the trigger carries. Templates are seeded from this
catalog; admins then edit copy/params/enabled and the engine reads them at send time.

Document id convention: f"{type}.{subtype}".
"""

NOTIFICATION_CATALOG = [
    # Social Pull — real time, never batched.
    {"type": "social_pull", "subtype": "nudge_received", "sound": "nudge",
     "body": "Plans are forming. Are you in or not?", "variables": ["sender_name"], "params": {}},
    {"type": "social_pull", "subtype": "nudge_accepted", "sound": "nudge",
     "body": "{friend_name} is in. The plan is happening.", "variables": ["friend_name"], "params": {}},

    # Groups
    {"type": "groups", "subtype": "invite_received", "sound": "group",
     "body": "{inviter_name} invited you to {group_name}.", "variables": ["inviter_name", "group_name"], "params": {}},
    {"type": "groups", "subtype": "invite_accepted", "sound": "group",
     "body": "{member_name} joined {group_name}.", "variables": ["member_name", "group_name"], "params": {}},
    {"type": "groups", "subtype": "member_left", "sound": "group",
     "body": "{member_name} left {group_name}.", "variables": ["member_name", "group_name"], "params": {}},
    {"type": "groups", "subtype": "member_removed", "sound": "group",
     "body": "You were removed from {group_name}.", "variables": ["group_name"], "params": {}},
    {"type": "groups", "subtype": "group_nudge_received", "sound": "nudge",
     "body": "A new nudge in {group_name}. Are you in?", "variables": ["group_name"], "params": {}},
    {"type": "groups", "subtype": "reminder_received", "sound": "nudge",
     "body": "Reminder: the plan in {group_name} is still open.", "variables": ["group_name"], "params": {}},
    {"type": "groups", "subtype": "nudge_accepted", "sound": "group",
     "body": "{member_name} is in.", "variables": ["member_name"], "params": {}},
    {"type": "groups", "subtype": "nudge_declined", "sound": "group",
     "body": "{member_name} passed this time.", "variables": ["member_name"], "params": {}},
    {"type": "groups", "subtype": "nudge_expired", "sound": "group",
     "body": "The nudge in {group_name} expired.", "variables": ["group_name"], "params": {}},
    {"type": "groups", "subtype": "group_dissolved", "sound": "group",
     "body": "{group_name} was dissolved.", "variables": ["group_name"], "params": {}},

    # Map FOMO — fires on a new event within radius_km of the user's area.
    {"type": "map_fomo", "subtype": "new_event_nearby", "sound": "pop",
     "body": "Something just popped up near you.", "variables": ["event_title"],
     "params": {"radius_km": 15}},

    # Time Pressure
    {"type": "time_pressure", "subtype": "event_24h", "sound": "tick",
     "body": "{event_title} is tomorrow.", "variables": ["event_title"], "params": {"offset_hours": 24}},
    {"type": "time_pressure", "subtype": "event_2h", "sound": "tick",
     "body": "{event_title} starts in 2 hours.", "variables": ["event_title"], "params": {"offset_hours": 2}},
    {"type": "time_pressure", "subtype": "event_30m", "sound": "tick",
     "body": "{event_title} starts in 30 minutes.", "variables": ["event_title"], "params": {"offset_minutes": 30}},
    {"type": "time_pressure", "subtype": "quest_halfway", "sound": "tick",
     "body": "Halfway through. Your side quest is still open.", "variables": ["quest_title"], "params": {}},
    {"type": "time_pressure", "subtype": "quest_3h", "sound": "tick",
     "body": "3 hours left on your side quest.", "variables": ["quest_title"], "params": {"offset_hours": 3}},
    {"type": "time_pressure", "subtype": "nudge_reminder", "sound": "tick",
     "body": "You have {minutes} minutes to decide.", "variables": ["minutes"], "params": {}},

    # Event Updates — one notification per save, with a cooldown.
    {"type": "event_updates", "subtype": "event_edited", "sound": "update",
     "body": "{event_title} changed. Check the new details.", "variables": ["event_title"],
     "params": {"cooldown_minutes": 10}},
    {"type": "event_updates", "subtype": "event_cancelled", "sound": "update",
     "body": "{event_title} was cancelled.", "variables": ["event_title"], "params": {}},

    # Inactivity — scheduled cron, dormant users only.
    {"type": "inactivity", "subtype": "warm", "sound": "soft",
     "body": "Things happened. You missed them.", "variables": [], "params": {"after_days": 1}},
    {"type": "inactivity", "subtype": "cold", "sound": "soft",
     "body": "Your streak ends tonight.", "variables": [], "params": {"after_days_min": 2, "after_days_max": 3}},
    {"type": "inactivity", "subtype": "dormant", "sound": "soft",
     "body": "We will stop showing you what is happening nearby.", "variables": [], "params": {"after_days": 4}},
]


def template_id(type_: str, subtype: str) -> str:
    return f"{type_}.{subtype}"
