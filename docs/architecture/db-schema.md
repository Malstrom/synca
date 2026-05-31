# Synca — Database Schema

**Version:** 1.0  
**Last updated:** May 2026  
**Status:** Draft

This is the single source of truth for all PostgreSQL table definitions,
indexes, and FK conventions. Feature docs reference this file — they do not
duplicate schema definitions.

---

## Conventions

### FK Rule
All foreign keys point to `users`, never to `profiles`.  
`profiles` is an application-level detail (1:1 with users), not a domain identity.  
Joining to profile data is done in the application layer via `user.profile`.

### Soft Delete
All primary domain tables include `deleted_at datetime` for soft delete.  
All Rails models use a default scope `where(deleted_at: nil)`.  
Hard deletes are never performed on these tables — GDPR erasure is handled
by nullifying PII columns and setting `deleted_at`.

Tables with soft delete: `users`, `profiles`, `matches`, `sparks`,
`circles`, `circle_messages`, `moments`.

### Indexes
Every FK column has an index unless it is part of a covering UNIQUE constraint.  
Composite indexes are documented explicitly per table.

---

## Profile

> Source feature: `docs/features/profile-v1.md`

```sql
users
  id              bigint PK
  email           string UNIQUE NOT NULL
  password_digest string                        -- null for guest accounts
  account_type    string NOT NULL DEFAULT 'guest'  -- 'guest' | 'active'
  deleted_at      datetime
  created_at      datetime
  updated_at      datetime

profiles
  id                     bigint PK
  user_id                bigint FK -> users NOT NULL UNIQUE
  display_name           string
  bio                    text
  date_of_birth          date NOT NULL
  gender                 string NOT NULL   -- 'man' | 'woman' | 'non_binary'
  city                   string NOT NULL
  photos                 jsonb NOT NULL DEFAULT '[]'
  -- photos element shape: { "url": "https://...", "moderation_status": "pending" | "approved" | "rejected" }
  onboarding_completed   boolean NOT NULL DEFAULT false
  trust_score            float NOT NULL DEFAULT 50.0
  completeness_score     integer NOT NULL DEFAULT 0
  spark_verified         boolean NOT NULL DEFAULT false
  irl_verification_count integer NOT NULL DEFAULT 0
  liveness_verified      boolean NOT NULL DEFAULT false  -- Phase 4
  liveness_verified_at   datetime                        -- Phase 4
  deleted_at             datetime
  created_at             datetime
  updated_at             datetime

preference_profiles
  id              bigint PK
  user_id         bigint FK -> users NOT NULL UNIQUE
  looking_for     string NOT NULL   -- 'man' | 'woman' | 'non_binary' | 'any'
  age_min         integer NOT NULL DEFAULT 18
  age_max         integer NOT NULL DEFAULT 99
  max_distance_km integer NOT NULL DEFAULT 25
  gender_targets  jsonb   NOT NULL DEFAULT '[]'
  dealbreakers    jsonb   NOT NULL DEFAULT '[]'
  city            string  NOT NULL
  created_at      datetime
  updated_at      datetime

refresh_tokens
  id         bigint PK
  user_id    bigint FK -> users NOT NULL
  token      string NOT NULL UNIQUE
  expires_at datetime NOT NULL
  revoked_at datetime
  created_at datetime

identity_providers
  id          bigint PK
  user_id     bigint FK -> users NOT NULL
  provider    string NOT NULL   -- 'apple' | 'google' | 'vk' | 'spotify' | 'yandex_music'
  uid         string NOT NULL
  created_at  datetime
  UNIQUE (provider, uid)
```

---

## Signals

> Source feature: `docs/features/signals-v1.md`

```sql
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

signals
  id                       bigint PK
  user_id                  bigint FK -> users NOT NULL UNIQUE
  -- Step 1.0: health
  sleep_duration_avg       float
  sleep_variability        float
  chronotype               string    -- 'early_bird' | 'night_owl' | 'intermediate'
  social_jetlag            float
  activity_minutes_avg     float
  rest_hr_avg              float
  step_count_avg           float
  peak_activity_window     string
  routine_stability_index  float     -- 0.0-1.0
  computed_at              datetime
  updated_at               datetime
  -- Step 1.1: cycle (explicit opt-in only)
  cycle_tracking_enabled   boolean
  cycle_phase              string    -- 'menstrual' | 'follicular' | 'ovulatory_window' | 'luteal' | 'unknown'
  cycle_regularity_score   float     -- 0.0-1.0
  cycle_length_avg         float
  cycle_phase_confidence   float     -- 0.0-1.0
  cycle_last_computed_at   datetime
  -- Step 2.0: music
  music_top_genres         jsonb
  music_energy_avg         float     -- 0.0-1.0
  music_valence_avg         float    -- 0.0-1.0
  music_peak_listening_window string
  music_source             string    -- 'spotify' | 'yandex_music'
  -- Step 3.0: travel
  travel_trips_per_year    float
  travel_avg_duration_days float
  travel_style             string    -- 'city' | 'nature' | 'mixed'
  travel_regions           jsonb
```

---

## Spark

> Source feature: `docs/features/spark-v1.md`

```sql
sparks
  id                   bigint PK
  initiator_id         bigint FK -> users NOT NULL
  receiver_id          bigint FK -> users          -- nullable for group sparks (Step 2.0)
  spark_type           string NOT NULL DEFAULT 'duo'  -- 'duo' | 'group'
  status               string NOT NULL DEFAULT 'pending'
                       -- 'pending' | 'awaiting_receiver' | 'completed' | 'expired' | 'cancelled'
  discovery_method     string NOT NULL              -- 'bluetooth' | 'qr_code'
  session_code         string                       -- Phase 2 PIN verification
  qr_token             string                       -- single-use UUID for QR flow
  compatibility_score  float
  score_breakdown      jsonb
  match_created        boolean NOT NULL DEFAULT false
  expires_at           datetime NOT NULL
  completed_at         datetime
  deleted_at           datetime
  created_at           datetime
  updated_at           datetime

spark_participants
  id           bigint PK
  spark_id     bigint FK -> sparks NOT NULL
  user_id      bigint FK -> users NOT NULL
  confirmed_at datetime
  created_at   datetime
  UNIQUE (spark_id, user_id)

spark_rewards
  id           bigint PK
  user_id      bigint FK -> users NOT NULL
  spark_id     bigint FK -> sparks NOT NULL
  reward_type  string NOT NULL   -- 'premium_week' | 'match_credit' | 'low_score_bonus'
  status       string NOT NULL DEFAULT 'pending'  -- 'pending' | 'redeemed' | 'expired'
  valid_until  datetime
  created_at   datetime
```

---

## Matching

> Source feature: `docs/features/matching-v1.md`

```sql
matches
  id                     bigint PK
  user_a_id              bigint FK -> users NOT NULL
  user_b_id              bigint FK -> users NOT NULL
  spark_id               bigint FK -> sparks       -- nil for algorithm-origin
  origin                 integer NOT NULL DEFAULT 0  -- 0: spark | 1: algorithm
  algorithm_confidence   float                       -- nil for spark-origin
  compatibility_score    float NOT NULL
  score_breakdown        jsonb
  status                 string NOT NULL DEFAULT 'active'
                         -- 'active' | 'drifted' | 'reconnected' | 'ended'
  deleted_at             datetime
  created_at             datetime
  updated_at             datetime
  UNIQUE (user_a_id, user_b_id)
  INDEX (user_b_id)   -- required: match lookups search both user_a and user_b

ml_events
  id              bigint PK
  user_id         bigint FK -> users NOT NULL
  event_type      string NOT NULL
                  -- 'profile_shown' | 'profile_liked' | 'profile_skipped'
                  -- 'match_created' | 'first_message_sent' | 'moment_completed'
  candidate_id    bigint FK -> users   -- null for non-pair events
  model_version   string               -- null in V1
  created_at      datetime

ml_match_scores
  id              bigint PK
  user_id         bigint FK -> users NOT NULL
  candidate_id    bigint FK -> users NOT NULL
  score           float NOT NULL
  model_version   string NOT NULL
  expires_at      datetime NOT NULL
  created_at      datetime
  UNIQUE (user_id, candidate_id)
```

---

## Trust

> Source feature: `docs/features/trust-v1.md`

```sql
phone_verifications
  id           bigint PK
  user_id      bigint FK -> users NOT NULL
  phone_number string NOT NULL
  verified     boolean NOT NULL DEFAULT false
  verified_at  datetime
  created_at   datetime
  UNIQUE (user_id)   -- one active verification per user

reports
  id              bigint PK
  reporter_id     bigint FK -> users NOT NULL
  reported_id     bigint FK -> users NOT NULL
  reason          string NOT NULL   -- 'fake' | 'inappropriate' | 'no_show' | 'other'
  status          string NOT NULL DEFAULT 'pending'  -- 'pending' | 'confirmed' | 'dismissed'
  reviewed_at     datetime
  created_at      datetime
```

---

## Circles

> Source feature: `docs/features/circles-v1.md`

```sql
circles
  id           bigint PK
  circle_type  string NOT NULL   -- 'duo' | 'small_group' | 'event'
  created_by   bigint FK -> users NOT NULL
  name         string            -- required for small_group and event; null for duo
  scheduled_at datetime
  deleted_at   datetime
  created_at   datetime
  updated_at   datetime

circle_memberships
  id         bigint PK
  circle_id  bigint FK -> circles NOT NULL
  user_id    bigint FK -> users NOT NULL
  spark_id   bigint FK -> sparks   -- proof of physical encounter; null for algorithm-origin matches
  joined_at  datetime
  UNIQUE (circle_id, user_id)

circle_messages
  id         bigint PK
  circle_id  bigint FK -> circles NOT NULL
  sender_id  bigint FK -> users NOT NULL
  body       text NOT NULL
  deleted_at datetime
  created_at datetime

circle_message_reads
  id         bigint PK
  message_id bigint FK -> circle_messages NOT NULL
  user_id    bigint FK -> users NOT NULL
  read_at    datetime NOT NULL
  UNIQUE (message_id, user_id)
```

---

## Moments

> Source feature: `docs/features/moments-v1.md`

```sql
moments
  id               bigint PK
  proposer_id      bigint FK -> users NOT NULL
  receiver_id      bigint FK -> users NOT NULL
  match_id         bigint FK -> matches NOT NULL
  parent_id        bigint FK -> moments           -- set on counter-proposals
  location         string NOT NULL
  scheduled_at     datetime NOT NULL
  status           string NOT NULL DEFAULT 'pending'
                   -- 'pending' | 'confirmed' | 'declined' | 'superseded'
                   -- 'completed' | 'no_show'
  proposer_rating  integer                        -- 1-5
  receiver_rating  integer                        -- 1-5
  completed_at     datetime
  deleted_at       datetime
  created_at       datetime
  updated_at       datetime
  -- Counter-proposal chain depth is enforced server-side (MomentProposalService)
  -- capped at 5 rounds by counting the parent_id chain depth.
```

---

## Notifications

> Source feature: `docs/features/notifications-v1.md`

```sql
device_tokens
  id          bigint PK
  user_id     bigint FK -> users NOT NULL
  token       string NOT NULL UNIQUE
  platform    string NOT NULL   -- 'ios' | 'android' | 'telegram'
  active      boolean NOT NULL DEFAULT true
  created_at  datetime
  updated_at  datetime

notification_preferences
  id                    bigint PK
  user_id               bigint FK -> users NOT NULL UNIQUE
  push_enabled          boolean NOT NULL DEFAULT true
  email_enabled         boolean NOT NULL DEFAULT true
  telegram_enabled      boolean NOT NULL DEFAULT false
  telegram_chat_id      string
  spark_scored          boolean NOT NULL DEFAULT true
  match_created         boolean NOT NULL DEFAULT true
  circle_message        boolean NOT NULL DEFAULT true
  moment_received       boolean NOT NULL DEFAULT true
  moment_reminder       boolean NOT NULL DEFAULT true
  signals_stale         boolean NOT NULL DEFAULT true
  created_at            datetime
  updated_at            datetime

notifications
  id                    bigint PK
  user_id               bigint FK -> users NOT NULL
  notification_type     string NOT NULL
  title                 string NOT NULL
  body                  string NOT NULL
  read_at               datetime
  payload               jsonb
  created_at            datetime
  INDEX (user_id, read_at)   -- required: unread-first queries
```
