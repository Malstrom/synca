# Feature: Spark
**Version:** 1.0
**Last updated:** May 2026
**Status:** Draft
**Phase:** 1

---

## Overview

Spark is the core IRL (in-real-life) interaction mechanism of Synca. It allows two users
who are physically co-located to initiate a proximity-based session and receive a
real-time compatibility score derived exclusively from their passive `signals`.

A completed `Spark` is the strongest trust and compatibility signal in the system
because it requires two verified users in the same physical location at the same time.
No questionnaire or manual input is required — the fact that two people choose to
initiate a Spark together is itself a meaningful intent signal.

Spark is the prerequisite for creating a Match with `origin: :spark` and for joining
or creating any Circle.

Prerequisites:
- `users`, `profiles` (ref: `docs/features/profile-v1.md`)
- `signals` (ref: `docs/features/signals-v1.md`)
- `matches` (ref: `docs/features/matching-v1.md`)

---

## Step 1.0 — Proximity Spark (Bluetooth / QR)

**Phase:** 1
**Status:** Draft

### User Flow

```
User A opens "Start Spark"
        ↓
App broadcasts BLE signal (or displays QR code)
        ↓
User B scans / detects signal → receives invite
        ↓
Both users confirm presence on their own device
        ↓
Spark created  (status: :pending)
        ↓
ScoringJob (Solid Queue, `spark` queue) computes pairwise score
using both users' signals (health, music, travel)
        ↓
score >= spark minimum threshold (ref: docs/features/matching-v1.md)
  →  Match created  (origin: :spark)
  →  trust_score incremented for both users
  →  SparkReward issued per user
  →  Spark status: :completed
score < spark minimum threshold
  →  no Match created
  →  Spark status: :completed  (stored for analytics)
```

The compatibility score is **never shown as a raw number** to users.
It is translated into plain-language explanations
(e.g. "Your sleep schedules are well aligned").

Scoring is fully passive — no questions, no manual input. The intent signal
is the Spark initiation itself.

### DB Schema

New tables introduced by this step:

```sql
sparks
  id                   bigint PK
  initiator_id         bigint FK -> users NOT NULL
  receiver_id          bigint FK -> users NOT NULL
  status               string NOT NULL DEFAULT 'pending'
                       -- 'pending' | 'completed' | 'expired' | 'cancelled'
  discovery_method     string NOT NULL
                       -- 'bluetooth' | 'qr_code'
  session_code         string             -- 6-digit numeric code for QR flow
  qr_token             string             -- UUID token for deep-link QR flow
  compatibility_score  float              -- nil until scoring completes
  score_breakdown      jsonb              -- domain sub-scores (never shown raw to users)
  match_created        boolean NOT NULL DEFAULT false
  expires_at           datetime NOT NULL  -- session expires if neither confirms within 10 min
  completed_at         datetime
  created_at           datetime
  updated_at           datetime

spark_rewards
  id           bigint PK
  user_id      bigint FK -> users NOT NULL
  spark_id     bigint FK -> sparks NOT NULL
  reward_type  string NOT NULL   -- 'premium_week' | 'match_credit'
  status       string NOT NULL DEFAULT 'pending'  -- 'pending' | 'redeemed' | 'expired'
  valid_until  datetime
  created_at   datetime
```

For `matches` schema see `docs/features/matching-v1.md`.

### API Endpoints

| Method | Path | Auth required | Description |
|--------|------|---------------|-------------|
| POST | `/api/v1/sparks` | Yes | Initiator creates a new Spark; returns `session_code` + `qr_token` |
| PATCH | `/api/v1/sparks/:id/join` | Yes | Receiver confirms presence and joins via `session_code` or `qr_token` |
| POST | `/api/v1/sparks/:id/submit_answers` | Yes | Each participant submits answers; triggers ScoringJob when both have submitted |
| GET | `/api/v1/sparks/:id/result` | Yes | Polls scoring result; returns 202 while in progress, 200 with score + match on completion |
| GET | `/api/v1/sparks/:id` | Yes | Returns spark status and result |
| GET | `/api/v1/sparks` | Yes | Lists the current user's past sparks |
| GET | `/api/v1/spark_rewards` | Yes | Lists all rewards for the current user |

Ref: `docs/api/openapi.yaml`

Scoring is triggered server-side automatically once both users have confirmed
presence (`join`) and submitted answers. The client polls
`GET /api/v1/sparks/:id/result` or listens via Action Cable for the
`spark:scored` event.

### Premium Gating

None — Sparks are fully available to free users. This is by design:
the more Sparks happen, the richer the compatibility data for everyone.

**Rewards:**
- Free users who complete a Spark receive a `premium_week` trial.
- Premium users who complete a Spark receive a `match_credit`.

### Open Questions

- Bluetooth vs QR code: should both discovery methods be available in Step 1.0
  or should we ship QR only first (simpler, no BLE permission edge cases)?
- Session expiry window: 10 minutes is the suggested default — is this too short
  for noisy environments (concerts, gyms)?
- What happens if a user has no `signals` record yet (never connected Apple Health)?
  Should scoring fall back to a partial score (Preferences domain only) or should
  the Spark be blocked until signals are available?

---

## Step 2.0 — Group Spark

**Phase:** 2
**Status:** Planned

### User Flow

```
User A opens "Start Group Spark"
        ↓
App broadcasts BLE signal to multiple nearby users
        ↓
Users B, C, D... confirm presence and join
        ↓
Group Spark created  (status: :pending)
        ↓
ScoringJob computes pairwise score
for EVERY pair in the group using their signals
        ↓
For each pair with score >= spark minimum threshold:
  →  Match created  (origin: :spark)
  →  trust_score incremented for both users
For the group as a whole:
  →  Circle eligible if every required pair has a verified Spark
        ↓
Spark status: :completed
```

### DB Schema

Changes to existing tables from Step 1.0:

```sql
-- sparks: new column to distinguish duo vs group
sparks
  spark_type   string NOT NULL DEFAULT 'duo'  -- 'duo' | 'group' (new)
  receiver_id  bigint FK -> users              -- becomes nullable for group sparks
```

New table introduced by this step:

```sql
spark_participants
  id         bigint PK
  spark_id   bigint FK -> sparks NOT NULL
  user_id    bigint FK -> users NOT NULL
  confirmed_at datetime
  created_at   datetime
  UNIQUE (spark_id, user_id)
```

### API Endpoints

| Method | Path | Auth required | Description |
|--------|------|---------------|-------------|
| POST | `/api/v1/sparks` | Yes | Creates a duo or group Spark (type in body) |
| POST | `/api/v1/sparks/:id/participants` | Yes | User joins a group Spark |
| POST | `/api/v1/sparks/:id/submit_answers` | Yes | Participant submits answers |
| GET | `/api/v1/sparks/:id/result` | Yes | Polls per-pair scoring results |
| GET | `/api/v1/sparks/:id` | Yes | Returns spark status and per-pair results |
| GET | `/api/v1/sparks` | Yes | Lists the current user's past sparks |

Ref: `docs/api/openapi.yaml`

### Premium Gating

None — Group Sparks are free for all users.

### Open Questions

- Maximum group size for a Group Spark? (Suggested: up to 22 for event Circle
  compatibility, but UI may cap lower for usability.)
- Should the group initiator see a summary of all pairwise scores after completion,
  or only their own pairs?
- If some participants do not confirm presence before expiry, should partial scoring
  proceed for the pairs that did confirm?
