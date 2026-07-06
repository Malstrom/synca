# Synca — Rails Backend Technical Spec

**Version:** 1.4  
**Last updated:** July 2026

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
| Gems reference | [docs/conventions/gems.md](gems.md) |

---

## DB Conventions

Full schema (tables, indexes, FK definitions): `docs/architecture/db-schema.md`.

### FK Rule
All foreign keys point to `users.id`, never to `profiles.id`.  
`profiles` is an application-level record (1:1 with users), not a domain identity.  
Access to profile data is done in the application layer via `user.profile`.

### Soft Delete
All primary domain tables include `deleted_at datetime`.  
All models use `default_scope { where(deleted_at: nil) }`.  
Hard deletes are never performed. GDPR erasure nullifies PII columns and sets `deleted_at`.

Tables with soft delete: `users`, `profiles`, `matches`, `sparks`,
`circles`, `circle_messages`, `moments`.

### Indexes
Every FK column has an index unless covered by a UNIQUE constraint.  
Composite indexes are documented in `docs/architecture/db-schema.md`.

---

## Score Thresholds

All score thresholds (Spark-origin, algorithm-origin, Circle admission) are defined
exclusively in `docs/features/matching-v1.md` and `docs/features/circles-v1.md`.
This file must not introduce or repeat numeric threshold values.

---

## Domain Settings

All numeric limits, thresholds, and configurable parameters are defined in YAML files
under `config/settings/` via the `config` gem. **Never hardcode these values in contracts,
models, or services.**

### Structure

```
config/
  settings.yml                     # root — required by gem, generally empty
  settings.development.yml         # local dev overrides
  settings.test.yml                # test overrides (e.g. spark.expiry_minutes: 0)
  settings/
    health_summary.yml             # routine_stability_index range, sleep duration min
    profile.yml                    # display_name max length, bio max length, photo max count
    spark.yml                      # expiry_minutes
    matching.yml                   # phase 1 — compatibility score thresholds
    trust.yml                      # phase 1 — trust score thresholds
```

One file per domain area. Do not create a single catch-all settings file.

### Access

```ruby
Settings.health_summary.routine_stability_index.min  # => 0.0
Settings.spark.expiry_minutes                        # => 10
Settings.profile.display_name.max_length             # => 50
```

### Adding a new setting

1. Identify the domain file (e.g. `config/settings/spark.yml`)
2. Add the key with its default value
3. Add overrides in `settings.test.yml` if test behavior differs
4. Reference via `Settings.domain.key` in code

---

## Domain Model (Rails associations)

Canonical schema for each table lives in `docs/architecture/db-schema.md`.
The associations below reflect that schema — keep them in sync.

```ruby
# app/models/user.rb
has_one :profile
has_one :signal
has_one :declared_preference   # ref: docs/features/signals-v1.md Step 0
has_one :preference_profile    # ref: docs/features/profile-v1.md
has_many :sparks, foreign_key: :initiator_id
has_many :identity_providers
has_many :ml_events            # ref: docs/architecture/ml-architecture-v1.md Section 9
has_many :circle_memberships,  foreign_key: :user_id
has_many :circles, through: :circle_memberships
has_many :moments_as_proposer, class_name: 'Moment', foreign_key: :proposer_id
has_many :moments_as_receiver, class_name: 'Moment', foreign_key: :receiver_id

# app/models/profile.rb
belongs_to :user
# Profile holds display data only. Never used as FK target.
# Access via user.profile in application code.

# app/models/match.rb
belongs_to :user_a, class_name: 'User'
belongs_to :user_b, class_name: 'User'
belongs_to :spark, optional: true
enum :origin, { spark: 0, algorithm: 1 }, default: :spark
enum :status, { active: 0, drifted: 1, reconnected: 2, ended: 3 }, default: :active

# app/models/spark.rb
belongs_to :initiator, class_name: 'User'
belongs_to :receiver, class_name: 'User', optional: true
has_many :spark_participants
has_many :spark_rewards
enum :status, { pending: 0, active: 1, completed: 2, expired: 3, cancelled: 4 }
enum :spark_type, { duo: 0, group: 1 }, default: :duo

# app/models/circle.rb
belongs_to :creator, class_name: 'User', foreign_key: :created_by
has_many :circle_memberships
has_many :circle_messages
enum :circle_type, { duo: 0, small_group: 1, event: 2 }

# app/models/circle_membership.rb
belongs_to :circle
belongs_to :user
belongs_to :spark, optional: true

# app/models/circle_message.rb
belongs_to :circle
belongs_to :sender, class_name: 'User', foreign_key: :sender_id
has_many :circle_message_reads

# app/models/circle_message_read.rb
belongs_to :message, class_name: 'CircleMessage'
belongs_to :user

# app/models/moment.rb
belongs_to :proposer, class_name: 'User', foreign_key: :proposer_id
belongs_to :receiver, class_name: 'User', foreign_key: :receiver_id
belongs_to :match
belongs_to :parent, class_name: 'Moment', optional: true
enum :status, { pending: 0, confirmed: 1, declined: 2, superseded: 3, completed: 4, no_show: 5 }

# app/models/declared_preference.rb
belongs_to :user

# app/models/ml_event.rb
# Logs user interaction events used as training data for the ML ranking model.
# event_type values: profile_shown | profile_liked | profile_skipped |
#                    match_created | first_message_sent | moment_completed
# candidate_id is null for non-pair events.
# model_version is null in V1; populated in V2.
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
| `CompatibilityScoreService` | Computes pairwise compatibility score from `signals` and `declared_preferences`. Accepts `user_a, user_b`. Returns score (0–100) + `score_breakdown` hash. **Do not call directly from jobs — use `MatchScoringFacade`.** |
| `MatchScoringFacade` | **Single entry point for all match scoring.** Routes to `MlRecommenderClient` when `ML_SCORING_ENABLED=true`, otherwise delegates to `CompatibilityScoreService`. All jobs and services must call this, never `CompatibilityScoreService` directly. Ref: `docs/architecture/ml-architecture-v1.md — Section 7.3` |
| `MlEventLogger` | Writes `MlEvent` records for ML training data. Must be called on: profile shown, profile liked, profile skipped, match created, first message sent, moment completed. Never raises — failures are silently rescued and logged. |
| `MlRecommenderClient` | **V2 — not active in V1.** HTTP client to the external ML Service. Timeout 5s, 2 retries, circuit breaker. Returns empty array on failure so `MatchScoringFacade` falls back to rule-based scoring transparently. |
| `MatchProposalService` | Wraps `MatchScoringFacade` for algorithm flow; filters candidate pool. |
| `TrustScoreService` | Computes or recomputes a user's `TrustScore` from image, behavioral, and IRL signals. |
| `MomentProposalService` | Generates 1–3 Moment proposals from match signals, city, and time preferences. Enforces the 5-round counter-proposal cap by counting the `parent_id` chain depth. |
| `SparkRewardService` | Determines and creates `SparkReward` records after a Spark is completed. |

---

## ML Readiness — Rules for V1 Development

1. **Always call `MatchScoringFacade`**, never `CompatibilityScoreService` directly.
2. **Always call `MlEventLogger`** at the interaction points listed above.
   Missing events = missing training data, which cannot be recovered retroactively.
3. **Never raise from `MlEventLogger`**. Wrap calls in rescue blocks.
4. **`ML_SCORING_ENABLED` defaults to `false`** in all environments.
5. **`ml_match_scores` table exists but is empty in V1.** Always check `expires_at` before reading.

Full ML architecture: `docs/architecture/ml-architecture-v1.md`

---

## API Conventions

- All endpoints under `/api/v1/`.
- Authentication: `Authorization: Bearer <jwt>` on every protected route.
- Responses: JSON only (`Content-Type: application/json`).
- On 401: token missing or expired.
- On 403: authenticated but not authorized.
- On 422: validation error — body contains `{ errors: { field: ["message"] } }`.
- Pagination: `page` + `per_page` params; response includes `meta.total_count`.

Full endpoint reference: `docs/api/openapi.yaml`.
