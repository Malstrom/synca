# Synca MVP — Backend (Rails API)

**Version 0.7 — May 2026**  
Target: implementable in 4–6 weeks by a small team.

---

## 1. Goals & Scope

This document defines the **first production-quality MVP** of the Synca backend API. It focuses on:

- Single region: **Moscow** (RU data residency in mind, but infra details can evolve).
- Core user lifecycle: sign-up, login, profile, health summary, preference profile.
- **Synca Spark**: live in-person compatibility game between two users, with rewards.
- Basic compatibility scoring and `Match` object with dual origin support (`:spark` / `:algorithm`).

Out of scope for the MVP backend:

- Full chat system (can be mocked or delegated to a later phase).
- Payments and subscriptions (stub endpoints or external integration only).
- Complex analytics dashboard.

---

## 2. High-Level Architecture

- **Rails API-only app** (no server-rendered views).
- **PostgreSQL** primary database.
- **Solid Queue** for background jobs and asynchronous processing (built into Rails 8, no external dependencies).
- Stateless API behind a load balancer.
- Authentication: JWT or signed tokens (short-lived access token + refresh token).

```text
iOS / Android / Telegram
        ↓
     Rails API
        ↓
 PostgreSQL (app data + Solid Queue job store)
```

---

## 3. Domain Model (MVP)

### 3.1 Users & Profiles

**users**

- `id` (PK)
- `email` (nullable for social login-only)
- `phone` (optional, string)
- `auth_provider` (enum: `email`, `apple`, `google`, `telegram`)
- `provider_uid` (string, nullable)
- `password_digest`
- `created_at`, `updated_at`

**profiles** (1–1 with users)

- `id` (PK)
- `user_id` (FK → users)
- `display_name`
- `birth_date`
- `gender` (string or enum)
- `bio` (short text)
- `city` (e.g. `Moscow`)
- `photo_url_main` (string)
- `photo_urls` (JSONB array of strings)
- `trust_score` (float, 0–100, default 50)
- `spark_verified` (boolean, default false)
- `created_at`, `updated_at`

### 3.2 Health & Lifestyle

**health_summaries** (derived data only, no raw samples)

- `id` (PK)
- `user_id` (FK)
- `chronotype` (enum: `early_bird`, `intermediate`, `night_owl`)
- `sleep_start_local` (time) — average sleep onset
- `sleep_end_local` (time) — average wake time
- `avg_sleep_duration_minutes` (integer)
- `routine_stability_index` (float, 0–1)
- `activity_level` (enum: `low`, `medium`, `high`)
- `peak_energy_start_local` (time)
- `peak_energy_end_local` (time)
- `recovery_score` (enum: `low`, `medium`, `high`)
- `source` (enum: `apple_health`, `health_connect`)
- `effective_from` (date)
- `effective_to` (date, nullable)
- `created_at`, `updated_at`

**preference_profiles**

- `id` (PK)
- `user_id` (FK)
- `visual_embedding` (JSONB) — vector or compressed representation
- `travel_style` (enum: `homebody`, `balanced`, `explorer`, nullable for MVP)
- `music_profile` (JSONB, optional in MVP)
- `created_at`, `updated_at`

### 3.3 Matching & Spark

**matches**

A match groups N participants (minimum 2). For MVP all matches are 1-to-1, but the model
supports group matches from day one.

- `id` (PK)
- `compatibility_score` (float, 0–100)
- `status` (enum: `proposed`, `accepted`, `rejected`)
- `origin` (enum: `spark`, `algorithm`, default: `spark`) — how the match was created
- `algorithm_confidence` (float, nullable) — set only for `origin: :algorithm`
- `accepted_at` (datetime, nullable)
- `rejected_at` (datetime, nullable)
- `created_at`, `updated_at`

**match_participants** (join table between matches and users)

- `id` (PK)
- `match_id` (FK → matches)
- `user_id` (FK → users)
- `role` (enum: `initiator`, `member`)
- `created_at`, `updated_at`
- **Unique index** on `[match_id, user_id]`

> **Why this structure?** Using a join table instead of `user_a_id / user_b_id` allows
> the same matching engine to handle both 1-to-1 dating matches and future group matches
> (e.g. Sync Rooms, sport events) without any schema migration.

**spark_sessions**

- `id` (PK)
- `initiator_id` (FK → users)
- `partner_id` (FK → users, nullable until joined)
- `status` (enum: `pending`, `active`, `completed`, `expired`)
- `session_code` (string, 6 chars, unique)
- `qr_token` (string, UUID)
- `location_lat` (float, nullable)
- `location_lng` (float, nullable)
- `started_at` (datetime, nullable)
- `completed_at` (datetime, nullable)
- `initiator_answers` (JSONB, nullable)
- `partner_answers` (JSONB, nullable)
- `compatibility_score` (float, nullable)
- `reward_issued_initiator` (boolean, default false)
- `reward_issued_partner` (boolean, default false)
- `created_at`, `updated_at`

**spark_rewards** (optional, can be derived, but explicit table helps)

- `id` (PK)
- `user_id` (FK)
- `spark_session_id` (FK)
- `reward_type` (enum: `premium_week`, `match_credit`, `boost`)
- `status` (enum: `pending`, `redeemed`, `expired`)
- `valid_until` (datetime)
- `created_at`, `updated_at`

---

## 4. API Surface (v0)

All endpoints are JSON-based, prefixed with `/api/v1`.

### 4.1 Auth & User

- `POST /api/v1/auth/register`
- `POST /api/v1/auth/login`
- `POST /api/v1/auth/refresh`
- `GET /api/v1/me`
- `PUT /api/v1/profile`

### 4.2 Health Summary

- `PUT /api/v1/health_summary`

### 4.3 Preference Profile

- `PUT /api/v1/preferences`

### 4.4 Matching

- `POST /api/v1/matches/simulate` — internal/testing: score between two users
- `GET /api/v1/matches` — all matches for authenticated user (includes `origin` field)

See `docs/api/` for full request/response shapes.

---

## 5. Synca Spark — API & Flow

### 5.1 Goal

Allow two users who are physically together to:

1. Create a Spark session (user A).
2. Join the session via code/QR (user B).
3. Complete a short synchronized micro-test.
4. Receive a compatibility score and a reward for each user.
5. If score ≥ 50, create a `Match` with `origin: :spark`.

### 5.2 Endpoints

1. `POST /api/v1/spark_sessions`
2. `POST /api/v1/spark_sessions/:id/join`
3. `POST /api/v1/spark_sessions/:id/submit_answers`
4. `GET /api/v1/spark_sessions/:id/result`
5. `GET /api/v1/spark_rewards`

### 5.3 Spark Business Rules (MVP)

- Max 1 **active** Spark session per user at a time.
- Sessions in `pending` or `active` expire after 10 minutes → `status = "expired"`
  (handled by a Solid Queue recurring job on the `spark` queue).
- Rewards:
  - Free user: `premium_week` (valid 7 days from activation).
  - Premium user: `match_credit` (valid 30 days).

---

## 6. Privacy & Data Protection (Backend)

- Backend receives only **aggregated health metrics**, never raw samples.
- All requests (except registration/login) must be authenticated with tokens.
- Logging: no sensitive health data in plain text logs.
- For Russian users: design with the option to separate database/schema on RU-local
  infrastructure (e.g. Yandex Cloud / VK Cloud).

---

## 7. Non-Goals / Next Steps

Not in this iteration:

- Messaging/chat system.
- Real payments (Stripe, YooMoney, SBP) — for now we can use mocks or a simple manual flag.
- Group Sync Rooms UI (data model ready via `docs/product/sync-rooms.md`, engine deferred to v2).

---

## 8. Testing & Code Coverage

All backend code written for the MVP must be covered by automated tests.

- **Framework**: Rails default **Minitest**.
- **What to test**:
  - Models: validations, associations, custom methods, scopes.
  - Service objects / POROs: matching logic, Spark reward logic, TrustScore updates.
  - Request/controller tests for all `/api/v1` endpoints.
- **Coverage**: use `simplecov`. **Global target: ≥ 90%.** Core domain logic
  (matching, Spark, TrustScore) must reach 100%.

Minimal setup (add to `test/test_helper.rb`):

```ruby
require 'simplecov'
SimpleCov.start 'rails' do
  add_filter '/config/'
  add_filter '/test/'
  minimum_coverage 90
end
```

Every new feature ships with tests in the same PR. Bugfixes include a regression test.

---

## 9. CI/CD on GitHub

CI must run on every push and pull request to main branches. GitHub Actions is the default.

- **Workflow file**: `.github/workflows/backend-ci.yml`.
- **Triggers**: push on `main`, pull_request targeting `main`.
- **Jobs (MVP)**:
  1. `actions/checkout`
  2. Set up Ruby (respecting `.ruby-version` / `Gemfile`)
  3. `bundle install`
  4. Set up PostgreSQL service and test database
  5. Run migrations for test DB
  6. `bundle exec rails test`

---

## 10. Background Jobs: Solid Queue

The backend uses **Solid Queue** for asynchronous processing (Rails 8 default, no Redis).

- **Queue adapter**: set in `config/application.rb`:
  ```ruby
  config.active_job.queue_adapter = :solid_queue
  ```
- **Job store**: PostgreSQL (same database as the app).
- **Queues (MVP)**:
  - `default` — general async tasks.
  - `algorithm` — nightly `MatchingJob` (algorithm-origin match creation, batch scoring).
  - `spark` — Spark scoring, reward issuing, session expiry.
  - `mailers` — email delivery.

> The `algorithm` queue is intentionally separate from `spark` so that the nightly
> batch run never blocks time-sensitive Spark session scoring.

**Examples of background work:**

- Compute Spark compatibility score once both users have submitted answers (`spark` queue).
- Issue Spark rewards and update TrustScore (`spark` queue).
- Expire Spark sessions after 10 minutes (`spark` queue).
- Nightly `MatchingJob`: create algorithm-origin matches from health summaries (`algorithm` queue).
- Recompute compatibility scores in batch when matching weights change (`algorithm` queue).
- Send transactional emails and push notification triggers (`mailers` queue).

**Configuration** (`config/queue.yml`):

```yaml
default: &default
  dispatchers:
    - polling_interval: 1
      batch_size: 500
  workers:
    - queues: [spark, algorithm, mailers, default]
      threads: 3
      polling_interval: 0.1

development:
  <<: *default

production:
  <<: *default
  workers:
    - queues: [spark]
      threads: 5
      polling_interval: 0.1
    - queues: [algorithm]
      threads: 2
      polling_interval: 1.0
    - queues: [mailers, default]
      threads: 3
      polling_interval: 0.5
```

**Testing**:

```ruby
assert_enqueued_with(job: SparkScoringJob, args: [spark_session.id]) do
  post :submit_answers, params: { answers: [...] }
end
```

**Operations (MVP)**: Solid Queue exposes a web UI via `mission_control-jobs` gem (optional
for v0). Protect it behind admin authentication.
