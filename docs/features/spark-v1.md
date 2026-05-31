# Feature: Spark
**Version:** 1.2
**Last updated:** May 2026
**Status:** Draft
**Phase:** 1

---

## Overview

Spark is the core IRL (in-real-life) interaction mechanism of Synca. It allows two users
who are physically co-located to initiate a proximity-based session and receive a
real-time compatibility score derived from their passive `signals` and their declared
preferences answered during the session.

A completed `Spark` is the strongest trust and compatibility signal in the system
because it requires two verified users in the same physical location at the same time.

Spark is the prerequisite for creating a Match with `origin: :spark` and for joining
or creating any Circle.

Spark owns the physical session lifecycle (discovery, join, expiry, questionnaire
submission). Compatibility scoring rules and match creation thresholds are defined
in `docs/features/matching-v1.md` and are referenced by Spark.

Prerequisites:
- `users`, `profiles` (ref: `docs/features/profile-v1.md`)
- `signals` (ref: `docs/features/signals-v1.md`)
- `declared_preferences` (ref: `docs/features/signals-v1.md — Step 0`)
- `matches` (ref: `docs/features/matching-v1.md`)

---

## Proximity Verification Strategy

Proximity verification evolves across phases. The goal is to balance **virality and
acquisition** in early phases with **trust and anti-abuse** as the user base grows.

| Phase | Method | Anti-abuse level | Notes |
|-------|--------|-----------------|-------|
| **1** | QR universal link, no proximity check | Low (intentional) | Virality over precision. Every join = a download. Token expiry limits zombie links. |
| **2** | Session code (PIN visible on initiator screen) | High | Receiver must physically see initiator's screen. No additional permissions needed. |
| **3** | BLE ambient discovery | High | Automatic, no QR needed. Enables passive "who's nearby with Synca open" discovery. |

> **Phase 1 rationale:** Spark abuse in early stages is acceptable and even desirable —
> every shared QR link is a potential new user. Proximity enforcement is deferred to
> Phase 2 when the user base justifies stricter trust rules.

The `session_code` field is already present in the schema for Phase 2 readiness.
BLE infrastructure is planned for Phase 3 as a premium ambient discovery layer.

---

## Step 1.0 — Proximity Spark (QR)

**Phase:** 1
**Status:** Draft

### User Flow

```
User A opens "Start Spark"
        ↓
App displays QR code (encodes universal link with qr_token)
        ↓
User B scans the QR
        ↓
If User B already has the app:
  → universal link opens Spark join flow directly
If User B does not have the app:
  → universal link redirects to App Store / Play Store
  → after install, deferred deep link restores qr_token
  → User B creates a guest account with email only
  → app resumes Spark join flow automatically
        ↓
Spark status: :pending (or :awaiting_receiver during install flow)
        ↓
Both users answer the Spark questionnaire on their own device
For guest receiver: questionnaire acts as the initial declared preferences setup
(ref: Spark Questionnaire section below)
        ↓
ScoringJob (Solid Queue, `spark` queue, high priority) triggers once both have submitted.
Computes pairwise score using both users' signals (health, music, travel)
and declared preference weights.
        ↓
score >= spark minimum threshold (ref: docs/features/matching-v1.md)
  → Match created (origin: :spark)
  → trust_score incremented for both users
  → SparkReward issued per user
  → Spark status: :completed
score < spark minimum threshold
  → no Match created
  → Spark status: :completed (stored for analytics)
```

The compatibility score is **never shown as a raw number** to users.
It is translated into plain-language explanations
(e.g. "Your sleep schedules are well aligned").

### Receiver without app

QR join must support the case where the receiving user does not have Synca installed.
The QR encodes a universal link containing the `qr_token` for the Spark session.

- If the app is installed, the universal link opens the Spark join flow directly.
- If the app is not installed, the universal link redirects to the App Store / Play Store.
- After installation, a deferred deep link restores the original `qr_token`.
- The receiver completes guest onboarding with email only (ref: `docs/features/profile-v1.md — Step 0`).
- No display name or photo is required for Spark guest join.
- Once guest onboarding is complete, the app resumes the pending Spark join flow automatically.
- Scanning the QR is the implicit proof of presence — no additional confirmation step required in Phase 1.

The `qr_token` is single-use: it is invalidated as soon as the first join is registered.
This prevents the same link from being used by multiple receivers.

### Spark Questionnaire

The Spark flow includes a short on-the-spot questionnaire to refine and update
the user's declared preferences in real time. This is not a manual input gate —
it is a lightweight calibration of the passive signals already on file.

For guest users joining via QR, the questionnaire also serves as their **initial
declared preferences setup**, replacing the standalone onboarding step they have not
completed yet. No prior declared preferences record is required to participate.

- Questions are a subset of the Declared Preferences questionnaire
  (ref: `docs/features/signals-v1.md — Step 0`).
- Each participant answers independently on their own device during the session.
- Answers are submitted via `POST /api/v1/sparks/:id/submit_answers`.
- The backend uses the answers as updated preference weights for this scoring round
  and persists any updated values to `declared_preferences`.
- Raw answers are not exposed to the other participant.
- ScoringJob is triggered automatically once **both** participants have submitted.

Scoring is primarily passive (signals drive the score); the questionnaire provides
the personalisation layer that makes the score meaningful for each specific user.

### DB Schema

New tables introduced by this step:

```sql
sparks
  id                   bigint PK
  initiator_id         bigint FK -> users NOT NULL
  receiver_id          bigint FK -> users NOT NULL
  status               string NOT NULL DEFAULT 'pending'
                       -- 'pending' | 'awaiting_receiver' | 'completed' | 'expired' | 'cancelled'
  discovery_method     string NOT NULL
                       -- 'bluetooth' | 'qr_code'
  session_code         string             -- reserved for Phase 2 PIN verification; not enforced in Phase 1
  qr_token             string             -- UUID token for deep-link QR flow; single-use
  compatibility_score  float              -- nil until scoring completes
  score_breakdown      jsonb              -- domain sub-scores (never shown raw to users)
  match_created        boolean NOT NULL DEFAULT false
  expires_at           datetime NOT NULL  -- default 30 min; covers app install + guest onboarding window
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
For `declared_preferences` schema see `docs/features/signals-v1.md`.

### API Endpoints

| Method | Path | Auth required | Description |
|--------|------|---------------|-------------|
| POST | `/api/v1/sparks` | Yes | Initiator creates a new Spark; returns `qr_token` (and `session_code` for future use) |
| PATCH | `/api/v1/sparks/:id/join` | Yes | Receiver joins via `qr_token`; invalidates token on first use |
| POST | `/api/v1/sparks/:id/submit_answers` | Yes | Each participant submits questionnaire; triggers high-priority ScoringJob when both have submitted |
| GET | `/api/v1/sparks/:id/result` | Yes | Polls scoring result; returns 202 while in progress, 200 with explanation + match on completion |
| GET | `/api/v1/sparks/:id` | Yes | Returns spark status and result |
| GET | `/api/v1/sparks` | Yes | Lists the current user's past sparks |
| GET | `/api/v1/spark_rewards` | Yes | Lists all rewards for the current user |

Ref: `docs/api/openapi.yaml`

Scoring is triggered server-side automatically once both users have joined and
submitted answers. The client polls `GET /api/v1/sparks/:id/result` or listens
via Action Cable for the `spark:scored` event.

#### Request body — `POST /api/v1/sparks/:id/submit_answers`

```json
{
  "answers": [
    { "question_key": "sleep_same_time_importance", "value": 4 },
    { "question_key": "sleep_temperature",           "value": "cool" },
    { "question_key": "daily_movement_preference",   "value": "3000_8000" },
    { "question_key": "rhythm_importance",           "value": 3 }
  ]
}
```

`question_key` values are the canonical keys defined in
`docs/features/signals-v1.md — Step 0 Questionnaire`.
The backend validates the keys and upserts `declared_preferences` for the submitting user.

### Premium Gating

None — Sparks are fully available to free users. This is by design:
the more Sparks happen, the richer the compatibility data for everyone.

**Rewards:**
- Free users who complete a Spark receive a `premium_week` trial.
- Premium users who complete a Spark receive a `match_credit`.

### Open Questions

- Should QR-only ship in Phase 1, deferring BLE entirely to Phase 3?
- What happens if a user has no `signals` record yet (never connected Apple Health)?
  Scoring falls back to declared preferences domain only — should this be made
  explicit in the score explanation shown to the user?

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
Group Spark created (status: :pending)
        ↓
All participants answer the Spark questionnaire on their own device
        ↓
ScoringJob computes pairwise score
for EVERY pair in the group using their signals
        ↓
For each pair with score >= spark minimum threshold:
  → Match created (origin: :spark)
  → trust_score incremented for both users
For the group as a whole:
  → Circle eligible if every required pair has a verified Spark
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
| POST | `/api/v1/sparks/:id/submit_answers` | Yes | Participant submits questionnaire answers |
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
