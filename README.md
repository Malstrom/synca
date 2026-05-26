# Synca

Synca is a health-based dating app for iOS and Android that uses Apple Health and Health Connect data
to generate high-quality, low-volume matches between people based on lifestyle compatibility.

Instead of endless swiping, Synca produces **few but highly compatible matches** by comparing
real behavioral signals: sleep patterns, activity habits, music taste, and travel lifestyle.

---

## Product Vision

Most dating apps optimize for engagement, not for outcomes. Synca is built around the opposite
principle: show fewer people, but show the right ones.

Compatibility is estimated from:

- **Sleep** — chronotype, regularity, social jetlag.
- **Activity** — movement patterns, weekly active minutes.
- **Music** — taste and listening habits (Spotify integration, future).
- **Travel & lifestyle** — consistency of routine, travel frequency.
- **Stated preferences** — dealbreakers, age range, distance.

Health data is never exposed between users. Only derived compatibility scores are used in matching.

---

## Core Pillars

1. **Health profile generation**
   The app reads authorized HealthKit / Health Connect data and transforms it into aggregated
   metrics (weekly averages, chronotype, activity score). Raw samples are never shared.

2. **Compatibility scoring**
   A matching engine compares aggregated health profiles and produces a 0–100 score with a
   domain breakdown (sleep, activity, lifestyle).

3. **Anti-swipe-fatigue design**
   Users receive very few matches per day (high quality over high volume).
   Profiles that are a bad fit are silently excluded ("ghosted") by the algorithm.

4. **Trust & Safety**
   Every user has a TrustScore that factors in liveness verification, profile completeness,
   and behavioral signals. Low-trust profiles are ranked down or gated.

5. **Date proposals**
   Matched users are guided toward a real date via structured proposals (time, place,
   confirmation by both sides), tracked to measure real-world outcomes.

---

## Privacy Principles

- Never expose raw HealthKit / Health Connect samples between users.
- Store and compare only derived, aggregated metrics.
- Ask for explicit consent for health-based matching at onboarding.
- Minimize long-term data storage: keep only what is needed for compatibility and UX.
- Data residency: Russian users' data stored in Russia; EU users' data in the EU.
- Make it easy to disconnect health permissions and refresh consent at any time.

---

## Repository Structure

```text
synca/
├── apps/
│   ├── ios/
│   │   └── Synca/
│   └── android/
│       └── Synca/
├── backend/
│   └── api/
├── docs/
│   ├── product/
│   │   ├── vision.md
│   │   ├── roadmap.md
│   │   └── matching.md
│   ├── architecture/
│   │   ├── ios-structure.md
│   │   ├── android-structure.md
│   │   └── api-flow.md
│   ├── api/
│   │   └── endpoints.md
│   └── roadmap/
│       └── Synca_Roadmap_Tecnica_0-24_mesi.md
├── scripts/
├── .github/
│   └── workflows/
├── .gitignore
└── README.md
```

---

## iOS App Structure

```text
apps/ios/Synca/
├── Synca/
│   ├── Models/
│   ├── Services/
│   │   ├── HealthKit/
│   │   ├── Matching/
│   │   └── API/
│   ├── ViewModels/
│   ├── Views/
│   │   ├── Onboarding/
│   │   ├── Dashboard/
│   │   ├── Health/
│   │   ├── Matching/
│   │   ├── DateProposals/
│   │   └── Auth/
│   ├── Resources/
│   └── SyncaApp.swift
├── Synca.xcodeproj/
└── SyncaTests/
```

---

## Android App Structure

```text
apps/android/Synca/
├── app/
│   └── src/main/
│       ├── java/com/synca/
│       │   ├── data/
│       │   │   ├── health/
│       │   │   ├── api/
│       │   │   └── models/
│       │   ├── ui/
│       │   │   ├── onboarding/
│       │   │   ├── matching/
│       │   │   ├── dateproposals/
│       │   │   └── profile/
│       │   └── SyncaApp.kt
│       └── res/
└── build.gradle
```

---

## Backend Structure

```text
backend/api/
├── app/
│   ├── controllers/
│   │   └── api/
│   │       └── v1/
│   ├── models/
│   │   ├── user.rb
│   │   ├── health_summary.rb
│   │   ├── preference_profile.rb
│   │   ├── trust_score.rb
│   │   ├── match.rb
│   │   ├── date_proposal.rb
│   │   ├── subscription.rb
│   │   └── transaction.rb
│   └── services/
│       ├── matching/
│       │   ├── matching_service.rb
│       │   └── compatibility_score_service.rb
│       └── trust/
│           └── trust_score_service.rb
├── config/
│   └── routes.rb
└── db/
    └── schema.rb
```

---

## Main Models

### iOS Domain Models

- `HealthDayValue`
- `SleepDayValue`
- `HealthSummary` (aggregated, sent to backend)
- `MatchingProfile`
- `CompatibilityBreakdown`
- `MatchCandidate`
- `SwipeAction`
- `DateProposal`

### Android Domain Models

- `HealthSummary` (aggregated via Health Connect)
- `MatchingProfile`
- `CompatibilityBreakdown`
- `DateProposal`

### Backend Domain Models

- `User`
- `HealthSummary`
- `PreferenceProfile`
- `TrustScore`
- `Match`
- `DateProposal`
- `Subscription`
- `Transaction`

---

## Matching Strategy

The compatibility score is a weighted sum across four domains:

| Domain      | Weight | Signals used                                |
|-------------|--------|---------------------------------------------|
| Sleep       | 35%    | Chronotype, sleep duration avg, regularity  |
| Activity    | 25%    | Weekly active minutes, step patterns        |
| Lifestyle   | 25%    | Music taste, travel frequency, routine      |
| Preferences | 15%    | Age range, distance, stated dealbreakers    |

Output: a single `score` 0–100 with a per-domain breakdown shown to users in plain language
(e.g. "Your sleep schedules are well aligned").

---

## TrustScore

Every user has a `TrustScore` (0–100) computed from:

- **Identity:** phone/email verification, liveness check.
- **Profile:** completeness, photo quality.
- **Behavior:** no-show rate, reports received, consistency across signals.

Low TrustScore profiles are ranked down in matching or gated from features.

---

## API Overview

Base path: `/api/v1`

| Method | Endpoint                     | Description                       |
|--------|------------------------------|-----------------------------------|
| POST   | `/auth/signup`               | Register a new user               |
| POST   | `/auth/login`                | Authenticate                      |
| GET    | `/profile`                   | Get current user profile          |
| PUT    | `/profile`                   | Update profile                    |
| POST   | `/health_summaries`          | Upload aggregated health data     |
| GET    | `/preferences`               | Get preference profile            |
| PUT    | `/preferences`               | Update preferences                |
| GET    | `/matches`                   | Get curated match list            |
| GET    | `/date_proposals`            | List date proposals               |
| POST   | `/date_proposals`            | Create a date proposal            |
| POST   | `/date_proposals/:id/accept` | Accept a proposal                 |
| POST   | `/date_proposals/:id/decline`| Decline a proposal                |

---

## Development Conventions

### Stack

- **iOS:** SwiftUI, HealthKit, lightweight MVVM
- **Android:** Kotlin, Jetpack Compose, Health Connect
- **Backend:** Rails API mode, PostgreSQL
- **Auth:** JWT token-based (or Sign in with Apple for iOS)
- **Source control:** Git + GitHub

### Code Rules

- Always state the file path before writing any code.
- Write code ready to paste into that file.
- Keep comments short and in English, only for non-obvious logic.
- Prefer small, incremental changes over big rewrites.
- When a model changes, update all dependent files consistently.
- Never expose raw health data between users.
- Avoid fake placeholders when a real structure can be proposed.

### Git Rules

- Commit messages in English, describing the change clearly.
- Prefer small feature branches.
- Keep `main` stable.

Suggested branch names:

```text
feature/health-profile
feature/matching-engine
feature/trust-score
feature/telegram-bot
feature/android-health-connect
feature/date-proposals
feature/premium-payments
```

---

## Recommended Development Workflow

1. Define the feature goal clearly.
2. Identify the exact files to create or edit.
3. Implement the smallest working version.
4. Compile and fix integration issues.
5. Commit a focused, single-purpose change.
6. Push to GitHub.
7. Document important structural decisions in `docs/`.

---

## Development Roadmap (summary)

Full roadmap: `docs/roadmap/Synca_Roadmap_Tecnica_0-24_mesi.md`

| Phase | Timeline    | Focus                                               |
|-------|-------------|-----------------------------------------------------|
| 0–1   | Month 0–1   | Foundation: monorepo, CI, environments              |
| 1     | Month 1–3   | iOS MVP: auth, HealthKit, profiles, matching v0     |
| 2     | Month 3–6   | Matching health-based v1, TrustScore v0, Telegram   |
| 3     | Month 6–9   | Android app, Payments, Premium tier                 |
| 4     | Month 9–12  | Date Proposals, Trust & Safety v1                   |
| 5     | Month 12–18 | Matching v2 (data-driven), Analytics                |
| 6     | Month 18–24 | Multi-city scaling, Localisation (RU/EN/IT/TH/PT/ES)|

---

## Local Development

### iOS

Open the Xcode project from:

```text
apps/ios/Synca/
```

Minimum deployment target: iOS 17+.

### Android

Open the Android project from:

```text
apps/android/Synca/
```

Minimum SDK: API 26+ (Health Connect requirement).

### Rails

```bash
cd backend/api
bundle install
rails db:create db:migrate
rails server
```

Stack:

- Ruby 3.3+
- Rails 7.1+ (API mode)
- PostgreSQL
- Versioned namespace: `/api/v1`

---

## Purpose of This Repository

This repository is the single source of truth for Synca: product vision, mobile development
(iOS + Android), Rails API backend, architecture decisions, and documentation.

It is designed to support an iterative workflow where product reasoning, code, and technical
documentation evolve together — kept simple, honest, and ready to ship.
