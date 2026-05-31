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
| Backend conventions | [docs/tech/backend.md](docs/tech/backend.md) |
| Infrastructure & deploy | [docs/infra/deployment.md](docs/infra/deployment.md) |
| ADR / decisions | [docs/decisions.md](docs/decisions.md) |

---

## Repository Structure

```text
synca/
├── apps/
│   ├── ios/        → SwiftUI app
│   └── android/    → Kotlin + Jetpack Compose app
├── backend/        → Rails 8 API
└── docs/           → all product and technical documentation
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
