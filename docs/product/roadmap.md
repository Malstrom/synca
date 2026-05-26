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

## Phase 2 — Health Matching + Trust (Month 3–6)

- [ ] Compatibility score v1 (sleep + activity + lifestyle)
- [ ] Match list with compatibility breakdown (plain language)
- [ ] TrustScore v0 (phone verification, profile completeness, behavior signals)
- [ ] Anti-fake: low trust profiles ranked down
- [ ] Telegram bot: match notifications + profile reminders

## Phase 3 — Android + Payments (Month 6–9)

- [ ] Android app: onboarding, Health Connect, profile, match list
- [ ] Premium subscription (iOS StoreKit + Android Play Billing + RU local provider)
- [ ] Feature gating: limited matches for free tier, priority for premium
- [ ] Date proposal v0 (basic proposal creation and acceptance)

## Phase 4 — Date Proposals + Safety (Month 9–12)

- [ ] Full date proposal flow (suggest, accept, decline, completed)
- [ ] Liveness check integration
- [ ] Image moderation (escort/nudity detection)
- [ ] Reputation signals (no-show, reports)
- [ ] TrustScore v1: includes behavioral reputation

## Phase 5 — Matching v2 + Analytics (Month 12–18)

- [ ] Outcome logging (chat started, date completed, rating)
- [ ] Adaptive matching: tune weights per user from outcomes
- [ ] Internal analytics dashboard (MAU, conversion, date rate)
- [ ] Spotify integration for music taste signal

## Phase 6 — Multi-city + Localisation (Month 18–24)

- [ ] CityConfig model (pricing, venue partners, orari)
- [ ] Data residency routing (RU / EU)
- [ ] App localisation: RU, EN, IT, TH, PT, ES
- [ ] 5–7 active cities
