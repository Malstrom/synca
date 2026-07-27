import SwiftUI

/// The ring-chart compatibility visualization used on Spark result, match list,
/// and match detail — see docs/design/ui-system.md (data_display: "abstract
/// rings/waves"). The percentage is shown deliberately, always paired with a
/// caption — see docs/conventions/ios.md § Key Conventions.
struct CompatibilityRing: View {
    let score: Int
    var diameter: CGFloat = 140
    var lineWidth: CGFloat = 10
    var caption: String = "compatibility"

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.syncaNeutral800, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: CGFloat(min(max(score, 0), 100)) / 100)
                .stroke(Color.syncaAccent, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))

            VStack(spacing: 2) {
                Text("\(score)%")
                    .font(.custom("Inter-Medium", size: diameter * 0.23))
                    .foregroundColor(.syncaText)
                if !caption.isEmpty {
                    Text(caption)
                        .font(.syncaCaption)
                        .foregroundColor(.syncaText.opacity(0.6))
                }
            }
        }
        .frame(width: diameter, height: diameter)
        .animation(.easeOut(duration: 0.6), value: score)
    }
}

/// Plain-language tier matching the score to the headline copy shown under the
/// ring — thresholds mirror docs/features/matching-v1.md § Score thresholds
/// (Spark match minimum: 50).
enum CompatibilityTier {
    case strong, good, some, different

    init(score: Int) {
        switch score {
        case 80...: self = .strong
        case 65..<80: self = .good
        case 50..<65: self = .some
        default: self = .different
        }
    }

    var headline: String {
        switch self {
        case .strong: return "Strong compatibility"
        case .good: return "Good compatibility"
        case .some: return "Some compatibility"
        case .different: return "Different rhythms"
        }
    }

    var subtext: String {
        switch self {
        case .strong: return "Your sleep rhythm and energy windows line up closely. That's rare."
        case .good: return "You share a good amount of overlap in rhythm and energy."
        case .some: return "There's some common ground — worth exploring."
        case .different: return "Your rhythms run pretty differently — that's useful to know early."
        }
    }
}

#Preview {
    CompatibilityRing(score: 84)
        .padding()
        .background(Color.syncaBackground)
}
