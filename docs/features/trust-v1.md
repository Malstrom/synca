# Feature: Trust
**Version:** 1.0
**Last updated:** May 2026
**Status:** Draft
**Phase:** 2
**User flows:** `docs/product/phases/` — no flows in Phase 0–1; flows will be added in phase-2.md

---

## Overview

Trust is Synca's anti-fake and safety layer. It maintains a `trust_score` (0–100)
on every profile and uses it to rank, gate, and flag users across the platform.
A low trust score causes a profile to be ranked down in match lists and
eventually suspended from active matching.

Trust has three components:
1. **Verification** — phone number, liveness check
2. **Profile quality** — completeness score, photo moderation
3. **Behavioral reputation** — reports, no-shows, Spark verifications

`trust_score` is stored on `profiles` (introduced in `docs/features/profile-v1.md`).

`TrustScoreService` always clamps `trust_score` between **0 and 100 inclusive**.
Any operation that would push the score below 0 or above 100 is truncated to the
nearest bound. All thresholds operate within this hard range; no negative or >100
scores are possible.

-- ref: docs/features/profile-v1.md
-- ref: docs/features/spark-v1.md

---

## Step 1.0 — TrustScore v0

**Phase:** 2
**Status:** Draft

### Overview

TrustScore v0 is rule-based. `TrustScoreService` recomputes the score whenever
a relevant event occurs. The score drives ranking in match lists: profiles below
the `low_trust` threshold are ranked last; profiles below `suspended` are
excluded entirely.

### Score Inputs

| Input | Delta | Trigger |
|-------|-------|---------|
| Phone verified | +20 | `POST /api/v1/trust/phone/verify` |
| Profile completeness ≥ 80 | +15 | Profile update |
| `irl_verification_count` ≥ 1 | +10 | Spark confirmed IRL |
| `irl_verification_count` ≥ 5 | +5 additional | Cumulative |
| Received report (pending) | −10 | Report created |
| Report confirmed by moderator | −20 | Moderation action |
| No-show on confirmed date | −15 | Date marked no-show |
| Photo rejected by moderation | −25 | Moderation action |

Initial score on registration: `50.0` (set in `docs/features/profile-v1.md`).

### Thresholds

| Threshold | Score | Effect |
|-----------|-------|--------|
| `trusted` | ≥ 70 | Standard ranking |
| `low_trust` | 40–69 | Ranked below trusted profiles |
| `suspended` | < 40 | Excluded from matching and Spark |

### DB Schema

```sql
phone_verifications
  id           bigint PK
  user_id      bigint FK -> users NOT NULL
  phone_number string NOT NULL
  verified     boolean NOT NULL DEFAULT false
  verified_at  datetime
  created_at   datetime

reports
  id              bigint PK
  reporter_id     bigint FK -> profiles NOT NULL
  reported_id     bigint FK -> profiles NOT NULL
  reason          string NOT NULL   -- 'fake' | 'inappropriate' | 'no_show' | 'other'
  status          string NOT NULL DEFAULT 'pending'  -- 'pending' | 'confirmed' | 'dismissed'
  reviewed_at     datetime
  created_at      datetime
```

### API Endpoints

| Method | Path | Auth required | Description |
|--------|------|---------------|-------------|
| POST | `/api/v1/trust/phone/request` | Yes | Sends OTP to phone number |
| POST | `/api/v1/trust/phone/verify` | Yes | Verifies OTP, marks phone verified |
| POST | `/api/v1/reports` | Yes | Creates a report against a profile |
| GET | `/api/v1/trust/score` | Yes | Returns own trust_score and breakdown |

Ref: `docs/api/openapi.yaml`

### Premium Gating

None — phone verification and reporting are available on all tiers.

---

## Step 2.0 — Liveness Check + Image Moderation

**Phase:** 4
**Status:** Planned

### Liveness Check

A selfie-based liveness check confirms that the person in the profile photo is
real and present. Passed liveness adds `+15` to `trust_score` and sets
`profiles.liveness_verified = true`.

Extension to `profiles` (ref: `docs/features/profile-v1.md`):

```sql
ALTER TABLE profiles ADD COLUMN liveness_verified boolean NOT NULL DEFAULT false;
ALTER TABLE profiles ADD COLUMN liveness_verified_at datetime;
```

### Image Moderation

Every uploaded photo is queued for automated moderation (escort / nudity
detection). Photos pending moderation are stored but not shown to other users.
Rejected photos trigger a `−25` trust delta and are removed from `profiles.photos`.

Moderation is handled asynchronously via a Solid Queue job (`PhotoModerationJob`).
No new tables are introduced — status is tracked via a `moderation_status` field
in the `profiles.photos` JSON array:

```json
[
  { "url": "https://...", "moderation_status": "approved" },
  { "url": "https://...", "moderation_status": "pending" }
]
```

### API Endpoints

| Method | Path | Auth required | Description |
|--------|------|---------------|-------------|
| POST | `/api/v1/trust/liveness` | Yes | Submits selfie for liveness check |

---

## Step 3.0 — TrustScore v1 (Behavioral Reputation)

**Phase:** 4
**Status:** Planned

TrustScore v1 adds behavioral signals from completed dates and Spark history
to the score computation.

-- ref: docs/features/moments-v1.md

Additional inputs on top of Step 1.0:

| Input | Delta | Trigger |
|-------|-------|---------|
| Date completed with positive rating | +5 | Date marked completed |
| Date completed with negative rating | −5 | Date marked completed |
| Liveness verified | +15 | Liveness check passed |
| `irl_verification_count` ≥ 10 | +5 additional | Cumulative |

No new tables introduced in this step.

---

### Open Questions

See [docs/product/decisions.md](../product/decisions.md) — filter by `source: docs/features/trust-v1.md`.
