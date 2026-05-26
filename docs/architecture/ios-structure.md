# iOS App Structure

**Directory:** `apps/ios/Synca/`

## Folder Layout

```text
apps/ios/Synca/
├── Synca/
│   ├── Models/               # Plain Swift structs and enums (no UIKit, no business logic)
│   ├── Services/
│   │   ├── HealthKit/        # HealthKit authorization and aggregation
│   │   ├── Matching/         # Local compatibility helpers (thin, most logic is backend)
│   │   └── API/              # URLSession-based API client
│   ├── ViewModels/           # ObservableObject classes, one per screen
│   ├── Views/
│   │   ├── Onboarding/       # Registration, consent, health permission
│   │   ├── Dashboard/        # Home screen
│   │   ├── Health/           # Health profile and metrics display
│   │   ├── Matching/         # Match list and compatibility detail
│   │   ├── DateProposals/    # Proposal list, detail, accept/decline
│   │   └── Auth/             # Login, signup
│   ├── Resources/            # Assets, fonts, localisation files
│   └── SyncaApp.swift        # App entry point
├── Synca.xcodeproj/
└── SyncaTests/               # Unit tests (XCTest)
```

## Architecture

- **Pattern:** Lightweight MVVM.
- **State:** `@Observable` (iOS 17+) or `ObservableObject` where needed.
- **Navigation:** `NavigationStack` with programmatic routing.
- **Networking:** thin `APIClient` wrapping `URLSession` with async/await.
- **Health data:** never stored raw on device beyond the current session. Aggregated before sending to backend.

## Key Design Rules

- Views are dumb. No business logic in View files.
- ViewModels call Services; Services call the API or HealthKit.
- Models are plain structs, Codable where they cross the network boundary.
- Health data aggregation happens in `Services/HealthKit/` before anything else touches it.
- Never pass raw HealthKit samples to a ViewModel or View.

## Minimum Deployment Target

iOS 17+. This ensures access to modern SwiftUI APIs, `@Observable`, and the latest HealthKit APIs.

## Testing

Unit tests live in `SyncaTests/`. Focus on:

- `CompatibilityService` logic.
- `HealthAggregator` output for known inputs.
- `APIClient` response parsing.

UI tests are optional for MVP.
