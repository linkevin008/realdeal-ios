# External Listing API Integration

This module provides integration with external listing services like MLS (Multiple Listing Service) and other third-party real estate APIs.

## Components

### 1. ExternalListingAPIProtocol
The base protocol that all external listing API clients must implement:
- `fetchListings(parameters:)` - Fetch listings from the external API
- `normalizeToProperty(_:)` - Convert external listing format to internal Property model

### 2. MLSAPIClient
Production implementation for MLS API integration:
- Handles HTTP requests to MLS endpoints
- Implements data normalization from MLS format to Property model
- Validates and sanitizes all external data
- Provides source attribution (all listings marked as `.mls`)
- Includes comprehensive error handling

**Usage:**
```swift
let client = MLSAPIClient(
    baseURL: URL(string: "https://api.mls.com/v1")!,
    apiKey: "your-api-key"
)

let parameters = SearchParameters(
    location: "San Francisco",
    radius: 10,
    minPrice: 500000,
    maxPrice: 1000000,
    propertyTypes: ["house", "condo"]
)

let listings = try await client.fetchListings(parameters: parameters)
let properties = listings.map { client.normalizeToProperty($0) }
```

### 3. MockMLSAPIClient
Mock implementation for testing and development:
- Provides sample MLS listings without requiring API access
- Supports filtering by price, property type
- Simulates network delay
- Can be configured to simulate failures

**Usage:**
```swift
let mockClient = MockMLSAPIClient()

// Fetch all mock listings
let listings = try await mockClient.fetchListings(parameters: SearchParameters())

// Simulate failure
mockClient.shouldFail = true
```

### 4. ExternalDataValidator
Utility for validating and sanitizing external listing data:
- Validates required fields (address, price, location, property type)
- Validates coordinate ranges
- Sanitizes strings (removes control characters, trims whitespace)
- Validates image URLs
- Validates numeric specifications

**Usage:**
```swift
let listing = ExternalListing(id: "123", rawData: externalData)

// Validate the listing
try ExternalDataValidator.validate(listing)

// Sanitize individual fields
let cleanString = ExternalDataValidator.sanitizeString(dirtyString)
let validURLs = ExternalDataValidator.sanitizeImageURLs(urlStrings)
```

## Data Normalization

The normalization process converts external listing formats to the internal Property model:

1. **Address Extraction**: Maps various address field names (street, city, state, zip_code/zipCode)
2. **Price Conversion**: Handles Double, Int, and String price formats
3. **Property Type Mapping**: Normalizes type strings to PropertyType enum
4. **Specifications**: Extracts bedrooms, bathrooms, square feet, lot size, year built
5. **Images**: Validates and converts image URLs to PropertyImage objects
6. **Location**: Extracts and validates latitude/longitude coordinates
7. **Source Attribution**: All external listings are marked with their source (.mls, .zillow, etc.)

## Requirements Coverage

This implementation satisfies the following requirements:

- **Requirement 8.1**: Data normalization from external formats to Property model
- **Requirement 8.2**: Source attribution for all external listings
- **Requirement 8.3**: Data validation and sanitization for external data

## Testing

Comprehensive tests are provided in `BackendIntegrationTests.swift`:

- Fetching listings with various filters
- Data normalization correctness
- Source attribution verification
- Data validation (valid and invalid cases)
- String sanitization
- Image URL validation

All tests pass successfully.

## Future Extensions

To add support for additional external APIs (Zillow, Realtor.com, etc.):

1. Create a new class implementing `ExternalListingAPIProtocol`
2. Implement the `fetchListings` method for the specific API
3. Implement the `normalizeToProperty` method to map their data format
4. Update the `ListingSource` enum if needed
5. Add tests for the new integration

Example:
```swift
@available(iOS 15.0, macOS 12.0, *)
class ZillowAPIClient: ExternalListingAPIProtocol {
    func fetchListings(parameters: SearchParameters) async throws -> [ExternalListing] {
        // Zillow-specific implementation
    }
    
    func normalizeToProperty(_ listing: ExternalListing) -> Property {
        // Zillow-specific normalization
    }
}
```
