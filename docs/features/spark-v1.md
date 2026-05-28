# Feature: Spark
**Version:** 1.0
**Last updated:** May 2026
**Status:** Draft
**Phase:** 1

---

## Overview

Spark is the core IRL (in-real-life) interaction mechanism of Synca. It allows two users
who are physically co-located to initiate a proximity-based session, answer a short
micro-test together, and receive a real-time compatibility score.

A completed `SparkSession` is the strongest trust and compatibility signal in the system
because it requires two verified users in the same physical location at the same time.
It is the prerequisite for creating a Match with `origin: :spark` and for joining or
creating any Sync Room.

Spark answers (micro-test responses) are **discarded immediately** after score computation
and are never persisted long-term.

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
Micro-test: both users answer 3 quick questions independently
        ↓
CompatibilityScoreService computes pairwise score
using signals (health, music, travel) + micro-test answers
        ↓
score >= 50  →  Match created  (origin: :spark)
             →  trust_score incremented for both users
             →  SparkSession status: :completed
score <  50  →  no Match created
             →  SparkSession status: :completed  (stored for analytics)
        ↓
Micro-test answers discarded immediately
```

The compatibility score is **never shown as a raw number** to users.
It is translated into plain-language explanations
(e.g. "Your sleep schedules are well aligned").

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
  expires_at           datetime NOT NULL -- session expires if not completed within 10 min
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
| PATCH | `/api/v1/spark_sessions/:id/join` | Yes | Receiver joins the session |
| PATCH | `/api/v1/spark_sessions/:id/submit` | Yes | User submits micro-test answers |
| GET | `/api/v1/spark_sessions/:id` | Yes | Returns session status and result |
| GET | `/api/v1/spark_sessions` | Yes | Lists the current user's past sessions |

Ref: `docs/api/openapi.yaml`

Scoring is triggered server-side automatically once both users have submitted
their micro-test answers. The client polls `GET /api/v1/spark_sessions/:id`
or listens via Action Cable for the `spark_session:scored` event.

### Premium Gating

None — Spark sessions are fully available to free users. This is by design:
the more Spark sessions happen, the richer the compatibility data for everyone.

### Open Questions

- Bluetooth vs QR code: should both discovery methods be available in Step 1.0
  or should we ship QR only first (simpler, no BLE permission edge cases)?
- Session expiry window: 10 minutes is the suggested default — is this too short
  for noisy environments (concerts, gyms)?
- Micro-test question set: how many questions (suggested: 3) and who owns the
  question bank? Should questions be randomized per session?
- What happens if only one user submits answers before the session expires?
  Is a partial score computed or is the session voided?

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
Users B, C, D... accept the invite
        ↓
GroupSparkSession created  (status: :pending)
        ↓
Each user completes the micro-test independently
        ↓
CompatibilityScoreService computes pairwise score
for EVERY pair in the group
        ↓
For each pair with score >= 50:
  →  Match created  (origin: :spark)
  →  trust_score incremented for both users
For the group as a whole:
  →  Sync Room eligible if every pair has a verified Spark
        ↓
Micro-test answers discarded immediately
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
  answers_submitted boolean NOT NULL DEFAULT false
  submitted_at      datetime
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
| PATCH | `/api/v1/spark_sessions/:id/submit` | Yes | User submits micro-test answers |
| GET | `/api/v1/spark_sessions/:id` | Yes | Returns session status and per-pair results |
| GET | `/api/v1/spark_sessions` | Yes | Lists the current user's past sessions |

Ref: `docs/api/openapi.yaml`

### Premium Gating

None — Group Spark sessions are free for all users. Individual Match creation
from group sessions follows standard Match premium rules.

### Open Questions

- Maximum group size for a Group Spark session? (Suggested: up to 22 for event_room
  compatibility, but UI may cap lower for usability.)
- Should the group initiator see a summary of all pairwise scores after completion,
  or only their own pairs?
- If some participants do not submit answers before expiry, should partial scoring
  proceed for the pairs that did complete?
