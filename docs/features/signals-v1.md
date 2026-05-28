# Feature: Signals
**Version:** 1.0
**Last updated:** May 2026
**Status:** Draft
**Phase:** 1

---

## Overview

Signals is the data ingestion layer of Synca. It collects, aggregates, and syncs
behavioral data from external sources to build each user's compatibility profile.

Raw data from external sources is **never stored on the backend**. All aggregation
happens on-device. Only derived metrics are sent to and stored in `signals`.

Signal sources are added incrementally across phases. Each new source enriches the
compatibility model without requiring re-architecture. The `signals` table grows
one column group per new source — one row per user at all times.

Prerequisite: `users` and `profiles` tables (ref: `docs/features/profile-v1.md`).

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
| GET | `/api/v1/signals/me` | Yes | Returns the current user's signals |

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
