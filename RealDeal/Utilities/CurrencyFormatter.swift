import Foundation

/// Centralises all price formatting and currency conversion for the app.
enum CurrencyFormatter {

    // MARK: - Supported currencies

    static let supported: [String] = ["CAD", "USD", "GBP", "EUR", "AUD"]

    // MARK: - Hardcoded fallback exchange rates (relative to CAD)
    // Source: approximate mid-market rates, update via ExchangeRateService when available.

    private static let ratesFromCAD: [String: Decimal] = [
        "CAD": 1.0,
        "USD": 0.74,
        "GBP": 0.58,
        "EUR": 0.68,
        "AUD": 1.13
    ]

    // MARK: - Format

    /// Format a price in its storage currency, with optional conversion to a display currency.
    /// - Parameters:
    ///   - price: The original price
    ///   - storageCurrency: The currency the price is stored in (e.g. "CAD")
    ///   - displayCurrency: The currency the user wants to see (e.g. "USD"). Pass nil to show storage currency.
    ///   - showApproximate: When true and currencies differ, prefixes with "~" and appends the storage amount
    /// - Returns: Formatted price string
    static func format(
        _ price: Decimal,
        storageCurrency: String,
        displayCurrency: String?,
        showApproximate: Bool = true
    ) -> String {
        let target = displayCurrency ?? storageCurrency

        if target == storageCurrency {
            return formatAmount(price, currency: storageCurrency)
        }

        // Convert storage → CAD → target
        guard
            let toCAD = ratesFromCAD[storageCurrency].map({ Decimal(1) / $0 }),
            let fromCAD = ratesFromCAD[target]
        else {
            // Unknown currency — show storage currency as fallback
            return formatAmount(price, currency: storageCurrency)
        }

        let converted = price * toCAD * fromCAD
        let convertedStr = formatAmount(converted, currency: target)

        if showApproximate {
            let originalStr = formatAmount(price, currency: storageCurrency)
            return "\(convertedStr) (~\(originalStr))"
        }
        return convertedStr
    }

    /// Format a price in its own storage currency (no conversion).
    static func format(_ price: Decimal, currency: String) -> String {
        formatAmount(price, currency: currency)
    }

    // MARK: - Private

    private static func formatAmount(_ amount: Decimal, currency: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currency
        formatter.locale = locale(for: currency)
        formatter.maximumFractionDigits = 0
        return formatter.string(from: amount as NSDecimalNumber) ?? "\(currency) \(amount)"
    }

    private static func locale(for currency: String) -> Locale {
        switch currency {
        case "CAD": return Locale(identifier: "en_CA")
        case "USD": return Locale(identifier: "en_US")
        case "GBP": return Locale(identifier: "en_GB")
        case "EUR": return Locale(identifier: "fr_FR")
        case "AUD": return Locale(identifier: "en_AU")
        default:    return Locale.current
        }
    }
}
