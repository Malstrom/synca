# Synca — Documentation Index

This file is the single entry point for all Synca documentation.
When in doubt about where to look, start here.

---

## Features

Each file covers one feature: DB schema, API endpoints, premium gating, and open questions.
User flows for each feature are documented in `docs/product/phases/`.

| File | Description | Phase |
|---|---|---|
| [profile-v1.md](features/profile-v1.md) | User profile, onboarding, identity providers, auth (guest tokens, JWT) | 0–2 |
| [signals-v1.md](features/signals-v1.md) | Health, music, travel, cycle signals | 0–3 |
| [spark-v1.md](features/spark-v1.md) | In-person Spark sessions and QR matching | 0–1 |
| [matching-v1.md](features/matching-v1.md) | Algorithm-origin matching and compatibility score | 1 |
| [trust-v1.md](features/trust-v1.md) | Trust score, anti-fake, verification | 1 |
| [circles-v1.md](features/circles-v1.md) | Community circles and offline events | 2 |
| [moments-v1.md](features/moments-v1.md) | Ephemeral moments and social proof | 2 |
| [notifications-v1.md](features/notifications-v1.md) | Push and in-app notifications | 1 |

---

## User Flows

User flows are documented per phase, not per feature.
Each phase file contains all user stories (US), flows (UF), and use cases (UC) for that phase.

| File | Description |
|---|---|
| [product/phases/phase-0.md](product/phases/phase-0.md) | Validation MVP — Spark, declared preferences, health self-summary, guest activation |

When a feature doc references a user flow, it links directly to the relevant section
in the phase file (e.g. `docs/product/phases/phase-0.md § UF-03`).

---

## Product

| File | Description |
|---|---|
| [product/phases/phase-0.md](product/phases/phase-0.md) | Phase 0 user stories and flows |

---

## API

| File | Description |
|---|---|
| [api/openapi.yaml](api/openapi.yaml) | Full OpenAPI spec — canonical reference for all endpoints |

---

## Architecture

| File | Description |
|---|---|
| [architecture/](architecture/) | API flow, iOS structure, Android structure |

---

## Conventions

| File | Description |
|---|---|
| [conventions/backend.md](conventions/backend.md) | Rails coding and testing conventions |
| [conventions/ios.md](conventions/ios.md) | SwiftUI/iOS conventions |
| [conventions/testing.md](conventions/testing.md) | TDD rules and coverage requirements |
| [conventions/workflow.md](conventions/workflow.md) | Git, branches, PR rules |

---

## Infrastructure

| File | Description |
|---|---|
| [infra/](infra/) | Deployment, CI/CD, environment configuration |

---

## Investor

| File | Description |
|---|---|
| [investor/](investor/) | Financial model, market analysis, litepaper, whitepaper |
