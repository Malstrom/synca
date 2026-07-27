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

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.syncaCaption)
                .foregroundColor(.syncaText.opacity(0.7))
            TextField(placeholder, text: $text)
                .font(.syncaSmall)
                .foregroundColor(.syncaText)
                .keyboardType(keyboardType)
                .textContentType(textContentType)
                .textInputAutocapitalization(autocapitalization)
                .autocorrectionDisabled(keyboardType == .emailAddress)
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
}

#Preview {
    SyncaTextField(label: "Email", placeholder: "you@email.com", text: .constant(""), keyboardType: .emailAddress)
        .padding()
        .background(Color.syncaBackground)
}
