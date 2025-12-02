import Foundation

/// Configuration for AI services and feature flags
/// Manages availability and settings for all AI-powered features
struct AIConfiguration {
    /// Feature flags for AI capabilities
    let featureFlags: AIFeatureFlags
    
    /// API keys and credentials for AI services
    let credentials: AICredentials
    
    /// Performance and behavior settings
    let settings: AISettings
    
    init(
        featureFlags: AIFeatureFlags = AIFeatureFlags(),
        credentials: AICredentials = AICredentials(),
        settings: AISettings = AISettings()
    ) {
        self.featureFlags = featureFlags
        self.credentials = credentials
        self.settings = settings
    }
    
    // MARK: - Predefined Configurations
    
    /// Configuration with all AI features disabled (default)
    static let disabled = AIConfiguration(
        featureFlags: AIFeatureFlags(
            recommendationsEnabled: false,
            naturalLanguageSearchEnabled: false,
            contentGenerationEnabled: false
        )
    )
    
    /// Configuration for development/testing with mock services
    static let development = AIConfiguration(
        featureFlags: AIFeatureFlags(
            recommendationsEnabled: true,
            naturalLanguageSearchEnabled: true,
            contentGenerationEnabled: true
        ),
        settings: AISettings(
            useMockServices: true,
            enableLogging: true
        )
    )
    
    /// Production configuration template (requires API keys)
    static func production(
        openAIKey: String? = nil,
        anthropicKey: String? = nil,
        customEndpoint: URL? = nil
    ) -> AIConfiguration {
        AIConfiguration(
            featureFlags: AIFeatureFlags(
                recommendationsEnabled: openAIKey != nil || anthropicKey != nil,
                naturalLanguageSearchEnabled: openAIKey != nil || anthropicKey != nil,
                contentGenerationEnabled: openAIKey != nil || anthropicKey != nil
            ),
            credentials: AICredentials(
                openAIAPIKey: openAIKey,
                anthropicAPIKey: anthropicKey,
                customEndpoint: customEndpoint
            ),
            settings: AISettings(
                useMockServices: false,
                enableLogging: false
            )
        )
    }
}

/// Feature flags for individual AI capabilities
struct AIFeatureFlags: Codable {
    /// Enable/disable property recommendations
    let recommendationsEnabled: Bool
    
    /// Enable/disable natural language search parsing
    let naturalLanguageSearchEnabled: Bool
    
    /// Enable/disable AI content generation
    let contentGenerationEnabled: Bool
    
    /// Enable/disable chatbot functionality (future)
    let chatbotEnabled: Bool
    
    /// Enable/disable price prediction (future)
    let pricePredictionEnabled: Bool
    
    /// Enable/disable image analysis (future)
    let imageAnalysisEnabled: Bool
    
    init(
        recommendationsEnabled: Bool = false,
        naturalLanguageSearchEnabled: Bool = false,
        contentGenerationEnabled: Bool = false,
        chatbotEnabled: Bool = false,
        pricePredictionEnabled: Bool = false,
        imageAnalysisEnabled: Bool = false
    ) {
        self.recommendationsEnabled = recommendationsEnabled
        self.naturalLanguageSearchEnabled = naturalLanguageSearchEnabled
        self.contentGenerationEnabled = contentGenerationEnabled
        self.chatbotEnabled = chatbotEnabled
        self.pricePredictionEnabled = pricePredictionEnabled
        self.imageAnalysisEnabled = imageAnalysisEnabled
    }
}

/// Credentials for AI service providers
struct AICredentials {
    /// OpenAI API key for GPT models
    let openAIAPIKey: String?
    
    /// Anthropic API key for Claude models
    let anthropicAPIKey: String?
    
    /// Custom AI service endpoint
    let customEndpoint: URL?
    
    /// Additional headers for custom services
    let customHeaders: [String: String]
    
    init(
        openAIAPIKey: String? = nil,
        anthropicAPIKey: String? = nil,
        customEndpoint: URL? = nil,
        customHeaders: [String: String] = [:]
    ) {
        self.openAIAPIKey = openAIAPIKey
        self.anthropicAPIKey = anthropicAPIKey
        self.customEndpoint = customEndpoint
        self.customHeaders = customHeaders
    }
}

/// Performance and behavior settings for AI services
struct AISettings {
    /// Use mock implementations instead of real AI services
    let useMockServices: Bool
    
    /// Enable detailed logging for AI service calls
    let enableLogging: Bool
    
    /// Timeout for AI service requests (in seconds)
    let requestTimeout: TimeInterval
    
    /// Maximum number of retry attempts for failed requests
    let maxRetryAttempts: Int
    
    /// Cache AI responses to reduce API calls
    let enableCaching: Bool
    
    /// Cache duration for AI responses (in seconds)
    let cacheDuration: TimeInterval
    
    init(
        useMockServices: Bool = false,
        enableLogging: Bool = false,
        requestTimeout: TimeInterval = 30.0,
        maxRetryAttempts: Int = 3,
        enableCaching: Bool = true,
        cacheDuration: TimeInterval = 3600 // 1 hour
    ) {
        self.useMockServices = useMockServices
        self.enableLogging = enableLogging
        self.requestTimeout = requestTimeout
        self.maxRetryAttempts = maxRetryAttempts
        self.enableCaching = enableCaching
        self.cacheDuration = cacheDuration
    }
}