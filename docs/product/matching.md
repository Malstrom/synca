# Synca — Matching Model

## Overview

Compatibility in Synca is a weighted score (0–100) computed from four domains.
The score is never shown as a raw number to users — it is translated into plain-language
explanations (e.g. "Your sleep schedules are well aligned").

---

## Compatibility Domains

| Domain      | Weight | Signals                                                              |
|-------------|--------|----------------------------------------------------------------------|
| Sleep       | 35%    | Chronotype, sleep duration average, sleep regularity, social jetlag |
| Activity    | 30%    | Weekly active minutes, step patterns, peak energy window, rest HR   |
| Lifestyle   | 20%    | Music taste (Spotify), travel frequency, routine consistency        |
| Preferences | 15%    | Age range, distance, stated dealbreakers                            |

> Weight distribution is indicative for MVP. Weights will be recalibrated per city as
> outcome data accumulates (see Evolution Plan below).

---

## Health Data Used

All health data is aggregated before being stored or compared. Raw HealthKit / Health Connect
samples are never stored on the backend and never shared between users.

Aggregated metrics computed on device and sent to backend:

- `sleep_duration_avg` — average sleep hours per night (last 30 days)
- `sleep_variability` — standard deviation of sleep duration
- `chronotype` — estimated from average bedtime/wake-time window
- `social_jetlag` — difference between weekday and weekend sleep timing
- `activity_minutes_avg` — average weekly active minutes
- `rest_hr_avg` — resting heart rate average (if available)
- `step_count_avg` — average daily steps
- `peak_activity_window` — time-of-day window with highest activity density
- `routine_stability_index` — how consistent the user's daily schedule is (0–1)

---

## Match Origin

Every `Match` record carries an `origin` field that tracks how it was created.
Two origins are supported from MVP:

| Origin        | Trigger                                      | UX label              |
|---------------|----------------------------------------------|-----------------------|
| `:spark`      | Two users complete a `SparkSession` in person | "Synca confermata" ✅ |
| `:algorithm`  | Nightly `MatchingJob` on health summaries     | "Synca suggerita" 💡  |

```ruby
# app/models/match.rb
enum :origin, { spark: 0, algorithm: 1 }, default: :spark
```

Algorithm-originated matches also carry an `algorithm_confidence` float (0.0–1.0).
Spark-originated matches leave this field `nil`.

### Why both origins in MVP

- **Spark** origin is the brand core: "we actually met". It validates the physical
  encounter and is the strongest trust signal in the system.
- **Algorithm** origin increases the match surface from day one, especially for users
  who do not yet have Spark sessions. It can be measured separately and gated behind
  premium later (see Premium Gating below).

---

## Matching Flows

### Flow 1 — Spark-triggered (`:spark`)

```
User A and B meet physically
        ↓
SparkSession completed
        ↓
CompatibilityScoreService computes score
        ↓
score >= 50 → Match created  (origin: :spark)
score <  50 → no match, session stored for analytics
```

Score is computed at session end using both users' `HealthSummary` +
`PreferenceProfile` + micro-test answers (discarded after scoring).

### Flow 2 — Algorithm-triggered (`:algorithm`)

```
MatchingJob runs nightly (Solid Queue, `algorithm` queue)
        ↓
Iterates users with a complete HealthSummary updated in the last 30 days
        ↓
Candidate pool filtered (city, age, gender, distance, dealbreakers)
        ↓
CompatibilityScoreService computes pairwise score
        ↓
score >= 65 → Match created  (origin: :algorithm)
score <  65 → silently skipped
```

The algorithm queue is separate from the `spark` queue to avoid blocking
time-sensitive Spark scoring during the nightly batch run.

---

## Score Thresholds

| Score range | Spark origin action             | Algorithm origin action         | Sync Room admission         |
|-------------|---------------------------------|---------------------------------|-----------------------------|
| 75–100      | High-quality match shown        | High-quality suggestion shown   | ✅ Eligible for group room  |
| 50–74       | Standard match shown            | Standard suggestion shown       | ✅ Eligible for duo only    |
| < 50        | No match created                | No match created                | ❌ Not eligible             |

> Minimum score for Sync Room group admission (small_group / event_room): **≥ 50**
> between each pair that requires a verified Spark.

Thresholds are configurable per city and will be tuned as real outcome data accumulates.

---

## TrustScore

Every user has a `trust_score` (float, 0.0–100.0) stored as a column on the `profiles`
table — not as a separate model. This keeps the schema simple for MVP.

Default value: **50.0** (neutral — neither boosted nor suppressed).

Inputs that raise the score:

- Email or phone verified
- Profile completeness (display name, bio, photos)
- `irl_verification_count` — incremented each time a SparkSession is completed with
  another verified user
- `spark_verified` flag — set after the first successful SparkSession

Inputs that lower the score:

- No-show reports from other users
- Rude/harassment reports
- Liveness check failure
- Behavioral inconsistency signals

Low TrustScore users are ranked down in the matching pool or gated from features.
The `trust_score` column lives on `profiles` and is updated by `TrustScoreService`.

> **Schema note:** `TrustScore` is referenced as a standalone model in some older docs
> and in the README domain model list. The actual implementation uses a column on
> `profiles` — simpler and sufficient for MVP. A dedicated `trust_score_events` table
> may be added later for audit history.

---

## Synca Spark — Live IRL Signal

When two users complete a `SparkSession` in person, the event contributes additional
matching signal beyond passively collected health data:

- The compatibility delta computed at session end enriches the pairwise score.
- `trust_score` is incremented for both users on `profiles`, increasing their
  visibility in the matching pool.
- A `Match` is created with `origin: :spark` if score >= 50.
- Spark answers (micro-test responses) are **discarded immediately** after score
  computation and are never persisted long-term.

Spark sessions are the strongest liveness and compatibility signal available in the system
because they require two real people in the same physical location at the same time.

---

## Premium Gating

| Feature                             | Free | Premium |
|-------------------------------------|------|---------|
| Spark-origin matches                | ✅   | ✅      |
| Algorithm-origin matches            | ❌   | ✅      |
| Compatibility breakdown detail      | ❌   | ✅      |
| Sync Room group (small_group)       | 1 active | Unlimited |
| Sync Room event (event_room)        | ❌   | ✅      |

---

## Anti-Fake Signal

Compatibility scores are harder to game than profile photos because they are derived from
continuous health data collected over weeks. A fake profile without health data gets a
reduced `trust_score` and is ranked down or excluded from match pools. Completing a
`SparkSession` with another verified user is the most effective way to increase trust
visibility.

---

## Evolution Plan

- **v0 (rule-based):** filter by city/age/gender, no health signal.
- **v1 (health-based):** weighted score from HealthKit/Health Connect aggregates.
  Both `:spark` and `:algorithm` origins active.
- **v2 (data-driven):** outcome feedback (date completed, rating) used to tune weights per user.
- **v3 (group compatibility):** extend the pairwise model to compute a multi-user group
  cohesion score across 4–22 participants (small_group and event_room types); surface
  curated small-group activity proposals (runs, sauna sessions, padel, calcetto).
  The individual compatibility profiles and `SparkSession` IRL data built in v1/v2 are
  the direct input to this layer — no re-architecture required.
