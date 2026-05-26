# Synca MVP — iOS App (SwiftUI)

**Version 0.4 — May 2026**  
Target: implementable MVP in 4–6 weeks by 1 iOS dev + part-time CTO.

---

## 1. Goals & Scope

MVP goals for the iOS app:

- Basic onboarding (login, privacy consent, HealthKit permissions).
- Collection and upload of an **aggregated health summary**.
- Simple visual preference game.
- Dashboard showing lifestyle profile (chronotype, energy windows, activity).
- Basic **Synca Spark** flow (create/join session, micro-test, show result).

Out of scope for the iOS MVP:

- Chat/messaging.
- Full in-app payments/subscriptions (only placeholder UI).
- Complex match feed.

---

## 2. iOS Architecture

- **SwiftUI** + simple **MVVM**.
- Networking via `URLSession` (no heavy dependencies at start).
- Health via **HealthKit** in a dedicated `HealthService`.

High-level structure:

```text
SyncaApp
 ├─ AppState (ObservableObject)
 ├─ AuthFlow
 │   ├─ LoginView
 │   ├─ RegisterView (optional)
 │   └─ ConsentView (privacy + HealthKit)
 ├─ OnboardingFlow
 │   ├─ PreferenceGameView
 │   └─ InitialProfileView (name, photo, city)
 ├─ MainTab
 │   ├─ DashboardView (lifestyle profile)
 │   ├─ SparkView (create/join session)
 │   └─ SettingsView
 └─ Services
     ├─ ApiClient
     ├─ HealthService
     └─ SparkService
```

---

## 3. MVP Screens

### 3.1 Auth & Consents

**LoginView**

- Actions:
  - "Continue with Apple" (preferred UX, less password handling).
  - Optionally: email + password.

**ConsentView**

- Explains clearly:
  - which health data is read,
  - that aggregation happens on-device,
  - that health data is never shared with other users.
- CTA: "Grant Health Access" → opens HealthKit authorization.

### 3.2 Preference Game

**PreferenceGameView**

- Minimal UI: 2–3 archetype images per round.
- User taps the one they prefer.
- 10–15 rounds.
- On completion, calls `ApiClient.updatePreferences()` with a simple payload (e.g., counters per archetype type; true embeddings can come later).

### 3.3 Lifestyle Dashboard

**DashboardView**

- Shows:
  - Chronotype (e.g., "You are a night owl").
  - Average sleep/wake times.
  - Peak energy window.
  - Activity level.
- All data comes from backend `/me` after the app uploads the summary.

### 3.4 Synca Spark

**SparkView** (dedicated tab)

Main states:

1. **Idle**: button "Start Spark" + field to enter session code.
2. **Pending** (after creation): shows QR code + 6-digit code.
3. **Active (Micro-test)**: series of quick questions (2–5) with sliders/buttons.
4. **Result**: shows score, a short explanation (e.g., "Great sleep alignment"), and a reward message (e.g., "You unlocked 7 days of Premium").

Actions:

- Create session → `SparkService.createSession()` → receives `session_code` + `qr_token`.
- Join session → user B enters code or scans QR (scanner can be added later; for MVP code entry is enough).
- Submit answers → `SparkService.submitAnswers()`.
- Fetch result → `SparkService.fetchResult()`.

---

## 4. Core Swift Models

### 4.1 User & Profile

```swift
struct User: Codable {
    let id: Int
    let email: String?
}

struct Profile: Codable {
    let displayName: String
    let city: String?
    let photoURLMain: URL?
    let trustScore: Double
    let sparkVerified: Bool
}
```

### 4.2 Health Summary Payload

```swift
struct HealthSummaryPayload: Codable {
    let chronotype: String          // "early_bird", "intermediate", "night_owl"
    let sleepStartLocal: String     // "HH:mm"
    let sleepEndLocal: String       // "HH:mm"
    let avgSleepDurationMinutes: Int
    let routineStabilityIndex: Double
    let activityLevel: String       // "low", "medium", "high"
    let peakEnergyStartLocal: String
    let peakEnergyEndLocal: String
    let recoveryScore: String       // "low", "medium", "high"
    let source: String              // "apple_health"
}
```

### 4.3 Match Models

The backend uses a `match_participants` join table instead of `user_a_id / user_b_id`.
This allows the same model to represent both 1-to-1 and future group matches.

```swift
struct MatchParticipant: Codable {
    let userId: Int
    let role: String                // "initiator", "member"
    let profile: MatchProfile?
}

struct MatchProfile: Codable {
    let displayName: String
    let photoURLMain: URL?
}

struct Match: Codable {
    let id: Int
    let status: String              // "proposed", "accepted", "rejected"
    let compatibilityScore: Double
    let participants: [MatchParticipant]
}
```

### 4.4 Spark Models

```swift
struct SparkSession: Codable {
    let id: Int
    let sessionCode: String
    let qrToken: String
    let status: String              // "pending", "active", "completed", "expired"
}

struct SparkResult: Codable {
    let compatibilityScore: Double
    let dimensions: [String: Double]
    let rewards: [SparkReward]
}

struct SparkReward: Codable {
    let type: String                // "premium_week", "match_credit", "boost"
    let status: String              // "pending", "redeemed", "expired"
}
```

---

## 5. HealthKit Integration (v0)

**MVP objective:** read minimal metrics needed for the summary:

- Sleep: `HKCategoryTypeIdentifier.sleepAnalysis`.
- Activity: `HKQuantityTypeIdentifier.stepCount` and/or `activeEnergyBurned`.

Workflow:

1. Request authorization for sleep + activity.
2. Read the last 14 days.
3. Compute:
   - average sleep start/end times,
   - average duration,
   - variance of times (for `routineStabilityIndex`),
   - average steps/activity level.
4. Map into `HealthSummaryPayload`.
5. Send to backend via `ApiClient.updateHealthSummary()`.

No HRV or resting HR in the MVP; these can be added in later iterations.

---

## 6. Core Services

### 6.1 ApiClient

Responsibilities:

- Manage tokens (access + refresh).
- Call `/auth`, `/me`, `/health_summary`, `/preferences`, `/spark_sessions`, `/matches` endpoints.

### 6.2 HealthService

Responsibilities:

- Manage HealthKit authorization.
- Execute queries and local aggregation.
- Expose `func buildSummary() async throws -> HealthSummaryPayload`.

### 6.3 SparkService

Responsibilities:

- Create/join session.
- Submit micro-test answers.
- Fetch result (score + rewards).
- On result received: update local `irl_verification_count` via `/me` refresh.
- Optionally expose observable state (e.g., `@Published var currentSession: SparkSession?`).

---

## 7. UX & MVP Limitations

- If the user denies HealthKit access, the app remains usable but with a limited dashboard and less accurate compatibility.
- If connection drops during Spark, show a simple error and allow retry.
- All copy must stress that health data is **never shared** with other users and is only used to improve compatibility.

---

## 8. Next Steps After MVP

- Add push notifications (to nudge Spark sessions and engagement at peak times).
- Integrate real payments (external webview + backend integration).
- Expand the matching model and add a proper suggested-matches screen.
- **Spark enhancements**: QR code scanner (AVFoundation), WebSocket for real-time session sync, animated result reveal.
- **IRL verification**: surface `irl_verification_count` and `spark_verified` badge prominently in the profile UI as trust signals.
- **Group Spark (v3+)**: the `Match` + `MatchParticipant` data model is already group-ready on the backend; the iOS client will need a multi-participant result screen and group match card when the engine enables it.

---

## 9. Testing & Code Coverage

All iOS app code for the MVP should have good automated test coverage.

- **Framework**: use **XCTest** (built-in).
- **Targets**:
  - `SyncaTests` for unit tests.
  - `SyncaUITests` for UI flows (optional in the very first iteration, but recommended for key flows later).
- **What to test (MVP)**:
  - View models: business logic, state transitions, mapping of API models to view state.
  - Services: `ApiClient`, `HealthService`, `SparkService` with mocked network/HealthKit.
  - Pure utility functions.
- **Coverage**:
  - Enable code coverage in the Xcode scheme.
  - Target at least ~70–80% coverage on `ViewModel` and `Service` layers.

Every new feature should ship with at least unit tests for the critical paths. Bugfixes should include regression tests.

---

## 10. CI/CD on GitHub

CI must run on every push and pull request to main branches for the iOS project.

- **Workflow file**: `.github/workflows/ios-ci.yml`.
- **Triggers**:
  - `push` on `main` and main feature branches.
  - `pull_request` targeting `main`.
- **Jobs (MVP)**:
  - Use `macos-latest` runner.
  - Steps:
    1. `actions/checkout`.
    2. Select appropriate Xcode version (e.g., with `xcode-select` or `maxim-lobanov/setup-xcode`).
    3. Resolve dependencies (Swift Package Manager or CocoaPods, depending on the project setup).
    4. Run tests with coverage enabled using `xcodebuild test` on the `Synca` scheme.

Example skeleton (to be refined once the Xcode project and scheme names are final):

```yaml
name: iOS CI

on:
  push:
    branches: ["main"]
  pull_request:
    branches: ["main"]

jobs:
  build-and-test:
    runs-on: macos-latest

    steps:
      - uses: actions/checkout@v4
      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode.app
      - name: Resolve SwiftPM dependencies
        run: xcodebuild -resolvePackageDependencies -scheme Synca -project apps/ios/Synca/Synca.xcodeproj
      - name: Build and test
        run: xcodebuild test -scheme Synca -project apps/ios/Synca/Synca.xcodeproj -destination 'platform=iOS Simulator,name=iPhone 15'
```

The CI workflow should become a required check before merging PRs. CD (automatic deployment to TestFlight/App Store) can be added in a later phase.
