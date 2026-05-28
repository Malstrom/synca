# Synca — Product Roadmap

This document defines **sequencing only**.
Specs, schemas, and API details live exclusively in the feature docs under `docs/features/`.

Each entry follows the pattern:
`Feature — Step X.Y` → [`feature-file.md`](../features/feature-file.md)

---

## Phase 1 — iOS MVP · Month 0–3

> Goal: working iOS app, first real users, health data flowing.

- Profile — Step 1.0 (registration, onboarding, JWT auth, refresh token) → [`profile-v1.md`](../features/profile-v1.md)
- Signals — Step 1.0 (HealthKit: sleep + activity aggregation) → [`signals-v1.md`](../features/signals-v1.md)
- Matching — v0 rule-based (city + age + gender filter, no score) → [`matching-v1.md`](../features/matching-v1.md)

---

## Phase 2 — Health Matching + Trust + Spark + Chat · Month 3–6

> Goal: first compatibility scores, first IRL Sparks, anti-fake baseline, and a chat
> channel for every match — a Spark without a conversation has nowhere to go.

- Matching — Step 1.0 (compatibility score: sleep + activity + preferences) → [`matching-v1.md`](../features/matching-v1.md)
- Trust — Step 1.0 (TrustScore v0: phone verification, completeness, behavior) → [`trust-v1.md`](../features/trust-v1.md)
- Spark — Step 1.0 (Proximity Spark via BLE/QR, scoring, SparkReward) → [`spark-v1.md`](../features/spark-v1.md)
- Circles — Step 1.0 (Duo Circle: 1-to-1 match chat via Action Cable) → [`circles-v1.md`](../features/circles-v1.md)

---

## Phase 3 — Android + Payments · Month 6–9

> Goal: Android parity, first revenue, premium gating live.

- Profile — Step 2.0 (social login: Apple, Google, VK) → [`profile-v1.md`](../features/profile-v1.md)
- Signals — Step 1.0 on Android (Health Connect) → [`signals-v1.md`](../features/signals-v1.md)
- Spark — Step 1.0 on Android (full feature parity) → [`spark-v1.md`](../features/spark-v1.md)
- Premium subscription (iOS StoreKit + Android Play Billing + RU local provider)
- Moments — Step 1.0 basic (proposal + accept/decline) → [`moments-v1.md`](../features/moments-v1.md)

---

## Phase 4 — Safety + Full Moments · Month 9–12

> Goal: full date lifecycle, liveness, image moderation, reputation signals.

- Moments — Step 1.0 full (counter-proposal, complete, no-show, rating) → [`moments-v1.md`](../features/moments-v1.md)
- Trust — Step 2.0 (liveness check + image moderation) → [`trust-v1.md`](../features/trust-v1.md)
- Trust — Step 3.0 (TrustScore v1: behavioral reputation from Moments) → [`trust-v1.md`](../features/trust-v1.md)
- Moments — Step 2.0 (reputation signals fed into TrustScore) → [`moments-v1.md`](../features/moments-v1.md)

---

## Phase 5 — Circles v2 · Month 12–15

> Goal: extend Circles beyond 1-to-1 — group and event spaces gated on the Spark graph.

- Circles — Step 2.0 (Small Group + Event Circles, Spark Invite Link) → [`circles-v1.md`](../features/circles-v1.md)

---

## Phase 6 — Matching v2 + Signal Expansion · Month 15–21

> Goal: richer compatibility signals, adaptive weights, premium analytics.

- Signals — Step 2.0 (Spotify / Yandex Music taste) → [`signals-v1.md`](../features/signals-v1.md)
- Signals — Step 3.0 (travel behavior: Polarsteps + location history) → [`signals-v1.md`](../features/signals-v1.md)
- Matching — Step 2.0 (music signal in compatibility score) → [`matching-v1.md`](../features/matching-v1.md)
- Matching — Step 3.0 (travel signal in compatibility score) → [`matching-v1.md`](../features/matching-v1.md)
- Profile — Step 3.0 (completeness score) → [`profile-v1.md`](../features/profile-v1.md)
- Internal analytics dashboard (MAU, conversion, date rate)

---

## Phase 7 — Multi-city + Localisation · Month 21–27

> Goal: 5–7 active cities, full localisation, data residency compliance.

- CityConfig model (pricing, venue partners, event calendar, threshold tuning)
- Data residency routing (RU / EU)
- App localisation: RU, EN, IT, TH, PT, ES

---

## Phase 8 — Group Compatibility Engine · Month 27+

> Goal: extend pairwise compatibility to group cohesion; enter the social wellness category.

- Spark — Step 2.0 (Group Spark: multi-user scoring) → [`spark-v1.md`](../features/spark-v1.md)
- Group compatibility engine v1 (pairwise model extended to group cohesion score)
- Group Moments: curated activity proposals (runs, sauna, padel) based on group alignment → [`moments-v1.md`](../features/moments-v1.md)
- Group Moment packs: venue partner monetization surface

> No re-architecture required — individual compatibility profiles and Spark IRL data
> from earlier phases are the direct data foundation.
