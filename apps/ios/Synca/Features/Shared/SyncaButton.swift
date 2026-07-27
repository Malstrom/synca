import SwiftUI

/// Matches the prototype's `.btn-primary` / `.btn-secondary` — outlined, not
/// filled. See docs/design/ui-system.md § SyncaButton.
struct SyncaButton: View {
    enum Style { case primary, secondary, ghost }

    let title: String
    let action: () -> Void
    var style: Style = .primary
    var isLoading: Bool = false
    var isDisabled: Bool = false

    var body: some View {
        Button(action: action) {
            Group {
                if isLoading {
                    ProgressView().tint(foregroundColor)
                } else {
                    Text(title)
                        .font(.syncaH6.weight(.medium))
                        .textCase(nil)
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
        .disabled(isLoading || isDisabled)
        .opacity((isLoading || isDisabled) ? 0.45 : 1)
    }

    private var foregroundColor: Color {
        switch style {
        case .primary, .ghost: return .syncaAccent
        case .secondary: return .syncaText
        }
    }

    private var borderColor: Color {
        switch style {
        case .primary: return .syncaAccent
        case .secondary: return .syncaDivider
        case .ghost: return .clear
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        SyncaButton(title: "Connect Apple Health", action: {})
        SyncaButton(title: "Enter code manually", action: {}, style: .secondary)
        SyncaButton(title: "Go to my profile instead", action: {}, style: .ghost)
        SyncaButton(title: "Loading…", action: {}, isLoading: true)
    }
    .padding()
    .background(Color.syncaBackground)
}
