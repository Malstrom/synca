import SwiftUI

/// `.accent` = "Synca Confirmed" (Spark-origin, high confidence).
/// `.accent2` = "Suggested" (algorithm-origin, Phase 1).
/// `.outline` = structural labels ("Registered users only", "Concept — not yet built").
struct SyncaTag: View {
    enum Style { case accent, accent2, neutral, outline }

    let text: String
    var style: Style = .neutral

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

#Preview {
    HStack {
        SyncaTag(text: "SYNCA CONFIRMED · SPARK", style: .accent)
        SyncaTag(text: "Suggested", style: .accent2)
        SyncaTag(text: "Phase 0", style: .neutral)
        SyncaTag(text: "Registered users only", style: .outline)
    }
    .padding()
    .background(Color.syncaBackground)
}
