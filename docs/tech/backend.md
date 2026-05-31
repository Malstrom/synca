# Synca — Rails Backend Technical Spec

**Version:** 1.2  
**Last updated:** 2026-05-31

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
has_many :ml_events            # ref: docs/architecture/ml-architecture-v1.md Section 9

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

# app/models/ml_event.rb
# Logs user interaction events used as training data for the ML ranking model.
# Written by MlEventLogger — never written directly from controllers or jobs.
# event_type values: profile_shown | profile_liked | profile_skipped |
#                    match_created | first_message_sent | moment_completed
# candidate_id is null for non-pair events (e.g. moment_completed).
# model_version is null in V1 (no ML active); populated in V2.
# Ref: docs/architecture/ml-architecture-v1.md — Section 9
belongs_to :user

# app/models/ml_match_score.rb
# Stores pre-computed ML ranking scores per (user, candidate) pair.
# Written by MlMatchScoringJob (V2). Empty in V1.
# MatchingJob reads this table when ML_SCORING_ENABLED=true.
# Scores past expires_at are ignored; MatchingJob falls back to rule-based.
# Ref: docs/architecture/ml-architecture-v1.md — Section 6.4
```

---

## Background Jobs

| Job | Queue | Trigger | Description |
|---|---|---|---|
| `ScoringJob` | `spark` | Spark completion | Computes compatibility score for a Spark session |
| `MatchingJob` | `algorithm` | Nightly (cron) | Algorithm-origin match generation. Calls `MatchScoringFacade`, not `CompatibilityScoreService` directly. |
| `MatchDecayJob` | `default` | Daily (cron) | Marks matches as `drifted` when signals are stale; marks as `reconnected` when signals are refreshed or new Spark completed. Ref: `docs/features/matching-v1.md — Match Lifecycle`. |
| `TrustScoreJob` | `default` | Event-triggered | Recomputes TrustScore for a user |
| `MomentReminderJob` | `default` | Scheduled | Sends reminder before a confirmed Moment |
| `MlMatchScoringJob` | `ml` | Daily cron + on significant signal update | **V2 — not active in V1.** Runs candidate generation, builds feature vectors, calls `MlRecommenderClient`, writes results to `ml_match_scores`. Ref: `docs/architecture/ml-architecture-v1.md — Section 7` |

---

## Services

| Service | Description |
|---|---|
| `CompatibilityScoreService` | Computes pairwise compatibility score from `signals` and `declared_preferences`. Accepts `user_a, user_b`. Returns score (0–100) + `score_breakdown` hash. **Do not call directly from jobs — use `MatchScoringFacade`.**|
| `MatchScoringFacade` | **Single entry point for all match scoring.** Routes to `MlRecommenderClient` when `ML_SCORING_ENABLED=true`, otherwise delegates to `CompatibilityScoreService`. All jobs and services must call this, never `CompatibilityScoreService` directly. Ref: `docs/architecture/ml-architecture-v1.md — Section 7.3` |
| `MlEventLogger` | Writes `MlEvent` records for ML training data collection. Must be called on: profile shown to user, profile liked, profile skipped, match created, first message sent, moment completed. Never raises — failures are silently rescued and logged. Ref: `docs/architecture/ml-architecture-v1.md — Section 9` |
| `MlRecommenderClient` | **V2 — not active in V1.** HTTP client to the external ML Service. Handles timeout (5s), 2 retries, circuit breaker. Returns empty array on failure so `MatchScoringFacade` falls back to rule-based scoring transparently. Ref: `docs/architecture/ml-architecture-v1.md — Section 6` |
| `MatchProposalService` | Wraps `MatchScoringFacade` for algorithm flow; filters candidate pool. |
| `TrustScoreService` | Computes or recomputes a user's `TrustScore` from image, behavioral, and IRL signals. |
| `MomentProposalService` | Generates 1–3 Moment proposals from match signals, city, and time preferences. |
| `SparkRewardService` | Determines and creates `SparkReward` records after a Spark is completed. |

---

## ML Readiness — Rules for V1 Development

These rules apply from day one and must be followed even before ML is active,
so that the codebase is ready for V2 with no breaking changes.

1. **Always call `MatchScoringFacade`**, never `CompatibilityScoreService` directly,
   from any job or service that needs a compatibility score.
2. **Always call `MlEventLogger`** at the interaction points listed in its description.
   Missing events = missing training data, which cannot be recovered retroactively.
3. **Never raise from `MlEventLogger`**. Wrap calls in rescue blocks so that a logging
   failure never breaks the user-facing flow.
4. **`ML_SCORING_ENABLED` env var defaults to `false`** in all environments until
   the ML Service is validated in staging and explicitly promoted to production.
5. **`ml_match_scores` table exists but is empty in V1.** Do not add business logic
   that depends on it being populated — always check `expires_at` before reading.

Full ML architecture: `docs/architecture/ml-architecture-v1.md`

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
