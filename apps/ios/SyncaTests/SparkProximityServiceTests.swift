import XCTest
@testable import Synca

final class SparkProximityServiceTests: XCTestCase {
    private let sut = SparkProximityService()

    func test_extractQRToken_fromUniversalLink_returnsTokenQueryValue() {
        let scanned = "https://synca.app/spark/join?qr_token=550e8400-e29b-41d4-a716-446655440000"

        XCTAssertEqual(sut.extractQRToken(from: scanned), "550e8400-e29b-41d4-a716-446655440000")
    }

    func test_extractQRToken_fromBareToken_returnsItTrimmed() {
        XCTAssertEqual(sut.extractQRToken(from: "  550e8400-e29b-41d4-a716-446655440000  "), "550e8400-e29b-41d4-a716-446655440000")
    }

    func test_extractQRToken_fromEmptyString_returnsNil() {
        XCTAssertNil(sut.extractQRToken(from: "   "))
    }

    func test_qrCodeImage_producesNonNilImage() {
        let image = sut.qrCodeImage(forQRToken: "550e8400-e29b-41d4-a716-446655440000")
        XCTAssertNotNil(image)
    }
}
