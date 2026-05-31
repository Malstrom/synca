# Feature: Notifications
**Version:** 1.0
**Last updated:** May 2026
**Status:** Draft
**Phase:** 1
**User flows:** `docs/product/phases/` — no flows in Phase 0; flows will be added in phase-1.md

---

## Overview

Notifications is the delivery layer for all async user-facing events in Synca.
It covers push notifications (APNs on iOS, FCM on Android), in-app notification
center, email transactional messages, and Telegram (opt-in, future phase).

Raw events are emitted by other features (Spark, Matching, Circles, Moments, Trust).
This feature owns the delivery infrastructure, device token management, user
preferences, and the `notifications` table.

**Notifications does not own business logic** — it only delivers events that other
features produce. Each trigger is documented with a `Ref:` to the feature that
owns the originating event.

Prerequisites:
- `users`, `profiles` (ref: `docs/features/profile-v1.md`)
- `sparks` (ref: `docs/features/spark-v1.md`)
- `matches` (ref: `docs/features/matching-v1.md`)
- `circles`, `circle_messages` (ref: `docs/features/circles-v1.md`)
- `moments` (ref: `docs/features/moments-v1.md`)

---

## Notification Triggers

All triggers by phase. Each row is a `notification_type` value
in the `notifications` table.

### Phase 1

| `notification_type` | Event | Channels | Ref |
|---|---|---|---|
| `spark_scored` | Spark scoring completed — match created or not | Push + In-app + Telegram | spark-v1.md § Step 1.0 |
| `spark_expired` | Spark session expired before both users submitted | Push + In-app | spark-v1.md § Step 1.0 |
| `match_created` | New match created (any origin) | Push + In-app + Telegram | matching-v1.md § Step 1.0 |
| `circle_message` | New message received in a Circle | Push + In-app | circles-v1.md § Step 1.0 |
| `account_activation` | Magic link to activate guest account | Email only | profile-v1.md § Step 0 |
| `password_reset` | Password reset link | Email only | profile-v1.md § Step 1.1 |
| `signals_stale` | Health data not updated in 7+ days | Push + In-app | signals-v1.md § Step 1.0 |
| `match_drifted` | Match transitioned to `drifted` status | Push + In-app + Telegram | matching-v1.md § Match Lifecycle |

> `circle_message` is excluded from Telegram intentionally: the conversation
> lives inside the app — a Telegram notification would pull the user out of context.

### Phase 3

| `notification_type` | Event | Channels | Ref |
|---|---|---|---|
| `moment_received` | User B receives a Moment proposal | Push + In-app + Telegram | moments-v1.md § Step 1.0 |
| `moment_accepted` | User A's proposal was accepted | Push + In-app + Telegram | moments-v1.md § Step 1.0 |
| `moment_declined` | User A's proposal was declined | Push + In-app | moments-v1.md § Step 1.0 |
| `moment_counter` | Counter-proposal received | Push + In-app + Telegram | moments-v1.md § Step 1.0 |
| `moment_reminder` | Reminder 2h before scheduled Moment | Push + In-app + Telegram | moments-v1.md § Step 1.0 |
| `moment_rate_prompt` | Prompt to rate after scheduled date/time | Push + In-app | moments-v1.md § Step 1.0 |
| `moment_no_show` | No-show reported against current user | Push + In-app | moments-v1.md § Step 1.0 |

---

## DB Schema

```sql
device_tokens
  id          bigint PK
  user_id     bigint FK -> users NOT NULL
  token       string NOT NULL UNIQUE   -- APNs/FCM token or Telegram chat_id
  platform    string NOT NULL          -- 'ios' | 'android' | 'telegram'
  active      boolean NOT NULL DEFAULT true
  created_at  datetime
  updated_at  datetime

notification_preferences
  id                    bigint PK
  user_id               bigint FK -> users NOT NULL UNIQUE
  push_enabled          boolean NOT NULL DEFAULT true
  email_enabled         boolean NOT NULL DEFAULT true
  telegram_enabled      boolean NOT NULL DEFAULT false  -- opt-in only
  telegram_chat_id      string            -- set when user connects the Telegram bot
  -- per-type overrides (false = muted for that type)
  spark_scored          boolean NOT NULL DEFAULT true
  match_created         boolean NOT NULL DEFAULT true
  circle_message        boolean NOT NULL DEFAULT true
  moment_received       boolean NOT NULL DEFAULT true
  moment_reminder       boolean NOT NULL DEFAULT true
  signals_stale         boolean NOT NULL DEFAULT true
  created_at            datetime
  updated_at            datetime

notifications
  id                    bigint PK
  user_id               bigint FK -> users NOT NULL
  notification_type     string NOT NULL   -- see trigger table above
  title                 string NOT NULL
  body                  string NOT NULL
  read_at               datetime          -- nil = unread
  payload               jsonb             -- deep link target + contextual data
  created_at            datetime
```

### Payload convention

`payload` carries the deep link target and contextual IDs needed
to open the correct screen:

```json
{ "screen": "spark_result", "spark_id": 42 }
{ "screen": "circle",       "circle_id": 7 }
{ "screen": "moment",       "moment_id": 15 }
{ "screen": "match",        "match_id": 3 }
```

---

## Delivery Architecture

```
Feature emits event (e.g. ScoringJob completes)
        ↓
NotificationJob enqueued (Solid Queue, `notifications` queue)
        ↓
NotificationJob#perform
  → loads user notification_preferences
  → if push_enabled AND type not muted:
      APNs (iOS) or FCM (Android) push sent via device_tokens
  → notification record created in `notifications` table (in-app center)
  → if channel includes email:
      TransactionalMailer enqueued separately
  → if telegram_enabled AND type supports Telegram:
      TelegramNotifier enqueued separately (future phase)
```

`NotificationJob` is always async — no feature should wait on delivery.
Delivery failures are retried up to 3 times with exponential backoff
(Solid Queue default).

### circle_message push suppression

For `circle_message` events, `NotificationJob` suppresses push delivery when
the user has an active real-time Action Cable subscription open for that specific
Circle (i.e. the user already sees the message in real time). If the subscription
state is uncertain or unavailable, the push is sent as normal to avoid missed messages.

### APNs / FCM token rotation

`NotificationJob` parses the provider response after every push delivery attempt.
When APNs or FCM returns an error indicating a token is invalid, unregistered,
or permanently unreachable, the corresponding `device_tokens.active` flag is set
to `false`. Inactive tokens are skipped on subsequent delivery attempts, keeping
the table clean without requiring manual cleanup.

---

## API Endpoints

| Method | Path | Auth required | Description |
|--------|------|---------------|-------------|
| GET | `/api/v1/notifications` | Yes | Lists in-app notifications for current user (paginated, unread first) |
| PATCH | `/api/v1/notifications/:id/read` | Yes | Marks a notification as read |
| PATCH | `/api/v1/notifications/read_all` | Yes | Marks all notifications as read |
| POST | `/api/v1/device_tokens` | Yes | Registers a device token (APNs / FCM / Telegram chat_id) |
| DELETE | `/api/v1/device_tokens/:token` | Yes | Deregisters a device token on logout |
| GET | `/api/v1/notification_preferences` | Yes | Returns current user's notification preferences |
| PATCH | `/api/v1/notification_preferences` | Yes | Updates push/email/telegram toggles and per-type mutes |

Ref: `docs/api/openapi.yaml`

---

## Premium Gating

None — push and in-app notifications are available on all tiers.
Telegram notifications are opt-in for all tiers (user must connect the bot).

---

### Open Questions

See [docs/product/decisions.md](../product/decisions.md) — filter by `source: docs/features/notifications-v1.md`.
