# Synca — UI Design System

> Single source of truth for visual design: tokens, components, states, and navigation map.
> For coding conventions and MVVM rules → See [docs/conventions/ios.md](../conventions/ios.md).
> For feature-level UI flows → See the relevant `docs/features/<feature>-v1.md`.

---

## Design Principles

- **Calm, not flashy.** Synca is health-based: the UI should feel clean and trustworthy.
- **Content first.** No decorative chrome. Every element earns its place.
- **Privacy visible.** When health data is shown, always make clear it stays on-device.

---

## Design Tokens

### Colors

```swift
// Resources/Assets.xcassets — define these as Color Sets for dark mode support

extension Color {
    // Brand
    static let syncaPrimary    = Color("SyncaPrimary")    // #1A1A2E deep navy
    static let syncaAccent     = Color("SyncaAccent")     // #E94560 coral red
    static let syncaBackground = Color("SyncaBackground") // #F7F7F7 light / #121212 dark

    // Semantic
    static let syncaSuccess    = Color("SyncaSuccess")    // #27AE60
    static let syncaWarning    = Color("SyncaWarning")    // #F39C12
    static let syncaError      = Color("SyncaError")      // #E74C3C
    static let syncaTextPrimary   = Color("SyncaTextPrimary")    // #1A1A2E / #FFFFFF
    static let syncaTextSecondary = Color("SyncaTextSecondary")  // #6B7280 / #9CA3AF
}
```

All colors must be defined as **Color Sets** in `Assets.xcassets` with light and dark variants.
Never use hardcoded hex values in View code.

### Typography

```swift
extension Font {
    static let syncaLargeTitle  = Font.system(size: 34, weight: .bold,   design: .rounded)
    static let syncaTitle       = Font.system(size: 22, weight: .semibold, design: .rounded)
    static let syncaHeadline    = Font.system(size: 17, weight: .semibold, design: .default)
    static let syncaBody        = Font.system(size: 16, weight: .regular,  design: .default)
    static let syncaCaption     = Font.system(size: 12, weight: .regular,  design: .default)
}
```

### Spacing

```swift
enum Spacing {
    static let xs:  CGFloat = 4
    static let sm:  CGFloat = 8
    static let md:  CGFloat = 16
    static let lg:  CGFloat = 24
    static let xl:  CGFloat = 32
    static let xxl: CGFloat = 48
}
```

### Corner Radius

```swift
enum Radius {
    static let sm:  CGFloat = 8
    static let md:  CGFloat = 12
    static let lg:  CGFloat = 20
    static let full: CGFloat = 999 // pill shape
}
```

---

## Reusable Components

All shared components live in `Features/Shared/` (create this folder).
Never duplicate a component — if two screens need the same element, extract it here.

### SyncaButton

```swift
// Features/Shared/SyncaButton.swift
struct SyncaButton: View {
    let title: String
    let action: () -> Void
    var style: Style = .primary
    var isLoading: Bool = false

    enum Style { case primary, secondary, destructive }

    var body: some View {
        Button(action: action) {
            Group {
                if isLoading {
                    ProgressView().tint(.white)
                } else {
                    Text(title).font(.syncaHeadline)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.md)
            .background(backgroundColor)
            .foregroundColor(.white)
            .cornerRadius(Radius.lg)
        }
        .disabled(isLoading)
    }

    private var backgroundColor: Color {
        switch style {
        case .primary:     return .syncaAccent
        case .secondary:   return .syncaPrimary
        case .destructive: return .syncaError
        }
    }
}
```

### LoadingView

```swift
// Features/Shared/LoadingView.swift
struct LoadingView: View {
    var message: String = "Loading..."
    var body: some View {
        VStack(spacing: Spacing.md) {
            ProgressView()
            Text(message).font(.syncaCaption).foregroundColor(.syncaTextSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
```

### ErrorView

```swift
// Features/Shared/ErrorView.swift
struct ErrorView: View {
    let message: String
    var retryAction: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title).foregroundColor(.syncaError)
            Text(message).font(.syncaBody).multilineTextAlignment(.center)
            if let retry = retryAction {
                SyncaButton(title: "Retry", action: retry, style: .secondary)
            }
        }
        .padding(Spacing.lg)
    }
}
```

### Usage pattern in Views

Every View that loads async data follows this pattern:

```swift
var body: some View {
    Group {
        if viewModel.isLoading {
            LoadingView()
        } else if let error = viewModel.errorMessage {
            ErrorView(message: error) { Task { await viewModel.load() } }
        } else {
            // actual content
        }
    }
    .task { await viewModel.load() }
}
```

---

## Navigation Map

All screens and how they connect. `AppRouter` destinations → See [architecture/ios-structure.md § AppRouter](../architecture/ios-structure.md).

```
App Launch
    ├── No token in Keychain ──▶ LoginView
    │       └── "Register" ▶ RegisterView
    │               └── Success ▶ OnboardingView (preferences)
    │                               └── Done ▶ DashboardView
    │
    ├── Token valid ──▶ DashboardView (home hub)
    │       ├── "Start Spark" ▶ SparkView
    │       │       └── Result ▶ MatchDetailView (if match created)
    │       ├── Match row ▶ MatchDetailView
    │       │       └── "Plan a Moment" ▶ MomentView
    │       ├── Circle row ▶ CircleView
    │       │       └── Messages ▶ CircleMessageView
    │       ├── Profile tab ▶ ProfileView
    │       │       ├── "My Health" ▶ SignalsView
    │       │       └── "Verify" ▶ TrustView
    │       └── (background) deep link ▶ ActivationView
    │
    └── Universal link (QR scan) ──▶ OnboardingView (guest) ▶ SparkView
```

---

## Loading & Error States

Every screen must handle three states: loading, error, and content.
→ See components `LoadingView` and `ErrorView` above.

Conventions:
- Loading state: full-screen `LoadingView` on first load; inline spinner on refresh.
- Error state: `ErrorView` with retry button for network errors.
- Empty state: custom per-feature empty view (e.g. "No matches yet").
- Never block the UI silently — always show feedback.

---

## Accessibility

- All interactive elements must have `.accessibilityLabel`.
- Minimum tap target: 44×44pt (Apple HIG standard).
- Support Dynamic Type: use `Font` extensions above (system fonts scale automatically).
- Never disable accessibility for decorative images — use `.accessibilityHidden(true)` instead.

---

## Open Questions

See [docs/product/decisions.md](../product/decisions.md) — filter by `source: docs/design/ui-system.md`.
