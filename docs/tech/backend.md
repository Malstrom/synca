# Synca — Rails API Technical Spec

**Version 2.0 — May 2026**

> This document derives entirely from the feature docs in `docs/features/`.
> In case of conflict, the feature doc is always the source of truth.

---

## Stack

| Layer | Technology |
|---|---|
| Language | Ruby 3.3 |
| Framework | Rails 8.0 (API mode) |
| Database | PostgreSQL 16 |
| Background jobs | Solid Queue (no Redis, no Sidekiq) |
| WebSockets | Action Cable |
| Auth | `has_secure_password` + JWT (`gem "jwt"`) |
| Storage | Active Storage + AWS S3 |
| CI | GitHub Actions — RuboCop, Brakeman, Minitest, SimpleCov |
| Deployment | Render (MVP), Kamal-ready |

---

## Key Conventions

- **No Devise, no Warden.** Auth is handled via `has_secure_password` on `User` and
  a custom `AuthenticationController` that issues JWT access + refresh tokens.
- **No Redis.** Solid Queue persists jobs to PostgreSQL. Action Cable uses the
  async adapter for MVP (switch to Solid Cable for horizontal scaling).
- **No shell commands** (`system`, `exec`, `Open3`) in app code. Use pure Ruby or
  ActiveRecord. Brakeman runs on every CI push and fails the build on any shell injection risk.
- **Variable names must be descriptive.** Never use single-letter or abbreviated names
  (`p`, `u`, `r`, `s`). Use full domain names (`profile`, `user`, `signal`, `match`).
- **Test files live only in `test/`.** Never place test files in `app/` — Zeitwerk
  will crash trying to autoload them.
- **Feature docs are the schema source of truth.** Never define or redefine a table
  here that already has a canonical definition in `docs/features/`. Use `-- ref:` comments
  to point to the owning doc.

---

## Domain Models

Each model lists only its Rails associations and a `-- ref:` to the feature doc
that owns its schema. Never duplicate column definitions here.

```ruby
User
  has_one  :profile
  has_one  :signal                          # ref: docs/features/signals-v1.md
  has_many :refresh_tokens                  # ref: docs/features/profile-v1.md
  has_many :identity_providers              # ref: docs/features/profile-v1.md
  has_many :sparks, foreign_key: :initiator_id  # ref: docs/features/spark-v1.md
  has_many :spark_rewards                   # ref: docs/features/spark-v1.md
  has_many :matches, ->(user) {
    where('user_a_id = ? OR user_b_id = ?', user.id, user.id)
  }                                         # ref: docs/features/matching-v1.md
  has_many :phone_verifications             # ref: docs/features/trust-v1.md

Profile
  belongs_to :user
  has_one    :preference_profile            # ref: docs/features/profile-v1.md
  has_many   :circle_memberships            # ref: docs/features/circles-v1.md
  has_many   :circles, through: :circle_memberships
  has_many   :moments_as_proposer, class_name: 'Moment', foreign_key: :proposer_id
  has_many   :moments_as_receiver, class_name: 'Moment', foreign_key: :receiver_id
  has_many   :reports_received, class_name: 'Report', foreign_key: :reported_id
  # ref: docs/features/profile-v1.md

Signal                                      # ref: docs/features/signals-v1.md
  belongs_to :user
  # One row per user. Columns grow per step:
  # Step 1.0: health columns (sleep, activity, chronotype, ...)
  # Step 2.0: music columns (music_top_genres, music_energy_avg, ...)
  # Step 3.0: travel columns (travel_trips_per_year, travel_style, ...)

PreferenceProfile                           # ref: docs/features/profile-v1.md
  belongs_to :profile

RefreshToken                                # ref: docs/features/profile-v1.md
  belongs_to :user

IdentityProvider                            # ref: docs/features/profile-v1.md
  belongs_to :user

Spark                                       # ref: docs/features/spark-v1.md
  belongs_to :initiator, class_name: 'User'
  belongs_to :receiver,  class_name: 'User', optional: true  # nullable in group sparks
  has_many   :spark_rewards
  has_many   :spark_participants            # Step 2.0 only

SparkReward                                 # ref: docs/features/spark-v1.md
  belongs_to :user
  belongs_to :spark

SparkParticipant                            # ref: docs/features/spark-v1.md (Step 2.0)
  belongs_to :spark
  belongs_to :user

Match                                       # ref: docs/features/matching-v1.md
  belongs_to :user_a, class_name: 'User'
  belongs_to :user_b, class_name: 'User'
  belongs_to :spark, optional: true         # nil for algorithm-origin matches
  has_many   :moments
  # status enum: active | drifted | reconnected | ended
  # origin enum: spark | algorithm

Circle                                      # ref: docs/features/circles-v1.md
  belongs_to :creator, class_name: 'Profile'
  has_many   :circle_memberships
  has_many   :circle_messages
  # circle_type enum: duo | small_group | event

CircleMembership                            # ref: docs/features/circles-v1.md
  belongs_to :circle
  belongs_to :profile
  belongs_to :spark, optional: true         # nil for duo on algorithm-origin matches

CircleMessage                               # ref: docs/features/circles-v1.md
  belongs_to :circle
  belongs_to :sender, class_name: 'Profile'

Moment                                      # ref: docs/features/moments-v1.md
  belongs_to :proposer, class_name: 'Profile'
  belongs_to :receiver, class_name: 'Profile'
  belongs_to :match
  belongs_to :parent, class_name: 'Moment', optional: true
  # status enum: pending | confirmed | declined | superseded | completed | no_show

PhoneVerification                           # ref: docs/features/trust-v1.md
  belongs_to :user

Report                                      # ref: docs/features/trust-v1.md
  belongs_to :reporter, class_name: 'Profile'
  belongs_to :reported, class_name: 'Profile'
  # status enum: pending | confirmed | dismissed
```

---

## Services

| Service | Responsibility | Ref |
|---|---|---|
| `CompatibilityScoreService` | Computes weighted score (0–100) from two `Signal` records | matching-v1.md |
| `TrustScoreService` | Recomputes `profiles.trust_score` on relevant events (spark, report, liveness, moment) | trust-v1.md |
| `MatchCreationService` | Creates a `Match` after score threshold validation | matching-v1.md |
| `CircleAdmissionService` | Validates Spark graph before creating/joining a `Circle` | circles-v1.md |
| `MomentCreationService` | Creates a `Moment`; enforces counter-proposal chain cap (max 5 rounds) | moments-v1.md |

---

## Background Jobs (Solid Queue)

| Job | Queue | Schedule | Description | Ref |
|---|---|---|---|---|
| `MatchingJob` | `algorithm` | Nightly 00:00 UTC | Iterates users with `signals` updated in last 30 days; creates `Match` records with `origin: :algorithm` for score ≥ 65 | matching-v1.md |
| `MatchDecayJob` | `default` | Daily | Marks matches as `:drifted` when signals not updated in 30 days | matching-v1.md |
| `SparkExpiryJob` | `default` | Hourly | Expires `Spark` records still `:pending` after 10 minutes | spark-v1.md |
| `MomentReminderJob` | `default` | Hourly | Prompts both users to mark a `Moment` as completed or no-show after `scheduled_at` | moments-v1.md |
| `PhotoModerationJob` | `default` | On upload | Runs automated moderation on newly uploaded photos; updates `moderation_status` in `profiles.photos` JSON | trust-v1.md |

---

## Auth Flow

Ref: `docs/features/profile-v1.md` — Step 1.0

```
POST /api/v1/auth/register  → creates User + Profile, returns access token + refresh token
POST /api/v1/auth/login     → validates password, returns access token + refresh token
POST /api/v1/auth/refresh   → exchanges refresh token for new access token (single-use, rotated)
DELETE /api/v1/auth/logout  → revokes refresh token
GET  /api/v1/auth/me        → returns current user from JWT
POST /api/v1/auth/social    → OAuth (Apple | Google | VK) — Step 2.0
```

JWT payload: `{ user_id: integer, exp: unix_timestamp }`.
Access token expiry: 30 days. Refresh token expiry: 90 days.
Refresh tokens are single-use and rotated on each use.
All protected endpoints require `Authorization: Bearer <token>`.
Auth enforced via `before_action :authenticate_user!` in `ApplicationController`.

---

## Score Thresholds

Ref: `docs/features/matching-v1.md` — single source of truth for all threshold values.

| Threshold | Value | Context |
|---|---|---|
| Spark match creation | ≥ 50 | `origin: :spark` |
| Algorithm match creation | ≥ 65 | `origin: :algorithm` |
| Circle duo admission | ≥ 50 | Per verified Spark pair |
| Circle group admission | ≥ 50 | Per each pair with verified Spark |

---

## Premium Gating

Premium status is stored as `profiles.premium` (boolean). Checked in controllers
via `require_premium!` helper.

| Feature | Free | Premium | Ref |
|---|---|---|---|
| Spark-origin matches | ✅ | ✅ | matching-v1.md |
| Algorithm-origin matches | ❌ | ✅ | matching-v1.md |
| Compatibility breakdown detail | ❌ | ✅ | matching-v1.md |
| Duo Circle | ✅ | ✅ | circles-v1.md |
| Small Group Circle | 1 active | Unlimited | circles-v1.md |
| Event Circle creation | ❌ | ✅ | circles-v1.md |
| Spark Invite Link | ❌ | ✅ | circles-v1.md |

---

## Security Constraints

- Raw HealthKit / Health Connect samples are **never stored** on the backend.
  Only aggregated metrics computed on-device are sent and stored in `signals`.
  Ref: `docs/features/signals-v1.md`.
- Spark location is stored as a **salted hash** — the original coordinates are never persisted.
  Ref: `docs/features/spark-v1.md`.
- Passwords are hashed with bcrypt via `has_secure_password`. Never stored in plaintext.
- Refresh tokens are stored hashed. Single-use and rotated on each exchange.
  Ref: `docs/features/profile-v1.md`.
- Brakeman runs on every CI push. Any shell injection or SQL injection risk fails the build.

---

## Folder Structure

```
app/
  controllers/
    api/v1/
      auth_controller.rb
      profiles_controller.rb
      signals_controller.rb
      sparks_controller.rb
      spark_rewards_controller.rb
      matches_controller.rb
      circles_controller.rb
      moments_controller.rb
      trust_controller.rb
      reports_controller.rb
  models/
    user.rb
    profile.rb
    preference_profile.rb
    refresh_token.rb
    identity_provider.rb
    signal.rb
    spark.rb
    spark_reward.rb
    spark_participant.rb
    match.rb
    circle.rb
    circle_membership.rb
    circle_message.rb
    moment.rb
    phone_verification.rb
    report.rb
  services/
    compatibility_score_service.rb
    trust_score_service.rb
    match_creation_service.rb
    circle_admission_service.rb
    moment_creation_service.rb
  jobs/
    matching_job.rb
    match_decay_job.rb
    spark_expiry_job.rb
    moment_reminder_job.rb
    photo_moderation_job.rb
  channels/
    circle_channel.rb
test/
  models/
  controllers/
  services/
  jobs/
  fixtures/
```

---

## CI Pipeline

`bin/rails ci` runs in order:

1. `rubocop --autocorrect` — style enforcement
2. `bundle-audit` — dependency vulnerability check
3. `brakeman --no-pager` — security static analysis
4. `rails test` — full test suite with SimpleCov
5. Coverage check — fails if < 90%
6. Push branch to origin

All PRs target `main`. Squash and merge only. Branch protection: CI must pass before merge.
