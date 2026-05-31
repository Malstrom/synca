# Feature: Matching
**Version:** 1.0
**Last updated:** May 2026
**Status:** Draft
**Phase:** 1
**User flows:** `docs/product/phases/phase-0.md` — UF-04, UF-05

---

## Overview

Matching is the layer that decides which users are compatible enough to be introduced
to each other. It supports two origins:
- **Spark-origin**: a match is created immediately when a Spark session scores above
  the compatibility threshold.
- **Algorithm-origin**: a nightly background job computes pairwise scores from the
  `signals` table and surfaces a small number of high-quality candidates.

A `Match` record is created once per ordered pair `(user_a, user_b)`. The system
ensures no duplicate matches exist for the same pair.

Prerequisite: `users`, `profiles` (ref: `docs/features/profile-v1.md`),
`signals` (ref: `docs/features/signals-v1.md`).

---

## Step 1.0 — Core Matching

**Phase:** 1
**Status:** Draft

### DB Schema

```sql
matches
  id               bigint PK
  user_a_id        bigint FK -> users NOT NULL
  user_b_id        bigint FK -> users NOT NULL
  origin           string NOT NULL   -- 'spark' | 'algorithm'
  spark_id         bigint FK -> sparks  -- null for algorithm-origin
  compatibility_score float NOT NULL
  status           string NOT NULL DEFAULT 'active'
                   -- 'active' | 'drifted' | 'reconnected' | 'ended'
  created_at       datetime
  updated_at       datetime
  UNIQUE (user_a_id, user_b_id)
```

### Match Lifecycle

```
active → drifted      (no Circle message or Spark for 30 days)
drifted → reconnected (new Spark between the same pair)
active | reconnected → ended (either user blocks or reports)
```

### API Endpoints

| Method | Path | Auth required | Description |
|--------|------|---------------|-------------|
| GET | `/api/v1/matches` | Yes | Lists all matches for the current user |
| GET | `/api/v1/matches/:id` | Yes | Returns a specific match with compatibility breakdown |
| DELETE | `/api/v1/matches/:id` | Yes | Ends a match (sets status to ended) |

Ref: `docs/api/openapi.yaml`

### Premium Gating

Algorithm-origin matching is a **premium feature**. Spark-origin matching is free
for all users. Without a `signals` record the user cannot enter the algorithm pool.

---

## Step 2.0 — Compatibility Score Breakdown

**Phase:** 2
**Status:** Planned

The compatibility score is decomposed into human-readable dimensions shown to both
users after a match is created.

No new tables introduced in this step.

### API Endpoints

| Method | Path | Auth required | Description |
|--------|------|---------------|-------------|
| GET | `/api/v1/matches/:id/breakdown` | Yes | Returns the compatibility score breakdown by signal domain |

### Premium Gating

Score breakdown is a **premium feature**. Free users see only the total score.

---

### Open Questions

See [docs/product/decisions.md](../product/decisions.md) — filter by `source: docs/features/matching-v1.md`.
