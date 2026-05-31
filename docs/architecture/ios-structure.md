# iOS App Structure

**Directory:** `apps/ios/Synca/`

> This document is the single source of truth for the iOS folder layout and MVVM pattern.
> In case of conflict with any other doc, this file wins for structural decisions.
> For stack and coding conventions → See [docs/conventions/ios.md](../conventions/ios.md).
> For feature-level flows → See the relevant `docs/features/<feature>-v1.md`.

---

## Folder Layout

Organized **by feature**, not by type. Each feature folder owns its ViewModel and View.
Shared infrastructure (Services, Models) lives at the top level.

```text
apps/ios/Synca/
├── App/
│   ├── SyncaApp.swift          # @main entry point
│   └── AppRouter.swift         # NavigationStack programmatic routing
├── Features/
│   ├── Auth/
│   │   ├── AuthViewModel.swift
│   │   ├── LoginView.swift
│   │   └── RegisterView.swift
│   ├── Onboarding/
│   │   ├── OnboardingViewModel.swift
│   │   └── OnboardingView.swift
│   ├── Profile/
│   │   ├── ProfileViewModel.swift
│   │   └── ProfileView.swift
│   ├── Signals/
│   │   ├── SignalAggregatorService.swift  # HealthKit — lives here, not in Services/
│   │   ├── SignalsViewModel.swift
│   │   └── SignalsView.swift
│   ├── Spark/
│   │   ├── SparkProximityService.swift    # CoreBluetooth scanning
│   │   ├── SparkViewModel.swift
│   │   └── SparkView.swift
│   ├── Matching/
│   │   ├── MatchListViewModel.swift
│   │   ├── MatchListView.swift
│   │   └── MatchDetailView.swift
│   ├── Circles/
│   │   ├── CircleViewModel.swift
│   │   ├── CircleView.swift
│   │   └── CircleMessageView.swift
│   ├── Moments/
│   │   ├── MomentViewModel.swift
│   │   └── MomentView.swift
│   ├── Trust/
│   │   ├── TrustViewModel.swift
│   │   └── TrustView.swift
│   └── Dashboard/
│       ├── DashboardViewModel.swift
│       └── DashboardView.swift
├── Services/
│   ├── APIClient.swift           # URLSession wrapper, JWT injection
│   ├── KeychainService.swift     # JWT read/write
│   └── WebSocketService.swift    # Action Cable client
├── Models/
│   ├── User.swift
│   ├── Signal.swift
│   ├── Spark.swift
│   ├── Match.swift
│   ├── Circle.swift
│   ├── CircleMessage.swift
│   ├── Moment.swift
│   └── PreferenceProfile.swift
├── Resources/
│   ├── Assets.xcassets
│   ├── Fonts/
│   └── Localizable.strings
└── SyncaTests/                   # Unit tests (XCTest)
```

### Why by-feature?

- A feature's ViewModel and View are always co-located — easy to find, easy to delete.
- `Services/` and `Models/` are shared cross-feature infrastructure.
- Feature-specific services (HealthKit, CoreBluetooth) live inside their feature folder,
  not in the global `Services/` directory.

---

## Architecture Pattern: MVVM

```
View  ──calls──▶  ViewModel  ──calls──▶  Service / APIClient
  ▲                   │
  └─── re-renders ────┘  (via @Observable state)
```

| Layer | Responsibility | Rule |
|---|---|---|
| **View** | Render state, capture user input | No business logic, no Service calls |
| **ViewModel** | Transform data for the View, call Services | No direct HealthKit or URLSession access |
| **Service** | Business logic, external SDKs, API calls | No SwiftUI imports |
| **Model** | Plain data structs | Codable, no logic, no SwiftUI |

---

## AppRouter

`AppRouter` is an `@Observable` class injected as an environment object at the root.
It holds the navigation path for `NavigationStack` and exposes typed navigation methods.

```swift
// App/AppRouter.swift
@Observable
final class AppRouter {
    var path = NavigationPath()

    func navigate(to destination: AppDestination) {
        path.append(destination)
    }

    func popToRoot() {
        path.removeLast(path.count)
    }
}

enum AppDestination: Hashable {
    case matchDetail(matchId: Int)
    case circleThread(circleId: Int)
    case momentProposal(matchId: Int)
    case sparkResult(sparkId: Int)
    case profile
    case signals
    case trust
}
```

Views never push routes directly — they call `router.navigate(to:)`.
This is the iOS equivalent of `redirect_to` in a Rails controller.

---

## Services Map

| Service | Location | Responsibility | Feature doc |
|---|---|---|---|
| `APIClient` | `Services/` | URLSession wrapper, JWT injection, error decoding | → See [conventions/ios.md § Networking](../conventions/ios.md) |
| `KeychainService` | `Services/` | JWT read/write via Keychain | → See [conventions/ios.md § Auth](../conventions/ios.md) |
| `WebSocketService` | `Services/` | Action Cable WebSocket client | → See [features/circles-v1.md](../features/circles-v1.md) |
| `SignalAggregatorService` | `Features/Signals/` | HealthKit aggregation, sends metrics to API | → See [features/signals-v1.md](../features/signals-v1.md) |
| `SparkProximityService` | `Features/Spark/` | CoreBluetooth BLE scan, QR session management | → See [features/spark-v1.md](../features/spark-v1.md) |

---

## Screen → Feature Doc Map

| Feature folder | Screens | Feature doc |
|---|---|---|
| `Auth/` | Login, Register | → See [features/profile-v1.md](../features/profile-v1.md) |
| `Onboarding/` | 4-step wizard, health permission | → See [features/profile-v1.md](../features/profile-v1.md) |
| `Profile/` | Own profile edit, preferences, trust score | → See [features/profile-v1.md](../features/profile-v1.md) · [features/trust-v1.md](../features/trust-v1.md) |
| `Signals/` | Apple Health connection, metrics summary | → See [features/signals-v1.md](../features/signals-v1.md) |
| `Spark/` | Start Spark (BLE/QR), join Spark, result | → See [features/spark-v1.md](../features/spark-v1.md) |
| `Matching/` | Match list, compatibility detail | → See [features/matching-v1.md](../features/matching-v1.md) |
| `Circles/` | Circle list, message thread | → See [features/circles-v1.md](../features/circles-v1.md) |
| `Moments/` | Propose, counter-propose, confirm, complete | → See [features/moments-v1.md](../features/moments-v1.md) |
| `Trust/` | Phone OTP, liveness check | → See [features/trust-v1.md](../features/trust-v1.md) |
| `Dashboard/` | Home hub: matches, moments, circles | → See all feature docs |

---

## Model Naming — Canonical Map

| iOS Model | Canonical | Deprecated | Feature doc |
|---|---|---|---|
| `Signal` | `Signal` | `HealthSummary` | → See [signals-v1.md](../features/signals-v1.md) |
| `Moment` | `Moment` | `DateProposal` | → See [moments-v1.md](../features/moments-v1.md) |
| `Circle` | `Circle` | `SyncRoom` | → See [circles-v1.md](../features/circles-v1.md) |
| `CircleMembership` | `CircleMembership` | — | → See [circles-v1.md](../features/circles-v1.md) |
| `CircleMessage` | `CircleMessage` | — | → See [circles-v1.md](../features/circles-v1.md) |
| `Spark` | `Spark` | — | → See [spark-v1.md](../features/spark-v1.md) |
| `Match` | `Match` | — | → See [matching-v1.md](../features/matching-v1.md) |
| `PreferenceProfile` | `PreferenceProfile` | — | → See [profile-v1.md](../features/profile-v1.md) |

---

## Minimum Deployment Target

iOS 17+. Required for `@Observable`, `NavigationStack`, and the latest HealthKit APIs.

---

## Testing

→ See [docs/conventions/ios.md § TDD](../conventions/ios.md) for rules and priority targets.

Unit tests live in `SyncaTests/`. TDD order: test first, implementation second.
UI tests are optional for MVP.

---

## Open Questions

See [docs/product/decisions.md](../product/decisions.md) — filter by `source: docs/architecture/ios-structure.md`.
