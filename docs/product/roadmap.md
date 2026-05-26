# Synca — Product Roadmap

This document tracks the high-level product roadmap. For the full technical roadmap see:
`docs/roadmap/Synca_Roadmap_Tecnica_0-24_mesi.md`

## Phase 1 — iOS MVP (Month 1–3)

- [ ] User registration and login
- [ ] HealthKit authorization and aggregation (sleep, steps)
- [ ] Health profile generation and sync to backend
- [ ] Preference profile setup
- [ ] Matching v0 (rule-based: city, age, gender)
- [ ] Basic match list UI
- [ ] Telegram bot v0 (onboarding reminders, match notifications)

## Phase 2 — Health Matching + Trust + Spark (Month 3–6)

- [ ] Compatibility score v1 (sleep + activity + lifestyle)
- [ ] Match list with compatibility breakdown (plain language)
- [ ] TrustScore v0 (phone verification, profile completeness, behavior signals)
- [ ] Anti-fake: low trust profiles ranked down
- [ ] Telegram bot: match notifications + profile reminders
- [ ] **Synca Spark v0**: QR session initiation, WebSocket sync, micro-test flow, instant
      compatibility result screen, reward issuance (`SparkReward`), IRL verification count

## Phase 3 — Android + Payments (Month 6–9)

- [ ] Android app: onboarding, Health Connect, profile, match list
- [ ] **Synca Spark on Android**: full feature parity with iOS
- [ ] Premium subscription (iOS StoreKit + Android Play Billing + RU local provider)
- [ ] Feature gating: limited matches for free tier, priority for premium
- [ ] Date proposal v0 (basic proposal creation and acceptance)

## Phase 4 — Date Proposals + Safety (Month 9–12)

- [ ] Full date proposal flow (suggest, accept, decline, completed)
- [ ] Liveness check integration
- [ ] Image moderation (escort/nudity detection)
- [ ] Reputation signals (no-show, reports)
- [ ] TrustScore v1: includes behavioral reputation and `irl_verification_count` weighting

## Phase 5 — Matching v2 + Analytics (Month 12–18)

- [ ] Outcome logging (chat started, date completed, rating)
- [ ] Adaptive matching: tune weights per user from outcomes
- [ ] Internal analytics dashboard (MAU, conversion, date rate)
- [ ] Spotify integration for music taste signal
- [ ] Travel behavior integration (Polarsteps / Maps)

## Phase 6 — Multi-city + Localisation (Month 18–24)

- [ ] CityConfig model (pricing, venue partners, event calendar)
- [ ] Data residency routing (RU / EU)
- [ ] App localisation: RU, EN, IT, TH, PT, ES
- [ ] 5–7 active cities

## Phase 7 — Group Compatibility (Month 24+)

- [ ] **Group compatibility engine v1 (research + validation)**: extend pairwise compatibility
      model to score multi-user group cohesion across 4–8 participants; validate with anonymized
      data from seeding events in Seoul and Milan (Wave 2 cities)
- [ ] **Group date proposals**: suggest curated small-group activities (morning runs, sauna
      sessions, padel games) based on lifestyle alignment across the group
- [ ] **Group date packs**: monetization surface co-branded with venue partners
- [ ] No re-architecture required — individual compatibility profiles and `SparkSession` IRL
      data from earlier phases are the direct data foundation
