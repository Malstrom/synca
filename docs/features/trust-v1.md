# Feature: Trust
**Version:** 2.0
**Last updated:** May 2026
**Status:** Draft
**Phase:** 2

---

## Overview

Trust is Synca’s anti-fake and safety layer. It maintains a `trust_score` (0–100)
on every profile and uses it to rank, gate, and flag users across the platform.
A low trust score causes a profile to be ranked down in match lists and
eventually suspended from active matching.

Trust has three components:
1. **Verification** — phone number, liveness check
2. **Profile quality** — completeness score, photo moderation
3. **Behavioral reputation** — reports, no-shows, Spark verifications

`trust_score` is stored on `profiles` (ref: `docs/features/profile-v1.md`).
`TrustScoreService` always clamps `trust_score` between **0 and 100 inclusive**.

Prerequisites: `users`, `profiles` (profile-v1.md) · `sparks` (spark-v1.md).

---

## Steps

| Step | Phase | Status | Description |
|---|---|---|---|
| 1.0 — TrustScore v0 | 2 | Draft | Rule-based score from verification and reports |
| 2.0 — Liveness Check + Image Moderation | 4 | Planned | Selfie liveness, automated photo moderation |
| 3.0 — TrustScore v1 (Behavioral) | 4 | Planned | Behavioral signals from completed Moments |

---

## Business Rules

### Score inputs

| Input | Delta | Trigger |
|---|---|---|
| Phone verified | +20 | `POST /api/v1/trust/phone/verify` |
| Profile completeness ≥ 80 | +15 | Profile update |
| `irl_verification_count` ≥ 1 | +10 | Spark confirmed IRL |
| `irl_verification_count` ≥ 5 | +5 additional | Cumulative |
| `irl_verification_count` ≥ 10 | +5 additional | Cumulative (Step 3.0) |
| Received report (pending) | −10 | Report created |
| Report confirmed by moderator | −20 | Moderation action |
| No-show on confirmed date | −15 | Moment marked no-show |
| Photo rejected by moderation | −25 | Moderation action (Step 2.0) |
| Date completed with positive rating | +5 | Moment marked completed (Step 3.0) |
| Date completed with negative rating | −5 | Moment marked completed (Step 3.0) |
| Liveness verified | +15 | Liveness check passed (Step 2.0) |

Initial score on registration: `50.0`.

### Thresholds

| Threshold | Score | Effect |
|---|---|---|
| `trusted` | ≥ 70 | Standard ranking |
| `low_trust` | 40–69 | Ranked below trusted profiles |
| `suspended` | < 40 | Excluded from matching and Spark |

### Reporting
- Any active user can report another profile.
- The reporter is unaffected by the report outcome.
- Reports are reviewed by moderators before applying confirmed penalties.

### Image moderation (Step 2.0)
- Every uploaded photo is queued for automated moderation (escort / nudity detection).
- Photos pending moderation are stored but not shown to other users.
- Moderation status is tracked as a `moderation_status` field in the `profiles.photos`
  JSON array: `"pending" | "approved" | "rejected"`.
- Rejected photos trigger −25 trust delta and are removed from the photos array.
- Moderation is handled asynchronously via `PhotoModerationJob`.

### Liveness check (Step 2.0)
- A selfie-based liveness check confirms the person in the profile photo is real.
- Passed liveness adds +15 to `trust_score` and sets `profiles.liveness_verified = true`.

---

## References

- DB Schema → [docs/architecture/db-schema.md § Trust](../architecture/db-schema.md#trust)
- API → `docs/api/openapi.yaml`
- Rails Model → [docs/conventions/backend.md § Domain Model](../conventions/backend.md#domain-model-rails-associations)
- Moments (behavioral inputs) → [docs/features/moments-v1.md](moments-v1.md)
- Monetization → [docs/product/monetization.md](../product/monetization.md)

---

## Open Questions

See [docs/product/decisions.md](../product/decisions.md) — filter by `source: docs/features/trust-v1.md`.
