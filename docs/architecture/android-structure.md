# Android App Structure

**Directory:** `apps/android/Synca/`

## Folder Layout

```text
apps/android/Synca/
├── app/
│   └── src/main/
│       ├── java/com/synca/
│       │   ├── data/
│       │   │   ├── health/        # Health Connect authorization and aggregation
│       │   │   ├── api/           # Retrofit-based API client
│       │   │   ├── models/        # Kotlin data classes (plain, Serializable/Parcelable)
│       │   │   └── repository/    # Single source of truth for each domain
│       │   ├── ui/
│       │   │   ├── auth/          # Login, signup
│       │   │   ├── onboarding/    # Registration, consent, health permissions
│       │   │   ├── profile/       # User profile editing, preferences
│       │   │   ├── signals/       # Health Connect connection, metrics display
│       │   │   ├── spark/         # Start/join Spark, questionnaire, result
│       │   │   ├── matching/      # Match list and compatibility detail
│       │   │   ├── circles/       # Circle list and messaging
│       │   │   ├── moments/       # Proposal, accept/decline, complete/no-show
│       │   │   └── trust/         # Phone verification, liveness
│       │   ├── di/                # Hilt dependency injection modules
│       │   └── SyncaApp.kt        # Application entry point
│       └── res/
│           ├── layout/
│           ├── values/
│           │   ├── strings.xml
│           │   └── colors.xml
│           └── drawable/
├── build.gradle
└── AndroidManifest.xml
```

## Architecture

- **Pattern:** MVVM with Repository.
- **UI:** Jetpack Compose.
- **State:** `StateFlow` / `collectAsState()`.
- **DI:** Hilt.
- **Networking:** Retrofit + Kotlin Coroutines.
- **Health data:** Health Connect SDK. Aggregated on device before sending to backend.

## Key Design Rules

- Composables are stateless where possible. State lives in ViewModel.
- Repository is the only class that talks to both the API and Health Connect.
- Health data is aggregated in `data/health/` before reaching any UI layer.
- Never send raw Health Connect records to the backend.

## Model Naming — Canonical Map

Always use canonical names from feature docs. Deprecated names are banned.

| Android data class | Canonical | Deprecated (do not use) | Feature doc |
|---|---|---|---|
| `Signal` | `Signal` | `HealthSummary` | signals-v1.md |
| `Moment` | `Moment` | `DateProposal` | moments-v1.md |
| `Circle` | `Circle` | `SyncRoom` | circles-v1.md |
| `CircleMessage` | `CircleMessage` | `SyncRoomMessage` | circles-v1.md |
| `Match` | `Match` | — | matching-v1.md |
| `Spark` | `Spark` | `SparkSession` | spark-v1.md |
| `PreferenceProfile` | `PreferenceProfile` | — | profile-v1.md |
| `DeclaredPreference` | `DeclaredPreference` | — | signals-v1.md |

## Minimum SDK

- `minSdk`: 26 (API 26)
- `targetSdk`: latest stable
- Health Connect requires API 26+.

## Testing

- Unit tests: `test/` directory, JUnit 4/5 + MockK.
- Focus on Repository logic, ViewModel state transitions, and health aggregation.
- Mock Health Connect via a `HealthConnectClientWrapper` interface — never hit the real SDK in tests.
- Network calls mocked via MockWebServer (OkHttp).
