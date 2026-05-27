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
   Profiles that are a bad fit are silently excluded (“ghostED”) by the algorithm.

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
- Data residency: Russian users’ data stored in Russia; EU users’ data in the EU.
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
│   ├── api/
│   ├── infra/
│   │   └── deployment.md
│   └── roadmap/
├── .github/
│   └── workflows/
│       ├── rails-ci.yml   ← CI (test + lint + security)
│       └── deploy.yml     ← CD (build + push + Kamal deploy)
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
│   ├── controllers/api/v1/
│   ├── models/
│   └── services/
│       ├── matching/
│       └── trust/
├── bin/
│   └── dev-ngrok     ← one-command dev environment
├── config/
│   ├── deploy.yml    ← Kamal production config
│   └── environments/
│       └── development.rb
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
| Activity    | 30%    | Weekly active minutes, step patterns        |
| Lifestyle   | 20%    | Music taste, travel frequency, routine      |
| Preferences | 15%    | Age range, distance, stated dealbreakers    |

Output: a single `score` 0–100 with a per-domain breakdown shown to users in plain language
(e.g. “Your sleep schedules are well aligned”).

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

| Method | Endpoint                      | Description                      |
|--------|-------------------------------|----------------------------------|
| POST   | `/auth/register`              | Register a new user              |
| POST   | `/auth/login`                 | Authenticate                     |
| GET    | `/users/me`                   | Get current user profile         |
| GET/PUT| `/profile`                    | Get / update profile             |
| POST   | `/health_summaries`           | Upload aggregated health data    |
| GET/PUT| `/preferences`                | Get / update preferences         |
| GET    | `/matches`                    | Get curated match list           |
| GET    | `/date_proposals`             | List date proposals              |
| POST   | `/date_proposals`             | Create a date proposal           |
| POST   | `/date_proposals/:id/accept`  | Accept a proposal                |
| POST   | `/date_proposals/:id/decline` | Decline a proposal               |

Full spec: `docs/api/endpoints.md` — interactive UI at `/api-docs`.

---

## Local Development

### Prerequisites

| Tool | Version | Install |
|------|---------|---------|
| Ruby | 3.3.1   | `rbenv install 3.3.1` |
| PostgreSQL | 16+ | `brew install postgresql@16` |
| ngrok | latest | `brew install ngrok` |
| Caddy | latest | `brew install caddy` |

### First-time setup

```bash
# 1. Clone and install dependencies
git clone https://github.com/Malstrom/synca.git
cd synca/backend/api
bundle install

# 2. Setup database
bin/rails db:create db:migrate db:seed

# 3. Add local dev domain (once only, requires sudo)
sudo bash -c 'echo "127.0.0.1 api.synca.local" >> /etc/hosts'

# 4. Authenticate ngrok (free account at ngrok.com)
ngrok config add-authtoken <YOUR_TOKEN>

# 5. Make the dev script executable (once only)
chmod +x bin/dev-ngrok
```

### Daily development

```bash
cd backend/api
bin/dev-ngrok
```

This single command:
- Starts **Rails** on `127.0.0.1:3000`
- Starts **Caddy** — proxies `http://api.synca.local` → `:3000`
- Starts **ngrok** — generates a public HTTPS tunnel for device testing
- Writes the ngrok URL to `.env.ngrok` at the repo root
- **Destroys `.env.ngrok`** automatically on `Ctrl+C`

URLs available after startup:

| URL | Use |
|-----|-----|
| `http://api.synca.local` | iOS Simulator, browser (fixed, never changes) |
| `http://api.synca.local/api-docs` | Interactive API documentation (Scalar) |
| `https://xxx.ngrok-free.app` | Physical device, external webhooks (changes each run) |

> **ngrok splash page (ERR_NGROK_6024):** On first browser visit, click “Visit Site”.
> For API calls, add the header `ngrok-skip-browser-warning: true`.

### iOS

Open the Xcode project:

```text
apps/ios/Synca/
```

- Minimum deployment target: **iOS 17+**
- Set `BASE_URL = http://api.synca.local` in the Debug scheme environment variables.
- For physical device testing, read `BASE_URL` from `.env.ngrok` (see `docs/infra/deployment.md`).

### Android

Open the Android project:

```text
apps/android/Synca/
```

- Minimum SDK: **API 26+** (Health Connect requirement)
- Set `BASE_URL` in `local.properties` (already gitignored).

---

## CI/CD Pipeline

### Continuous Integration (on every push/PR to `main`)

File: `.github/workflows/rails-ci.yml`

Four jobs run in parallel:

| Job | Tool | Check |
|-----|------|-------|
| `scan_ruby` | Brakeman | Rails security vulnerabilities |
| `gem_audit` | bundler-audit | CVE check on all gems |
| `lint` | RuboCop | Code style + autocorrect diff |
| `test` | Minitest + SimpleCov | Tests + coverage ≥ 90% |

### Continuous Deployment (after CI passes on `main`)

File: `.github/workflows/deploy.yml`

```
CI passes → Build Docker image → Push ghcr.io → Kamal deploy → db:migrate
```

> CD is configured but requires a VPS to be provisioned.
> See `docs/infra/deployment.md` for the full setup guide.

### Required GitHub Secrets

Add in `Settings → Secrets and variables → Actions`:

| Secret | Description |
|--------|-------------|
| `RAILS_MASTER_KEY` | Content of `config/master.key` (decrypts credentials) |
| `SECRET_KEY_BASE` | Output of `bin/rails secret` |
| `KAMAL_REGISTRY_PASSWORD` | GitHub PAT with `write:packages` |
| `KAMAL_SSH_PRIVATE_KEY` | SSH private key for VPS access |
| `KAMAL_SERVER_IP` | VPS IP address |
| `KAMAL_SERVER_HOST` | Public hostname e.g. `api.synca.app` |
| `DATABASE_URL` | PostgreSQL connection string |
| `POSTGRES_PASSWORD` | PostgreSQL password |

---

## Development Conventions

### Stack

- **iOS:** SwiftUI, HealthKit, lightweight MVVM
- **Android:** Kotlin, Jetpack Compose, Health Connect
- **Backend:** Rails 8 API mode, PostgreSQL 16, Solid Queue
- **Auth:** JWT (access + refresh tokens)
- **Infra:** Docker, Kamal, GitHub Container Registry (ghcr.io)

### Code Rules

- Always state the file path before writing any code.
- Write code ready to paste into that file.
- Keep comments short and in English, only for non-obvious logic.
- Prefer small, incremental changes over big rewrites.
- When a model changes, update all dependent files consistently.
- Never expose raw health data between users.

### Git Rules

- Conventional commits format: `type(scope): description`
- Never commit directly to `main` — use feature branches.
- All PRs target `main`, merged via **squash and merge** only.
- Branch protection on `main`: PR required, CI must pass.

Example branch names:

```text
feat/health-profile
feat/matching-engine
feat/trust-score
feat/android-health-connect
feat/date-proposals
fix/auth-token-refresh
```

---

## Development Roadmap (summary)

Full roadmap: `docs/roadmap/Synca_Roadmap_Tecnica_0-24_mesi.md`

| Phase | Timeline   | Focus                                                |
|-------|------------|------------------------------------------------------|
| 0–1   | Month 0–1  | Foundation: monorepo, CI/CD, environments            |
| 1     | Month 1–3  | iOS MVP: auth, HealthKit, profiles, matching v0      |
| 2     | Month 3–6  | Matching health-based v1, TrustScore v0              |
| 3     | Month 6–9  | Android app, Payments, Premium tier                  |
| 4     | Month 9–12 | Date Proposals, Trust & Safety v1                    |
| 5     | Month 12–18| Matching v2 (data-driven), Analytics                 |
| 6     | Month 18–24| Multi-city scaling, Localisation (RU/EN/IT/TH/PT/ES) |

---

## Purpose of This Repository

This repository is the single source of truth for Synca: product vision, mobile development
(iOS + Android), Rails API backend, architecture decisions, and documentation.

It is designed to support an iterative workflow where product reasoning, code, and technical
documentation evolve together — kept simple, honest, and ready to ship.
