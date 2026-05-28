# Synca — iOS Technical Spec

**Version 1.0 — May 2026**

---

## Stack

| Layer | Technology |
|---|---|
| Language | Swift 5.10 |
| UI Framework | SwiftUI |
| Minimum target | iOS 17.0 |
| Health data | HealthKit (`HKHealthStore`) |
| Networking | `URLSession` + `async/await` |
| Real-time | URLSessionWebSocketTask (Action Cable protocol) |
| Location (Spark) | CoreLocation (`CLLocationManager`) |
| Bluetooth (Spark proximity) | CoreBluetooth |
| Local persistence | SwiftData (MVP) |
| Architecture | MVVM — `View` + `ViewModel` + `Service` |
| Auth | JWT stored in Keychain (`SecItemAdd`) |

---

## Key Conventions

- **SwiftUI only.** No UIKit unless a third-party SDK forces it (wrap in `UIViewRepresentable`).
- **`async/await` throughout.** No Combine, no callback pyramids.
- **No raw HealthKit samples leave the device.** Only aggregated metrics
  (computed by `HealthAggregatorService`) are sent to the API.
- **JWT in Keychain.** Never store tokens in `UserDefaults` or any plain-text storage.
- **Variable names must be descriptive.** Full domain names:
  `healthSummary`, `sparkSession`, `currentUser`, `compatibilityScore`.
  Never single-letter or abbreviated.

---

## HealthKit Integration

`HealthAggregatorService` requests read-only permissions for:

```swift
let readTypes: Set<HKObjectType> = [
    HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
    HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
    HKObjectType.quantityType(forIdentifier: .stepCount)!,
    HKObjectType.quantityType(forIdentifier: .restingHeartRate)!,
    HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
]
```

Aggregated metrics computed on-device and uploaded:

- `sleep_duration_avg` — 30-day rolling average of sleep hours
- `sleep_variability` — standard deviation of nightly sleep duration
- `chronotype` — derived from average bedtime/wake-time window
- `social_jetlag` — weekday vs weekend sleep timing delta
- `activity_minutes_avg` — weekly active minutes average
- `rest_hr_avg` — resting heart rate average
- `step_count_avg` — daily step count average
- `peak_activity_window` — time-of-day window with highest activity
- `routine_stability_index` — consistency of daily schedule (0.0–1.0)

All aggregation runs locally. The `HKSample` objects are **never serialized or sent** to the API.

---

## Spark Session Flow (iOS)

```
1. User opens "Start Spark" in the app
2. CoreBluetooth scans for nearby Synca peers
3. CoreLocation records coarse location (city-level hash sent to API)
4. POST /api/v1/spark_sessions → server creates pending SparkSession
5. Both users see a countdown timer (5 minutes)
6. Micro-test questions displayed (answers discarded after scoring)
7. POST /api/v1/spark_sessions/:id/complete
8. Server computes compatibility score, creates Match if score ≥ 50
9. App receives result via Action Cable (SyncRoomChannel)
10. Match result shown with plain-language explanation
```

---

## App Structure

```
Synca/
  App/
    SyncaApp.swift          -- @main entry point
    AppRouter.swift         -- NavigationStack routing
  Features/
    Auth/
      AuthViewModel.swift
      LoginView.swift
      RegisterView.swift
    Health/
      HealthAggregatorService.swift
      HealthPermissionView.swift
    Spark/
      SparkSessionViewModel.swift
      SparkSessionView.swift
      SparkProximityService.swift  -- CoreBluetooth scanning
    Matches/
      MatchListViewModel.swift
      MatchListView.swift
      MatchDetailView.swift
    SyncRoom/
      SyncRoomViewModel.swift
      SyncRoomView.swift
      SyncRoomMessageView.swift
    Profile/
      ProfileViewModel.swift
      ProfileView.swift
  Services/
    APIClient.swift           -- URLSession wrapper, JWT injection
    KeychainService.swift     -- JWT read/write
    WebSocketService.swift    -- Action Cable client
  Models/
    User.swift
    Profile.swift
    HealthSummary.swift
    SparkSession.swift
    Match.swift
    SyncRoom.swift
    SyncRoomMessage.swift
```

---

## Networking

`APIClient` is a singleton that:

- Reads the JWT from `KeychainService` and injects it as `Authorization: Bearer <token>`
  on every request.
- Uses `async/await` with `URLSession.data(for:)`.
- Decodes responses with `JSONDecoder` using `.convertFromSnakeCase` strategy.
- On 401, clears the Keychain token and posts a `NotificationCenter` event to
  redirect the user to the login screen.

---

## Action Cable (WebSocket)

`WebSocketService` implements the Action Cable handshake over `URLSessionWebSocketTask`:

```
1. Connect to wss://api.synca.app/cable?token=<jwt>
2. Send { command: "subscribe", identifier: { channel: "SyncRoomChannel", room_id: <id> } }
3. Receive messages, decode JSON, update ViewModel via @Published
4. Disconnect on app background / view dismiss
```

One connection per active Sync Room. Connections are closed when the view disappears.

---

## Privacy

- `NSHealthShareUsageDescription` — required in `Info.plist`. Explains aggregation only.
- `NSLocationWhenInUseUsageDescription` — for Spark proximity (city-level only).
- `NSBluetoothAlwaysUsageDescription` — for peer discovery during Spark session.
- Health data never appears in logs or crash reports. HealthKit samples are read,
  aggregated in memory, and released immediately.

---

## Testing

- Unit tests for all Services and ViewModels using `XCTest`.
- HealthKit is mocked via a `HealthStoreProtocol` protocol — never hit the real
  `HKHealthStore` in tests.
- Network calls are mocked via a `URLProtocol` subclass (`MockURLProtocol`).
- No UI tests for MVP — add `XCUITest` in Phase 2 for critical flows.
