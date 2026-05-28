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

A completed `SparkSession` is the strongest trust and compatibility signal in the system
because it requires two verified users in the same physical location at the same time.
No questionnaire or manual input is required — the fact that two people choose to
initiate a Spark together is itself a meaningful intent signal.

Spark is the prerequisite for creating a Match with `origin: :spark` and for joining
or creating any Sync Room.

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
SparkSession created  (status: :pending)
        ↓
CompatibilityScoreService computes pairwise score
using both users' signals (health, music, travel)
        ↓
score >= 50  →  Match created  (origin: :spark)
             →  trust_score incremented for both users
             →  SparkSession status: :completed
score <  50  →  no Match created
             →  SparkSession status: :completed  (stored for analytics)
```

The compatibility score is **never shown as a raw number** to users.
It is translated into plain-language explanations
(e.g. "Your sleep schedules are well aligned").

Scoring is fully passive — no questions, no manual input. The intent signal
is the Spark initiation itself.

### DB Schema

```sql
users
  id              bigint PK
  email           string UNIQUE
  password_digest string
  created_at      datetime
  updated_at      datetime

profiles
  id                     bigint PK
  user_id                bigint FK -> users NOT NULL
  display_name           string
  bio                    text
  photos                 jsonb DEFAULT '[]'
  trust_score            float NOT NULL DEFAULT 50.0
  spark_verified         boolean NOT NULL DEFAULT false
  irl_verification_count integer NOT NULL DEFAULT 0
  premium                boolean NOT NULL DEFAULT false
  created_at             datetime
  updated_at             datetime

signals
  id                      bigint PK
  user_id                 bigint FK -> users NOT NULL UNIQUE
  -- Step 1.0: health
  sleep_duration_avg      float
  sleep_variability       float
  chronotype              string
  social_jetlag           float
  activity_minutes_avg    float
  rest_hr_avg             float
  step_count_avg          float
  peak_activity_window    string
  routine_stability_index float
  computed_at             datetime
  updated_at              datetime

spark_sessions
  id                   bigint PK
  initiator_id         bigint FK -> users NOT NULL
  receiver_id          bigint FK -> users NOT NULL
  status               string NOT NULL DEFAULT 'pending'
                       -- 'pending' | 'completed' | 'expired' | 'cancelled'
  discovery_method     string NOT NULL
                       -- 'bluetooth' | 'qr_code'
  compatibility_score  float             -- nil until scoring completes
  score_breakdown      jsonb             -- domain sub-scores (never shown raw to users)
  match_created        boolean NOT NULL DEFAULT false
  expires_at           datetime NOT NULL -- session expires if neither confirms within 10 min
  completed_at         datetime
  created_at           datetime
  updated_at           datetime

matches
  id                     bigint PK
  user_a_id              bigint FK -> users NOT NULL
  user_b_id              bigint FK -> users NOT NULL
  spark_session_id       bigint FK -> spark_sessions  -- nil for algorithm-origin matches
  origin                 integer NOT NULL DEFAULT 0   -- 0: spark | 1: algorithm
  algorithm_confidence   float                        -- nil for spark-origin matches
  compatibility_score    float NOT NULL
  status                 string NOT NULL DEFAULT 'active'
                         -- 'active' | 'drifted' | 'reconnected' | 'ended'
  created_at             datetime
  updated_at             datetime
  UNIQUE (user_a_id, user_b_id)
```

### API Endpoints

| Method | Path | Auth required | Description |
|--------|------|---------------|-------------|
| POST | `/api/v1/spark_sessions` | Yes | Initiator creates a new SparkSession |
| PATCH | `/api/v1/spark_sessions/:id/join` | Yes | Receiver confirms presence and joins |
| GET | `/api/v1/spark_sessions/:id` | Yes | Returns session status and result |
| GET | `/api/v1/spark_sessions` | Yes | Lists the current user's past sessions |

Ref: `docs/api/openapi.yaml`

Scoring is triggered server-side automatically once both users have confirmed
presence (`join`). The client polls `GET /api/v1/spark_sessions/:id` or listens
via Action Cable for the `spark_session:scored` event.

### Premium Gating

None — Spark sessions are fully available to free users. This is by design:
the more Spark sessions happen, the richer the compatibility data for everyone.

### Open Questions

- Bluetooth vs QR code: should both discovery methods be available in Step 1.0
  or should we ship QR only first (simpler, no BLE permission edge cases)?
- Session expiry window: 10 minutes is the suggested default — is this too short
  for noisy environments (concerts, gyms)?
- What happens if a user has no `signals` record yet (never connected Apple Health)?
  Should scoring fall back to a partial score (Preferences domain only) or should
  the SparkSession be blocked until signals are available?

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
GroupSparkSession created  (status: :pending)
        ↓
CompatibilityScoreService computes pairwise score
for EVERY pair in the group using their signals
        ↓
For each pair with score >= 50:
  →  Match created  (origin: :spark)
  →  trust_score incremented for both users
For the group as a whole:
  →  Sync Room eligible if every required pair has a verified Spark
        ↓
SparkSession status: :completed
```

### DB Schema

```sql
-- All Step 1.0 tables unchanged.

spark_sessions
  id                   bigint PK
  initiator_id         bigint FK -> users NOT NULL
  receiver_id          bigint FK -> users         -- nil for group sessions
  session_type         string NOT NULL DEFAULT 'duo'
                       -- 'duo' | 'group'
  status               string NOT NULL DEFAULT 'pending'
  discovery_method     string NOT NULL
  compatibility_score  float             -- nil for group sessions (per-pair scores used)
  score_breakdown      jsonb
  match_created        boolean NOT NULL DEFAULT false
  expires_at           datetime NOT NULL
  completed_at         datetime
  created_at           datetime
  updated_at           datetime

spark_session_participants
  id                bigint PK
  spark_session_id  bigint FK -> spark_sessions NOT NULL
  user_id           bigint FK -> users NOT NULL
  confirmed_at      datetime
  created_at        datetime
  UNIQUE (spark_session_id, user_id)

matches
  id                     bigint PK
  user_a_id              bigint FK -> users NOT NULL
  user_b_id              bigint FK -> users NOT NULL
  spark_session_id       bigint FK -> spark_sessions
  origin                 integer NOT NULL DEFAULT 0
  algorithm_confidence   float
  compatibility_score    float NOT NULL
  status                 string NOT NULL DEFAULT 'active'
  created_at             datetime
  updated_at             datetime
  UNIQUE (user_a_id, user_b_id)
```

### API Endpoints

| Method | Path | Auth required | Description |
|--------|------|---------------|-------------|
| POST | `/api/v1/spark_sessions` | Yes | Creates a duo or group SparkSession (type in body) |
| POST | `/api/v1/spark_sessions/:id/participants` | Yes | User joins a group session |
| GET | `/api/v1/spark_sessions/:id` | Yes | Returns session status and per-pair results |
| GET | `/api/v1/spark_sessions` | Yes | Lists the current user's past sessions |

Ref: `docs/api/openapi.yaml`

### Premium Gating

None — Group Spark sessions are free for all users.

### Open Questions

- Maximum group size for a Group Spark session? (Suggested: up to 22 for event_room
  compatibility, but UI may cap lower for usability.)
- Should the group initiator see a summary of all pairwise scores after completion,
  or only their own pairs?
- If some participants do not confirm presence before expiry, should partial scoring
  proceed for the pairs that did confirm?
