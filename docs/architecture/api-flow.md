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
  "profile": { "name": "...", "age": 29, "city": "Moscow", "photos": [...] },
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

## Date Proposal Flow

```
User A                        Backend                     User B
  |                              |                           |
  |-- POST /date_proposals ----->|                           |
  |   { user_b_id, time_slot }   |                           |
  |<-- 201 { proposal } ---------|                           |
  |                              |-- push notification ----->|
  |                              |                           |
  |                              |<-- POST .../accept -------|
  |                              |                           |
  |<-- push notification --------|                           |
```

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
