import Foundation

/// Configuration for the CREA Data Distribution Facility (DDF) integration.
///
/// Credentials are intentionally not hard-coded. Set the `REPLIERS_API_KEY`
/// environment variable locally, or store the value in AWS Secrets Manager and
/// inject it at app launch.
struct CREAConfiguration {
    // MARK: - Repliers API (wraps CREA DDF)

    /// API key read from the process environment. Set `REPLIERS_API_KEY` via
    /// a local `.xcconfig`, a CI secret, or AWS Secrets Manager.
    static var repliersAPIKey: String? {
        ProcessInfo.processInfo.environment["REPLIERS_API_KEY"]
    }

    /// Base URL for the Repliers API.
    static var baseURL: String { "https://api.repliers.io" }

    /// Returns `true` when a Repliers API key is present and live data can be fetched.
    static var isConfigured: Bool { repliersAPIKey != nil }
}
