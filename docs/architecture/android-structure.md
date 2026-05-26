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
│       │   │   ├── onboarding/    # Registration, consent, health permissions
│       │   │   ├── matching/      # Match list and compatibility detail
│       │   │   ├── dateproposals/ # Proposals list, detail, accept/decline
│       │   │   ├── profile/       # User profile editing
│       │   │   └── auth/          # Login, signup
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

## Minimum SDK

- `minSdk`: 26 (API 26)
- `targetSdk`: latest stable
- Health Connect requires API 26+.

## Testing

- Unit tests: `test/` directory, JUnit 4/5 + MockK.
- Focus on Repository logic, ViewModel state transitions, and health aggregation.
