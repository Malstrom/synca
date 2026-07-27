# Synca — UI Design System

> Single source of truth for visual design: tokens, components, states, and navigation map.
> For coding conventions and MVVM rules → See [docs/conventions/ios.md](../conventions/ios.md).
> For feature-level UI flows → See the relevant `docs/features/<feature>-v1.md`.

**Version 3.0 — July 2026.** Supersedes the v2 navy/coral light+dark tokens below with the
system actually shipped in `apps/ios/Synca` — the "Nocturne" theme from the Claude Design
handoff (see `chats/chat1.md`). Dark-only for MVP; no light variant exists in the approved
design.

---

## Design Principles

- **Calm, not flashy.** Synca is health-based: the UI should feel clean and trustworthy.
- **Content first.** No decorative chrome. Every element earns its place.
- **Privacy visible.** When health data is shown, always make clear it stays on-device.
- **Two accents, two jobs.** Cool (purple) reads as compatibility & trust — scores, rings,
  confirmations. Warm (coral) reads as vitality & live moments — the pulsing QR, energy
  windows, anything happening *right now*. Don't swap their roles.

---

## Design Tokens

### Colors

Dark-only ground. Define these as Color Sets in `Assets.xcassets` with only a Dark
Appearance value for MVP (add a Light Appearance later if/when a light mode ships —
there is no approved light design to derive one from today).

```swift
// Resources/Assets.xcassets — Color Sets, dark appearance only for MVP

extension Color {
    // Ground
    static let syncaBackground = Color("SyncaBackground") // #161826
    static let syncaSurface    = Color("SyncaSurface")    // #232532
    static let syncaText       = Color("SyncaText")       // #e9e9ed
    static let syncaDivider    = Color("SyncaDivider")    // SyncaText @ 16% opacity

    // Accent — cool: compatibility & trust (scores, rings, confirmed tags, links)
    static let syncaAccent  = Color("SyncaAccent")  // #9184d9 — OKLCH hue 289.2, L 0.660, C 0.125
    static let syncaAccent2 = Color("SyncaAccent2") // #a7a1db — same hue, L 0.734 (Suggested/algorithm tags)

    // Accent — warm: vitality & live moments (QR pulse, energy windows, in-progress Spark).
    // Added per design review (Igor): "aggiungi anche un altro colore al design".
    static let syncaWarm       = Color("SyncaWarm")       // oklch(72% 0.14 55)
    static let syncaWarmStrong = Color("SyncaWarmStrong") // oklch(60% 0.16 55)
    static let syncaWarmBg     = Color("SyncaWarmBg")     // oklch(28% 0.05 55)
    static let syncaWarmSoft   = Color("SyncaWarmSoft")   // oklch(90% 0.04 55)

    // Neutral ramp (100 lightest → 900 darkest) — tonal, generated in OKLCH
    static let syncaNeutral100 = Color("SyncaNeutral100") // #f3f5fe
    static let syncaNeutral200 = Color("SyncaNeutral200") // #e4e7f5
    static let syncaNeutral300 = Color("SyncaNeutral300") // #cfd3e5
    static let syncaNeutral400 = Color("SyncaNeutral400") // #b2b6ca
    static let syncaNeutral500 = Color("SyncaNeutral500") // #9397ab
    static let syncaNeutral600 = Color("SyncaNeutral600") // #75798c
    static let syncaNeutral700 = Color("SyncaNeutral700") // #595d6c
    static let syncaNeutral800 = Color("SyncaNeutral800") // #3f424d
    static let syncaNeutral900 = Color("SyncaNeutral900") // #292b31

    // Accent ramp (800/900/100 used for tag fills — tag-accent, tag-accent-2)
    static let syncaAccent100 = Color("SyncaAccent100") // #f5f4ff
    static let syncaAccent800 = Color("SyncaAccent800") // #423a6a
    static let syncaAccent900 = Color("SyncaAccent900") // #2b2741
    static let syncaAccent2_100 = Color("SyncaAccent2_100") // #f5f4ff
    static let syncaAccent2_800 = Color("SyncaAccent2_800") // #423e5d
    static let syncaAccent2_700 = Color("SyncaAccent2_700") // #5c5783 — "concept" outline

    // Semantic
    static let syncaError = Color("SyncaError") // #E74C3C — Nocturne has no native error hue; kept for destructive actions
}
```

Never use hardcoded hex values in View code — reference these tokens.

### Typography

Inter throughout (heading weight 500 — medium, not bold).

```swift
extension Font {
    static let syncaH1     = Font.custom("Inter-Medium", size: 42) // hero titles
    static let syncaH2     = Font.custom("Inter-Medium", size: 32)
    static let syncaH3     = Font.custom("Inter-Medium", size: 25)
    static let syncaH4     = Font.custom("Inter-Medium", size: 20)
    static let syncaH6     = Font.custom("Inter-Medium", size: 13) // uppercase, +0.08em tracking — eyebrow/kicker
    static let syncaBody   = Font.custom("Inter-Regular", size: 15)
    static let syncaSmall  = Font.custom("Inter-Regular", size: 13)
    static let syncaCaption = Font.custom("Inter-Regular", size: 11)
}
```

`.syncaH6` is always applied with `.textCase(.uppercase)` and `.tracking(1.0)` — used as the
screen eyebrow ("STEP 1 OF 2", "SPARK QUESTIONNAIRE") and card kicker.

### Spacing

```swift
enum Spacing {
    static let space1: CGFloat = 3   // 2.8px in the web tokens, rounded to the point grid
    static let space2: CGFloat = 6
    static let space3: CGFloat = 8
    static let space4: CGFloat = 11
    static let space6: CGFloat = 17
    static let space8: CGFloat = 22
}
```

### Corner Radius

```swift
enum Radius {
    static let sm: CGFloat = 4
    static let md: CGFloat = 8
    static let lg: CGFloat = 14
    static let full: CGFloat = 999 // pill shape
}
```

### Elevation

SwiftUI has no `box-shadow` ring equivalent — approximate the web tokens' hairline + ambient
shadow with a `.overlay(RoundedRectangle().stroke(...))` plus `.shadow(...)`:

```swift
enum Elevation {
    static func md(_ view: some View) -> some View {
        view
            .overlay(RoundedRectangle(cornerRadius: Radius.md).stroke(Color.syncaNeutral700, lineWidth: 1))
            .shadow(color: .black.opacity(0.55), radius: 18, y: 6)
    }
}
```

---

## Reusable Components

All shared components live in `Features/Shared/`.
Never duplicate a component — if two screens need the same element, extract it here.

### SyncaButton

```swift
// Features/Shared/SyncaButton.swift
struct SyncaButton: View {
    let title: String
    let action: () -> Void
    var style: Style = .primary
    var isLoading: Bool = false

    enum Style { case primary, secondary, ghost }

    var body: some View {
        Button(action: action) {
            Group {
                if isLoading {
                    ProgressView().tint(foregroundColor)
                } else {
                    Text(title).font(.syncaH6.weight(.medium))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.space3)
            .foregroundColor(foregroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: Radius.md)
                    .stroke(borderColor, lineWidth: 1)
            )
        }
        .disabled(isLoading)
        .opacity(isLoading ? 0.45 : 1)
    }

    private var foregroundColor: Color { style == .primary ? .syncaAccent : .syncaText }
    private var borderColor: Color { style == .primary ? .syncaAccent : .syncaDivider }
}
```

Matches the prototype's `.btn-primary` (accent outline, no fill) / `.btn-secondary` (divider
outline) / `.btn-ghost` (accent text, no border — "Go to my profile instead" on Scan QR) —
Nocturne buttons are outlined or ghost, never filled.

### SyncaTag

```swift
// Features/Shared/SyncaTag.swift
struct SyncaTag: View {
    let text: String
    var style: Style = .neutral

    enum Style { case accent, accent2, neutral, outline }

    var body: some View {
        Text(text)
            .font(.syncaCaption)
            .padding(.horizontal, 10)
            .padding(.vertical, 3)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .clipShape(RoundedRectangle(cornerRadius: Radius.md * 0.75))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.md * 0.75)
                    .stroke(style == .outline ? Color.syncaAccent : .clear, lineWidth: 1)
            )
    }

    private var backgroundColor: Color {
        switch style {
        case .accent: return .syncaAccent900
        case .accent2: return .syncaAccent2_800
        case .neutral: return .syncaNeutral800
        case .outline: return .clear
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .accent: return .syncaAccent100
        case .accent2: return .syncaAccent2_100
        case .neutral: return .syncaNeutral100
        case .outline: return .syncaAccent
        }
    }
}
```

`.accent` = "Synca Confirmed" (Spark-origin, high confidence). `.accent2` = "Suggested"
(algorithm-origin, Phase 1). `.outline` = structural labels ("Registered users only",
"Concept — not yet built").

### SyncaCard

```swift
// Features/Shared/SyncaCard.swift
struct SyncaCard<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.space2) {
            content
        }
        .padding(Spacing.space3)
        .background(Color.syncaSurface)
        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
    }
}
```

### LoadingView

```swift
// Features/Shared/LoadingView.swift
struct LoadingView: View {
    var message: String = "Loading..."
    var body: some View {
        VStack(spacing: Spacing.space4) {
            ProgressView().tint(.syncaAccent)
            Text(message).font(.syncaCaption).foregroundColor(.syncaText.opacity(0.6))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.syncaBackground)
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
        VStack(spacing: Spacing.space4) {
            Image(systemName: "exclamationmark.triangle")
                .font(.title).foregroundColor(.syncaError)
            Text(message).font(.syncaBody).multilineTextAlignment(.center).foregroundColor(.syncaText)
            if let retry = retryAction {
                SyncaButton(title: "Retry", action: retry, style: .secondary)
            }
        }
        .padding(Spacing.space6)
        .background(Color.syncaBackground)
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

All screens and how they connect. `AppRouter` destinations → See
[architecture/ios-structure.md § AppRouter](../architecture/ios-structure.md).

Revised per design review (`chats/chat1.md`, Igor): the guest flow opens directly on Apple
Health, then straight into scanning a Spark QR — no separate onboarding questionnaire (the
Spark questionnaire doubles as it), one recap-rich result screen, email capture moved to
*after* the result. QR generation is registered-users-only. The tab bar is Home / Spark /
Profile only — Matching screens exist in code (`Features/Matching/`) but are a labelled
"Concept — not yet built" and are **not** wired into the tab bar or reachable from Dashboard.

```
App Launch
    ├── Valid token in Keychain, account_type == active ──▶ DashboardView (home hub)
    │       ├── "Start a Spark" ▶ GenerateQRView (registered users only)
    │       ├── Spark row ▶ SparkResultView (past result)
    │       ├── Profile tab ▶ ProfileView ("My Health")
    │       └── Home tab ▶ DashboardView
    │
    └── No token, or account_type == guest ──▶ ConnectHealthView (guest Spark flow)
            └── "Connect Apple Health" ▶ ScanQRView
                    ├── QR scanned / code entered ▶ SparkQuestionnaireView (5 questions)
                    │       └── Submitted, both sides in ▶ SparkResultView (rich recap)
                    │               └── "Save this connection" ▶ SaveResultsView (email)
                    │                       └── "Continue" ▶ ActivationView (display name)
                    │                               └── Activated ▶ DashboardView
                    └── "Go to my profile instead" ▶ LoginView (returning user, email + password)
                            └── Signed in ▶ DashboardView
```

`Features/Matching/` (not in the map above — reachable only via SwiftUI previews or a debug
menu today):

```
MatchListView ▶ MatchDetailView ▶ (Phase 1) "Propose a Moment"
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
