# Synca — Rails API Technical Spec

**Version 1.1 — May 2026**

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
  a custom `AuthenticationController` that issues JWT tokens.
- **No Redis.** Solid Queue persists jobs to PostgreSQL. Action Cable uses the
  async adapter for MVP (switch to Solid Cable for horizontal scaling).
- **No shell commands** (`system`, `exec`, `Open3`) in app code. Use pure Ruby or
  ActiveRecord. Brakeman runs on every CI push and fails the build on any shell injection risk.
- **Variable names must be descriptive.** Never use single-letter or abbreviated names
  (`p`, `u`, `r`, `hs`). Use full domain names (`profile`, `user`, `reward`, `health_summary`).
- **Test files live only in `test/`.** Never place test files in `app/` — Zeitwerk
  will crash trying to autoload them.

---

## Domain Models

```
User
  has_one  :profile
  has_one  :health_summary
  has_many :sparks, foreign_key: :initiator_id
  has_many :spark_rewards
  has_many :matches
  has_many :circle_memberships, through: :profile
  has_many :circles, through: :circle_memberships
  has_many :moments, foreign_key: :proposer_id, through: :profile

Profile
  belongs_to :user
  columns: display_name, bio, photos (JSON), trust_score (float, default: 50.0),
           spark_verified (bool), irl_verification_count (int)

HealthSummary
  belongs_to :user
  columns: sleep_duration_avg, sleep_variability, chronotype, social_jetlag,
           activity_minutes_avg, rest_hr_avg, step_count_avg,
           peak_activity_window, routine_stability_index, updated_at

Spark
  belongs_to :initiator (User)
  belongs_to :receiver  (User)  -- nullable for group sparks (Step 2.0)
  has_many   :spark_rewards
  columns: status (enum: pending | completed | expired | cancelled),
           discovery_method (enum: bluetooth | qr_code),
           session_code (string),
           qr_token (string),
           compatibility_score (float),
           score_breakdown (jsonb),
           match_created (bool, default: false),
           expires_at (datetime),
           completed_at (datetime)
  -- ref: docs/features/spark-v1.md

SparkReward
  belongs_to :user
  belongs_to :spark
  columns: reward_type (enum: premium_week | match_credit),
           status (enum: pending | redeemed | expired),
           valid_until (datetime)
  -- ref: docs/features/spark-v1.md

Match
  belongs_to :user_a (User)
  belongs_to :user_b (User)
  columns: compatibility_score (float),
           origin (enum: spark | algorithm, default: spark),
           algorithm_confidence (float, nullable),
           status (enum: active | expired | unmatched),
           expires_at
  -- ref: docs/features/matching-v1.md

Circle
  belongs_to :creator, class_name: 'Profile'
  has_many   :circle_memberships
  has_many   :circle_messages
  columns: circle_type (enum: duo | small_group | event),
           name (string, null for duo),
           scheduled_at (datetime, optional)
  -- ref: docs/features/circles-v1.md

CircleMembership
  belongs_to :circle
  belongs_to :profile
  belongs_to :spark, optional: true  -- proof of physical encounter; nil for duo on algorithm matches
  columns: joined_at
  -- ref: docs/features/circles-v1.md

CircleMessage
  belongs_to :circle
  belongs_to :sender, class_name: 'Profile'
  columns: body (text), read_at (datetime nullable)
  -- ref: docs/features/circles-v1.md

Moment
  belongs_to :proposer, class_name: 'Profile'
  belongs_to :receiver, class_name: 'Profile'
  belongs_to :match
  belongs_to :parent, class_name: 'Moment', optional: true
  columns: location (string),
           scheduled_at (datetime),
           status (enum: pending | confirmed | declined | superseded | completed | no_show),
           proposer_rating (integer, 1-5),
           receiver_rating (integer, 1-5),
           completed_at (datetime)
  -- ref: docs/features/moments-v1.md
```

---

## Services

| Service | Responsibility |
|---|---|
| `CompatibilityScoreService` | Computes weighted score (0–100) from two `HealthSummary` records |
| `TrustScoreService` | Updates `profiles.trust_score` based on events (spark, reports, liveness, moments) |
| `MatchCreationService` | Creates a `Match` record after score threshold validation |
| `CircleAdmissionService` | Validates Spark graph before creating/joining a `Circle` |
| `MomentCreationService` | Creates a `Moment` and enforces counter-proposal chain cap (max 5 rounds) |

---

## Background Jobs (Solid Queue)

| Job | Queue | Schedule | Description |
|---|---|---|---|
| `MatchingJob` | `algorithm` | Nightly (00:00 UTC) | Iterates users with recent `HealthSummary`, computes pairwise scores, creates `Match` records with `origin: :algorithm` for score ≥ 65 |
| `MatchDecayJob` | `default` | Daily | Marks matches as `:drifted` if health data has not been updated in 30 days |
| `SparkExpiryJob` | `default` | Hourly | Expires `Spark` records older than 10 minutes with status `:pending` |
| `MomentReminderJob` | `default` | Hourly | Prompts both users to mark a `Moment` as completed or no-show after `scheduled_at` has passed |

---

## Auth Flow

```
POST /auth/register  → creates User + Profile, returns JWT
POST /auth/login     → validates password, returns JWT
GET  /auth/me        → returns current user from JWT
```

JWT payload: `{ user_id:, exp: }`. Expiry: 30 days. No refresh tokens for MVP.

All protected endpoints require `Authorization: Bearer <token>` header.
Auth is enforced via `before_action :authenticate_user!` in `ApplicationController`.

---

## Score Thresholds

| Threshold | Value | Context |
|---|---|---|
| Spark match creation | ≥ 50 | `origin: :spark` |
| Algorithm match creation | ≥ 65 | `origin: :algorithm` |
| Circle duo admission | ≥ 50 | Per verified Spark pair |
| Circle group admission | ≥ 50 | Per each pair with verified Spark |

---

## Premium Gating

Premium status is stored as `profiles.premium` (boolean). Checked in controllers
via `require_premium!` helper. Features gated behind premium:

- Algorithm-origin matches
- Compatibility breakdown detail
- Unlimited Small Group Circles (free: 1 active)
- Event Circle creation
- Spark Invite Link (facilitate missing Spark)

---

## Security Constraints

- Raw HealthKit / Health Connect samples are **never stored** on the backend.
  Only aggregated metrics computed on-device are sent and stored in `HealthSummary`.
- Spark location is stored as a **salted hash** — the original coordinates are
  never persisted.
- Brakeman runs on every CI push. Any detected shell injection or SQL injection
  risk fails the build.
- `has_secure_password` handles bcrypt hashing automatically. Passwords are never
  stored in plaintext.

---

## Folder Structure

```
app/
  controllers/
    api/v1/
      auth_controller.rb
      profiles_controller.rb
      health_summaries_controller.rb
      sparks_controller.rb
      spark_rewards_controller.rb
      matches_controller.rb
      circles_controller.rb
      moments_controller.rb
  models/
    user.rb  profile.rb  health_summary.rb
    spark.rb  spark_reward.rb
    match.rb
    circle.rb  circle_membership.rb  circle_message.rb
    moment.rb
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
