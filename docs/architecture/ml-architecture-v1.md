# ML Architecture — Synca

**Version:** 1.0  
**Status:** Approved for implementation in V2 (async matching phase)  
**Owner:** Engineering  
**Last updated:** 2026-05-31

---

## 1. Purpose

This document describes how Machine Learning will be integrated into the Synca
architecture. It is intended as the reference spec for any ML engineer or
external specialist working on Synca's recommendation system.

It covers:
- When and why ML is introduced
- Architectural pattern chosen and motivation
- Data flow and system boundaries
- Feature design and data contract
- What ML must never access (privacy constraints)
- Implementation roadmap

---

## 2. Context and Motivation

### 2.1 Current state (V1 — rule-based)

In V1, compatibility scoring is computed by a deterministic rule-based engine
inside the Rails API (`CompatibilityScoreService`). It produces a score (0–100)
from declared preferences, health signals, and spark data.

This is intentional for MVP: no user behavior data exists yet to train a model,
and a rule-based engine is transparent, testable, and fast to iterate on.

Refs:
- `docs/features/matching-v1.md`
- `docs/features/signals-v1.md`

### 2.2 Why introduce ML

Once async matching is live and user behavior data accumulates (likes, skips,
first messages, moment completions, retention), the rule-based engine becomes
a ceiling. ML can:

- Learn which signal combinations actually predict mutual interest
- Rank candidates by estimated match quality, not just compatibility score
- Personalize ranking per user based on their individual behavioral history
- Detect anomalous behavior patterns for trust/anti-fake purposes

ML is not introduced earlier because:

- Without behavioral outcome data (labels), there is nothing to train on
- A model trained on synthetic or insufficient data performs worse than rules
- Async matching is the natural trigger: it is exactly the moment Rails must
  decide "who to show to whom" at scale, which is the core ML problem

### 2.3 What ML will not do

ML will not:
- Replace hard business rules (distance filters, age/gender preferences,
  blocked users, privacy limits) — these stay in Rails
- Access raw HealthKit / Health Connect samples (see Section 4)
- Make decisions without a Rails layer validating and serving results
- Run synchronously inside a user-facing HTTP request

---

## 3. Chosen Architecture — Async Pre-computation

### 3.1 Pattern

ML is integrated as an **independent service** called asynchronously by Rails
via Solid Queue background jobs. Results are pre-computed and stored in the
Rails database. The app always reads from a pre-computed table — never waits
for ML inference at request time.

### 3.2 System diagram

```text
iOS / Android
     │
     │  (aggregated health metrics only — no raw samples)
     ▼
Rails API ──────────────────────── PostgreSQL (main DB)
     │                                    │
     │  Solid Queue Job                   │
     │  (MlMatchScoringJob)               │
     ▼                                    │
ML Service  ◄── reads feature view ───────┘
(Python)
     │
     │  writes ranked scores
     ▼
PostgreSQL: ml_match_scores table
     │
Rails reads ml_match_scores
     │
     ▼
iOS / Android  ◄── ranked match list
```

### 3.3 Why this pattern and not synchronous

| Criterion | Synchronous (Option A) | Async pre-computation (Option B) |
|---|---|---|
| User-facing latency | High — user waits for ML | Zero — reads from DB |
| Resilience | ML down = matching broken | ML down = serve previous scores |
| Fit with async matching | Poor | Perfect |
| Solid Queue reuse | No | Yes (already in stack) |
| ML inference time budget | Tight (< 200ms) | Unlimited |
| Scalability | Limited | High |

Option B (async pre-computation) is chosen because Synca's product promise is
**few but high-quality matches**, not real-time swipe ranking. Users do not
expect instant match updates — they expect the matches they receive to be
meaningful. This removes any latency constraint from ML inference and makes
the system resilient to ML service downtime.

---

## 4. Privacy Constraints (Non-Negotiable)

These rules are architectural invariants. They must never be violated.

1. **Raw health samples never leave the device.**  
   HealthKit (iOS) and Health Connect (Android) raw samples are aggregated
   on-device inside `SignalAggregatorService` (iOS) and `data/health/` (Android).
   Only derived metrics are transmitted to the backend.  
   Ref: `docs/architecture/ios-structure.md`, `docs/architecture/android-structure.md`

2. **The ML Service receives only aggregated feature vectors.**  
   The ML Service never reads user PII (name, phone, photo, email).
   It receives `user_id` (an opaque internal integer) + feature vector.
   `user_id` is not a public identifier and carries no personal information.

3. **The ML Service has read-only access to a dedicated feature view.**  
   It never has write access to the main Rails DB, and never queries tables
   containing personal data directly.

4. **ML scores are never shown raw to users.**  
   The compatibility score (0–100) is never rendered in the UI.
   Only the plain-language explanation generated by Rails is shown.  
   Ref: `docs/features/matching-v1.md`

---

## 5. Feature Design — Data Contract

The ML Service receives a feature vector per user. These are computed by Rails
from existing signal and profile data. Raw HealthKit samples are never included.

### 5.1 Health-derived features

| Feature name | Type | Description | Source |
|---|---|---|---|
| `avg_sleep_hours` | float | Average nightly sleep duration (last 30d) | signals |
| `sleep_consistency_score` | float 0–1 | Variance in sleep schedule (1 = very consistent) | signals |
| `chronotype` | enum | `early_bird`, `night_owl`, `intermediate` | signals |
| `avg_daily_steps` | int | Average daily step count (last 30d) | signals |
| `active_days_per_week` | float | Average active days per week | signals |
| `resting_heart_rate_avg` | float | Average resting HR (last 30d), nullable | signals |
| `activity_pattern` | enum | `sedentary`, `moderate`, `active`, `athlete` | signals |

### 5.2 Profile and preference features

| Feature name | Type | Description | Source |
|---|---|---|---|
| `age` | int | User age in years | profile |
| `gender` | enum | User declared gender | profile |
| `looking_for` | enum | Relationship intent | preference_profile |
| `max_distance_km` | int | Max search distance | preference_profile |
| `spark_score` | float 0–1 | Average spark compatibility score | sparks |
| `trust_score` | float 0–1 | Current trust score | trust |

### 5.3 Behavioral features (available post-async matching)

These features become available once async matching and user interaction data
are collected. They are the primary input for the ML ranking model.

| Feature name | Type | Description | Source |
|---|---|---|---|
| `like_rate` | float 0–1 | Fraction of shown profiles liked | match events |
| `response_rate` | float 0–1 | Fraction of matches that led to a message | match events |
| `moment_completion_rate` | float 0–1 | Fraction of proposed moments completed | moments |
| `days_since_last_active` | int | Recency signal | sessions |
| `mutual_like_rate` | float 0–1 | Fraction of likes that became mutual matches | match events |

### 5.4 Pair-level features (computed per candidate pair)

| Feature name | Type | Description |
|---|---|---|
| `sleep_schedule_delta` | float | Absolute diff in avg sleep start time (hours) |
| `activity_level_delta` | int | Diff in activity_pattern enum ordinal |
| `chronotype_match` | bool | True if chronotypes are compatible |
| `age_delta` | int | Absolute age difference |
| `preference_overlap_score` | float 0–1 | Overlap between declared preferences |

---

## 6. ML Service Interface

### 6.1 Trigger

Rails calls the ML Service via `MlMatchScoringJob` (Solid Queue).

Trigger conditions:
- Daily scheduled run (all active users)
- On-demand: when a user updates their signals significantly
- On-demand: when a new user completes onboarding

### 6.2 Input payload

```json
{
  "user_id": 42,
  "user_features": { "avg_sleep_hours": 7.1 },
  "candidates": [
    { "user_id": 101, "features": { "avg_sleep_hours": 7.4 } },
    { "user_id": 102, "features": { "avg_sleep_hours": 6.2 } }
  ]
}
```

Candidates are pre-filtered by Rails using hard rules (distance, preferences,
blocked users) before being sent to ML. The ML Service only ranks — it never
filters.

### 6.3 Output payload

```json
{
  "user_id": 42,
  "ranked_candidates": [
    { "user_id": 101, "score": 0.91 },
    { "user_id": 102, "score": 0.74 }
  ],
  "model_version": "v1.2.0",
  "computed_at": "2026-05-31T03:00:00Z"
}
```

### 6.4 Rails DB schema — results table

```sql
-- Table: ml_match_scores
-- Owned by: docs/architecture/ml-architecture-v1.md

CREATE TABLE ml_match_scores (
  id              bigserial PRIMARY KEY,
  user_id         bigint NOT NULL,  -- ref: docs/features/profile-v1.md
  candidate_id    bigint NOT NULL,  -- ref: docs/features/profile-v1.md
  score           float NOT NULL,   -- 0.0–1.0, higher = better predicted match
  model_version   varchar NOT NULL,
  computed_at     timestamp NOT NULL,
  expires_at      timestamp NOT NULL,
  created_at      timestamp NOT NULL
);

CREATE INDEX idx_ml_match_scores_user_id ON ml_match_scores (user_id);
CREATE INDEX idx_ml_match_scores_expires ON ml_match_scores (expires_at);
```

---

## 7. Rails Integration Points

### 7.1 MlMatchScoringJob (Solid Queue)

Responsibilities:
1. Run candidate generation (SQL + hard filters)
2. Build feature vectors for user + candidates
3. Call ML Service via HTTP (`MlRecommenderClient`)
4. Write results to `ml_match_scores`
5. Log prediction metadata for future retraining

### 7.2 MlRecommenderClient

A thin Ruby HTTP client wrapping the ML Service API.  
Must handle: timeouts, retries (max 2), circuit breaker (skip ML, use
rule-based fallback if ML is unavailable).

### 7.3 CompatibilityScoreService (existing — fallback)

The existing rule-based `CompatibilityScoreService` remains in place as fallback.
When `ml_match_scores` are unavailable or expired, Rails falls back to
rule-based ranking transparently. This ensures zero downtime during ML
service outages.

---

## 8. Model Strategy

### Phase 1 — Propensity model (first model to build)

- **Objective:** Predict probability that user A likes user B
- **Model type:** Gradient Boosted Trees (LightGBM or XGBoost)
- **Features:** Sections 5.1 + 5.2 (no behavioral features yet)
- **Label:** `liked = true/false` from match events
- **Why:** Simple to train, fast to serve, highly interpretable,
  no deep learning infrastructure needed

### Phase 2 — Ranking model

- **Objective:** Optimize ordering of candidates for mutual match outcome
- **Model type:** LambdaMART or pairwise ranking on top of Phase 1 features
  + behavioral features (Section 5.3)
- **Label:** `mutual_match = true/false`, `moment_completed = true/false`
- **Why:** Moves from "will A like B?" to "will A and B have a good relationship?"
  which is Synca's actual product goal

### Phase 3 — Embeddings (future, only at scale)

- User embeddings via neural networks to capture complex signal interactions
- Only justified with tens of thousands of active users and sufficient
  training data density

---

## 9. Logging Requirements

For ML to be trainable, Rails must log the following events from day one.
These are prediction labels — without them, no model can be trained.

| Event | When | Fields to log |
|---|---|---|
| `profile_shown` | Rails shows a candidate to user | user_id, candidate_id, timestamp, model_version |
| `profile_liked` | User likes a candidate | user_id, candidate_id, timestamp |
| `profile_skipped` | User skips a candidate | user_id, candidate_id, timestamp |
| `match_created` | Mutual like | user_id_a, user_id_b, timestamp |
| `first_message_sent` | First message in a match | match_id, timestamp |
| `moment_completed` | Moment marked complete | moment_id, user_id_a, user_id_b, timestamp |

These events must be stored in an `ml_events` table or equivalent event log,
separate from the main business tables, to simplify future data pipeline work.

---

## 10. What the ML Specialist Needs to Deliver

1. **ML Service** — Python service exposing `POST /score_pairs` as per Section 6
2. **Feature pipeline** — reads from the Rails feature view, builds input vectors
3. **Training pipeline** — reads from `ml_events`, trains Phase 1 model, exports artifact
4. **Model versioning** — each deployed model has a `model_version` string included in responses
5. **Retraining job** — scheduled retraining (weekly or on data threshold), with model validation before promotion
6. **Fallback behavior** — if model confidence is low, return empty `ranked_candidates` so Rails uses rule-based fallback

The ML Service must be stateless between requests. All state lives in the
pre-loaded model artifact and the Rails DB.

---

## 11. Roadmap

| Phase | Trigger | Deliverable |
|---|---|---|
| V1 (now) | MVP live | Rule-based scoring only. Log all events from day one. |
| V2 | Async matching live + ~1k active users | Phase 1 propensity model, `ml_match_scores` table, `MlMatchScoringJob` |
| V3 | ~10k active users, behavioral data mature | Phase 2 ranking model with behavioral features |
| V4 | Scale + compliance needs | Consider pseudonymised ML DB separation if required by GDPR audit |
