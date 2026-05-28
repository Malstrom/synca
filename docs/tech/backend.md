# Synca — Rails API Technical Spec

**Version 1.0 — May 2026**

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
  has_many :spark_sessions (as initiator or receiver)
  has_many :matches
  has_many :sync_room_memberships
  has_many :sync_rooms, through: :sync_room_memberships

Profile
  belongs_to :user
  columns: display_name, bio, photos (JSON), trust_score (float, default: 50.0),
           spark_verified (bool), irl_verification_count (int)

HealthSummary
  belongs_to :user
  columns: sleep_duration_avg, sleep_variability, chronotype, social_jetlag,
           activity_minutes_avg, rest_hr_avg, step_count_avg,
           peak_activity_window, routine_stability_index, updated_at

SparkSession
  belongs_to :initiator (User)
  belongs_to :receiver  (User)
  columns: status (enum: pending | completed | expired),
           compatibility_score (float), location_hash (hashed),
           completed_at

Match
  belongs_to :user_a (User)
  belongs_to :user_b (User)
  columns: compatibility_score (float),
           origin (enum: spark | algorithm, default: spark),
           algorithm_confidence (float, nullable),
           status (enum: active | expired | unmatched),
           expires_at

SyncRoom
  belongs_to :creator (User)
  has_many   :sync_room_memberships
  has_many   :sync_room_messages
  columns: name, room_type (enum: duo | small_group | event_room)

SyncRoomMembership
  belongs_to :sync_room
  belongs_to :user
  belongs_to :spark_session  -- cryptographic proof of physical encounter
  columns: joined_at

SyncRoomMessage
  belongs_to :sync_room
  belongs_to :sender (User)
  columns: body (text), read_at (datetime nullable)
```

---

## Services

| Service | Responsibility |
|---|---|
| `CompatibilityScoreService` | Computes weighted score (0–100) from two `HealthSummary` records |
| `TrustScoreService` | Updates `profiles.trust_score` based on events (spark, reports, liveness) |
| `MatchCreationService` | Creates a `Match` record after score threshold validation |
| `SyncRoomAdmissionService` | Validates Spark graph before creating/joining a `SyncRoom` |

---

## Background Jobs (Solid Queue)

| Job | Queue | Schedule | Description |
|---|---|---|---|
| `MatchingJob` | `algorithm` | Nightly (00:00 UTC) | Iterates users with recent `HealthSummary`, computes pairwise scores, creates `Match` records with `origin: :algorithm` for score ≥ 65 |
| `MatchDecayJob` | `default` | Daily | Marks matches as `:drifted` if health data has not been updated in 30 days |
| `SparkSessionExpiryJob` | `default` | Hourly | Expires `SparkSession` records older than 15 minutes with status `:pending` |

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
| Sync Room duo admission | ≥ 50 | Per verified Spark pair |
| Sync Room group admission | ≥ 50 | Per each pair with verified Spark |

---

## Premium Gating

Premium status is stored as `profiles.premium` (boolean). Checked in controllers
via `require_premium!` helper. Features gated behind premium:

- Algorithm-origin matches
- Compatibility breakdown detail
- Unlimited Small Group Sync Rooms (free: 1 active)
- Event Room creation
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
      spark_sessions_controller.rb
      matches_controller.rb
      sync_rooms_controller.rb
  models/
    user.rb  profile.rb  health_summary.rb
    spark_session.rb  match.rb
    sync_room.rb  sync_room_membership.rb  sync_room_message.rb
  services/
    compatibility_score_service.rb
    trust_score_service.rb
    match_creation_service.rb
    sync_room_admission_service.rb
  jobs/
    matching_job.rb
    match_decay_job.rb
    spark_session_expiry_job.rb
  channels/
    sync_room_channel.rb
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
