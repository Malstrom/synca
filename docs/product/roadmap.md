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
      compatibility result screen, reward issuance (`SparkReward`), IRL verification count.
      Spark-origin matches labeled *"Synca confermata"* in the UI.
- [ ] **Algorithm matching v0** (`MatchingJob`): nightly job generates suggested matches from
      health summaries; origin: `algorithm`; gated as premium feature from launch.
      Algorithm-origin matches labeled *"Synca suggerita"* in the UI.

## Phase 3 — Android + Payments (Month 6–9)

- [ ] Android app: onboarding, Health Connect, profile, match list
- [ ] **Synca Spark on Android**: full feature parity with iOS
- [ ] Premium subscription (iOS StoreKit + Android Play Billing + RU local provider)
- [ ] Feature gating:
  - Free tier: Spark-origin matches only, max 3 active matches
  - Premium tier: algorithm-origin matches, unlimited active matches, Sync Rooms
- [ ] Date proposal v0 (basic proposal creation and acceptance)

## Phase 4 — Date Proposals + Safety (Month 9–12)

- [ ] Full date proposal flow (suggest, accept, decline, completed)
- [ ] Liveness check integration
- [ ] Image moderation (escort/nudity detection)
- [ ] Reputation signals (no-show, reports)
- [ ] TrustScore v1: includes behavioral reputation and `irl_verification_count` weighting

## Phase 5 — Sync Rooms (Month 12–15)

- [ ] **Sync Room `duo`**: 1-to-1 match chat as a Sync Room (replaces raw match chat)
- [ ] **Sync Room `small_group`** (3–8 members): requires full Spark graph between all members.
      Use cases: group of friends, aperitivo, weekend plans.
- [ ] **Sync Room `event`** (9–22 members): each member needs ≥1 Spark with the creator.
      Use cases: calcetto, escape room, padel. Creator acts as social guarantor.
- [ ] Spark invite flow: creator can send a deep-link invite to facilitate a Spark between
      two members who have not yet met, enabling them to join the group.
- [ ] Action Cable broadcast for real-time group messaging
- [ ] Sync Room premium gating: `small_group` and `event` rooms are premium-only

## Phase 6 — Matching v2 + Analytics (Month 15–21)

- [ ] Outcome logging (chat started, date completed, rating)
- [ ] Adaptive matching: tune weights per user from outcomes
- [ ] Internal analytics dashboard (MAU, conversion, date rate)
- [ ] Spotify integration for music taste signal
- [ ] Travel behavior integration (Polarsteps / Maps)
- [ ] Algorithm confidence score surfaced in UI for premium users

## Phase 7 — Multi-city + Localisation (Month 21–27)

- [ ] CityConfig model (pricing, venue partners, event calendar)
- [ ] Data residency routing (RU / EU)
- [ ] App localisation: RU, EN, IT, TH, PT, ES
- [ ] 5–7 active cities

## Phase 8 — Group Compatibility Engine (Month 27+)

- [ ] **Group compatibility engine v1 (research + validation)**: extend pairwise compatibility
      model to score multi-user group cohesion; validate with anonymized data from seeding
      events in Seoul and Milan (Wave 2 cities)
- [ ] **Group date proposals**: suggest curated activities (morning runs, sauna sessions,
      padel games) based on lifestyle alignment across the group
- [ ] **Group date packs**: monetization surface co-branded with venue partners
- [ ] No re-architecture required — individual compatibility profiles and `SparkSession` IRL
      data from earlier phases are the direct data foundation
