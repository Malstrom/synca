# Feature: Matching
**Version:** 1.0
**Last updated:** May 2026
**Status:** Draft
**Phase:** 1

---

## Overview

Matching is the algorithm layer of Synca. It computes compatibility scores between
users and creates `Match` records through two distinct origins: `:spark` (IRL session)
and `:algorithm` (nightly batch job).

Every match carries a human-readable explanation of why two people are compatible.
The raw score (0–100) is **never exposed to users** — only plain-language insights
(e.g. "Your sleep schedules are well aligned").

Matching deliberately produces **few, high-quality matches**. The system does not
produce an infinite swipeable feed.

---

## Step 1.0 — Compatibility Score (Health Signals)

**Phase:** 1
**Status:** Draft

### Compatibility Domains

| Domain | Weight | Signals used |
|--------|--------|--------------|
| Sleep | 35% | `chronotype`, `sleep_duration_avg`, `sleep_variability`, `social_jetlag` |
| Activity | 30% | `activity_minutes_avg`, `step_count_avg`, `peak_activity_window`, `rest_hr_avg` |
| Lifestyle | 20% | `routine_stability_index` (Step 1.0); music and travel added in Steps 2–3 |
| Preferences | 15% | Age range, distance, stated dealbreakers |

> Weights are indicative for MVP. They will be recalibrated per city as outcome
> data accumulates (see Evolution Plan below).

### Score Thresholds

| Score range | Spark origin | Algorithm origin | Sync Room admission |
|-------------|--------------|------------------|---------------------|
| 75–100 | High-quality match shown | High-quality suggestion shown | ✅ Eligible for group room |
| 50–74 | Standard match shown | Standard suggestion shown | ✅ Eligible for duo only |
| < 50 | No match created | No match created | ❌ Not eligible |

Minimum score for algorithm-origin match creation: **65** (higher bar than Spark,
because no physical presence confirms mutual intent).

Thresholds are configurable per city.

### Match Origins

| Origin | Trigger | UX label |
|--------|---------|----------|
| `:spark` | Two users complete a `SparkSession` in person | "Synca confermata" ✅ |
| `:algorithm` | Nightly `MatchingJob` on signals | "Synca suggerita" 💡 |

```ruby
# app/models/match.rb
enum :origin, { spark: 0, algorithm: 1 }, default: :spark
```

Algorithm-originated matches also carry an `algorithm_confidence` float (0.0–1.0).
Spark-originated matches leave this field `nil`.

### Flow 1 — Spark-triggered (`:spark`)

```
Both users confirm presence in SparkSession
        ↓
CompatibilityScoreService.call(user_a, user_b)
        ↓
score >= 50  →  Match.create!(origin: :spark, compatibility_score: score)
             →  trust_score incremented for both users on profiles
score <  50  →  no Match created
             →  SparkSession stored for analytics
```

`CompatibilityScoreService` is called synchronously at session completion.
Result is available to the client immediately via the `spark_session:scored`
Action Cable event.

### Flow 2 — Algorithm-triggered (`:algorithm`)

```
MatchingJob runs nightly  (Solid Queue, `algorithm` queue)
        ↓
Iterates users with a signals record updated in the last 30 days
        ↓
Candidate pool filtered by: city, age, gender, distance, dealbreakers
        ↓
CompatibilityScoreService.call(user_a, user_b)
        ↓
score >= 65  →  Match.create!(origin: :algorithm, compatibility_score: score,
                               algorithm_confidence: confidence)
score <  65  →  silently skipped
```

The `algorithm` queue is separate from default to avoid blocking Spark scoring
during the nightly batch run.

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

preference_profiles
  id              bigint PK
  user_id         bigint FK -> users NOT NULL UNIQUE
  min_age         integer
  max_age         integer
  max_distance_km integer
  gender_targets  jsonb   -- e.g. ["woman", "non_binary"]
  dealbreakers    jsonb   -- e.g. ["smoker", "no_kids"]
  city            string
  created_at      datetime
  updated_at      datetime

matches
  id                     bigint PK
  user_a_id              bigint FK -> users NOT NULL
  user_b_id              bigint FK -> users NOT NULL
  spark_session_id       bigint FK -> spark_sessions  -- nil for algorithm-origin
  origin                 integer NOT NULL DEFAULT 0   -- 0: spark | 1: algorithm
  algorithm_confidence   float                        -- nil for spark-origin
  compatibility_score    float NOT NULL
  score_breakdown        jsonb  -- domain sub-scores; never exposed raw to users
  status                 string NOT NULL DEFAULT 'active'
                         -- 'active' | 'drifted' | 'reconnected' | 'ended'
  created_at             datetime
  updated_at             datetime
  UNIQUE (user_a_id, user_b_id)
```

### API Endpoints

| Method | Path | Auth required | Description |
|--------|------|---------------|--------------|
| GET | `/api/v1/matches` | Yes | Lists the current user's matches |
| GET | `/api/v1/matches/:id` | Yes | Returns a specific match with plain-language explanation |
| PATCH | `/api/v1/matches/:id` | Yes | Updates match status (e.g. ended) |

Ref: `docs/api/openapi.yaml`

### Premium Gating

| Feature | Free | Premium |
|---------|------|---------|
| Spark-origin matches | ✅ | ✅ |
| Algorithm-origin matches | ❌ | ✅ |
| Compatibility breakdown detail | ❌ | ✅ |

Free users can receive and view Spark-origin matches. Algorithm-origin matches
require a premium subscription. The compatibility plain-language explanation is
available to all users; the domain-level breakdown (Sleep 87%, Activity 72%, ...)
is premium only.

### Open Questions

- Minimum signals data threshold before a user enters the algorithm pool:
  how many days of health data are required? (Suggested: 7 days.)
- Should the algorithm run daily for all eligible users, or only for users
  who have not yet received a match in the last N days?
- What is the maximum number of algorithm-origin matches surfaced per user
  per nightly run? (Suggested: 1–3 to reinforce scarcity positioning.)
- How is `algorithm_confidence` computed? Suggested: normalized pairwise score
  relative to the candidate pool for that user.

---

## Step 2.0 — Music Signal Integration

**Phase:** 2
**Status:** Planned

### Changes from Step 1.0

- `CompatibilityScoreService` reads `music_top_genres`, `music_energy_avg`,
  `music_valence_avg` from `signals` when available.
- Music sub-score contributes to the **Lifestyle domain** (which grows from
  `routine_stability_index` only in Step 1.0 to a richer set of sub-signals).
- No schema change to `matches` — `score_breakdown` JSONB absorbs the new
  music sub-score naturally.
- Users without music signals are scored only on health + preferences.
  Missing signals never block scoring; they reduce the Lifestyle domain weight
  proportionally.

### Lifestyle Domain Weight Distribution (Step 2.0)

| Sub-signal | Weight within Lifestyle |
|------------|-------------------------|
| `routine_stability_index` | 40% |
| Music taste | 60% |

---

## Step 3.0 — Travel Signal Integration

**Phase:** 3
**Status:** Planned

### Changes from Step 2.0

- `CompatibilityScoreService` reads `travel_trips_per_year`, `travel_avg_duration_days`,
  `travel_style`, `travel_regions` from `signals` when available.
- Travel sub-score contributes to the **Lifestyle domain**.
- No schema change to `matches`.

### Lifestyle Domain Weight Distribution (Step 3.0)

| Sub-signal | Weight within Lifestyle |
|------------|-------------------------|
| `routine_stability_index` | 20% |
| Music taste | 40% |
| Travel behavior | 40% |

---

## Evolution Plan

- **v0 (rule-based):** filter by city/age/gender; no signal-based scoring.
- **v1 (health-based):** weighted score from health signals. Both `:spark`
  and `:algorithm` origins active.
- **v2 (data-driven):** outcome feedback (date completed, rating) used to
  recalibrate domain weights per user and per city.
- **v3 (group compatibility):** extend the pairwise model to compute a
  multi-user group cohesion score across 4–22 participants; surface curated
  small-group activity proposals (runs, sauna, padel, calcetto). The
  individual compatibility profiles built in v1/v2 are the direct input
  to this layer — no re-architecture required.
