# API Flow — Synca

## Overview

The Rails API runs in API mode and serves both iOS and Android clients.
All endpoints are versioned under `/api/v1`.
Authentication is token-based (JWT).

## Auth Flow

```
Client                          Backend
  |                                |
  |-- POST /auth/signup ---------->|
  |   (email/phone, name, city)    |
  |<-- 201 { token, user } --------|
  |                                |
  |-- POST /auth/login ----------->|
  |   (email/phone, password)      |
  |<-- 200 { token, user } --------|
```

All subsequent requests include the token in the `Authorization: Bearer <token>` header.

## Health Data Upload Flow

Health data is aggregated on device. The client sends only derived metrics.

```
Client                                  Backend
  |                                         |
  | [HealthKit/Health Connect aggregation]  |
  |                                         |
  |-- POST /api/v1/health_summaries ------->|
  |   {                                     |
  |     period: "weekly",                   |
  |     sleep_duration_avg: 7.2,            |
  |     sleep_variability: 0.8,             |
  |     chronotype: "intermediate",         |
  |     activity_minutes: 210,              |
  |     step_count_avg: 8500               |
  |   }                                     |
  |<-- 201 { id, created_at } -------------|
```

Raw samples are **never** sent or stored on the backend.

## Matching Flow

Synca has **two match origins**:

### Origin 1 — Spark (MVP, default)

A match is created when two users complete a Spark session physically together
and their compatibility score meets the threshold.

```
User A & B (physically together)
  |
  |-- POST /spark_sessions -----------> SparkSession created
  |-- POST /spark_sessions/:id/join --> Partner joins
  |-- POST /spark_sessions/:id/submit_answers (both users)
  |                                         |
  |                               ScoringJob (Solid Queue)
  |                                    compute score
  |                                    score >= 65 → Match created
  |                                    origin: :spark
  |<-- GET /spark_sessions/:id/result --|
```

### Origin 2 — Algorithm (v1.1+, premium)

A nightly background job analyses health summaries and creates suggested matches
for users who have not yet met in person.

```
                          Backend (nightly, ~02:00 UTC)
                               |
                          MatchingJob (Solid Queue)
                               |
                          load all active users with health_summary
                               |
                          compute CompatibilityScore for candidate pairs
                               |
                          score >= 70 → Match created
                          origin: :algorithm
                          algorithm_confidence: 0.0–1.0
```

Algorithm matches are surfaced via `GET /matches` with `origin: "algorithm"` and
are gated behind the premium subscription tier.

### Match object (both origins)

```json
{
  "id": 1,
  "origin": "spark",
  "status": "proposed",
  "compatibility_score": 82,
  "algorithm_confidence": null,
  "participants": [
    { "user_id": 5,  "role": "initiator" },
    { "user_id": 12, "role": "member" }
  ],
  "compatibility": {
    "score": 82,
    "breakdown": {
      "sleep": 88,
      "activity": 74,
      "lifestyle": 80,
      "preferences": 90
    },
    "summary": "Your sleep schedules are well aligned."
  }
}
```

### Match size

- **MVP**: all matches are 1-to-1 (2 participants).
- **v2+**: Sync Rooms (small group 3–8, event room 9–22) enabled progressively.

## Sync Room Flow (v2+)

A Sync Room is a group conversation space created only when all members have
verified Spark sessions with the room creator. For Event Rooms (9–22 members),
each member must have at least one Spark with the creator.

```
Alice (creator)                Backend                  Bob, Cara
  |                               |                         |
  |-- POST /sync_rooms ---------->|                         |
  |   { member_ids: [Bob, Cara] } |                         |
  |                               |--> validate Spark graph |
  |                               |    all pairs verified?  |
  |<-- 201 { sync_room } ---------|                         |
  |                               |-- invite push --------->|
  |                               |                         |
  |                               |<-- POST .../join --------|
  |                               |                         |
  |<-- Action Cable broadcast ----|                         |
```

## Date Proposal Flow

```
User A                        Backend                     User B
  |                              |                           |
  |-- POST /date_proposals ----->|                           |
  |   { match_id, time_slot }    |                           |
  |<-- 201 { proposal } ---------|                           |
  |                              |-- push notification ----->|
  |                              |                           |
  |                              |<-- POST .../accept -------|
  |                              |                           |
  |<-- push notification --------|                           |
```

> Note: `match_id` replaces the old `user_b_id` field. The backend resolves participants from `match_participants`.

## Background Jobs (Solid Queue)

All async work uses **Solid Queue** (no Redis, no Sidekiq).

| Job | Queue | Trigger |
|---|---|---|
| `ScoringJob` | `spark` | After both Spark answers submitted |
| `MatchingJob` | `default` | Nightly cron ~02:00 UTC |
| `MatchResyncJob` | `default` | Weekly cron, checks match decay |
| `SparkRewardJob` | `default` | After ScoringJob completes |

## Error Format

All errors follow a consistent JSON structure:

```json
{
  "error": {
    "code": "validation_failed",
    "message": "Age must be between 18 and 80",
    "field": "age"
  }
}
```

## Rate Limiting

- Auth endpoints: 10 requests/minute per IP.
- Match endpoint: 20 requests/minute per user.
- Health summaries: 5 uploads/day per user.
- Sync Rooms: 5 creations/day per user.
