# AI Service Extensibility Layer

This document describes the AI service extensibility layer implemented for the Real Estate Listings application.

## Overview

The AI service extensibility layer provides a structured way to integrate AI capabilities into the application without requiring major architectural changes. The system is designed to be:

- **Modular**: Each AI service is independent and can be enabled/disabled individually
- **Extensible**: New AI services can be easily added by implementing the base protocols
- **Configurable**: Feature flags control which AI capabilities are available
- **Testable**: Mock implementations allow for development and testing without real AI services

## Architecture

### Core Components

#### 1. Base Protocol (`AIServiceProtocol`)
- Defines common interface for all AI services
- Provides availability checking and configuration methods
- Located in: `RealDeal/Services/Protocols/AIServiceProtocol.swift`

#### 2. Specific AI Service Protocols
- **RecommendationEngineProtocol**: Property recommendations based on user behavior
- **NaturalLanguageSearchProtocol**: Parse natural language queries into structured filters
- **ContentGenerationProtocol**: Generate property descriptions, marketing copy, and insights

#### 3. Configuration System (`AIConfiguration`)
- **AIFeatureFlags**: Enable/disable individual AI capabilities
- **AICredentials**: Store API keys and service endpoints
- **AISettings**: Performance and behavior configuration
- Located in: `RealDeal/Services/AIConfiguration.swift`

#### 4. Service Manager (`AIServiceManager`)
- Centralized management of all AI services
- Handles service initialization and health monitoring
- Provides unified access to AI capabilities
- Located in: `RealDeal/Services/AIServiceManager.swift`

#### 5. Mock Implementations
- **MockRecommendationEngine**: Simulates property recommendations
- **MockNaturalLanguageSearch**: Simulates query parsing
- **MockContentGeneration**: Simulates content generation
- Enable development and testing without real AI services

## Usage Examples

### Basic Setup

```swift
// Initialize AI services with development configuration
let aiManager = AIServiceManager(configuration: .development)

// Check if recommendations are available
if aiManager.isFeatureAvailable(.recommendations) {
    let engine = aiManager.getRecommendationEngine()
    // Use recommendation engine
}
```

### Property Recommendations

```swift
if let engine = aiManager.getRecommendationEngine() {
    let recommendations = try await engine.getRecommendations(
        for: currentUser, 
        limit: 10
    )
    // Display recommendations to user
}
```

### Natural Language Search

```swift
if let nlSearch = aiManager.getNaturalLanguageSearch() {
    let filters = try await nlSearch.parseQuery(
        "3 bedroom house under $500k near downtown"
    )
    // Use parsed filters for property search
}
```

### Content Generation

```swift
if let contentGen = aiManager.getContentGeneration() {
    let description = try await contentGen.generateDescription(for: property)
    // Use generated description in listing
}
```

## Configuration Options

### Development Configuration
```swift
let config = AIConfiguration.development
// - All features enabled
// - Uses mock services
// - Logging enabled
```

### Production Configuration
```swift
let config = AIConfiguration.production(
    openAIKey: "your-openai-key",
    anthropicKey: "your-anthropic-key"
)
// - Features enabled based on available API keys
// - Uses real AI services
// - Logging disabled for performance
```

### Disabled Configuration
```swift
let config = AIConfiguration.disabled
// - All AI features disabled
// - No API calls made
// - Minimal performance impact
```

## Adding New AI Services

To add a new AI service:

1. **Create Protocol**: Define the service interface extending `AIServiceProtocol`
2. **Add Feature Flag**: Add new feature to `AIFeatureFlags`
3. **Implement Service**: Create both real and mock implementations
4. **Update Manager**: Add service to `AIServiceManager`
5. **Add Configuration**: Update configuration options as needed

### Example: Adding a Chatbot Service

```swift
// 1. Define protocol
protocol ChatbotServiceProtocol: AIServiceProtocol {
    func sendMessage(_ message: String) async throws -> String
}

// 2. Add to feature flags
struct AIFeatureFlags {
    let chatbotEnabled: Bool = false
    // ... other flags
}

// 3. Implement service
class MockChatbotService: ChatbotServiceProtocol {
    // Implementation here
}

// 4. Update manager
class AIServiceManager {
    private(set) var chatbotService: ChatbotServiceProtocol?
    
    private func setupServices() {
        if configuration.featureFlags.chatbotEnabled {
            chatbotService = createChatbotService()
        }
    }
}
```

## Integration Points

### ViewModels
AI services are typically accessed through ViewModels:

```swift
class PropertyListViewModel: ObservableObject {
    private let aiManager: AIServiceManager
    
    func loadRecommendations() async {
        if let engine = aiManager.getRecommendationEngine() {
            // Load AI recommendations
        }
    }
}
```

### Backend Configuration
AI configuration can be integrated with backend configuration:

```swift
let backendConfig = BackendConfiguration.custom(
    baseURL: apiURL,
    aiConfiguration: .production(openAIKey: "key")
)
```

## Files Created

The following files implement the AI service extensibility layer:

### Protocols
- `RealDeal/Services/Protocols/AIServiceProtocol.swift`
- `RealDeal/Services/Protocols/RecommendationEngineProtocol.swift`
- `RealDeal/Services/Protocols/NaturalLanguageSearchProtocol.swift`
- `RealDeal/Services/Protocols/ContentGenerationProtocol.swift`

### Configuration
- `RealDeal/Services/AIConfiguration.swift`

### Service Manager
- `RealDeal/Services/AIServiceManager.swift`

### Mock Implementations
- `RealDeal/Services/MockRecommendationEngine.swift`
- `RealDeal/Services/MockNaturalLanguageSearch.swift`
- `RealDeal/Services/MockContentGeneration.swift`

### Documentation and Examples
- `RealDeal/Services/AIServiceExample.swift`
- `RealDeal/Services/AI_SERVICES_README.md`

## Next Steps

To fully integrate the AI services:

1. **Add Files to Xcode Project**: The created files need to be added to the Xcode project
2. **Install AI Dependencies**: Add AI service SDKs (OpenAI, Anthropic, etc.)
3. **Configure API Keys**: Set up secure API key management
4. **Implement Real Services**: Replace mock implementations with real AI service calls
5. **Add UI Integration**: Create UI components that leverage AI capabilities
6. **Add Tests**: Create comprehensive tests for AI service integration

## Benefits

This extensibility layer provides:

- **Future-Proof Architecture**: Easy to add new AI capabilities as they become available
- **Graceful Degradation**: App works fully without AI services enabled
- **Development Flexibility**: Mock services enable development without API dependencies
- **Performance Control**: Feature flags allow fine-grained control over AI usage
- **Testability**: Comprehensive testing possible with mock implementations