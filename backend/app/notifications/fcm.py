"""Thin wrapper over Firebase Admin Messaging (FCM) for iOS (APNs) + Android.

Isolates the rest of the system from the SDK so the dispatcher can reason in terms of
"sent / retry / prune these tokens" instead of FCM specifics. Reuses the Firebase app
already initialised in app.firebase — no extra credentials.
"""

from __future__ import annotations

import logging
from dataclasses import dataclass, field

from firebase_admin import messaging

from app.config import NUDGE_CUSTOM_SOUNDS

# Sound ids bundled in the app as .caf for iOS push (brief 7.4).
_CUSTOM_NUDGE_SOUNDS = {"n", "exp"}

logger = logging.getLogger(__name__)


@dataclass
class SendResult:
    success_count: int = 0
    failure_count: int = 0
    # Tokens FCM reported as permanently invalid — prune these from the device registry.
    invalid_tokens: list[str] = field(default_factory=list)
    # True if at least one failure was transient (worth retrying the whole send).
    retryable: bool = False


# Error types that mean "this token is dead, stop sending to it".
_INVALID_TOKEN_ERRORS = (
    messaging.UnregisteredError,
    messaging.SenderIdMismatchError,
)


def _ios_nudge_sound(sound: str | None) -> str:
    """iOS plays bundled push sounds by file name (brief 7.4: N, EXP as .caf)."""
    if NUDGE_CUSTOM_SOUNDS and sound in _CUSTOM_NUDGE_SOUNDS:
        return f"{sound}.caf"
    return "default"


def build_message(
    token: str,
    *,
    title: str | None,
    body: str,
    data: dict | None = None,
    sound: str | None = None,
    android_data_only: bool = False,
) -> messaging.Message:
    """Build a single-token message with sane iOS + Android defaults.

    `android_data_only` (V3 live nudge notifications, brief 7.3): Android gets a
    data-only message and the app draws the notification itself (countdown bar);
    the copy travels as `n_title`/`n_body`. iOS still gets a normal alert.
    """
    # FCM data payload values must be strings.
    str_data = {k: str(v) for k, v in (data or {}).items()}
    if android_data_only:
        return messaging.Message(
            token=token,
            data={**str_data, "n_title": title or "", "n_body": body},
            android=messaging.AndroidConfig(priority="high"),
            apns=messaging.APNSConfig(
                payload=messaging.APNSPayload(
                    aps=messaging.Aps(
                        alert=messaging.ApsAlert(title=title, body=body),
                        sound=_ios_nudge_sound(sound),
                    ),
                ),
            ),
        )
    return messaging.Message(
        token=token,
        notification=messaging.Notification(title=title, body=body),
        data=str_data,
        android=messaging.AndroidConfig(
            priority="high",
            notification=messaging.AndroidNotification(sound=sound or "default"),
        ),
        apns=messaging.APNSConfig(
            payload=messaging.APNSPayload(
                aps=messaging.Aps(sound=sound or "default"),
            ),
        ),
    )


def send_to_tokens(
    tokens: list[str],
    *,
    title: str | None,
    body: str,
    data: dict | None = None,
    sound: str | None = None,
    android_data_only: bool = False,
) -> SendResult:
    """Send the same notification to many tokens, classifying per-token outcomes.

    Never raises: any unexpected error is treated as a fully-retryable failure so the
    dispatcher can decide whether to retry. This keeps a single bad token or transient
    FCM blip from taking down a whole dispatch batch.
    """
    result = SendResult()
    tokens = [t for t in tokens if t]
    if not tokens:
        return result

    messages = [
        build_message(t, title=title, body=body, data=data, sound=sound, android_data_only=android_data_only)
        for t in tokens
    ]
    try:
        batch = messaging.send_each(messages)
    except Exception as exc:  # noqa: BLE001 — never let FCM internals escape.
        logger.warning("FCM send_each failed entirely: %s", exc)
        return SendResult(failure_count=len(tokens), retryable=True)

    for token, resp in zip(tokens, batch.responses):
        if resp.success:
            result.success_count += 1
            continue
        result.failure_count += 1
        exc = resp.exception
        if isinstance(exc, _INVALID_TOKEN_ERRORS):
            result.invalid_tokens.append(token)
        else:
            # Quota, unavailable, internal, network — transient, worth a retry.
            result.retryable = True
            logger.info("FCM transient failure for token: %s", exc)
    return result
