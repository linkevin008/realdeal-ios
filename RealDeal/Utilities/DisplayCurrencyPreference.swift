import Foundation

/// Manages the user's preferred display currency.
/// The stored value is the ISO 4217 currency code (e.g. "CAD", "USD").
/// Defaults to "CAD".
final class DisplayCurrencyPreference: ObservableObject {
    static let shared = DisplayCurrencyPreference()

    private let key = "displayCurrency"

    @Published var displayCurrency: String {
        didSet { UserDefaults.standard.set(displayCurrency, forKey: key) }
    }

    private init() {
        displayCurrency = UserDefaults.standard.string(forKey: "displayCurrency") ?? "CAD"
    }
}
