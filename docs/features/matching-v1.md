# Feature: Matching
**Version:** 1.1
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

Prerequisites:
- `users`, `profiles`, `preference_profiles` (ref: `docs/features/profile-v1.md`)
- `signals`, `declared_preferences` (ref: `docs/features/signals-v1.md`)

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
| Preferences | 15% | Age range, distance, stated dealbreakers, `declared_preferences` multipliers |

The `declared_preferences` record for each user is loaded via
`user.declared_preference` and used as multipliers within the Preferences domain
and as weight modifiers across Sleep/Activity domains.
Ref: `docs/features/signals-v1.md — Step 0`.

> Weights are indicative for MVP. They will be recalibrated per city as outcome
> data accumulates (see Evolution Plan below).

### Score Thresholds

Thresholds are the **single source of truth** for match creation decisions.
No other document should hardcode threshold values — always reference this table.

| Threshold | Spark origin | Algorithm origin |
|-----------|--------------|------------------|
| Minimum score to create a match | 50 | 65 |

> Algorithm origin has a higher bar than Spark because no physical presence
> confirms mutual intent. Thresholds are configurable per city.

| Score range | Spark origin | Algorithm origin | Circle (duo) admission |
|-------------|--------------|------------------|------------------------|
| High | High-quality match shown | High-quality suggestion shown | ✅ Eligible |
| Standard | Standard match shown | Standard suggestion shown | ✅ Eligible (duo only) |
| Below minimum | No match created | No match created | ❌ Not eligible |

### Match Origins

| Origin | Trigger | UX label |
|--------|---------|----------|
| `:spark` | Two users complete a `Spark` in person | "Synca confermata" ✅ |
| `:algorithm` | Nightly `MatchingJob` on signals | "Synca suggerita" 💡 |

```ruby
# app/models/match.rb
enum :origin, { spark: 0, algorithm: 1 }, default: :spark
```

Algorithm-originated matches also carry an `algorithm_confidence` float (0.0–1.0).
Spark-originated matches leave this field `nil`.

### Flow 1 — Spark-triggered (`:spark`)

```
Both users confirm presence in Spark
        ↓
CompatibilityScoreService.call(user_a, user_b)
        ↓
score >= spark minimum threshold
  →  Match.create!(origin: :spark, compatibility_score: score)
  →  trust_score incremented for both users on profiles
score <  spark minimum threshold
  →  no Match created
  →  Spark stored for analytics
```

`CompatibilityScoreService` is called synchronously at spark completion.
Result is available to the client immediately via the `spark:scored`
Action Cable event.

### Flow 2 — Algorithm-triggered (`:algorithm`)

```
MatchingJob runs nightly  (Solid Queue, `algorithm` queue)
        ↓
Iterates users with a signals record updated in the last 30 days
        ↓
Candidate pool filtered by: city, age, gender, distance, dealbreakers
(ref: preference_profiles → docs/features/profile-v1.md)
        ↓
CompatibilityScoreService.call(user_a, user_b)
        ↓
score >= algorithm minimum threshold
  →  Match.create!(origin: :algorithm, compatibility_score: score,
                   algorithm_confidence: confidence)
score < algorithm minimum threshold
  →  silently skipped
```

The `algorithm` queue is separate from default to avoid blocking Spark scoring
during the nightly batch run.

> **V2 note:** When async matching is active and `ml_match_scores` are available,
> `MatchingJob` will read pre-computed ML scores instead of calling
> `CompatibilityScoreService` synchronously. Rule-based scoring remains as fallback.
> Ref: `docs/architecture/ml-architecture-v1.md — Section 7`

### DB Schema

```sql
-- preference_profiles: ref docs/features/profile-v1.md
-- declared_preferences: ref docs/features/signals-v1.md
-- (canonical definitions live there; do not redefine here)

matches
  id                     bigint PK
  user_a_id              bigint FK -> users NOT NULL
  user_b_id              bigint FK -> users NOT NULL
  spark_id               bigint FK -> sparks       -- nil for algorithm-origin
  origin                 integer NOT NULL DEFAULT 0  -- 0: spark | 1: algorithm
  algorithm_confidence   float                       -- nil for spark-origin
  compatibility_score    float NOT NULL
  score_breakdown        jsonb  -- domain sub-scores; never exposed raw to users
  status                 string NOT NULL DEFAULT 'active'
                         -- 'active' | 'drifted' | 'reconnected' | 'ended'
  created_at             datetime
  updated_at             datetime
  UNIQUE (user_a_id, user_b_id)
```

For `signals` schema see `docs/features/signals-v1.md`.
For `sparks` schema see `docs/features/spark-v1.md`.

### API Endpoints

| Method | Path | Auth required | Description |
|--------|------|---------------|--------------|
| GET | `/api/v1/matches` | Yes | Lists the current user's matches |
| GET | `/api/v1/matches/:id` | Yes | Returns a specific match with plain-language explanation |
| PATCH | `/api/v1/matches/:id` | Yes | Updates match status (e.g. ended) |

Ref: `docs/api/openapi.yaml`

### Open Questions

See `docs/decisions.md` for tracked decisions on this feature.

- Minimum signals data threshold before a user enters the algorithm pool:
  how many days of health data are required? (Suggested: 7 days.)
- Should the algorithm run daily for all eligible users, or only for users
  who have not yet received a match in the last N days?
- What is the maximum number of algorithm-origin matches surfaced per user
  per nightly run? (Suggested: 1–3 to reinforce scarcity positioning.)
- How is `algorithm_confidence` computed? Suggested: normalized pairwise score
  relative to the candidate pool for that user.

---

## Match Lifecycle

Matches have a `status` field with the following values:

| Status | Meaning |
|--------|---------|
| `active` | Default on creation. Match is visible and both users can interact. |
| `drifted` | Health signals for one or both users have not been updated in the last 30 days. Match is deprioritized in list but still visible in history. |
| `reconnected` | A drifted match where both users have refreshed their signals and/or completed a new Spark session. |
| `ended` | Match explicitly ended by one of the users via `PATCH /api/v1/matches/:id`. |

### MatchDecayJob

`MatchDecayJob` runs daily via Solid Queue and marks matches as `drifted` when
health signals for one or both users have not been updated in the last 30 days.

```
MatchDecayJob runs daily
        ↓
Iterates matches with status: 'active'
        ↓
For each match: checks signals.updated_at for user_a and user_b
        ↓
If either user's signals.updated_at < 30 days ago:
  →  match.update!(status: 'drifted')

For each match with status: 'drifted':
  →  If both users have signals.updated_at >= (now - 7 days)
     OR a new Spark was completed between the same users:
  →  match.update!(status: 'reconnected')
```

Drifted matches:
- Remain visible in match history.
- Are excluded from the top of the active matches list.
- Do not trigger new Moment proposals.

Reconnected matches:
- Return to the top of the active match list.
- May generate a new Moment proposal if none is pending.

Ref: `docs/tech/backend.md` for Rails domain model.

---

## Step 2.0 — Music Signal Integration

**Phase:** 2
**Status:** Planned

### Changes from Step 1.0

- `CompatibilityScoreService` reads music columns from `signals` when available
  (ref: `docs/features/signals-v1.md` Step 2.0).
- Music sub-score contributes to the **Lifestyle domain**.
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

- `CompatibilityScoreService` reads travel columns from `signals` when available
  (ref: `docs/features/signals-v1.md` Step 3.0).
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
- **v2 (data-driven):** ML ranking layer replaces rule-based candidate ordering.
  Pre-computed scores stored in `ml_match_scores` via `MlMatchScoringJob`.
  Rule-based `CompatibilityScoreService` remains as fallback.
  Ref: `docs/architecture/ml-architecture-v1.md`
- **v3 (group compatibility):** extend the pairwise model to compute a
  multi-user group cohesion score across 4–22 participants; surface curated
  small-group activity proposals (runs, sauna, padel, calcetto). The
  individual compatibility profiles built in v1/v2 are the direct input
  to this layer — no re-architecture required.
