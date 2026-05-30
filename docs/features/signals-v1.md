# Feature: Signals
**Version:** 1.0
**Last updated:** May 2026
**Status:** Draft
**Phase:** 1

---

## Overview

Signals is the data ingestion and computation layer of Synca. It collects, aggregates,
and syncs behavioral data from external sources to build each user's compatibility profile.
It also exposes a user-facing summary of the computed values so that users can understand
their own profile before receiving any match.

Raw data from external sources is **never stored on the backend**. All aggregation
happens on-device. Only derived metrics are sent to and stored in `signals`.

Signal sources are added incrementally across phases. Each new source enriches the
compatibility model without requiring re-architecture. The `signals` table grows
one column group per new source — one row per user at all times.

The signals layer has three complementary components:
- **Objective signals** (Steps 1.0–3.0): passively collected behavioral data from
  health, music, and travel sources. Cannot be gamed without sustained behavioral
  change over weeks.
- **Declared preferences** (Step 0): a short questionnaire that captures what each
  user considers important. These are not filters — they are personalisation weights
  that shape how objective signals are interpreted for that specific user.
- **User-facing layer**: a computed, human-readable summary derived from the signals
  record. Served separately from the raw metrics. No additional data store required.

Prerequisite: `users` and `profiles` tables (ref: `docs/features/profile-v1.md`).

---

## Step 0 — Declared Preferences

**Phase:** 0 (Validation MVP)
**Status:** Draft

### Purpose

Objective behavioral signals tell us what a person *does*. Declared preferences tell
us what a person *values*. The combination is more predictive than either alone.

Example: two people with different chronotypes may still be highly compatible if
neither of them considers sleeping at the same time important. Two people with
identical chronotypes may be incompatible if one requires complete silence in the
morning and the other does not. The declared preference is the interpretation key.

This questionnaire is completed once during onboarding. It takes under 2 minutes.
Answers are stored as `declared_preferences` on the user record and used as
multipliers when computing pairwise compatibility scores.

The qualitative research and real-world cases that motivated this questionnaire are
documented in [`../product/user-research.md`](../product/user-research.md).

### Questionnaire (Phase 0)

All questions use a 1–5 scale or a categorical choice. Plain language, no jargon.

| # | Question | Type | Signal it weights |
|---|----------|------|-------------------|
| 1 | Is it important to you to fall asleep at the same time as your partner? | 1–5 scale | `sleep_onset` alignment weight |
| 2 | Do you prefer sleeping in a cool or warm environment? | Cool / Warm / No preference | Shared as compatibility dimension |
| 3 | How much daily movement feels right for you? | Very little / Moderate / A lot / As much as possible | `step_count_avg` similarity threshold |
| 4 | How important is it that the people close to you share your daily rhythm? | 1–5 scale | Global chronotype alignment weight |
| 5 | Do you consider yourself more of a morning person or a night person? | Morning / Night / Depends | Cross-validated with `chronotype` from HealthKit |

Additional questions may be added in Phase 1 based on feedback from Phase 0 users.

### DB Schema

New table introduced by this step:

```sql
-- Canonical table name: declared_preferences
declared_preferences
  id                              bigint PK
  user_id                         bigint FK -> users NOT NULL UNIQUE
  sleep_together_importance       integer   -- 1-5 scale
  sleep_temperature_preference    string    -- 'cool' | 'warm' | 'no_preference'
  daily_movement_level            string    -- 'very_little' | 'moderate' | 'a_lot' | 'maximum'
  rhythm_alignment_importance     integer   -- 1-5 scale
  self_reported_chronotype        string    -- 'morning' | 'night' | 'flexible'
  created_at                      datetime
  updated_at                      datetime
```

### API Endpoints

| Method | Path | Auth required | Description |
|--------|------|---------------|-------------|
| POST | `/api/v1/signals/preferences` | Yes (guest token ok) | Creates declared preferences record |
| GET | `/api/v1/signals/preferences` | Yes | Returns own declared preferences |
| PATCH | `/api/v1/signals/preferences` | Yes | Updates one or more preference fields |

Ref: `docs/api/openapi.yaml`

### Premium Gating

None — declared preferences are available on all tiers including guest accounts.

### Open Questions

- Should declared preferences be re-asked after 6 months, or remain static until
  manually updated by the user?
- Should the app surface a "your preferences vs your data" comparison — e.g. user
  says they are a morning person but HealthKit shows average sleep offset at 09:30?
- How many questions can be added before completion rate drops below acceptable threshold?

---

## Step 1.0 — Apple Health / Health Connect

**Phase:** 1
**Status:** Draft

### User Flow

1. After profile onboarding, user is prompted to connect Apple Health (iOS) or
   Health Connect (Android).
2. App requests read-only permissions for sleep, steps, heart rate, and activity.
3. `SignalsAggregatorService` reads the last 30 days of samples and computes
   aggregated metrics entirely on-device.
4. Aggregated metrics are sent to the backend (`POST /api/v1/signals`).
5. Backend stores the metrics in `signals`. Raw samples are never transmitted.
6. Metrics are refreshed automatically once per day in the background.
7. User can manually trigger a refresh from the Profile screen.

### DB Schema

New table introduced by this step:

```sql
signals
  id                       bigint PK
  user_id                  bigint FK -> users NOT NULL UNIQUE
  -- Step 1.0: health
  sleep_duration_avg       float     -- average nightly sleep hours (last 30 days)
  sleep_variability        float     -- standard deviation of nightly sleep duration
  chronotype               string    -- 'early_bird' | 'night_owl' | 'intermediate'
  social_jetlag            float     -- weekday vs weekend sleep timing delta (hours)
  activity_minutes_avg     float     -- average weekly active minutes
  rest_hr_avg              float     -- resting heart rate average (bpm)
  step_count_avg           float     -- average daily step count
  peak_activity_window     string    -- time-of-day window with highest activity density
  routine_stability_index  float     -- daily schedule consistency score (0.0-1.0)
  computed_at              datetime  -- when the aggregation was last run on-device
  updated_at               datetime  -- when the backend last received a sync
```

### API Endpoints

| Method | Path | Auth required | Description |
|--------|------|---------------|-------------|
| POST | `/api/v1/signals` | Yes | Creates the user's signal record |
| GET | `/api/v1/signals/me` | Yes | Returns the current user's raw signals |

Ref: `docs/api/openapi.yaml`

### Premium Gating

None — Apple Health / Health Connect integration is free for all users.
Without a `signals` record, the user cannot receive algorithm-origin matches
(premium feature), but Spark-origin matching still works.

### Open Questions

- Minimum data threshold: how many days of data are required before the user
  enters the matching pool? (Suggested: 7 days minimum.)
- What happens if the user revokes HealthKit permissions after onboarding?
  Does their `signals` record get stale-flagged or deleted?
- Should `computed_at` be validated server-side to reject signals older than 48 hours?

---

## User-facing layer

**Phase:** 0 (Validation MVP)
**Status:** Draft

### Purpose

After health data is connected and the `signals` record is populated, the user is
shown a computed summary of their own profile. This is the immediate value hook of
Synca: the user must recognise themselves in what the data says about them before
any match is presented.

This layer introduces no additional data store. All values are derived at request
time from the existing `signals` and `declared_preferences` records.

### Computed fields

| Raw signal | Derived label | Example output |
|---|---|---|
| `chronotype` | Chronotype label | "Night owl" / "Early bird" / "Intermediate" |
| `peak_activity_window` | Peak energy window | "Your energy peaks between 21:00 and 23:00" |
| `routine_stability_index` | Routine stability tier | "Very stable" / "Moderate" / "Flexible" |
| `activity_minutes_avg` | Activity tier | "Highly active" / "Moderately active" / "Low activity" |
| `sleep_duration_avg` | Sleep pattern label | "You average 7.2 hours of sleep" |
| `social_jetlag` | Weekend shift note | "Your sleep shifts 1.5 hours on weekends" |
| `self_reported_chronotype` vs `chronotype` | Alignment note | "You said morning person — your data agrees" or "Your data tells a different story" |

### API Endpoint

| Method | Path | Auth required | Description |
|--------|------|---------------|-------------|
| GET | `/api/v1/signals/me/summary` | Yes | Returns computed human-readable summary derived from the user's signals record |

Response shape (JSON):

```json
{
  "chronotype_label": "Night owl",
  "peak_energy_window": "21:00–23:00",
  "routine_stability_tier": "very_stable",
  "activity_tier": "highly_active",
  "sleep_avg_hours": 7.2,
  "social_jetlag_hours": 1.5,
  "self_report_alignment": "confirmed"
}
```

### Premium Gating

None — the user-facing summary is available to all users who have a `signals` record.

### Open Questions

- Should the summary be recomputed on every request or cached with a TTL matching
  the signals refresh cadence (daily)?
- Should mismatches between declared preferences and objective signals be surfaced
  as a prompt to update preferences, or only shown as informational?

---

## Step 2.0 — Music (Spotify / Yandex Music)

**Phase:** 2
**Status:** Planned

### User Flow

1. User connects their Spotify or Yandex Music account from the Profile screen.
2. App requests read-only OAuth access to listening history and top artists/genres.
3. `SignalsAggregatorService` computes a music taste profile on-device:
   - Top genres (weighted by listening time)
   - Energy and valence averages (from Spotify audio features)
   - Listening time-of-day pattern
4. Music metrics are appended via `PATCH /api/v1/signals`.
5. `CompatibilityScoreService` includes music taste as a sub-signal within
   the Lifestyle domain (ref: `docs/features/matching-v1.md`).

### DB Schema

New columns added to `signals` in this step:

```sql
signals
  -- Step 2.0: music (appended to existing table)
  music_top_genres            jsonb     -- e.g. ["hip-hop", "jazz", "electronic"]
  music_energy_avg            float     -- Spotify audio feature average (0.0-1.0)
  music_valence_avg           float     -- Spotify audio feature average (0.0-1.0)
  music_peak_listening_window string    -- time-of-day window with highest listening
  music_source                string    -- 'spotify' | 'yandex_music'
```

New table introduced by this step (OAuth provider link, shared with profile):

```sql
-- identity_providers: ref docs/features/profile-v1.md Step 2.0
-- provider values extended: 'spotify' | 'yandex_music' added to existing set
```

### API Endpoints

| Method | Path | Auth required | Description |
|--------|------|---------------|-------------|
| POST | `/api/v1/signals` | Yes | Unchanged from Step 1.0 |
| GET | `/api/v1/signals/me` | Yes | Unchanged from Step 1.0 |
| PATCH | `/api/v1/signals` | Yes | Partial update — appends music metrics |
| POST | `/api/v1/auth/social` | No | Reused from profile Step 2.0 for Spotify/Yandex OAuth |

Ref: `docs/api/openapi.yaml`

### Premium Gating

None — music signal is free for all users.

### Open Questions

- Yandex Music does not have a public audio features API equivalent to Spotify.
  What is the fallback for genre/energy computation on Yandex?
- Should music taste influence Spark-origin matching or only algorithm-origin?
- Refresh cadence for music data: daily (same as health) or weekly?

---

## Step 3.0 — Travel Behavior

**Phase:** 3
**Status:** Planned

### User Flow

1. User connects Polarsteps or grants access to location history.
2. `SignalsAggregatorService` computes travel behavior on-device:
   - Average trips per year
   - Typical trip duration
   - Travel style (city vs nature vs mixed)
   - Preferred regions
3. Travel metrics are appended via `PATCH /api/v1/signals`.
4. `CompatibilityScoreService` includes travel behavior as a sub-signal
   within the Lifestyle domain (ref: `docs/features/matching-v1.md`).

### DB Schema

New columns added to `signals` in this step:

```sql
signals
  -- Step 3.0: travel (appended to existing table)
  travel_trips_per_year    float     -- average number of trips per year
  travel_avg_duration_days float     -- average trip duration in days
  travel_style             string    -- 'city' | 'nature' | 'mixed'
  travel_regions           jsonb     -- e.g. ["Europe", "Southeast Asia"]
```

### API Endpoints

| Method | Path | Auth required | Description |
|--------|------|---------------|-------------|
| POST | `/api/v1/signals` | Yes | Unchanged from Step 1.0 |
| GET | `/api/v1/signals/me` | Yes | Unchanged from Step 1.0 |
| PATCH | `/api/v1/signals` | Yes | Partial update — appends travel metrics |

Ref: `docs/api/openapi.yaml`

### Premium Gating

None — travel signal is free for all users.

### Open Questions

- Polarsteps has no public API. Is manual import (GPX / JSON export) acceptable
  for MVP of this step, or should we wait for a proper integration?
- Should travel behavior affect the Preferences domain weight instead of Lifestyle?
- Privacy: travel history is sensitive. Should users be able to exclude specific
  trips from the aggregation?
