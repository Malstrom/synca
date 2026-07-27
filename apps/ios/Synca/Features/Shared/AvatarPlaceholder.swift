import SwiftUI

/// Plain placeholder circles — no photo yet in Phase 0 (photos are Phase 1, see
/// docs/product/phases/phase-0.md § Out of Scope). Matches the prototype after
/// its avatar `<image-slot>`s were reverted to plain circles during review
/// (see chats/chat1.md) — never render clipped placeholder initials/text here.
struct AvatarPlaceholder: View {
    var diameter: CGFloat = 44

    var body: some View {
        Circle()
            .fill(Color.syncaNeutral800)
            .frame(width: diameter, height: diameter)
    }
}

/// Two overlapping avatar circles — "you and your Spark partner".
struct OverlappingAvatarPair: View {
    var diameter: CGFloat = 72
    var borderColor: Color = .syncaBackground
    var borderWidth: CGFloat = 3

    var body: some View {
        HStack(spacing: -diameter * 0.22) {
            AvatarPlaceholder(diameter: diameter)
                .overlay(Circle().stroke(borderColor, lineWidth: borderWidth))
            AvatarPlaceholder(diameter: diameter)
                .overlay(Circle().stroke(borderColor, lineWidth: borderWidth))
                .zIndex(-1)
        }
    }
}

#Preview {
    OverlappingAvatarPair()
        .padding()
        .background(Color.syncaBackground)
}
