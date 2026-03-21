import Foundation

/// Protocol for fetching live exchange rates.
/// Swap in a real implementation (e.g. backed by exchangerate.host or AWS Lambda)
/// when the backend is ready. Until then, CurrencyFormatter uses hardcoded fallback rates.
protocol ExchangeRateServiceProtocol {
    /// Fetch the exchange rate from one currency to another.
    /// Returns nil if the rate is unavailable.
    func rate(from: String, to: String) async throws -> Decimal?
}

/// Stub that always returns nil, causing CurrencyFormatter to use its hardcoded fallbacks.
struct StubExchangeRateService: ExchangeRateServiceProtocol {
    func rate(from: String, to: String) async throws -> Decimal? { nil }
}
