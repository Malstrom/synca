# Feature: Spark
**Version:** 2.0
**Last updated:** May 2026
**Status:** Draft
**Phase:** 0

---

## Overview

Spark is the core IRL interaction mechanism of Synca. It allows two users who are
physically co-located to initiate a proximity-based session and receive a real-time
compatibility score derived from their passive signals and declared preferences.

A completed Spark is the strongest trust and compatibility signal in the system
because it requires two verified users in the same physical location at the same time.
Spark is also a social icebreaker: the score creates a shared experience and a
natural conversation starter regardless of the outcome.

Spark is the prerequisite for creating a Match with `origin: :spark` and for joining
or creating a Spark-origin Circle.

Scoring rules and match creation thresholds are defined in
`docs/features/matching-v1.md` and are referenced by Spark.

Prerequisites: `users`, `profiles` (profile-v1.md) · `signals`, `declared_preferences` (signals-v1.md) · `matches` (matching-v1.md).

---

## Steps

| Step | Phase | Status | Description |
|---|---|---|---|
| 1.0 — Proximity Spark (QR) | 0 | Draft | QR-based session, scoring, rewards |
| 2.0 — Group Spark | 2 | Planned | Multi-participant session |

UX flows:
- Phase 0 → [phase-0.md — UF-01](../product/phases/phase-0.md#uf-01--first-spark-full-journey-new-user)
- Phase 1 → [phase-1.md — UF-05](../product/phases/phase-1.md#uf-05)

---

## Business Rules

### Proximity verification strategy

Proximity verification evolves across phases, balancing virality in early stages
with trust and anti-abuse as the user base grows.

| Phase | Method | Anti-abuse level | Notes |
|---|---|---|---|
| 1 | QR universal link, no proximity check | Low (intentional) | Virality over precision. Every join = a download. |
| 2 | Session code (PIN visible on initiator screen) | High | Receiver must physically see initiator’s screen. |
| 3 | BLE ambient discovery | High | Automatic, no QR needed. |

### QR flow
- `qr_token` is a single-use UUID: invalidated as soon as the first join is registered.
- If the receiver does not have the app installed, the universal link redirects to
  the App Store / Play Store; a deferred deep link restores the `qr_token` after install.
- Scanning the QR is the implicit proof of presence in Phase 1.

### Spark questionnaire
- A short on-the-spot subset of declared preferences questions.
- For guest users, this also serves as their initial declared preferences setup.
- Each participant answers independently on their own device.
- Raw answers are never exposed to the other participant.
- `ScoringJob` is triggered automatically once **both** participants have submitted.
- Answers are persisted to `declared_preferences` as updated preference weights.

### Scoring and match creation
- Scoring is primarily passive (signals drive the score); the questionnaire provides
  the personalisation layer.
- Score thresholds for match creation → ref: `docs/features/matching-v1.md § Score Thresholds`.
- Score result is delivered via `spark:scored` Action Cable event.

### Apple Health prerequisite
- Spark is blocked if the user has not granted HealthKit permissions and completed
  an initial signals sync (ref: `docs/features/signals-v1.md`).

### Rewards
- Free users who complete a Spark receive a `premium_week` trial.
- Premium users who complete a Spark receive a `match_credit`.
- Any user whose Spark produces a low compatibility score receives a `low_score_bonus`
  (threshold TBD — ref: `decisions.md`).

### Group Spark (Phase 2)
- `receiver_id` becomes nullable; participants tracked via `spark_participants`.
- Per-pair scoring results returned individually.

---

## References

- DB Schema → [docs/architecture/db-schema.md § Spark](../architecture/db-schema.md#spark)
- API → `docs/api/openapi.yaml`
- Rails Model → [docs/conventions/backend.md § Domain Model](../conventions/backend.md#domain-model-rails-associations)
- Scoring rules → [docs/features/matching-v1.md](matching-v1.md)
- Monetization → [docs/product/monetization.md](../product/monetization.md)

---

## Open Questions

See [docs/product/decisions.md](../product/decisions.md) — filter by `source: docs/features/spark-v1.md`.
