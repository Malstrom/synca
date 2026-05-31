# iOS Setup & Development Guide

> Step-by-step guide to set up the iOS project and develop feature by feature,
> ordered by product phase.
> For folder layout and MVVM pattern → See [docs/architecture/ios-structure.md](../architecture/ios-structure.md).
> For coding conventions and rules → See [docs/conventions/ios.md](../conventions/ios.md).
> For UI components and design tokens → See [docs/design/ui-system.md](../design/ui-system.md).

---

## 1. Environment Setup

### Requirements

- **Xcode 16+** (download from Mac App Store or [developer.apple.com](https://developer.apple.com/xcode/))
- **iOS 17+ simulator** (included with Xcode)
- **Apple Developer account** (free tier is enough for simulator; paid required for real device)
- **Ruby + Rails API** running locally on `http://localhost:3000`
  → See [docs/infra/](../infra/) for backend setup.

### First run

```bash
# Clone the repo
git clone https://github.com/Malstrom/synca.git
cd synca/apps/ios

# Open in Xcode
open Synca.xcodeproj
```

Select a simulator (iPhone 16, iOS 17+), press **⌘R** to build and run.

---

## 2. Swift Package Manager (= Bundler for iOS)

Dependencies are declared in `Synca.xcodeproj` under *Package Dependencies*.
No `Podfile`, no `Cartfile`. SPM is the only dependency manager used.

To add a package: Xcode → File → Add Package Dependencies → paste the GitHub URL.

---

## 3. Capabilities & Entitlements

Some iOS features require explicit permissions in Xcode and in `Info.plist`.

| Capability | Where to enable | Info.plist key |
|---|---|---|
| HealthKit | Xcode → Target → Signing & Capabilities → + HealthKit | `NSHealthShareUsageDescription` |
| Bluetooth | Automatic (CoreBluetooth framework) | `NSBluetoothAlwaysUsageDescription` |
| Location (Spark) | Xcode → + Location | `NSLocationWhenInUseUsageDescription` |
| Push Notifications | Xcode → + Push Notifications | — (handled by APNs) |
| Associated Domains | Xcode → + Associated Domains | `applinks:synca.app` (deep links) |

All permission strings must be human-readable and honest about why the data is used.
Example: *“Synca reads your sleep and activity data on-device to estimate lifestyle compatibility.
Nothing leaves your phone without your consent.”*

---

## 4. API Base URL

In development, point `APIClient` to your local Rails server:

```swift
// Services/APIClient.swift
#if DEBUG
let baseURL = "http://localhost:3000"
#else
let baseURL = "https://api.synca.app"
#endif
```

On simulator, `localhost` resolves correctly. On a real device, use your Mac's local IP.

---

## 5. Development Order

Always build **foundation first**, then features in phase order.
For each feature: write the test first (TDD), then the implementation.
→ TDD rules → See [docs/conventions/ios.md § TDD](../conventions/ios.md).

### Foundation (before any feature)

Build these once — every feature depends on them.

| Step | File(s) | What it does |
|---|---|---|
| 1 | `Models/*.swift` | Plain Codable structs for all domain objects |
| 2 | `Services/KeychainService.swift` | JWT read/write |
| 3 | `Services/APIClient.swift` | URLSession wrapper, JWT injection, error decoding |
| 4 | `App/AppRouter.swift` | NavigationStack routing → See [architecture/ios-structure.md § AppRouter](../architecture/ios-structure.md) |
| 5 | `App/SyncaApp.swift` | Root view, inject AppRouter as environment object |

---

### Phase 0 — Validation MVP (iOS only)

→ Full user stories and UX flows: See [docs/product/phases/phase-0.md](../product/phases/phase-0.md).

#### Step 1 — Guest onboarding + QR Spark (US-01, UF-01)

Files to create:
```
Features/Auth/AuthViewModel.swift
Features/Auth/LoginView.swift
Features/Auth/RegisterView.swift
Features/Spark/SparkProximityService.swift
Features/Spark/SparkViewModel.swift
Features/Spark/SparkView.swift
```

Key behaviours:
- Display QR code for User A (initiator).
- Handle universal link / deferred deep link restoring `qr_token` for User B.
- Guest onboarding: email only, no password required at this stage.
- Poll or receive via Action Cable the `spark:scored` event.
- Show result with plain-language explanation (never raw score).

→ API endpoints: See [docs/features/spark-v1.md](../features/spark-v1.md).

#### Step 2 — Declared preferences questionnaire (US-02, UF-02)

Files to create:
```
Features/Onboarding/OnboardingViewModel.swift
Features/Onboarding/OnboardingView.swift
```

Key behaviours:
- 5-question questionnaire shown on first launch and to guest users joining via QR.
- Answers submitted to `POST /api/v1/signals/preferences`.
- If user already has preferences, answers upsert the existing record.

→ API endpoints: See [docs/features/signals-v1.md](../features/signals-v1.md).

#### Step 3 — HealthKit self-discovery (US-03, UF-03)

Files to create:
```
Features/Signals/SignalAggregatorService.swift
Features/Signals/SignalsViewModel.swift
Features/Signals/SignalsView.swift
```

Key behaviours:
- Request HealthKit read-only permissions.
- Aggregate last 30 days of data on-device.
- Send derived metrics to `POST /api/v1/signals`.
- Display human-readable health profile (chronotype, peak energy, routine stability).

→ HealthKit permissions and aggregated metrics: See [docs/conventions/ios.md § HealthKit](../conventions/ios.md).

#### Step 4 — Guest account activation (US-04, UF-04)

Files to create/update:
```
Features/Auth/ActivationView.swift   # handles magic link deep link
Features/Auth/AuthViewModel.swift    # add activation flow
```

Key behaviours:
- Universal link opens `ActivationView` with token from magic link.
- User sets display name — only required field.
- On success: permanent JWT issued, account upgraded to `:active`.
- Handle expired token (72h) with resend option.

→ Full flow: See [docs/features/profile-v1.md § Step 0](../features/profile-v1.md).

---

### Phase 1

→ See [docs/product/phases/phase-1.md](../product/phases/phase-1.md) for user stories.

Features to build (in order):
1. Full registration + photo upload (`Features/Profile/`)
2. Dashboard hub (`Features/Dashboard/`)
3. Match list + compatibility detail (`Features/Matching/`)
4. Circles + messaging (`Features/Circles/` + `Services/WebSocketService.swift`)
5. Moments — propose/counter-propose date (`Features/Moments/`)
6. Trust — phone OTP + liveness (`Features/Trust/`)
7. Push notifications (`Features/Notifications/`)

---

### Phase 2

→ See [docs/product/phases/phase-2.md](../product/phases/phase-2.md) for user stories.

Android development starts here. iOS work in Phase 2 focuses on premium features.

---

## 6. Running Tests

```bash
# In Xcode
⌘U  # run all tests
⌘⇧U  # run tests without building
```

Or from terminal:
```bash
xcodebuild test -scheme Synca -destination 'platform=iOS Simulator,name=iPhone 16'
```

→ Priority test targets and TDD rules: See [docs/conventions/ios.md § TDD](../conventions/ios.md).

---

## Open Questions

See [docs/product/decisions.md](../product/decisions.md) — filter by `source: docs/guides/ios-setup.md`.
