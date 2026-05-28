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

1. **Signal generation**
   The app reads authorized HealthKit / Health Connect data and transforms it into aggregated
   metrics (weekly averages, chronotype, activity score). Raw samples are never shared.
   See [signals-v1.md](docs/features/signals-v1.md).

2. **Compatibility scoring**
   A matching engine compares aggregated health profiles and produces a 0–100 score with a
   domain breakdown (sleep, activity, lifestyle).
   See [matching-v1.md](docs/features/matching-v1.md).

3. **Anti-swipe-fatigue design**
   Users receive very few matches per day (high quality over high volume).
   Profiles that are a bad fit are silently excluded ("ghostED") by the algorithm.
   See [matching-v1.md](docs/features/matching-v1.md).

4. **Trust & Safety**
   Every user has a trust score that factors in liveness verification, profile completeness,
   and behavioral signals. Low-trust profiles are ranked down or gated.
   See [trust-v1.md](docs/features/trust-v1.md).

5. **Moments**
   Matched users are guided toward a real meetup via structured moment proposals (time, place,
   confirmation by both sides), tracked to measure real-world outcomes.
   See [moments-v1.md](docs/features/moments-v1.md).

6. **Circles and offline activation**
   Synca extends beyond private matching with circles and offline spark flows.
   See [circles-v1.md](docs/features/circles-v1.md) and [spark-v1.md](docs/features/spark-v1.md).

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
│   ├── features/
│   ├── product/
│   ├── api/
│   ├── architecture/
│   ├── tech/
│   ├── infra/
│   └── investor/
├── .github/
│   └── workflows/
│       ├── rails-ci.yml   ← CI (test + lint + security)
│       └── deploy.yml     ← CD (build + push + Kamal deploy)
├── .gitignore
└── README.md
```

Documentation entry points:

- Product vision: [docs/product/vision.md](docs/product/vision.md)
- Product roadmap: [docs/product/roadmap.md](docs/product/roadmap.md)
- API spec: [docs/api/openapi.yaml](docs/api/openapi.yaml)
- iOS architecture: [docs/architecture/ios-structure.md](docs/architecture/ios-structure.md)
- Android architecture: [docs/architecture/android-structure.md](docs/architecture/android-structure.md)
- Backend conventions: [docs/tech/backend.md](docs/tech/backend.md)

---

## iOS App Structure

```text
apps/ios/Synca/
├── Synca/
│   ├── Models/
│   ├── Services/
│   │   ├── HealthKit/
│   │   ├── API/
│   │   ├── Auth/
│   │   └── ActionCable/
│   ├── ViewModels/
│   ├── Views/
│   │   ├── Onboarding/
│   │   ├── Dashboard/
│   │   ├── Signals/
│   │   ├── Matching/
│   │   ├── Moments/
│   │   ├── Circles/
│   │   ├── Spark/
│   │   ├── Trust/
│   │   └── Auth/
│   ├── Resources/
│   └── SyncaApp.swift
├── Synca.xcodeproj/
└── SyncaTests/
```

Full reference: [docs/architecture/ios-structure.md](docs/architecture/ios-structure.md)

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
│       │   │   ├── moments/
│       │   │   ├── circles/
│       │   │   ├── spark/
│       │   │   ├── trust/
│       │   │   └── profile/
│       │   └── SyncaApp.kt
│       └── res/
└── build.gradle
```

Full reference: [docs/architecture/android-structure.md](docs/architecture/android-structure.md)

---

## Backend Structure

```text
backend/api/
├── app/
│   ├── controllers/api/v1/
│   ├── models/
│   ├── channels/
│   ├── jobs/
│   └── services/
├── bin/
│   └── dev-ngrok     ← one-command dev environment
├── config/
│   ├── deploy.yml    ← Kamal production config
│   ├── recurring.yml
│   └── environments/
│       └── development.rb
└── db/
    └── schema.rb
```

Backend README: [backend/api/README.md](backend/api/README.md)

---

## Main Models

### Shared Canonical Models

- `User`
- `Signal`
- `PreferenceProfile`
- `Match`
- `Moment`
- `Circle`
- `Spark`
- `Subscription`
- `Transaction`

### Notes on naming

- `Signal` is the canonical name; avoid legacy references such as `HealthSummary`.
- `Moment` is the canonical name; avoid legacy references such as `DateProposal`.
- Trust score is a product concept and ranking dimension, not a canonical standalone model name.

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

See [docs/features/matching-v1.md](docs/features/matching-v1.md).

---

## Trust & Safety

Every user has a trust score (0–100) computed from:

- **Identity:** phone/email verification, liveness check.
- **Profile:** completeness, photo quality.
- **Behavior:** no-show rate, reports received, consistency across signals.

Low-trust profiles are ranked down in matching or gated from features.

See [docs/features/trust-v1.md](docs/features/trust-v1.md).

---

## API Overview

Base path: `/api/v1`

| Method | Endpoint                  | Description                    |
|--------|---------------------------|--------------------------------|
| POST   | `/auth/register`          | Register a new user            |
| POST   | `/auth/login`             | Authenticate                   |
| GET    | `/users/me`               | Get current user profile       |
| GET/PUT| `/profile`                | Get / update profile           |
| POST   | `/signals`                | Upload aggregated signals      |
| GET/PUT| `/preferences`            | Get / update preferences       |
| GET    | `/matches`                | Get curated match list         |
| GET    | `/moments`                | List moments                   |
| POST   | `/moments`                | Create a moment                |
| POST   | `/moments/:id/accept`     | Accept a moment                |
| POST   | `/moments/:id/decline`    | Decline a moment               |
| GET    | `/circles`                | List circles                   |
| GET    | `/spark`                  | Get Spark session status       |
| POST   | `/trust/verify_phone`     | Start phone verification       |
| POST   | `/trust/verify_liveness`  | Submit liveness verification   |

Full spec: [docs/api/openapi.yaml](docs/api/openapi.yaml).

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
- For physical device testing, read `BASE_URL` from `.env.ngrok` (see [docs/infra/deployment.md](docs/infra/deployment.md)).

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

File: [.github/workflows/rails-ci.yml](.github/workflows/rails-ci.yml)

Four jobs run in parallel:

| Job | Tool | Check |
|-----|------|-------|
| `scan_ruby` | Brakeman | Rails security vulnerabilities |
| `gem_audit` | bundler-audit | CVE check on all gems |
| `lint` | RuboCop | Code style + autocorrect diff |
| `test` | Minitest + SimpleCov | Tests + coverage ≥ 90% |

### Continuous Deployment (after CI passes on `main`)

File: [.github/workflows/deploy.yml](.github/workflows/deploy.yml)

```text
CI passes → Build Docker image → Push ghcr.io → Kamal deploy → db:migrate
```

> CD is configured but requires a VPS to be provisioned.
> See [docs/infra/deployment.md](docs/infra/deployment.md) for the full setup guide.

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
feat/signals
feat/matching-engine
feat/trust-score
feat/android-health-connect
feat/moments
fix/auth-token-refresh
```

---

## Development Roadmap (summary)

Full roadmap: [docs/product/roadmap.md](docs/product/roadmap.md)

| Phase | Timeline   | Focus                                                |
|-------|------------|------------------------------------------------------|
| 0–1   | Month 0–1  | Foundation: monorepo, CI/CD, environments            |
| 1     | Month 1–3  | iOS MVP: auth, signals, profiles, matching v0        |
| 2     | Month 3–6  | Matching health-based v1, trust v0                   |
| 3     | Month 6–9  | Android app, payments, premium tier                  |
| 4     | Month 9–12 | Moments, trust & safety v1                           |
| 5     | Month 12–18| Matching v2 (data-driven), analytics                 |
| 6     | Month 18–24| Multi-city scaling, localisation (RU/EN/IT/TH/PT/ES) |

---

## Purpose of This Repository

This repository is the single source of truth for Synca: product vision, mobile development
(iOS + Android), Rails API backend, architecture decisions, and documentation.

It is designed to support an iterative workflow where product reasoning, code, and technical
documentation evolve together — kept simple, honest, and ready to ship.
