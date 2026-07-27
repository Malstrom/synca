import SwiftUI

/// Matches the prototype's `.btn-primary` / `.btn-secondary` — outlined, not
/// filled. See docs/design/ui-system.md § SyncaButton.
struct SyncaButton: View {
    enum Style { case primary, secondary }

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

    private var foregroundColor: Color { style == .primary ? .syncaAccent : .syncaText }
    private var borderColor: Color { style == .primary ? .syncaAccent : .syncaDivider }
}

#Preview {
    VStack(spacing: 12) {
        SyncaButton(title: "Connect Apple Health", action: {})
        SyncaButton(title: "Enter code manually", action: {}, style: .secondary)
        SyncaButton(title: "Loading…", action: {}, isLoading: true)
    }
    .padding()
    .background(Color.syncaBackground)
}
