import XCTest
@testable import RealDeal

final class CurrencyFormatterTests: XCTestCase {

    // MARK: - format(_:currency:)

    func testFormatCADNoConversion() {
        let result = CurrencyFormatter.format(500_000, currency: "CAD")
        XCTAssertTrue(result.contains("500,000"), "Expected formatted CAD amount, got: \(result)")
    }

    func testFormatUSDNoConversion() {
        let result = CurrencyFormatter.format(100_000, currency: "USD")
        XCTAssertTrue(result.contains("100,000"))
    }

    // MARK: - format(_:storageCurrency:displayCurrency:)

    func testSameCurrencyNoConversion() {
        let result = CurrencyFormatter.format(800_000, storageCurrency: "CAD", displayCurrency: "CAD")
        XCTAssertFalse(result.contains("~"), "Should not show approximate marker when currencies match")
        XCTAssertTrue(result.contains("800,000"))
    }

    func testNilDisplayCurrencyShowsStorage() {
        let result = CurrencyFormatter.format(400_000, storageCurrency: "CAD", displayCurrency: nil)
        XCTAssertFalse(result.contains("~"))
        XCTAssertTrue(result.contains("400,000"))
    }

    func testCADtoUSDConversionShowsApproximate() {
        let result = CurrencyFormatter.format(1_000_000, storageCurrency: "CAD", displayCurrency: "USD")
        XCTAssertTrue(result.contains("~"), "Should show ~ when currencies differ")
        // CAD 1,000,000 × 0.74 = USD 740,000
        XCTAssertTrue(result.contains("740,000"), "Expected converted USD amount, got: \(result)")
    }

    func testCADtoUSDWithoutApproximate() {
        let result = CurrencyFormatter.format(1_000_000, storageCurrency: "CAD", displayCurrency: "USD", showApproximate: false)
        XCTAssertFalse(result.contains("~"))
        XCTAssertTrue(result.contains("740,000"))
    }

    func testUnknownDisplayCurrencyFallsBackToStorage() {
        let result = CurrencyFormatter.format(500_000, storageCurrency: "CAD", displayCurrency: "JPY")
        // JPY not in supported list, should fall back to CAD
        XCTAssertTrue(result.contains("500,000"))
    }

    func testSupportedCurrenciesListIsNotEmpty() {
        XCTAssertFalse(CurrencyFormatter.supported.isEmpty)
        XCTAssertTrue(CurrencyFormatter.supported.contains("CAD"))
        XCTAssertTrue(CurrencyFormatter.supported.contains("USD"))
    }

    func testGBPConversion() {
        let result = CurrencyFormatter.format(1_000_000, storageCurrency: "CAD", displayCurrency: "GBP", showApproximate: false)
        // CAD 1,000,000 × 0.58 = GBP 580,000
        XCTAssertTrue(result.contains("580,000"), "Expected GBP 580,000, got: \(result)")
    }
}
