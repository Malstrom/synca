# Synca — Rails Backend Technical Spec

**Version 1.1 — May 2026**

---

## Stack

| Layer | Technology |
|---|---|
| Language | Ruby 3.3 |
| Framework | Rails 8.0 (API mode) |
| Database | PostgreSQL 16 |
| Background jobs | Solid Queue (no Redis) |
| WebSockets | Action Cable (Solid Cable adapter) |
| Auth | `has_secure_password` + JWT (gem `jwt`) |
| File storage | Active Storage + S3-compatible |
| Tests | Minitest + SimpleCov (≥ 90%) |

---

## Score Thresholds

All score thresholds (Spark-origin, algorithm-origin, Circle admission) are defined
exclusively in `docs/features/matching-v1.md` and `docs/features/circles-v1.md`.
This file must not introduce or repeat numeric threshold values.

---

## Domain Model (Rails associations)

```ruby
# app/models/user.rb
has_one :profile
has_one :signal
has_one :declared_preference   # ref: docs/features/signals-v1.md Step 0
has_one :trust_score
has_one :preference_profile    # ref: docs/features/profile-v1.md
has_many :sparks, foreign_key: :initiator_id
has_many :identity_providers

# app/models/profile.rb
belongs_to :user
belongs_to :city
has_one :preference_profile
has_many :circle_memberships
has_many :circles, through: :circle_memberships
has_many :moments, foreign_key: :proposer_id

# app/models/match.rb
belongs_to :user_a, class_name: 'User'
belongs_to :user_b, class_name: 'User'
belongs_to :spark, optional: true
enum :origin, { spark: 0, algorithm: 1 }, default: :spark
enum :status, { active: 0, drifted: 1, reconnected: 2, ended: 3 }, default: :active
# Note: Match uses user_a_id/user_b_id (FK -> users).
# Duo Circle creation resolves profile via match.user_a.profile.
# Ref: docs/features/circles-v1.md Step 1.0

# app/models/spark.rb
belongs_to :initiator, class_name: 'User'
belongs_to :receiver, class_name: 'User', optional: true
has_many :spark_participants
has_many :spark_rewards
enum :status, { pending: 0, active: 1, completed: 2, expired: 3, cancelled: 4 }
enum :spark_type, { duo: 0, group: 1 }, default: :duo

# app/models/circle.rb
belongs_to :creator, class_name: 'Profile', foreign_key: :created_by
has_many :circle_memberships
has_many :circle_messages
enum :circle_type, { duo: 0, small_group: 1, event: 2 }

# app/models/moment.rb
belongs_to :proposer, class_name: 'Profile'
belongs_to :receiver, class_name: 'Profile'
belongs_to :match
belongs_to :parent, class_name: 'Moment', optional: true
enum :status, { pending: 0, confirmed: 1, declined: 2, superseded: 3, completed: 4, no_show: 5 }

# app/models/declared_preference.rb
belongs_to :user
# FK: declared_preferences.user_id -> users (NOT profiles)
# Loaded via user.declared_preference in CompatibilityScoreService
```

---

## Background Jobs

| Job | Queue | Trigger | Description |
|---|---|---|---|
| `ScoringJob` | `spark` | Spark completion | Computes compatibility score for a Spark session |
| `MatchingJob` | `algorithm` | Nightly (cron) | Algorithm-origin match generation |
| `MatchDecayJob` | `default` | Daily (cron) | Marks matches as `drifted` when signals are stale; marks as `reconnected` when signals are refreshed or new Spark completed. Ref: `docs/features/matching-v1.md — Match Lifecycle`. |
| `TrustScoreJob` | `default` | Event-triggered | Recomputes TrustScore for a user |
| `MomentReminderJob` | `default` | Scheduled | Sends reminder before a confirmed Moment |

---

## Services

| Service | Description |
|---|---|
| `CompatibilityScoreService` | Computes pairwise compatibility score from `signals` and `declared_preferences`. Accepts `user_a, user_b`. Returns score (0–100) + `score_breakdown` hash. |
| `MatchProposalService` | Wraps `CompatibilityScoreService` for algorithm flow; filters candidate pool. |
| `TrustScoreService` | Computes or recomputes a user's `TrustScore` from image, behavioral, and IRL signals. |
| `MomentProposalService` | Generates 1–3 Moment proposals from match signals, city, and time preferences. |
| `SparkRewardService` | Determines and creates `SparkReward` records after a Spark is completed. |

---

## API Conventions

- All endpoints under `/api/v1/`.
- Authentication: `Authorization: Bearer <jwt>` on every protected route.
- Responses: JSON only (`Content-Type: application/json`).
- On 401: token missing or expired.
- On 403: authenticated but not authorized (e.g. resource belongs to another user).
- On 422: validation error — body contains `{ errors: { field: ["message"] } }`.
- Pagination: `page` + `per_page` params; response includes `meta.total_count`.

Full endpoint reference: `docs/api/openapi.yaml`.
