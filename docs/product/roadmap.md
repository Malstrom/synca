# Synca — Product Roadmap

This document defines **sequencing only**.
Specs, schemas, and API details live exclusively in the feature docs under `docs/features/`.
User flows for each phase live in `docs/product/phases/` — see [phase-0.md](phases/phase-0.md).
Go-to-market strategy by phase lives in `docs/growth/go-to-market.md` *(planned)*.

Each entry follows the pattern:
`Feature — Step X.Y` → [`feature-file.md`](../features/feature-file.md)

---

## Phase 0 — Validation MVP · Month 0–3

> Goal: prove the core hypothesis with real users before building full infrastructure.
> Primary mechanic: Spark IRL. Onboarding is frictionless (guest account via email only).
> Success metric: 50 active users, 20 completed Spark sessions, 5+ spontaneous re-encounters
> tracked within 30 days of a Spark session.

**User flows:** [`docs/product/phases/phase-0.md`](phases/phase-0.md)

### Research — Field Research Bot

- Telegram bot used by trusted friends and field researchers to conduct structured
  in-person interviews in Italian, English, or Russian
- Responses are appended to a shared Google Sheet as the canonical dataset
- Founder receives a structured Telegram recap for each completed interview
- Enables rapid pre-app research before product instrumentation exists
- Ref: [`field-research-bot.md`](../research/field-research-bot.md)

### Onboarding — Guest Account (no password)

- User enters email only → backend creates a guest `User` record silently
- No password required at this stage
- After the first Spark session: magic link sent to email → user activates full account
- If user never activates: guest record retained for 30 days, then purged
- Rationale: removes the auth wall from the highest-curiosity moment (two people
  physically together wanting to try Spark immediately)

Ref: [`profile-v1.md — Step 0`](../features/profile-v1.md)

### Spark — Step 1.0 (core validation mechanic)

- BLE/QR session linking two devices in the same physical location
- Instant compatibility snapshot from health signals + declared preferences
- Plain-language explanation of alignment dimensions
- No algorithm matching in this phase — Spark is the only match origin
- Ref: [`spark-v1.md`](../features/spark-v1.md)

### Signals — Step 0 (Declared Preferences questionnaire)

- Short questionnaire at onboarding (5–7 questions)
- Captures preference weights: sleep-together importance, temperature preference,
  activity level self-assessment, routine rigidity
- Stored as `declared_preferences` on the user record
- Ref: [`signals-v1.md — Step 0`](../features/signals-v1.md)

### Signals — Step 1.0 (HealthKit / Health Connect)

- Sleep + activity aggregation, on-device only
- Derived metrics sent to backend
- Ref: [`signals-v1.md — Step 1.0`](../features/signals-v1.md)

### Signals — User-facing layer

- After connecting health data, the user sees their own computed profile:
  chronotype label, peak energy window, routine stability tier, activity tier
- Derived entirely from the `signals` record — no separate data store
- Served by `GET /api/v1/signals/me/summary`
- This is the immediate value hook before any match is received:
  the user must recognise themselves in what the data says about them
- Ref: [`signals-v1.md — User-facing layer`](../features/signals-v1.md)

### What is explicitly out of scope in Phase 0

- Algorithm matching (nightly MatchingJob) — deferred to Phase 1
- Trust scoring beyond guest/active account distinction — deferred to Phase 1
- Premium gating — deferred to Phase 2
- Android — iOS only in Phase 0
- Photos and bio — optional, not required
- Circles (match chat) — deferred to Phase 1

---

## Phase 1 — iOS MVP · Month 3–9

> Goal: working iOS app with real users, health data flowing, first compatibility scores,
> first IRL Sparks, anti-fake baseline, and a chat channel for every match —
> a Spark without a conversation has nowhere to go.

- Profile — Step 1.0 (full registration, onboarding wizard, JWT auth, refresh token) → [`profile-v1.md`](../features/profile-v1.md)
- Signals — Step 1.0 (HealthKit: sleep + activity aggregation) → [`signals-v1.md`](../features/signals-v1.md)
- Matching — v0 rule-based (city + age + gender filter, no score) → [`matching-v1.md`](../features/matching-v1.md)
- Matching — Step 1.0 (compatibility score: sleep + activity + declared preferences) → [`matching-v1.md`](../features/matching-v1.md)
- Trust — Step 1.0 (TrustScore v0: phone verification, completeness, behavior) → [`trust-v1.md`](../features/trust-v1.md)
- Spark — Step 1.0 (Proximity Spark via BLE/QR, scoring, SparkReward) → [`spark-v1.md`](../features/spark-v1.md)
- Circles — Step 1.0 (Duo Circle: 1-to-1 match chat via Action Cable) → [`circles-v1.md`](../features/circles-v1.md)

---

## Phase 2 — Android + Payments · Month 9–12

> Goal: Android parity, first revenue, premium gating live.

- Profile — Step 2.0 (social login: Apple, Google, VK) → [`profile-v1.md`](../features/profile-v1.md)
- Signals — Step 1.0 on Android (Health Connect) → [`signals-v1.md`](../features/signals-v1.md)
- Spark — Step 1.0 on Android (full feature parity) → [`spark-v1.md`](../features/spark-v1.md)
- Premium subscription (iOS StoreKit + Android Play Billing + RU local provider)
- Moments — Step 1.0 basic (proposal + accept/decline) → [`moments-v1.md`](../features/moments-v1.md)

---

## Phase 3 — Safety + Full Moments · Month 12–15

> Goal: full meeting lifecycle, liveness, image moderation, reputation signals.

- Moments — Step 1.0 full (counter-proposal, complete, no-show, rating) → [`moments-v1.md`](../features/moments-v1.md)
- Trust — Step 2.0 (liveness check + image moderation) → [`trust-v1.md`](../features/trust-v1.md)
- Trust — Step 3.0 (TrustScore v1: behavioral reputation from Moments) → [`trust-v1.md`](../features/trust-v1.md)
- Moments — Step 2.0 (reputation signals fed into TrustScore) → [`moments-v1.md`](../features/moments-v1.md)

---

## Phase 4 — Circles v2 · Month 15–18

> Goal: extend Circles beyond 1-to-1 — group and event spaces gated on the Spark graph.

- Circles — Step 2.0 (Small Group + Event Circles, Spark Invite Link) → [`circles-v1.md`](../features/circles-v1.md)

---

## Phase 5 — Matching v2 + Signal Expansion · Month 18–24

> Goal: richer compatibility signals, adaptive weights, premium analytics.

- Signals — Step 2.0 (Spotify / Yandex Music taste) → [`signals-v1.md`](../features/signals-v1.md)
- Signals — Step 3.0 (travel behavior: Polarsteps + location history) → [`signals-v1.md`](../features/signals-v1.md)
- Matching — Step 2.0 (music signal in compatibility score) → [`matching-v1.md`](../features/matching-v1.md)
- Matching — Step 3.0 (travel signal in compatibility score) → [`matching-v1.md`](../features/matching-v1.md)
- Profile — Step 3.0 (completeness score) → [`profile-v1.md`](../features/profile-v1.md)
- Internal analytics dashboard (MAU, conversion, re-encounter rate)

---

## Phase 6 — Multi-city + Localisation · Month 24–30

> Goal: 5–7 active cities, full localisation, data residency compliance.

- CityConfig model (pricing, venue partners, event calendar, threshold tuning)
- Data residency routing (RU / EU)
- App localisation: RU, EN, IT, TH, PT, ES

---

## Phase 7 — Group Compatibility Engine · Month 30+

> Goal: extend pairwise compatibility to group cohesion; enter the social wellness category.

- Spark — Step 2.0 (Group Spark: multi-user scoring) → [`spark-v1.md`](../features/spark-v1.md)
- Group compatibility engine v1 (pairwise model extended to group cohesion score)
- Group Moments: curated activity proposals (runs, sauna, padel) based on group alignment → [`moments-v1.md`](../features/moments-v1.md)
- Group Moment packs: venue partner monetization surface

> No re-architecture required — individual compatibility profiles and Spark IRL data
> from earlier phases are the direct data foundation.
