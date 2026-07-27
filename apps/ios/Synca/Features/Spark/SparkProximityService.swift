import Foundation
import CoreImage.CIFilterBuiltins
import UIKit

/// QR generation (for registered users starting a Spark) and QR-payload parsing
/// (for guests scanning one). Phase 1 discovery method is QR-only, no proximity
/// check — see docs/features/spark-v1.md § Proximity verification strategy.
/// Bluetooth/location are Phase 3 and intentionally not implemented here.
struct SparkProximityService {
    private static let universalLinkHost = "synca.app"
    private static let universalLinkQueryKey = "qr_token"

    /// Renders a scannable QR code image encoding the given Spark's universal link.
    func qrCodeImage(forQRToken qrToken: String, size: CGFloat = 300) -> UIImage? {
        let payload = "https://\(Self.universalLinkHost)/spark/join?\(Self.universalLinkQueryKey)=\(qrToken)"
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(payload.utf8)
        filter.correctionLevel = "M"

        guard let outputImage = filter.outputImage else { return nil }

        let scale = size / outputImage.extent.width
        let transformed = outputImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

        let context = CIContext()
        guard let cgImage = context.createCGImage(transformed, from: transformed.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }

    /// Accepts either a bare `qr_token` UUID (manual code entry) or a scanned
    /// universal link and returns the token to pass to `POST /sparks/:id/join`.
    func extractQRToken(from scannedValue: String) -> String? {
        let trimmed = scannedValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if let url = URL(string: trimmed),
           let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let token = components.queryItems?.first(where: { $0.name == Self.universalLinkQueryKey })?.value {
            return token
        }

        return trimmed
    }
}
