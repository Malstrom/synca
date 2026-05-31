# Synca — iOS Technical Spec

**Version 1.1 — May 2026**

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
  (computed by `SignalAggregatorService`) are sent to the API.
- **JWT in Keychain.** Never store tokens in `UserDefaults` or any plain-text storage.
- **Variable names must be descriptive.** Full domain names:
  `signal`, `spark`, `currentUser`, `compatibilityScore`.
  Never single-letter or abbreviated.

---

## HealthKit Integration

`SignalAggregatorService` requests read-only permissions for:

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

Ref: `docs/architecture/ios-structure.md`

---

## Spark Session Flow (iOS)

```
1. User opens "Start Spark" in the app
2. CoreBluetooth scans for nearby Synca peers
3. CoreLocation records coarse location (city-level hash sent to API)
4. POST /api/v1/sparks → server creates pending Spark record
5. Both users see a countdown timer (5 minutes)
6. Compatibility computed from existing signals (no questionnaire during session)
7. POST /api/v1/sparks/:id/submit_answers (presence confirmation + declared preference refinement)
8. Server computes compatibility score via ScoringJob, creates Match if score ≥ 50
9. App receives result via Action Cable (CircleChannel)
10. Match result shown with plain-language explanation
```

Ref: `docs/features/spark-v1.md`

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
    Signals/
      SignalAggregatorService.swift
      SignalPermissionView.swift
    Spark/
      SparkViewModel.swift
      SparkView.swift
      SparkProximityService.swift  -- CoreBluetooth scanning
    Matches/
      MatchListViewModel.swift
      MatchListView.swift
      MatchDetailView.swift
    Circles/
      CircleViewModel.swift
      CircleView.swift
      CircleMessageView.swift
    Moments/
      MomentViewModel.swift
      MomentView.swift
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
    Signal.swift
    Spark.swift
    Match.swift
    Circle.swift
    CircleMessage.swift
    Moment.swift
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

`WebSocketService` implements the Action Cable handshake over `URLSessionWebSocketTask`.

Channels used:
- `CircleChannel` — real-time messages for Circles (replaces deprecated `SyncRoomChannel`)
- Spark scoring events are received via Action Cable on session completion

Ref: `docs/features/circles-v1.md`, `docs/features/spark-v1.md`
