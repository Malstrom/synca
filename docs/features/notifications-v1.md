# Feature: Notifications
**Version:** 2.0
**Last updated:** May 2026
**Status:** Draft
**Phase:** 1

---

## Overview

Notifications is the delivery layer for all async user-facing events in Synca.
It covers push notifications (APNs on iOS, FCM on Android), in-app notification
center, email transactional messages, and Telegram (opt-in, future phase).

Raw events are emitted by other features. This feature owns the delivery
infrastructure, device token management, user preferences, and the `notifications` table.

**Notifications does not own business logic** — it only delivers events that other
features produce. Each trigger references the feature that owns the originating event.

Prerequisites: `users`, `profiles` (profile-v1.md) · `sparks` (spark-v1.md) · `matches` (matching-v1.md) · `circles` (circles-v1.md) · `moments` (moments-v1.md).

---

## Steps

| Step | Phase | Status | Description |
|---|---|---|---|
| 1.0 — Push + In-app + Email | 1 | Draft | Core delivery infrastructure |
| 2.0 — Telegram | Future | Planned | Opt-in Telegram bot notifications |

---

## Business Rules

### Notification triggers

**Phase 1:**

| `notification_type` | Event | Channels | Ref |
|---|---|---|---|
| `spark_scored` | Spark scoring completed | Push + In-app + Telegram | spark-v1.md § Step 1.0 |
| `spark_expired` | Spark expired before both submitted | Push + In-app | spark-v1.md § Step 1.0 |
| `match_created` | New match (any origin) | Push + In-app + Telegram | matching-v1.md § Step 1.0 |
| `circle_message` | New message in a Circle | Push + In-app | circles-v1.md § Step 1.0 |
| `account_activation` | Magic link to activate guest | Email only | profile-v1.md § Step 0 |
| `password_reset` | Password reset link | Email only | profile-v1.md § Step 1.1 |
| `signals_stale` | Health data not updated in 7+ days | Push + In-app | signals-v1.md § Step 1.0 |
| `match_drifted` | Match transitioned to `drifted` | Push + In-app + Telegram | matching-v1.md § Match Lifecycle |

> `circle_message` is excluded from Telegram intentionally: the conversation
> lives inside the app — a Telegram notification would pull the user out of context.

**Phase 3:**

| `notification_type` | Event | Channels | Ref |
|---|---|---|---|
| `moment_received` | Moment proposal received | Push + In-app + Telegram | moments-v1.md § Step 1.0 |
| `moment_accepted` | Proposal accepted | Push + In-app + Telegram | moments-v1.md § Step 1.0 |
| `moment_declined` | Proposal declined | Push + In-app | moments-v1.md § Step 1.0 |
| `moment_counter` | Counter-proposal received | Push + In-app + Telegram | moments-v1.md § Step 1.0 |
| `moment_reminder` | Reminder 2h before scheduled Moment | Push + In-app + Telegram | moments-v1.md § Step 1.0 |
| `moment_rate_prompt` | Prompt to rate after date | Push + In-app | moments-v1.md § Step 1.0 |
| `moment_no_show` | No-show reported against current user | Push + In-app | moments-v1.md § Step 1.0 |

### Delivery rules
- `NotificationJob` is always async — no feature should wait on delivery.
- Delivery failures are retried up to 3 times with exponential backoff.
- For `circle_message` events, push delivery is suppressed when the user has
  an active Action Cable subscription for that Circle (user already sees the message).
- When APNs or FCM returns an invalid token error, `device_tokens.active` is set
  to `false` automatically.

### Delivery architecture
```
Feature emits event
  ↓
NotificationJob enqueued (Solid Queue, `notifications` queue)
  ↓
NotificationJob#perform
  → loads notification_preferences
  → if push_enabled AND type not muted: APNs or FCM push
  → notification record created in `notifications` (in-app center)
  → if channel includes email: TransactionalMailer enqueued
  → if telegram_enabled AND type supports Telegram: TelegramNotifier enqueued
```

---

## References

- DB Schema → [docs/architecture/db-schema.md § Notifications](../architecture/db-schema.md#notifications)
- API → `docs/api/openapi.yaml`
- Rails Model → [docs/conventions/backend.md § Domain Model](../conventions/backend.md#domain-model-rails-associations)
- Monetization → [docs/product/monetization.md](../product/monetization.md)

---

## Open Questions

See [docs/product/decisions.md](../product/decisions.md) — filter by `source: docs/features/notifications-v1.md`.
