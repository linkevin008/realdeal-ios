import Foundation

/// Centralized manager for all AI services
/// Handles configuration, initialization, and coordination of AI capabilities
class AIServiceManager: ObservableObject {
    // MARK: - Published Properties
    
    @Published private(set) var configuration: AIConfiguration
    @Published private(set) var isInitialized = false
    
    // MARK: - AI Services
    
    private(set) var recommendationEngine: RecommendationEngineProtocol?
    private(set) var naturalLanguageSearch: NaturalLanguageSearchProtocol?
    private(set) var contentGeneration: ContentGenerationProtocol?
    
    // MARK: - Initialization
    
    init(configuration: AIConfiguration = .disabled) {
        self.configuration = configuration
        setupServices()
    }
    
    // MARK: - Public Methods
    
    /// Update the AI configuration and reinitialize services
    func updateConfiguration(_ newConfiguration: AIConfiguration) {
        self.configuration = newConfiguration
        setupServices()
    }
    
    /// Check if a specific AI feature is available
    func isFeatureAvailable(_ feature: AIFeature) -> Bool {
        switch feature {
        case .recommendations:
            return configuration.featureFlags.recommendationsEnabled && recommendationEngine?.isAvailable == true
        case .naturalLanguageSearch:
            return configuration.featureFlags.naturalLanguageSearchEnabled && naturalLanguageSearch?.isAvailable == true
        case .contentGeneration:
            return configuration.featureFlags.contentGenerationEnabled && contentGeneration?.isAvailable == true
        case .chatbot:
            return configuration.featureFlags.chatbotEnabled
        case .pricePrediction:
            return configuration.featureFlags.pricePredictionEnabled
        case .imageAnalysis:
            return configuration.featureFlags.imageAnalysisEnabled
        }
    }
    
    /// Get the recommendation engine if available
    func getRecommendationEngine() -> RecommendationEngineProtocol? {
        guard isFeatureAvailable(.recommendations) else { return nil }
        return recommendationEngine
    }
    
    /// Get the natural language search service if available
    func getNaturalLanguageSearch() -> NaturalLanguageSearchProtocol? {
        guard isFeatureAvailable(.naturalLanguageSearch) else { return nil }
        return naturalLanguageSearch
    }
    
    /// Get the content generation service if available
    func getContentGeneration() -> ContentGenerationProtocol? {
        guard isFeatureAvailable(.contentGeneration) else { return nil }
        return contentGeneration
    }
    
    /// Perform health check on all enabled AI services
    func performHealthCheck() async -> AIHealthStatus {
        var serviceStatuses: [AIFeature: Bool] = [:]
        
        if configuration.featureFlags.recommendationsEnabled {
            do {
                serviceStatuses[.recommendations] = try await recommendationEngine?.checkHealth() ?? false
            } catch {
                serviceStatuses[.recommendations] = false
            }
        }
        
        if configuration.featureFlags.naturalLanguageSearchEnabled {
            do {
                serviceStatuses[.naturalLanguageSearch] = try await naturalLanguageSearch?.checkHealth() ?? false
            } catch {
                serviceStatuses[.naturalLanguageSearch] = false
            }
        }
        
        if configuration.featureFlags.contentGenerationEnabled {
            do {
                serviceStatuses[.contentGeneration] = try await contentGeneration?.checkHealth() ?? false
            } catch {
                serviceStatuses[.contentGeneration] = false
            }
        }
        
        let healthyServices = serviceStatuses.values.filter { $0 }.count
        let totalServices = serviceStatuses.count
        
        return AIHealthStatus(
            overallHealth: totalServices > 0 ? Double(healthyServices) / Double(totalServices) : 1.0,
            serviceStatuses: serviceStatuses,
            lastChecked: Date()
        )
    }
    
    // MARK: - Private Methods
    
    private func setupServices() {
        // Clear existing services
        recommendationEngine = nil
        naturalLanguageSearch = nil
        contentGeneration = nil
        
        // Initialize services based on configuration
        if configuration.featureFlags.recommendationsEnabled {
            recommendationEngine = createRecommendationEngine()
        }
        
        if configuration.featureFlags.naturalLanguageSearchEnabled {
            naturalLanguageSearch = createNaturalLanguageSearch()
        }
        
        if configuration.featureFlags.contentGenerationEnabled {
            contentGeneration = createContentGeneration()
        }
        
        isInitialized = true
        
        if configuration.settings.enableLogging {
            logServiceInitialization()
        }
    }
    
    private func createRecommendationEngine() -> RecommendationEngineProtocol {
        if configuration.settings.useMockServices {
            let service = MockRecommendationEngine()
            service.configure(apiKey: "mock-key")
            return service
        } else {
            // In a real implementation, this would create the actual AI service
            // based on the configured provider (OpenAI, Anthropic, etc.)
            let service = MockRecommendationEngine()
            if let apiKey = configuration.credentials.openAIAPIKey {
                service.configure(apiKey: apiKey)
            }
            return service
        }
    }
    
    private func createNaturalLanguageSearch() -> NaturalLanguageSearchProtocol {
        if configuration.settings.useMockServices {
            let service = MockNaturalLanguageSearch()
            service.configure(apiKey: "mock-key")
            return service
        } else {
            // In a real implementation, this would create the actual AI service
            let service = MockNaturalLanguageSearch()
            if let apiKey = configuration.credentials.openAIAPIKey {
                service.configure(apiKey: apiKey)
            }
            return service
        }
    }
    
    private func createContentGeneration() -> ContentGenerationProtocol {
        if configuration.settings.useMockServices {
            let service = MockContentGeneration()
            service.configure(apiKey: "mock-key")
            return service
        } else {
            // In a real implementation, this would create the actual AI service
            let service = MockContentGeneration()
            if let apiKey = configuration.credentials.openAIAPIKey {
                service.configure(apiKey: apiKey)
            }
            return service
        }
    }
    
    private func logServiceInitialization() {
        print("🤖 AI Service Manager initialized with configuration:")
        print("   - Recommendations: \(configuration.featureFlags.recommendationsEnabled)")
        print("   - Natural Language Search: \(configuration.featureFlags.naturalLanguageSearchEnabled)")
        print("   - Content Generation: \(configuration.featureFlags.contentGenerationEnabled)")
        print("   - Mock Services: \(configuration.settings.useMockServices)")
    }
}

// MARK: - Supporting Types

/// Available AI features in the application
enum AIFeature: String, CaseIterable {
    case recommendations = "recommendations"
    case naturalLanguageSearch = "natural_language_search"
    case contentGeneration = "content_generation"
    case chatbot = "chatbot"
    case pricePrediction = "price_prediction"
    case imageAnalysis = "image_analysis"
    
    var displayName: String {
        switch self {
        case .recommendations:
            return "Property Recommendations"
        case .naturalLanguageSearch:
            return "Natural Language Search"
        case .contentGeneration:
            return "Content Generation"
        case .chatbot:
            return "AI Chatbot"
        case .pricePrediction:
            return "Price Prediction"
        case .imageAnalysis:
            return "Image Analysis"
        }
    }
}

/// Health status of AI services
struct AIHealthStatus {
    let overallHealth: Double // 0.0 to 1.0
    let serviceStatuses: [AIFeature: Bool]
    let lastChecked: Date
    
    var isHealthy: Bool {
        return overallHealth >= 0.8
    }
    
    var healthDescription: String {
        if overallHealth >= 0.9 {
            return "Excellent"
        } else if overallHealth >= 0.7 {
            return "Good"
        } else if overallHealth >= 0.5 {
            return "Fair"
        } else {
            return "Poor"
        }
    }
}