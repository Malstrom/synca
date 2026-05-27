# Synca — Matching Model

## Overview

Compatibility in Synca is a weighted score (0–100) computed from four domains.
The score is never shown as a raw number to users — it is translated into plain-language
explanations (e.g. "Your sleep schedules are well aligned").

## Compatibility Domains

| Domain      | Weight | Signals                                                              |
|-------------|--------|----------------------------------------------------------------------|
| Sleep       | 35%    | Chronotype, sleep duration average, sleep regularity, social jetlag |
| Activity    | 30%    | Weekly active minutes, step patterns, peak energy window, rest HR   |
| Lifestyle   | 20%    | Music taste (Spotify), travel frequency, routine consistency        |
| Preferences | 15%    | Age range, distance, stated dealbreakers                            |

> Weight distribution is indicative for MVP. Weights will be recalibrated per city as
> outcome data accumulates (see Evolution Plan below).

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

## Matching Flow

1. User opens the app → client requests `GET /matches`.
2. Backend calls `MatchingService` with user's `HealthSummary` + `PreferenceProfile`.
3. Candidate pool is filtered (city, age, gender, distance, dealbreakers).
4. `CompatibilityScoreService` computes a score for each candidate.
5. Top 3–5 candidates (score ≥ threshold) are returned.
6. Candidates below threshold are silently excluded (not shown).

## Score Thresholds

| Score range | Action                          |
|-------------|---------------------------------|
| 75–100      | Show as high-quality match      |
| 50–74       | Show as standard match          |
| < 50        | Silently excluded               |

Thresholds are configurable per city and will be tuned as real outcome data accumulates.

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

## Synca Spark — Live IRL Signal

When two users complete a `SparkSession` in person, the event contributes additional
matching signal beyond passively collected health data:

- The compatibility delta computed at session end enriches the pairwise score.
- `trust_score` is incremented for both users on `profiles`, increasing their
  visibility in the matching pool.
- Spark answers (micro-test responses) are **discarded immediately** after score
  computation and are never persisted long-term.

Spark sessions are the strongest liveness and compatibility signal available in the system
because they require two real people in the same physical location at the same time.

## Anti-Fake Signal

Compatibility scores are harder to game than profile photos because they are derived from
continuous health data collected over weeks. A fake profile without health data gets a
reduced `trust_score` and is ranked down or excluded from match pools. Completing a
`SparkSession` with another verified user is the most effective way to increase trust
visibility.

## Evolution Plan

- **v0 (rule-based):** filter by city/age/gender, no health signal.
- **v1 (health-based):** weighted score from HealthKit/Health Connect aggregates.
- **v2 (data-driven):** outcome feedback (date completed, rating) used to tune weights per user.
- **v3 (group compatibility):** extend the pairwise model to compute a multi-user group
  cohesion score across 4–8 participants; surface curated small-group activity proposals
  (runs, sauna sessions, padel). The individual compatibility profiles and `SparkSession`
  IRL data built in v1/v2 are the direct input to this layer — no re-architecture required.
