import SwiftUI

/// Nocturne design tokens — see docs/design/ui-system.md § Colors.
/// Dark-only for MVP: every Color Set in Assets.xcassets has a single "universal"
/// value, so these read the same regardless of the system appearance setting.
extension Color {
    // Ground
    static let syncaBackground = Color("SyncaBackground")
    static let syncaSurface = Color("SyncaSurface")
    static let syncaText = Color("SyncaText")
    static let syncaDivider = Color("SyncaDivider")

    // Accent — cool: compatibility & trust
    static let syncaAccent = Color("SyncaAccent")
    static let syncaAccent2 = Color("SyncaAccent2")

    // Accent — warm: vitality & live moments (added per design review, Igor)
    static let syncaWarm = Color("SyncaWarm")
    static let syncaWarmStrong = Color("SyncaWarmStrong")
    static let syncaWarmBg = Color("SyncaWarmBg")
    static let syncaWarmSoft = Color("SyncaWarmSoft")

    // Neutral ramp
    static let syncaNeutral100 = Color("SyncaNeutral100")
    static let syncaNeutral200 = Color("SyncaNeutral200")
    static let syncaNeutral300 = Color("SyncaNeutral300")
    static let syncaNeutral400 = Color("SyncaNeutral400")
    static let syncaNeutral500 = Color("SyncaNeutral500")
    static let syncaNeutral600 = Color("SyncaNeutral600")
    static let syncaNeutral700 = Color("SyncaNeutral700")
    static let syncaNeutral800 = Color("SyncaNeutral800")
    static let syncaNeutral900 = Color("SyncaNeutral900")

    // Accent ramp (tag fills)
    static let syncaAccent100 = Color("SyncaAccent100")
    static let syncaAccent700 = Color("SyncaAccent700")
    static let syncaAccent800 = Color("SyncaAccent800")
    static let syncaAccent900 = Color("SyncaAccent900")
    static let syncaAccent2_100 = Color("SyncaAccent2_100")
    static let syncaAccent2_800 = Color("SyncaAccent2_800")
    static let syncaAccent2_700 = Color("SyncaAccent2_700")

    static let syncaError = Color("SyncaError")
}
