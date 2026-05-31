# Feature: Cycle
**Version:** 1.0
**Last updated:** May 2026
**Status:** Draft
**Phase:** 1

---

## Overview

Cycle adds an optional menstrual-cycle signal layer to Synca. It is designed for users
who explicitly consent to importing cycle-related data from Apple Health or Android
health providers and want the app to use that information to improve timing,
personalisation, and compatibility interpretation.

This feature is privacy-first by design. Cycle data is treated as highly sensitive.
Raw samples are never stored on the backend. Phase classification and aggregation happen
on-device first, and only derived values needed by the product are synced.

Cycle is not a fertility, contraception, or medical feature. It must never present
medical claims, pregnancy predictions, or health advice. Its role inside Synca is
limited to behavioural context, self-understanding, and better timing of product
surfaces such as match delivery, Spark prompts, and social energy interpretation.

Prerequisite: `users`, `profiles`, and `signals` tables (ref: `docs/features/profile-v1.md`, `docs/features/signals-v1.md`).

---

## Product Goals

### Primary goals

- Add a high-value optional signal that improves personalisation for users who menstruate.
- Help users recognise their own rhythm through non-medical behavioural summaries.
- Improve timing quality for high-intent product moments without increasing notification pressure.
- Preserve user trust through strict consent, minimisation, and zero exposure of cycle state to matches.

### Non-goals

- No fertility tracking.
- No ovulation prediction messaging.
- No pregnancy-related inference.
- No direct display of cycle phase, symptoms, or period status to other users.
- No hard filtering of candidates based on menstrual-cycle information.

---

## User Flow

1. User opens Signals settings and sees an optional card: `Cycle insights`.
2. The app explains what will be imported, what will not be imported, and how the data will be used.
3. User grants explicit consent for cycle data processing.
4. App requests read-only access to cycle-related types from Apple Health or Android health provider.
5. `SignalsAggregatorService` reads the recent history on-device and computes derived values.
6. App sends only derived cycle metrics to the backend through a partial signals update.
7. User can pause, revoke, or delete cycle-derived data independently from the rest of Signals.

---

## Data Sources

### iOS

Primary source: Apple Health / HealthKit.

Relevant categories may include:
- Menstrual flow entries
- Cycle tracking events available through HealthKit
- Optional symptom categories only if a separate consent gate is added in a later version

### Android

Primary source: Health Connect when supported by the device and available apps.

Android parity should begin with the minimal common subset needed to classify a coarse
cycle rhythm. Any category not consistently available across devices must be ignored in v1.

---

## Derived Signals

All values below are derived on-device and stored as optional additions to the existing
`signals` row.

### v1 fields

| Field | Type | Description |
|---|---|---|
| `cycle_tracking_enabled` | boolean | Whether user explicitly enabled cycle-based signals |
| `cycle_phase` | string | Coarse current phase: `menstrual` \| `follicular` \| `ovulatory_window` \| `luteal` \| `unknown` |
| `cycle_regularity_score` | float | Stability score from recent cycles (0.0–1.0) |
| `cycle_length_avg` | float | Average cycle length in days across recent complete cycles |
| `cycle_phase_confidence` | float | Confidence in current phase estimation (0.0–1.0) |
| `cycle_last_computed_at` | datetime | When cycle aggregation was last computed on-device |

### Optional future fields

These are intentionally excluded from v1 until privacy and product value are validated:
- Symptom clusters
- Energy trend by phase
- Sleep delta by phase
- Mood self-report by phase
- Period prediction windows

---

## DB Schema

No dedicated new table in v1. Cycle is introduced as an optional column group appended
to `signals`, consistent with the current Signals architecture.

```sql
signals
  -- Step 1.x: cycle (appended to existing table)
  cycle_tracking_enabled   boolean   -- explicit user opt-in
  cycle_phase              string    -- 'menstrual' | 'follicular' | 'ovulatory_window' | 'luteal' | 'unknown'
  cycle_regularity_score   float     -- 0.0-1.0 rhythm stability based on recent complete cycles
  cycle_length_avg         float     -- average cycle length in days
  cycle_phase_confidence   float     -- 0.0-1.0 confidence of phase classification
  cycle_last_computed_at   datetime  -- when cycle aggregation last ran on-device
```

Important: no raw menstrual-flow samples, symptom logs, or event history are stored on the backend.

---

## API Endpoints

Cycle reuses the existing Signals endpoints with partial update semantics.

| Method | Path | Auth required | Description |
|--------|------|---------------|-------------|
| PATCH | `/api/v1/signals` | Yes | Appends or updates derived cycle metrics on the user's signals record |
| GET | `/api/v1/signals/me` | Yes | Returns current user's raw signals including cycle-derived fields |
| GET | `/api/v1/signals/me/summary` | Yes | Returns human-readable self-summary that may include cycle-aware insights |
| DELETE | `/api/v1/signals/cycle` | Yes | Deletes cycle-derived fields without deleting other signal groups |

Ref: `docs/api/openapi.yaml`

---

## Consent and Privacy

Cycle data requires a separate explicit opt-in. Access to general health signals does
not imply consent for menstrual-cycle processing.

### Consent rules

- Separate toggle from general Health permissions.
- Clear pre-permission screen with plain-language explanation.
- Explicit statement that cycle data is never shown to matches.
- Explicit statement that the feature is not medical and not contraceptive.
- Independent revocation and deletion flow.

### Data minimisation

- Raw samples remain on-device.
- Only coarse derived metrics are synced.
- `cycle_phase` must remain coarse and product-limited.
- No timestamp-level event history on backend.
- No sharing with ad networks, analytics vendors, or recommendation explanations visible to other users.

### Usage restrictions

Allowed:
- Timing of match delivery
- Timing of Spark prompts
- Self-insight summaries
- Lightweight compatibility interpretation

Not allowed:
- Fertility prediction
- Exclusion from the matching pool
- Ranking copy such as "best time to date"
- Any explanation shown to another user that mentions cycle-derived state

---

## User-facing Layer

This feature may enrich only the current user's own summary.

Examples of acceptable copy:
- "Your energy rhythm appears more variable across the month."
- "Some weeks you seem more socially active than others."
- "Your recent rhythm looks consistent enough for better timing personalisation."

Examples of forbidden copy:
- "You are ovulating today."
- "This is your fertile window."
- "You are more attractive this week."
- "You should meet people now."

All user-facing copy must stay behavioural, non-medical, and low-precision.

---

## Matching Integration

Cycle should be used as a soft contextual signal, never as a dominant domain.

### Allowed uses in v1

- Reduce notification pressure during lower-engagement phases when confidence is high.
- Shift delivery timing of Sparks or prompts toward moments of historically higher engagement.
- Slightly adjust interpretation of other signals such as routine stability or social energy.

### Forbidden uses in v1

- Hard boost or penalty on desirability.
- Direct pairing based on same-phase or opposite-phase logic.
- Visible compatibility labels mentioning menstrual-cycle state.

Recommended implementation: treat cycle as a contextual modifier on product timing,
not as a standalone score driver in `CompatibilityScoreService`.

---

## Premium Gating

None in v1.

Reasoning: cycle insights increase trust and differentiation, and the strongest early
value is user self-recognition rather than monetisation. Premium gating can be tested
later only for advanced summaries, never for basic privacy controls or deletion rights.

---

## Analytics

Track only privacy-safe product events:
- `cycle_opt_in_started`
- `cycle_opt_in_completed`
- `cycle_sync_completed`
- `cycle_sync_deleted`
- `cycle_summary_viewed`

No analytics event should include raw phase history or symptom content.

---

## Open Questions

- Should Android v1 launch only when Health Connect parity reaches minimum acceptable quality?
- Is `cycle_phase` necessary on the backend, or can timing decisions happen fully on-device?
- Should `DELETE /api/v1/signals/cycle` nullify fields or create a dedicated deletion audit record?
- What minimum amount of recent history is required before phase confidence is high enough to use?
- Should the feature be available only to users who self-identify as menstruating, or to anyone who enables it?
