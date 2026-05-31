# Feature: Signals
**Version:** 2.0
**Last updated:** May 2026
**Status:** Draft
**Phase:** 0

---

## Overview

Signals is the data ingestion and computation layer of Synca. It collects, aggregates,
and syncs behavioral data from external sources to build each user's compatibility profile.
It also exposes a user-facing summary so users understand their own profile before
receiving any match.

Raw data from external sources is **never stored on the backend**. All aggregation
happens on-device. Only derived metrics are sent to and stored in `signals`.

The signals layer has three components:
- **Declared preferences** (Step 0): a short questionnaire capturing what each user values.
  Used as multipliers when computing pairwise compatibility scores.
- **Objective signals** (Steps 1.0–3.0): passively collected behavioral data from
  health, music, and travel sources. Cannot be gamed without sustained behavioral
  change over weeks.
- **User-facing summary**: computed human-readable output derived from signals.
  No additional data store required.

Prerequisite: `users` (ref: `docs/features/profile-v1.md`).

---

## Steps

| Step | Phase | Status | Description |
|---|---|---|---|
| 0 — Declared Preferences | 0 | Draft | Short questionnaire on values and rhythm preferences |
| 1.0 — Apple Health / Health Connect | 1 | Draft | Sleep, activity, chronotype signals |
| 1.1 — Menstrual Cycle | 1 | Draft | Optional, explicit opt-in only |
| User-facing layer | 0 | Draft | Human-readable summary of own signals |
| 2.0 — Music (Spotify / Yandex Music) | 2 | Planned | Top genres, energy, valence, listening window |
| 3.0 — Travel Behavior | 3 | Planned | Trips/year, duration, style, regions |

UX flows:
- Phase 0 → [phase-0.md — UF-02, UF-03](../product/phases/phase-0.md)

---

## Business Rules

### Declared preferences
- Completed once during onboarding. Takes under 2 minutes.
- Available to guest accounts.
- Used as personalisation multipliers in `CompatibilityScoreService`, not as hard filters.
- Re-calibrated in real time during each Spark session questionnaire
  (ref: `docs/features/spark-v1.md — Step 1.0`).

### Questionnaire (Phase 0)

| # | Question | Type | Signal it weights |
|---|---|---|---|
| 1 | Is it important to you to fall asleep at the same time as your partner? | 1–5 | `sleep_onset` alignment weight |
| 2 | Do you prefer sleeping in a cool or warm environment? | Cool / Warm / No preference | Shared as compatibility dimension |
| 3 | How much daily movement feels right for you? | Very little / Moderate / A lot / As much as possible | `step_count_avg` similarity threshold |
| 4 | How important is it that the people close to you share your daily rhythm? | 1–5 | Global chronotype alignment weight |
| 5 | Do you consider yourself more of a morning person or a night person? | Morning / Night / Depends | Cross-validated with `chronotype` |

### Health signals
- Without a `signals` record, the user cannot receive algorithm-origin matches;
  Spark-origin matching still works.
- Minimum 7 days of signals data required to enter the algorithm matching pool
  (ref: `docs/features/matching-v1.md`).

### Cycle signals
- Entirely opt-in with a separate explicit consent gate — never bundled with Step 1.0.
- Cycle data is **never shown to matches**.
- This feature is **not medical**. No medical claims, fertility predictions,
  pregnancy-related inference, or health advice of any kind.
- Allowed use: reduce notification pressure in low-engagement phases; shift Spark
  prompt delivery toward higher-engagement moments.
- Forbidden use: hard boost or penalty on desirability score; pairing logic based
  on phase; any match explanation that mentions cycle state.
- Independent revocation: `DELETE /api/v1/signals/cycle` nullifies only cycle columns.

### User-facing summary
- Derived at request time from `signals` and `declared_preferences` — no additional store.
- Available to all users with a `signals` record.
- The user must recognise themselves in what the data says about them before any
  match is presented — this is the immediate value hook of Synca.

---

## References

- DB Schema → [docs/architecture/db-schema.md § Signals](../architecture/db-schema.md#signals)
- API → `docs/api/openapi.yaml`
- Rails Model → [docs/conventions/backend.md § Domain Model](../conventions/backend.md#domain-model-rails-associations)
- Monetization → [docs/product/monetization.md](../product/monetization.md)
- User research motivating the questionnaire → [docs/product/user-research.md](../product/user-research.md)

---

## Open Questions

See [docs/product/decisions.md](../product/decisions.md) — filter by `source: docs/features/signals-v1.md`.
