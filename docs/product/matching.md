# Synca — Matching Model

## Overview

Compatibility in Synca is a weighted score (0–100) computed from four domains.
The score is never shown as a raw number to users — it is translated into plain-language
explanations (e.g. "Your sleep schedules are well aligned").

## Compatibility Domains

| Domain      | Weight | Signals                                                        |
|-------------|--------|----------------------------------------------------------------|
| Sleep       | 35%    | Chronotype, sleep duration average, sleep regularity          |
| Activity    | 25%    | Weekly active minutes, step patterns, rest HR trends          |
| Lifestyle   | 25%    | Music taste (Spotify), travel frequency, routine consistency  |
| Preferences | 15%    | Age range, distance, stated dealbreakers                      |

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

## Anti-Fake Signal

Compatibility scores are harder to game than profile photos because they are derived from
continuous health data collected over weeks. A fake profile without health data gets a
reduced `trust_score` and is ranked down or excluded from match pools.

## Evolution Plan

- **v0 (Matching rule-based):** filter by city/age/gender, no health signal.
- **v1 (Health-based):** weighted score from HealthKit/Health Connect aggregates.
- **v2 (Data-driven):** outcome feedback (date completed, rating) used to tune weights per user.
