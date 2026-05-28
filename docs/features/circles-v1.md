# Feature: Circles
**Version:** 1.0
**Last updated:** May 2026
**Status:** Draft
**Phase:** 5

> **Canonical name:** `Circles`.
> All code, API paths, DB tables, and documentation must use `circles` / `Circles`.
> The term **"Sync Rooms"** is **deprecated** and must not appear anywhere in code,
> comments, migrations, UI copy, or documentation.

---

## Overview

Circles are conversational spaces that exist only when a verified physical
compatibility graph exists between all members. They are the digital continuation
of a real-world Spark encounter — not a generic group chat.

> A Circle is proof that the people inside it have actually met and been compatible.

Three types exist, differentiated by size and admission rules. The `duo` type is
the default channel for every match: every accepted match creates a Circle of
type `duo` under the hood.

-- ref: docs/features/spark-v1.md
-- ref: docs/features/matching-v1.md

---

## Circle Types

| Type | Members | Admission rule | Use case |
|------|---------|----------------|----------|
| `duo` | 2 | 1 confirmed Spark between the two members | Match chat |
| `small_group` | 3–8 | Full graph: every pair ≥1 confirmed Spark | Friend group, aperitivo |
| `event` | 9–22 | Every member ≥1 confirmed Spark with the creator | Football, escape room, padel |

---

## Step 1.0 — Duo Circle (Match Chat)

**Phase:** 5
**Status:** Draft

### User Flow

1. A match is confirmed (algorithm or Spark origin).
2. The backend automatically creates a Circle of type `duo` for the two profiles.
3. Both users can open the Circle and exchange messages in real time via
   Action Cable.
4. The Circle persists as long as the match is active.

### DB Schema

```sql
-- Canonical table names: circles, circle_memberships, circle_messages
circles
  id           bigint PK
  circle_type  string NOT NULL   -- 'duo' | 'small_group' | 'event'
  created_by   bigint FK -> profiles NOT NULL
  name         string            -- required for small_group and event; null for duo
  scheduled_at datetime          -- optional, relevant for event type
  created_at   datetime
  updated_at   datetime

circle_memberships
  id         bigint PK
  circle_id  bigint FK -> circles NOT NULL
  profile_id bigint FK -> profiles NOT NULL
  spark_id   bigint FK -> sparks  -- proof of physical encounter; null for duo on algorithm matches
  joined_at  datetime
  UNIQUE (circle_id, profile_id)

circle_messages
  id         bigint PK
  circle_id  bigint FK -> circles NOT NULL
  sender_id  bigint FK -> profiles NOT NULL
  body       text NOT NULL
  read_at    datetime
  created_at datetime
```

-- ref: docs/features/spark-v1.md (sparks table)

### API Endpoints

| Method | Path | Auth required | Description |
|--------|------|---------------|-------------|
| GET | `/api/v1/circles` | Yes | Lists own circles |
| GET | `/api/v1/circles/:id` | Yes | Returns circle details and members |
| GET | `/api/v1/circles/:id/messages` | Yes | Returns paginated messages |
| POST | `/api/v1/circles/:id/messages` | Yes | Sends a message |

Real-time messaging is handled by Action Cable (`CircleChannel`), not polling.

Ref: `docs/api/openapi.yaml`

### Premium Gating

`duo` circles are available on all tiers.

### Open Questions

- Should duo circles be created automatically on match confirmation, or on first
  user action (opening the chat)?
- Message retention policy: how long are messages stored?

---

## Step 2.0 — Small Group + Event Circles

**Phase:** 5
**Status:** Planned

### Admission Rules

**small_group:** every pair of members must have ≥1 confirmed Spark.
```ruby
# For every combination (profile_a, profile_b) in members:
Spark.confirmed_between(profile_a, profile_b).exists?
```
If a pair is missing a Spark, the API returns `422` with a structured payload
identifying the missing pairs. The creator can share a Spark Invite Link
(a deep link that pre-configures a Spark between two users for their next
physical encounter).

**event:** every new member must have ≥1 confirmed Spark with the circle creator.
```ruby
Spark.confirmed_between(circle.created_by, new_member).exists?
```
The creator acts as social guarantor of the group.

### API Endpoints

| Method | Path | Auth required | Description |
|--------|------|---------------|-------------|
| POST | `/api/v1/circles` | Yes | Creates a small_group or event circle |
| POST | `/api/v1/circles/:id/members` | Yes | Adds a member (admission rule enforced) |
| DELETE | `/api/v1/circles/:id/members/:profile_id` | Yes | Removes a member |
| POST | `/api/v1/circles/:id/invite` | Yes | Generates a Spark Invite Link |

### Premium Gating

| Feature | Free | Premium |
|---------|------|---------|
| Duo circle | ✅ | ✅ |
| Small group circle | 1 active | Unlimited |
| Event circle | ❌ | ✅ |
| Spark Invite Link | ❌ | ✅ |

### Open Questions

- Maximum lifetime of an event circle (auto-archive after `scheduled_at`?).
- Notification strategy for new messages in backgrounded circles.
- Should `event` circles require a `scheduled_at` field at creation time?
