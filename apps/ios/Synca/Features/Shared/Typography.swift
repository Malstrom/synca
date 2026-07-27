import SwiftUI

/// Inter throughout, heading weight 500 (medium) — see docs/design/ui-system.md § Typography.
///
/// `Font.custom` falls back to the system font automatically if "Inter-*" isn't
/// registered, so this is safe today even though the actual Inter `.ttf` files
/// aren't bundled yet (no font assets were included in the Claude Design handoff —
/// see README.md). Add them under Resources/Fonts/ and list them in
/// `UIAppFonts` (Info.plist) to pick up the real typeface.
extension Font {
    static let syncaH1 = Font.custom("Inter-Medium", size: 42)
    static let syncaH2 = Font.custom("Inter-Medium", size: 32)
    static let syncaH3 = Font.custom("Inter-Medium", size: 25)
    static let syncaH4 = Font.custom("Inter-Medium", size: 20)
    static let syncaH6 = Font.custom("Inter-Medium", size: 13)
    static let syncaBody = Font.custom("Inter-Regular", size: 15)
    static let syncaSmall = Font.custom("Inter-Regular", size: 13)
    static let syncaCaption = Font.custom("Inter-Regular", size: 11)
}

/// `.syncaH6` is always used as an uppercase, tracked eyebrow/kicker label
/// ("STEP 1 OF 2", card kickers) — this bundles the modifiers that go with it.
struct SyncaEyebrow: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.syncaH6)
            .textCase(.uppercase)
            .tracking(1.0)
    }
}

extension View {
    func syncaEyebrowStyle() -> some View {
        modifier(SyncaEyebrow())
    }
}
