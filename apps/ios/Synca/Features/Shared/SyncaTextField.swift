import SwiftUI

/// Matches the prototype's `.field` + `.input` — a small uppercase-free label
/// above a surface-filled text field.
struct SyncaTextField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var textContentType: UITextContentType? = nil
    var autocapitalization: TextInputAutocapitalization = .sentences
    var isSecure: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.syncaCaption)
                .foregroundColor(.syncaText.opacity(0.7))
            fieldContent
                .font(.syncaSmall)
                .foregroundColor(.syncaText)
                .keyboardType(keyboardType)
                .textContentType(textContentType)
                .textInputAutocapitalization(autocapitalization)
                .autocorrectionDisabled(keyboardType == .emailAddress || isSecure)
                .padding(.horizontal, 10)
                .frame(height: 36)
                .background(Color.syncaSurface)
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.md)
                        .stroke(Color.syncaDivider, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: Radius.md))
        }
    }

    @ViewBuilder
    private var fieldContent: some View {
        if isSecure {
            SecureField(placeholder, text: $text)
        } else {
            TextField(placeholder, text: $text)
        }
    }
}

#Preview {
    VStack(spacing: 12) {
        SyncaTextField(label: "Email", placeholder: "you@email.com", text: .constant(""), keyboardType: .emailAddress)
        SyncaTextField(label: "Password", placeholder: "••••••••", text: .constant(""), isSecure: true)
    }
    .padding()
    .background(Color.syncaBackground)
}
