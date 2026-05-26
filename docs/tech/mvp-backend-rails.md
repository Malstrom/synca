# Synca MVP — Backend (Rails API)

**Version 0.6 — May 2026**  
Target: implementable in 4–6 weeks by a small team.

---

## 1. Goals & Scope

This document defines the **first production-quality MVP** of the Synca backend API. It focuses on:

- Single region: **Moscow** (RU data residency in mind, but infra details can evolve).
- Core user lifecycle: sign-up, login, profile, health summary, preference profile.
- **Synca Spark**: live in-person compatibility game between two users, with rewards.
- Basic compatibility scoring and `Match` object (for explanations and future use).

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

A match groups N participants (minimum 2). For MVP all matches are 1-to-1, but the model supports group matches from day one.

- `id` (PK)
- `compatibility_score` (float, 0–100)
- `status` (enum: `proposed`, `accepted`, `rejected`)
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

> **Why this structure?** Using a join table instead of `user_a_id / user_b_id` allows the same matching engine to handle both 1-to-1 dating matches and future group matches (e.g. friend groups, social events, run clubs) without any schema migration.

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
  Input: email/phone + password OR provider info (Apple/Google/Telegram).  
  Output: `access_token`, `refresh_token`, minimal user object.

- `POST /api/v1/auth/login`  
  Input: email/phone + password.  
  Output: tokens + user.

- `POST /api/v1/auth/refresh`  
  Input: refresh token.  
  Output: new access token.

- `GET /api/v1/me`  
  Output: user + profile + latest health summary + preference profile (minimal).

- `PUT /api/v1/profile`  
  Updates basic profile fields (display_name, bio, city, photos).

### 4.2 Health Summary

- `PUT /api/v1/health_summary`  
  Called by iOS/Android after local aggregation of HealthKit / Health Connect.  
  Input example:

  ```json
  {
    "chronotype": "intermediate",
    "sleep_start_local": "23:30",
    "sleep_end_local": "07:15",
    "avg_sleep_duration_minutes": 460,
    "routine_stability_index": 0.74,
    "activity_level": "medium",
    "peak_energy_start_local": "10:00",
    "peak_energy_end_local": "13:00",
    "recovery_score": "medium",
    "source": "apple_health"
  }
  ```

  Output: updated health summary.

For the MVP we do not support complex versioning logic: we always update the latest active record, optionally keeping history using `effective_from` / `effective_to`.

### 4.3 Preference Profile

- `PUT /api/v1/preferences`  
  Input: preference game result (embedding or reduced structure):

  ```json
  {
    "visual_embedding": { "v": [0.1, 0.7, 0.2] },
    "travel_style": "balanced"
  }
  ```

  Output: updated preference profile.

### 4.4 Matching (stub MVP)

- `POST /api/v1/matches/simulate`  
  Purpose: for internal/testing use, calculate a compatibility score between two users.  
  Input: `user_id`, `other_user_id`.  
  Output: `compatibility_score` (0–100) + breakdown per dimension.

This endpoint can be used by Spark and for internal debugging. Later it can become part of the background engine that generates real matches.

- `GET /api/v1/matches`  
  Returns all matches for the authenticated user, including participants and compatibility score.
  Output example:

  ```json
  [
    {
      "id": 1,
      "status": "accepted",
      "compatibility_score": 82.5,
      "participants": [
        { "user_id": 5,  "role": "initiator", "profile": { "display_name": "Anna" } },
        { "user_id": 12, "role": "member",    "profile": { "display_name": "Luca" } }
      ]
    }
  ]
  ```

---

## 5. Synca Spark — API & Flow

### 5.1 Goal

Allow two users who are physically together to:

1. Create a Spark session (user A).
2. Join the session via code/QR (user B).
3. Complete a short synchronized micro-test.
4. Receive a compatibility score and a reward for each user.

### 5.2 Endpoints

1. `POST /api/v1/spark_sessions`  
   Auth required.  
   Input: optional approximate location `{ "lat": ..., "lng": ... }`.  
   Logic: creates `spark_sessions` row with `status = "pending"`, generates `session_code` (6 digits) and `qr_token` (UUID).  
   Output:

   ```json
   {
     "id": 123,
     "session_code": "834920",
     "qr_token": "uuid-...",
     "status": "pending"
   }
   ```

2. `POST /api/v1/spark_sessions/:id/join`  
   Auth required.  
   Input: `session_code` OR `qr_token`.  
   Checks: session not expired, `partner_id` not yet set, optional GPS check (distance < X meters).  
   Logic: set `partner_id`, `status = "active"`, `started_at`.

3. `POST /api/v1/spark_sessions/:id/submit_answers`  
   Auth required.  
   Input: `answers` (simple JSON, e.g. array of answer IDs).  
   Logic: store `initiator_answers` or `partner_answers` depending on user; if both present, enqueue scoring job via Solid Queue (`spark` queue).

4. `GET /api/v1/spark_sessions/:id/result`  
   Auth required.  
   Logic: if both sides submitted answers:
   - compute `compatibility_score` using health summary + preference profile + micro-test;
   - create (or update) a `match` between the two users via `match_participants`;
   - call Reward Engine to issue 1 reward per user (type depends on their plan: free → `premium_week`, premium → `match_credit`);
   - update Trust Score and `spark_verified`.  
   Output example:

   ```json
   {
     "compatibility_score": 82.5,
     "dimensions": {
       "sleep_rhythm": 90,
       "energy_overlap": 85,
       "lifestyle": 78
     },
     "rewards": [
       { "type": "premium_week", "status": "pending" },
       { "type": "premium_week", "status": "pending" }
     ]
   }
   ```

5. `GET /api/v1/spark_rewards`  
   Lists rewards for the authenticated user (for iOS/Android UI).

### 5.3 Spark Business Rules (MVP)

- Max 1 **active** Spark session per user at a time.
- Sessions in `pending` or `active` expire after 10 minutes → `status = "expired"` (handled by a Solid Queue recurring job).
- Rewards:
  - Free user: `premium_week` (valid 7 days from activation).
  - Premium user: `match_credit` (valid 30 days).
  - Premium+ user: `match_credit` + optional `boost` (to be decided later).

---

## 6. Privacy & Data Protection (Backend)

- Backend receives only **aggregated health metrics**, never raw samples.
- All requests (except registration/login) must be authenticated with tokens.
- Logging: no sensitive health data in plain text logs (IDs and session codes are fine).
- For Russian users: design with the option to separate database/schema on RU-local infrastructure (e.g. Yandex Cloud / VK Cloud).

---

## 7. Non-Goals / Next Steps

Not in this iteration:

- Fully automated matching engine generating match feeds.
- Messaging/chat system.
- Real payments (Stripe, YooMoney, SBP) — for now we can use mocks or a simple manual flag.
- Group match UI and group compatibility scoring (data model is ready, UI/engine deferred to v2).

Once this MVP backend is implemented, next steps:

- Integrate the matching engine with a background job pipeline that proposes matches.
- Integrate real payments.
- Expand Trust Score model and antifraud logging.
- Enable group matches in the matching engine and expose them in the API.

---

## 8. Testing & Code Coverage

All backend code written for the MVP must be covered by automated tests.

- **Framework**: use Rails default **Minitest**.
- **What to test**:
  - Models: validations, associations, custom methods, scopes.
  - Service objects / POROs: matching logic, Spark reward logic, Trust Score updates.
  - Request/controller tests for API endpoints under `/api/v1`.
- **Coverage**:
  - Use `simplecov` to track coverage.
  - Target at least ~80% overall coverage, with higher coverage (≥90%) on core domain logic (matching, Spark, TrustScore).

Minimal setup example (to be added in `test/test_helper.rb` during implementation):

```ruby
require 'simplecov'
SimpleCov.start 'rails' do
  add_filter '/config/'
  add_filter '/test/'
end
```

Every new feature should come with tests in the same PR. Bugfixes should include a regression test.

---

## 9. CI/CD on GitHub

CI must run on every push and pull request to main branches. GitHub Actions is the default.

- **Workflow file**: `.github/workflows/backend-ci.yml`.
- **Triggers**:
  - `push` on `main` and main feature branches.
  - `pull_request` targeting `main`.
- **Jobs (MVP)**:
  - Use `ubuntu-latest` runner.
  - Steps:
    1. `actions/checkout`.
    2. Set up Ruby (respecting the version from `.ruby-version` / `Gemfile`).
    3. Install dependencies: `bundle install`.
    4. Set up PostgreSQL service and test database.
    5. Run migrations for test DB.
    6. Run tests: `bundle exec rails test`.

Example skeleton (to be refined when the Rails app exists):

```yaml
name: Backend CI

on:
  push:
    branches: ["main"]
  pull_request:
    branches: ["main"]

jobs:
  test:
    runs-on: ubuntu-latest

    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_USER: postgres
          POSTGRES_PASSWORD: postgres
          POSTGRES_DB: synca_test
        ports: ["5432:5432"]
        options: >-
          --health-cmd "pg_isready -U postgres" --health-interval 10s
          --health-timeout 5s --health-retries 5

    steps:
      - uses: actions/checkout@v4
      - uses: ruby/setup-ruby@v1
        with:
          bundler-cache: true
      - name: Set up database
        run: |
          bin/rails db:prepare RAILS_ENV=test
      - name: Run tests
        run: |
          bundle exec rails test
```

CD (deployment) is out of scope for the very first MVP but this CI workflow should be required to pass before merging any PR.

---

## 10. Background Jobs: Solid Queue

The backend uses **Solid Queue** for asynchronous processing. Solid Queue is the default
job backend in Rails 8 — it stores jobs in PostgreSQL and requires no additional
infrastructure (no Redis, no separate process in development).

- **Queue adapter**: `ActiveJob` with `Solid Queue` adapter (default in Rails 8).
  - Set in `config/application.rb`:
    ```ruby
    config.active_job.queue_adapter = :solid_queue
    ```
- **Job store**: PostgreSQL (same database as the app). No Redis required.
- **Queues (MVP)**:
  - `default` — general async tasks.
  - `matching` — heavier matching-related jobs (simulations, batch recompute).
  - `spark` — Spark-specific jobs (scoring, reward issuing, session expiry).
  - `mailers` — email delivery (if/when needed).

Examples of work that must run in background jobs:

- Compute Spark compatibility score once both users have submitted answers.
- Issue Spark rewards and update Trust Score.
- Expire Spark sessions after 10 minutes (`pending` → `expired`).
- Recompute compatibility scores in batch when matching weights change.
- Send transactional emails and, later, push notification triggers.

**Local development**:

- Solid Queue runs in-process via the Puma plugin (default Rails 8 behaviour) — no
  separate worker process needed in development.
- For tests, use `ActiveJob::TestHelper` to assert enqueued jobs; the `test` adapter
  runs jobs synchronously so no worker process is required.

**Configuration** (`config/queue.yml`):

```yaml
default: &default
  dispatchers:
    - polling_interval: 1
      batch_size: 500
  workers:
    - queues: [spark, matching, mailers, default]
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
    - queues: [matching, mailers, default]
      threads: 3
      polling_interval: 0.5
```

**Testing**:

```ruby
# assert a job was enqueued
assert_enqueued_with(job: SparkScoringJob, args: [spark_session.id]) do
  post :submit_answers, params: { answers: [...] }
end
```

**Operations (MVP)**:

- Solid Queue exposes a web UI via the `mission_control-jobs` gem (optional for v0).
  If enabled, protect it behind admin authentication and do not expose it publicly.
- Monitor job throughput and failures via standard Rails log output or a simple
  health-check endpoint that queries the `solid_queue_jobs` table.
