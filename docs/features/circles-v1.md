# Feature: Circles
**Version:** 1.0
**Last updated:** May 2026
**Status:** Draft
**Phase:** 1
**User flows:** `docs/product/phases/` — no flows in Phase 0; flows will be added in phase-1.md

> **Phase note:**
> - `duo` circles are created automatically for every match, from Phase 0/1 (Validation MVP / iOS MVP).
> - `small_group` and `event` circles are introduced in Phase 4 of the roadmap.
> - Ref: `docs/product/roadmap.md`.

---

## Overview

Circles are conversational and coordination spaces that exist only when a verified
physical compatibility exists between all members. A Circle is not a generic group
chat — it is proof that the people inside it have actually met and been compatible.

The term **"Sync Room" is deprecated** and does not appear anywhere in the codebase
or documentation. The canonical name is **Circle** (table: `circles`,
channel: `CircleChannel`).

Prerequisites:
- `users`, `profiles` (ref: `docs/features/profile-v1.md`)
- `matches`, `sparks` (ref: `docs/features/matching-v1.md`, `docs/features/spark-v1.md`)

---

## Step 1.0 — Duo Circle

**Phase:** 1 (created automatically on every match — available from MVP)
**Status:** Draft

### Purpose

The Duo Circle is the standard 1:1 communication space between two matched users.
It is created automatically when a `Match` record is created, regardless of origin
(`:spark` or `:algorithm`).

For algorithm-origin matches, the Duo Circle is created on match creation with
`spark_id: nil` in `circle_memberships`. It is expected (but not required) that
both users complete a Spark at some point to strengthen the trust signal.

### Admission Rules

| Circle type | Members | Admission rule |
|------------|---------|----------------|
| `duo` | 2 | Created automatically on match confirmation. 1 confirmed Spark required for Spark-origin; nil for algorithm-origin. |
| `small_group` | 3–8 | Every pair of members must have ≥1 confirmed Spark (full graph). Phase 4+. |
| `event` | 9–22 | Every member must have ≥1 confirmed Spark with the circle creator. Phase 4+. |

### Match → Circle Creation Flow

```
Match created (origin: :spark or :algorithm)
        ↓
circle = Circle.create!(circle_type: :duo, created_by: match.user_a.profile)
        ↓
CircleMembership.create!(circle: circle, profile: match.user_a.profile, spark_id: match.spark_id)
CircleMembership.create!(circle: circle, profile: match.user_b.profile, spark_id: match.spark_id)
        ↓
Both users are notified and the Circle is immediately available for messaging
```

> Note: `circles.created_by` and `circle_memberships.profile_id` reference `profiles`.
> Match records use `user_a_id` / `user_b_id` referencing `users`.
> The creation flow resolves this via `match.user_a.profile` / `match.user_b.profile`.
> Ref: `docs/features/matching-v1.md`, `docs/features/profile-v1.md`.

### DB Schema

```sql
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
  spark_id   bigint FK -> sparks  -- proof of physical encounter; null for algorithm-origin matches
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

### API Endpoints

| Method | Path | Auth required | Description |
|--------|------|---------------|-------------|
| GET | `/api/v1/circles` | Yes | Lists all circles for the current user |
| GET | `/api/v1/circles/:id` | Yes | Returns a specific circle with members and messages |
| POST | `/api/v1/circles/:id/messages` | Yes | Sends a message in the circle |
| GET | `/api/v1/circles/:id/messages` | Yes | Lists messages in a circle (paginated) |

Real-time delivery: `CircleChannel` via Action Cable.

Ref: `docs/api/openapi.yaml`

---

## Step 2.0 — Small Group and Event Circles

**Phase:** 4
**Status:** Planned

### Changes from Step 1.0

- `circle_type: :small_group` (3–8 members): full Spark graph required — every pair of members must have ≥1 confirmed Spark.
- `circle_type: :event` (9–22 members): hub-and-spoke admission — every member must have ≥1 confirmed Spark with the circle creator.
- New endpoint: `POST /api/v1/circles` — allows manual creation of small_group and event circles by users with sufficient Spark history.
- Group Moment proposals (ref: `docs/features/moments-v1.md`) become available for small_group and event circles.

No schema changes beyond those introduced in Step 1.0.

---

### Open Questions

See [docs/product/decisions.md](../product/decisions.md) — filter by `source: docs/features/circles-v1.md`.
