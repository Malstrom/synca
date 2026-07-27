import SwiftUI

struct SyncaCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.space2) {
            content
        }
        .padding(Spacing.space3)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.syncaSurface)
        .clipShape(RoundedRectangle(cornerRadius: Radius.md))
    }
}

struct SyncaCardKicker: View {
    let text: String
    var body: some View {
        Text(text)
            .syncaEyebrowStyle()
            .foregroundColor(.syncaAccent)
    }
}

struct SyncaCardTitle: View {
    let text: String
    var size: CGFloat = 17
    var body: some View {
        Text(text)
            .font(.custom("Inter-Medium", size: size))
            .foregroundColor(.syncaText)
    }
}

#Preview {
    SyncaCard {
        SyncaCardKicker(text: "SLEEP AVG")
        SyncaCardTitle(text: "7h 12m")
    }
    .padding()
    .background(Color.syncaBackground)
}
