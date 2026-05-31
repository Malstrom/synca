# Synca — iOS Conventions

**Version 2.0 — June 2026**

> Single reference for iOS coding conventions, stack, and rules.
> For folder layout and MVVM pattern → See [docs/architecture/ios-structure.md](../architecture/ios-structure.md).
> For setup and development order → See [docs/guides/ios-setup.md](../guides/ios-setup.md).
> For UI design system and components → See [docs/design/ui-system.md](../design/ui-system.md).

---

## Stack

| Layer | Technology |
|---|---|
| Language | Swift 5.10 |
| UI Framework | SwiftUI (iOS 17+) |
| Minimum target | iOS 17.0 |
| Health data | HealthKit (`HKHealthStore`) |
| Networking | `URLSession` + `async/await` |
| Real-time | `URLSessionWebSocketTask` (Action Cable protocol) |
| Location (Spark) | CoreLocation (`CLLocationManager`) |
| Bluetooth (Spark) | CoreBluetooth |
| Local persistence | SwiftData (MVP) |
| Architecture | MVVM — by-feature layout |
| Auth | JWT stored in Keychain (`SecItemAdd`) |

---

## Key Conventions

- **SwiftUI only.** No UIKit unless a third-party SDK forces it (wrap in `UIViewRepresentable`).
- **`async/await` throughout.** No Combine, no callback pyramids.
- **Views are dumb.** No business logic, no Service calls, no API calls in View files.
- **One ViewModel per screen.** Never share a ViewModel between two Views.
- **Variable names must be descriptive.** Full domain names: `signal`, `spark`,
  `currentUser`, `compatibilityScore`. Never single-letter or abbreviated (`p`, `u`, `s`).
- **JWT in Keychain only.** Never store tokens in `UserDefaults` or any plain-text storage.
- **No raw HealthKit samples leave the device.** Only aggregated metrics from
  `SignalAggregatorService` are sent to the API.
- **Raw compatibility score (0–100) is never shown in the UI.** Display only the
  plain-language explanation returned by the backend.
  → See [features/matching-v1.md](../features/matching-v1.md).

---

## Networking

`APIClient` is a singleton (`Services/APIClient.swift`) that:

- Injects `Authorization: Bearer <token>` on every request (token read from `KeychainService`).
- Uses `async/await` with `URLSession.data(for:)`.
- Decodes responses with `JSONDecoder` using `.convertFromSnakeCase` — no manual key mapping.
- On 401: clears Keychain token, posts `NotificationCenter` event to redirect to login.

### Error handling

All errors surface to the user through the ViewModel. Conventions:

- Transient errors (network, timeout) → inline message in the View (`errorMessage: String?` on ViewModel).
- Auth errors (401) → automatic redirect to login via `AppRouter`.
- Validation errors (422) → field-level messages decoded from API response body.
- Never use `fatalError` or `try!` in production code.

### Loading states

Every ViewModel that performs async work exposes:

```swift
var isLoading: Bool = false
var errorMessage: String? = nil
```

Views bind to these properties to show spinners and error states.
→ See [docs/design/ui-system.md](../design/ui-system.md) for the LoadingView and ErrorView components.

---

## Auth

→ See [docs/features/profile-v1.md](../features/profile-v1.md) for the full auth flow.

- JWT access token + refresh token, both stored in Keychain.
- `TokenRefreshService` handles silent renewal before every request when near expiry.
- On app launch: check Keychain for valid token → route to Dashboard or Login.

---

## HealthKit Integration

`SignalAggregatorService` (in `Features/Signals/`) requests read-only permissions for:

```swift
let readTypes: Set<HKObjectType> = [
    HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
    HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
    HKObjectType.quantityType(forIdentifier: .stepCount)!,
    HKObjectType.quantityType(forIdentifier: .restingHeartRate)!,
    HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
]
```

All aggregation runs locally. `HKSample` objects are **never serialized or sent** to the API.
→ See [docs/features/signals-v1.md](../features/signals-v1.md) for the full list of aggregated metrics.

---

## Action Cable (WebSocket)

`WebSocketService` (`Services/WebSocketService.swift`) implements the Action Cable handshake
over `URLSessionWebSocketTask`.

Channels:
- `CircleChannel` — real-time Circle messages.
- Spark scoring events received on session completion.

→ See [docs/features/circles-v1.md](../features/circles-v1.md) and [docs/features/spark-v1.md](../features/spark-v1.md).

---

## TDD

TDD order (same as Rails):
1. Write failing test in `SyncaTests/` — red.
2. Write minimal code to pass — green.
3. Refactor.

`XCTestCase` = `ActiveSupport::TestCase`. `XCTAssertEqual` = `assert_equal`.
`async throws` tests work natively in XCTest from iOS 15+, no extra setup needed.

Priority test targets:
- `SignalAggregatorService` — HealthKit inputs → expected metric outputs.
- `APIClient` — response decoding for every model, error handling.
- `TokenRefreshService` — silent renewal, expired token flow.
- `SparkProximityService` — session state machine (pending → joined → scored).
- `MomentViewModel` — counter-proposal chain, 5-round cap.
- `WebSocketService` — connect/disconnect, message delivery.

UI tests are optional for MVP.

---

## Rails → iOS Mental Model

| Rails | iOS (Synca) | Notes |
|---|---|---|
| `ActiveRecord` model | `Models/` struct Codable | Pure data, no logic |
| Controller | `ViewModel` (@Observable) | Coordinates data and UI |
| View (ERB) | `View` (SwiftUI) | Dumb, only rendering |
| Service Object | `Services/` or feature service | Isolated business logic |
| `config/routes.rb` | `AppRouter.swift` | Programmatic navigation |
| `application.rb` | `SyncaApp.swift` | App entry point |
| Gemfile / Bundler | Swift Package Manager | Dependency management |
| `as_json` / `from_json` | `Codable` + `JSONDecoder` | JSON serialization |
| `has_secure_password` | `KeychainService` | Secure credential storage |
| Minitest | XCTest | Unit testing framework |
| `before_action` | `.task { }` in SwiftUI | Runs on View appear |
| `rescue` | `do / try / catch` | Error handling |
| `let` (mutable) | `var` | Mutable variable |
| `freeze` | `let` | Immutable constant |

### Common pitfalls (coming from Ruby)

| Ruby/Rails habit | iOS reality | Fix |
|---|---|---|
| Everything is nil-safe | Swift has strict optionals (`String?` vs `String`) | Unwrap safely with `if let` or `guard let` |
| Dynamic typing | Swift is statically typed | Compiler catches type errors at build time |
| Mutable by default | `let` = immutable, `var` = mutable | Prefer `let`, use `var` only when needed |
| `rescue` catches anything | `do/try/catch` is typed | Define specific error enums |
| `puts` for debugging | `print()` or LLDB `po` | Use breakpoints |

---

## Open Questions

See [docs/product/decisions.md](../product/decisions.md) — filter by `source: docs/conventions/ios.md`.
