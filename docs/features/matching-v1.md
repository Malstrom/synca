# Feature: Matching
**Version:** 2.0
**Last updated:** May 2026
**Status:** Draft
**Phase:** 1

---

## Overview

Matching is the algorithm layer of Synca. It computes compatibility scores between
users and creates `Match` records through two distinct origins: `:spark` (IRL session)
and `:algorithm` (nightly batch job).

Every match carries a human-readable explanation of why two people are compatible.
The score is always paired with plain-language insights (e.g. "Your sleep
schedules are well aligned") — it is never shown as a bare number with no
context. An earlier version of this rule said the raw score must never be
exposed at all; the approved Spark result / match detail design (see
docs/design/ui-system.md) does show it, in a ring alongside the explanation, and
the design review overruled the stricter reading.

Matching deliberately produces **few, high-quality matches**. The system does not
produce an infinite swipeable feed.

Prerequisites: `users`, `profiles`, `preference_profiles` (profile-v1.md) · `signals`, `declared_preferences` (signals-v1.md).

---

## Steps

| Step | Phase | Status | Description |
|---|---|---|---|
| 1.0 — Compatibility Score (Health Signals) | 1 | Draft | Rule-based scoring from health signals |
| 2.0 — Music Signal Integration | 2 | Planned | Music sub-score added to Lifestyle domain |
| 3.0 — Travel Signal Integration | 3 | Planned | Travel sub-score added to Lifestyle domain |

UX flows:
- Phase 1 → [phase-1.md — UF-08](../product/phases/phase-1.md#uf-08--algorithm-match-nightly-job)

---

## Business Rules

### Match origins

| Origin | Trigger | UX label |
|---|---|---|
| `:spark` | Two users complete a Spark in person | "Synca confermata" ✅ |
| `:algorithm` | Nightly `MatchingJob` on signals | "Synca suggerita" 💡 |

Algorithm-originated matches carry an `algorithm_confidence` float (0.0–1.0).
Spark-originated matches leave this field `nil`.

### Score thresholds

These values are the **single source of truth** for match creation decisions.
No other document should hardcode threshold values.

| Threshold | Spark origin | Algorithm origin |
|---|---|---|
| Minimum score to create a match | 50 | 65 |

Algorithm origin has a higher bar because no physical presence confirms mutual intent.
Thresholds are configurable per city.

### Algorithm matching pool
- A user enters the algorithm matching pool only after accumulating at least **7 days**
  of signals data. This value is configurable (default 7) and can be adjusted per city
  without a code deploy.
- Algorithm-origin matching requires Premium (ref: `docs/product/monetization.md`).

### Compatibility domains

| Domain | Weight (Step 1.0) | Signals used |
|---|---|---|
| Sleep | 35% | `chronotype`, `sleep_duration_avg`, `sleep_variability`, `social_jetlag` |
| Activity | 30% | `activity_minutes_avg`, `step_count_avg`, `peak_activity_window`, `rest_hr_avg` |
| Lifestyle | 20% | `routine_stability_index` (Step 1.0); music and travel added in Steps 2–3 |
| Preferences | 15% | Age range, distance, dealbreakers, `declared_preferences` multipliers |

Weights are indicative for MVP and will be recalibrated per city as outcome data accumulates.

### Lifestyle domain weight evolution

| Sub-signal | Step 1.0 | Step 2.0 | Step 3.0 |
|---|---|---|---|
| `routine_stability_index` | 100% | 40% | 20% |
| Music taste | — | 60% | 40% |
| Travel behavior | — | — | 40% |

### Missing signals
Missing signals never block scoring. They reduce the affected domain weight proportionally.

### Match lifecycle

| Status | Meaning |
|---|---|
| `active` | Default on creation. Both users can interact. |
| `drifted` | Health signals not updated in 30+ days. Deprioritized but still visible. |
| `reconnected` | Drifted match where both users have refreshed signals or completed a new Spark. |
| `ended` | Explicitly ended by one of the users. |

`MatchDecayJob` runs daily and marks matches as `drifted` when signals are stale.
Drifted matches are excluded from the top of the active list and do not trigger
new Moment proposals. Reconnected matches return to the top.

### Scoring architecture
- `CompatibilityScoreService` must never be called directly from jobs or services —
  always use `MatchScoringFacade` (ref: `docs/conventions/backend.md`).
- V2: ML ranking layer replaces rule-based candidate ordering when
  `ML_SCORING_ENABLED=true`. Rule-based scoring remains as fallback.
  (ref: `docs/architecture/ml-architecture-v1.md § Section 7`)

---

## References

- DB Schema → [docs/architecture/db-schema.md § Matching](../architecture/db-schema.md#matching)
- API → `docs/api/openapi.yaml`
- Rails Model → [docs/conventions/backend.md § Domain Model](../conventions/backend.md#domain-model-rails-associations)
- ML Architecture → [docs/architecture/ml-architecture-v1.md](../architecture/ml-architecture-v1.md)
- Monetization → [docs/product/monetization.md](../product/monetization.md)

---

## Open Questions

See [docs/product/decisions.md](../product/decisions.md) — filter by `source: docs/features/matching-v1.md`.
