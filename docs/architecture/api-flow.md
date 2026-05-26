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

Synca supports both **1-to-1 matches** (standard dating) and **group matches** (e.g. friend groups, social events). Both use the same `matches` + `match_participants` structure.

```
Client                          Backend
  |                                |
  |-- GET /api/v1/matches -------->|
  |                                |--> MatchingService
  |                                |      filter candidates
  |                                |      compute CompatibilityScore
  |                                |      return top 3-5
  |<-- 200 { matches: [...] } -----|
```

Each match object includes:

```json
{
  "id": "uuid",
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

- **MVP**: all matches are 1-to-1 (2 participants). The group feature is supported by the data model but not yet exposed in the UI or matching engine.
- **v2+**: group matches with N participants will be enabled progressively.

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
