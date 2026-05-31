# Synca

Synca is a health-based dating app (iOS + Android + Rails API) that uses
Apple Health and Health Connect data to generate few, high-quality matches
based on real lifestyle compatibility: sleep, activity, music, and travel.

Instead of endless swiping, Synca shows fewer people — but the right ones.

---

## Documentation

| What | Where |
|---|---|
| Product vision | [docs/product/vision.md](docs/product/vision.md) |
| Roadmap | [docs/product/roadmap.md](docs/product/roadmap.md) |
| Phase specs (US · UF · UC) | [docs/product/phases/](docs/product/phases/) |
| Feature specs | [docs/features/](docs/features/) |
| API spec (OpenAPI) | [docs/api/openapi.yaml](docs/api/openapi.yaml) |
| iOS architecture | [docs/architecture/ios-structure.md](docs/architecture/ios-structure.md) |
| Android architecture | [docs/architecture/android-structure.md](docs/architecture/android-structure.md) |
| ML architecture | [docs/architecture/ml-architecture-v1.md](docs/architecture/ml-architecture-v1.md) |
| Backend conventions | [docs/conventions/backend.md](docs/conventions/backend.md) |
| iOS conventions | [docs/conventions/ios.md](docs/conventions/ios.md) |
| Testing strategy | [docs/conventions/testing.md](docs/conventions/testing.md) |
| Development workflow (Git · PR · TDD · CI) | [docs/conventions/workflow.md](docs/conventions/workflow.md) |
| Gems reference (per-phase) | [docs/conventions/gems.md](docs/conventions/gems.md) |
| Infrastructure & deploy | [docs/infra/deployment.md](docs/infra/deployment.md) |
| Open decisions log | [docs/product/decisions.md](docs/product/decisions.md) |
| Investor materials | [docs/investor/](docs/investor/) |

---

## Repository Structure

```text
synca/
├── apps/
│   ├── ios/          → SwiftUI app
│   └── android/      → Kotlin + Jetpack Compose app
├── backend/          → Rails 8 API
└── docs/
    ├── architecture/  → how the system is structured
    ├── conventions/   → how to write code in this system
    ├── features/      → per-feature specs (canonical source of truth)
    └── ...            → product, api, infra, investor
```

---

## Quick Start

```bash
cd backend/api
bundle install
bin/rails db:create db:migrate db:seed
bin/dev-ngrok   # Rails + Caddy + ngrok in one command
```

Full setup: [docs/infra/deployment.md](docs/infra/deployment.md)

---

## Stack

- **iOS:** SwiftUI · HealthKit · MVVM
- **Android:** Kotlin · Jetpack Compose · Health Connect
- **Backend:** Rails 8 API · PostgreSQL 16 · Solid Queue
- **Auth:** JWT (access + refresh tokens) — no Devise
- **Infra:** Docker · Kamal · GitHub Container Registry
