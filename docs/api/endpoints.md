# Synca API — Endpoints Reference

Base URL: `/api/v1`  
Auth: `Authorization: Bearer <token>` (all endpoints except auth)

Full OpenAPI spec: `docs/api/openapi.yaml`

---

## Authentication

### POST /auth/signup

Register a new user.

**Request body:**
```json
{
  "user": {
    "email": "user@example.com",
    "phone": "+79001234567",
    "name": "Alex",
    "age": 28,
    "gender": "male",
    "city": "Moscow"
  }
}
```

**Response 201:**
```json
{
  "token": "eyJ...",
  "user": { "id": "uuid", "name": "Alex", "city": "Moscow" }
}
```

---

### POST /auth/login

**Request body:**
```json
{ "email": "user@example.com", "password": "secret" }
```

**Response 200:**
```json
{ "token": "eyJ...", "user": { "id": "uuid", "name": "Alex" } }
```

---

## Profile

### GET /profile

Returns the current authenticated user's profile.

**Response 200:**
```json
{
  "id": "uuid",
  "name": "Alex",
  "age": 28,
  "gender": "male",
  "city": "Moscow",
  "photos": ["https://cdn.synca.app/photos/uuid.jpg"],
  "trust_score": 74
}
```

---

### PUT /profile

Update name, photos, city.

---

## Health Summaries

### POST /health_summaries

Upload aggregated health metrics. Called after device-side aggregation.

**Request body:**
```json
{
  "health_summary": {
    "period": "weekly",
    "sleep_duration_avg": 7.2,
    "sleep_variability": 0.8,
    "chronotype": "intermediate",
    "social_jetlag": 1.1,
    "activity_minutes": 210,
    "step_count_avg": 8500,
    "rest_hr_avg": 62
  }
}
```

**Response 201:**
```json
{ "id": "uuid", "created_at": "2026-05-26T00:00:00Z" }
```

---

## Preferences

### GET /preferences

Returns current user's preference profile.

### PUT /preferences

**Request body:**
```json
{
  "preference_profile": {
    "preferred_age_min": 24,
    "preferred_age_max": 36,
    "max_distance_km": 20,
    "chronotype_preference": "morning",
    "dealbreakers": ["smoker"]
  }
}
```

---

## Matches

### GET /matches

Returns curated match list (3–5 profiles). Profiles below compatibility threshold are excluded.

**Response 200:**
```json
{
  "matches": [
    {
      "id": "uuid",
      "profile": { "name": "Maria", "age": 27, "city": "Moscow", "photos": [...] },
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
  ]
}
```

---

## Date Proposals

### GET /date_proposals

List all date proposals for the current user.

### POST /date_proposals

**Request body:**
```json
{
  "date_proposal": {
    "user_b_id": "uuid",
    "suggested_time_slot": "2026-06-01T19:00:00Z",
    "venue_note": "Coffee near Gorky Park"
  }
}
```

**Response 201:**
```json
{
  "id": "uuid",
  "status": "suggested",
  "suggested_time_slot": "2026-06-01T19:00:00Z"
}
```

### POST /date_proposals/:id/accept

Accept a proposal. Both users are notified.

**Response 200:**
```json
{ "id": "uuid", "status": "accepted" }
```

### POST /date_proposals/:id/decline

**Response 200:**
```json
{ "id": "uuid", "status": "declined" }
```

---

## Error Format

```json
{
  "error": {
    "code": "validation_failed",
    "message": "Age must be between 18 and 80",
    "field": "age"
  }
}
```
