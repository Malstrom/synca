# iOS App Structure

**Directory:** `apps/ios/Synca/`

> This document derives entirely from the feature docs in `docs/features/`.
> In case of conflict, the feature doc is always the source of truth.

---

## Folder Layout

```text
apps/ios/Synca/
├── Synca/
│   ├── Models/                   # Plain Swift structs and enums — Codable, no business logic
│   ├── Services/
│   │   ├── HealthKit/             # HealthKit authorization and signal aggregation
│   │   ├── API/                   # URLSession-based API client (async/await)
│   │   ├── Auth/                  # JWT storage (Keychain), token refresh
│   │   │── ActionCable/           # Action Cable WebSocket client (CircleChannel)
│   ├── ViewModels/               # @Observable classes, one per screen
│   ├── Views/
│   │   ├── Auth/                  # Login, signup, token refresh
│   │   ├── Onboarding/            # Registration wizard (4 steps), health permission
│   │   ├── Profile/               # Own profile, photo management, preferences
│   │   ├── Signals/               # Signal connection (Apple Health), metrics display
│   │   ├── Spark/                 # Spark initiation (BLE / QR), scoring result
│   │   ├── Matching/              # Match list, compatibility detail
│   │   ├── Circles/               # Circle list, messaging (duo / small_group / event)
│   │   ├── Moments/               # Moment proposal, counter-proposal, complete / no-show
│   │   ├── Trust/                 # Phone verification, liveness check
│   │   └── Dashboard/             # Home screen hub
│   ├── Resources/                # Assets, fonts, localisation files
│   └── SyncaApp.swift            # App entry point
├── Synca.xcodeproj/
└── SyncaTests/                   # Unit tests (XCTest)
```

---

## Architecture

- **Pattern:** Lightweight MVVM.
- **State:** `@Observable` (iOS 17+) or `ObservableObject` where needed.
- **Navigation:** `NavigationStack` with programmatic routing via a `AppRouter` observable.
- **Networking:** thin `APIClient` wrapping `URLSession` with `async/await`. All responses
  are decoded into `Codable` model structs.
- **Auth:** JWT access token + refresh token. Access token stored in Keychain.
  Refresh token stored in Keychain. `Auth/TokenRefreshService` handles silent renewal
  before every request when the access token is near expiry.
  Ref: `docs/features/profile-v1.md`.
- **Health data:** raw HealthKit samples are aggregated entirely in
  `Services/HealthKit/SignalAggregatorService` before being sent to the backend.
  Raw samples never leave this service. The backend receives only derived metrics.
  Ref: `docs/features/signals-v1.md`.
- **Real-time:** `Services/ActionCable/CircleChannel` maintains the WebSocket
  connection for Circle messaging. Ref: `docs/features/circles-v1.md`.

---

## Key Design Rules

- Views are dumb. No business logic in View files.
- ViewModels call Services; Services call the API or HealthKit.
- Models are plain `struct`s, `Codable` where they cross the network boundary.
- Raw HealthKit samples must never be passed to a ViewModel or View.
  Aggregate in `SignalAggregatorService`, then send to backend.
- JWT tokens are stored exclusively in Keychain. Never in `UserDefaults` or
  any unencrypted storage.
- The raw compatibility score (0–100) is **never rendered** in the UI.
  Display only the plain-language explanation returned by the backend.
  Ref: `docs/features/matching-v1.md`.
- Variable names must be descriptive. Never use single-letter or abbreviated names
  (`p`, `u`, `r`). Use full domain names (`profile`, `signal`, `match`, `moment`).

---

## Model Naming — Canonical Map

Always use the canonical names from the feature docs. Old names are deprecated.

| iOS Model | Canonical | Deprecated | Feature doc |
|---|---|---|---|
| `Signal` | `Signal` | `HealthSummary` | signals-v1.md |
| `Moment` | `Moment` | `DateProposal` | moments-v1.md |
| `Circle` | `Circle` | `SyncRoom` | circles-v1.md |
| `CircleMembership` | `CircleMembership` | — | circles-v1.md |
| `CircleMessage` | `CircleMessage` | — | circles-v1.md |
| `Spark` | `Spark` | — | spark-v1.md |
| `Match` | `Match` | — | matching-v1.md |
| `PreferenceProfile` | `PreferenceProfile` | — | profile-v1.md |

---

## Services

| Service | Responsibility | Ref |
|---|---|---|
| `SignalAggregatorService` | Reads HealthKit samples, computes aggregated metrics, sends `POST /api/v1/signals` | signals-v1.md |
| `APIClient` | Base URLSession wrapper: auth headers, token refresh, error decoding | profile-v1.md |
| `TokenRefreshService` | Silent JWT renewal using the refresh token from Keychain | profile-v1.md |
| `SparkSessionService` | Manages BLE broadcast / QR display, session code validation, polling `spark:scored` | spark-v1.md |
| `CircleChannelService` | Action Cable WebSocket connection for real-time Circle messaging | circles-v1.md |

---

## Screen → Feature Doc Map

| View folder | Feature | Doc |
|---|---|---|
| `Auth/` | Registration, login, token refresh | profile-v1.md |
| `Onboarding/` | 4-step wizard, photo upload, preferences | profile-v1.md |
| `Profile/` | Own profile edit, `preference_profile`, `trust_score` display | profile-v1.md, trust-v1.md |
| `Signals/` | Apple Health connection, signal metrics summary | signals-v1.md |
| `Spark/` | Start Spark (BLE/QR), join Spark, scoring result screen | spark-v1.md |
| `Matching/` | Match list, compatibility explanation, match status | matching-v1.md |
| `Circles/` | Circle list, message thread (duo / small_group / event) | circles-v1.md |
| `Moments/` | Propose date, counter-propose, confirm, complete, no-show | moments-v1.md |
| `Trust/` | Phone OTP verification, liveness check | trust-v1.md |
| `Dashboard/` | Home hub: active matches, pending moments, unread circles | all |

---

## Minimum Deployment Target

iOS 17+. Required for `@Observable`, `NavigationStack`, and the latest HealthKit APIs.

---

## Testing

Unit tests live in `SyncaTests/`. TDD order: test first, implementation second.

Priority test targets:

- `SignalAggregatorService` — known HealthKit inputs → expected metric outputs.
- `APIClient` — response decoding for every model, error handling.
- `TokenRefreshService` — silent renewal flow, expired token handling.
- `SparkSessionService` — session state machine (pending → joined → scored).
- `MomentViewModel` — counter-proposal chain, 5-round cap enforcement.
- `CircleChannelService` — WebSocket connect/disconnect, message delivery.

UI tests are optional for MVP.
