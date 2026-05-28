# Synca — Product Roadmap

> **Single source of truth** for product + tech milestones.
> Last updated: May 2026.

---

## Phase 1 — iOS MVP (Month 1–2) 🎯

> Target: fully working iOS app with health-based matching and Spark — shipped within 2 months.

- [ ] User registration and login (JWT auth, `has_secure_password`)
- [ ] HealthKit authorization and aggregation (sleep, steps, heart rate)
- [ ] Health profile generation and sync to backend (`HealthSummary`)
- [ ] Compatibility score v1 (sleep + activity + lifestyle — weighted 0–100)
- [ ] **Matching Flow 1 — Spark** (`origin: :spark`): QR session initiation, WebSocket sync,
      micro-test flow, instant compatibility result screen, reward issuance (`SparkReward`),
      IRL verification count. Score ≥ 50 → Match created.
      Spark-origin matches labeled *"Synca confermata"* in the UI.
- [ ] **Matching Flow 2 — Algorithm** (`origin: :algorithm`): nightly `MatchingJob` generates
      suggested matches from health summaries. Score ≥ 65 → Match created.
      Algorithm-origin matches labeled *"Synca suggerita"* in the UI.
      Gated as premium feature from launch.
- [ ] Match list UI with plain-language compatibility explanation

---

## Phase 2 — Trust + Safety + Notifications (Month 3–6)

- [ ] TrustScore v0: phone verification, profile completeness, behavior signals
- [ ] Anti-fake: low-trust profiles ranked down or excluded from match pools
- [ ] Telegram bot v0: onboarding reminders, match notifications, profile reminders
- [ ] Preference profile setup (age range, distance, dealbreakers)
- [ ] Liveness check integration (basic)

---

## Phase 3 — Android + Payments (Month 6–9)

- [ ] Android app: onboarding, Health Connect, profile, match list
- [ ] **Synca Spark on Android**: full feature parity with iOS
- [ ] Premium subscription (iOS StoreKit + Android Play Billing + RU local provider)
- [ ] Feature gating:
  - Free tier: Spark-origin matches only, max 3 active matches
  - Premium tier: algorithm-origin matches, unlimited active matches, Sync Rooms
- [ ] Date proposal v0 (basic proposal creation and acceptance)

---

## Phase 4 — Date Proposals + Reputation (Month 9–12)

- [ ] Full date proposal flow (suggest, accept, decline, completed)
- [ ] Image moderation (escort/nudity detection)
- [ ] Reputation signals (no-show, reports)
- [ ] TrustScore v1: includes behavioral reputation and `irl_verification_count` weighting

---

## Phase 5 — Sync Rooms (Month 12–15)

- [ ] **Sync Room `duo`**: 1-to-1 match chat as a Sync Room (replaces raw match chat)
- [ ] **Sync Room `small_group`** (3–8 members): requires full Spark graph between all members.
      Use cases: group of friends, aperitivo, weekend plans.
- [ ] **Sync Room `event_room`** (9–22 members): each member needs ≥1 Spark with the creator.
      Use cases: calcetto, escape room, padel. Creator acts as social guarantor.
- [ ] Spark invite flow: creator can send a deep-link invite to facilitate a Spark between
      two members who have not yet met, enabling them to join the room.
- [ ] Action Cable broadcast for real-time group messaging
- [ ] Sync Room premium gating: `small_group` and `event_room` are premium-only

---

## Phase 6 — Matching v2 + Analytics (Month 15–21)

- [ ] Outcome logging (chat started, date completed, rating)
- [ ] Adaptive matching: tune weights per user from outcome data
- [ ] Internal analytics dashboard (MAU, conversion, date rate)
- [ ] Spotify integration for music taste signal
- [ ] Travel behavior integration (Polarsteps / Maps)
- [ ] Algorithm confidence score surfaced in UI for premium users

---

## Phase 7 — Multi-city + Localisation (Month 21–27)

- [ ] CityConfig model (pricing, venue partners, event calendar)
- [ ] Data residency routing (RU / EU)
- [ ] App localisation: RU, EN, IT, TH, PT, ES
- [ ] 5–7 active cities

---

## Phase 8 — Group Compatibility Engine (Month 27+)

- [ ] **Group compatibility engine v1**: extend pairwise model to score multi-user group
      cohesion; validate with anonymized data from seeding events in Seoul and Milan.
- [ ] **Group date proposals**: curated activity suggestions (morning runs, sauna, padel)
      based on lifestyle alignment across the group.
- [ ] **Group date packs**: monetization surface co-branded with venue partners.
- [ ] No re-architecture required — individual compatibility profiles and `SparkSession`
      IRL data from earlier phases are the direct data foundation.
