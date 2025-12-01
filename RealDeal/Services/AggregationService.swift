import Foundation

/// Configuration for conflict resolution when multiple sources provide the same property
struct ConflictResolutionConfig {
    /// Priority order for data sources (higher priority = more trusted)
    var sourcePriority: [ListingSource: Int]
    
    /// Default configuration prioritizing user-generated content over external sources
    static let `default` = ConflictResolutionConfig(
        sourcePriority: [
            .userGenerated: 100,
            .mls: 80,
            .zillow: 60,
            .realtor: 60,
            .other: 40
        ]
    )
    
    /// Get priority for a given source
    func priority(for source: ListingSource) -> Int {
        return sourcePriority[source] ?? 0
    }
}

/// Service for aggregating property listings from multiple data sources
/// Handles duplicate detection, conflict resolution, and parallel fetching
@available(iOS 15.0, macOS 12.0, *)
class AggregationService {
    private let localDataSource: LocalDataSourceProtocol
    private let externalAPIs: [ExternalListingAPIProtocol]
    private let conflictResolution: ConflictResolutionConfig
    private let networkMonitor: NetworkMonitor
    
    init(
        localDataSource: LocalDataSourceProtocol,
        externalAPIs: [ExternalListingAPIProtocol] = [],
        conflictResolution: ConflictResolutionConfig = .default,
        networkMonitor: NetworkMonitor = .shared
    ) {
        self.localDataSource = localDataSource
        self.externalAPIs = externalAPIs
        self.conflictResolution = conflictResolution
        self.networkMonitor = networkMonitor
    }
    
    /// Fetch and aggregate listings from all configured sources
    /// - Parameter parameters: Search parameters to apply to external APIs
    /// - Returns: Deduplicated and merged property listings
    func fetchAggregatedListings(parameters: SearchParameters) async throws -> [Property] {
        var allProperties: [Property] = []
        var errors: [ListingSource: Error] = [:]
        
        // Fetch user-generated listings from local data source
        do {
            let localProperties = try await fetchLocalListings(parameters: parameters)
            allProperties.append(contentsOf: localProperties)
        } catch {
            errors[.userGenerated] = error
            // Continue even if local fetch fails
        }
        
        // Fetch from external APIs in parallel if connected
        if networkMonitor.isConnected && !externalAPIs.isEmpty {
            let externalResults = await fetchExternalListingsInParallel(parameters: parameters)
            
            for result in externalResults {
                switch result.result {
                case .success(let properties):
                    allProperties.append(contentsOf: properties)
                case .failure(let error):
                    errors[result.source] = error
                    // Continue with other sources even if one fails
                }
            }
        }
        
        // Remove duplicates and resolve conflicts
        let deduplicatedProperties = deduplicateAndResolveConflicts(allProperties)
        
        // Cache the aggregated results locally
        if !deduplicatedProperties.isEmpty {
            try? await localDataSource.saveProperties(deduplicatedProperties)
        }
        
        return deduplicatedProperties
    }
    
    // MARK: - Private Methods
    
    /// Fetch user-generated listings from local data source
    private func fetchLocalListings(parameters: SearchParameters) async throws -> [Property] {
        // Convert SearchParameters to PropertyFilters
        let filters = convertToPropertyFilters(parameters)
        return try await localDataSource.fetchProperties(filters: filters)
    }
    
    /// Fetch listings from all external APIs in parallel
    private func fetchExternalListingsInParallel(parameters: SearchParameters) async -> [ExternalFetchResult] {
        await withTaskGroup(of: ExternalFetchResult.self) { group in
            // Add a task for each external API
            for api in externalAPIs {
                group.addTask {
                    await self.fetchFromExternalAPI(api: api, parameters: parameters)
                }
            }
            
            // Collect all results
            var results: [ExternalFetchResult] = []
            for await result in group {
                results.append(result)
            }
            return results
        }
    }
    
    /// Fetch listings from a single external API with error handling
    private func fetchFromExternalAPI(api: ExternalListingAPIProtocol, parameters: SearchParameters) async -> ExternalFetchResult {
        do {
            let externalListings = try await api.fetchListings(parameters: parameters)
            let properties = externalListings.map { api.normalizeToProperty($0) }
            
            // Determine source from the first property (all should have same source)
            let source = properties.first?.source ?? .other
            
            return ExternalFetchResult(source: source, result: .success(properties))
        } catch {
            // Determine source - we'll use a heuristic based on the API type
            let source = determineSource(for: api)
            return ExternalFetchResult(source: source, result: .failure(error))
        }
    }
    
    /// Determine the source type for an API client
    private func determineSource(for api: ExternalListingAPIProtocol) -> ListingSource {
        let typeName = String(describing: type(of: api))
        if typeName.contains("MLS") {
            return .mls
        } else if typeName.contains("Zillow") {
            return .zillow
        } else if typeName.contains("Realtor") {
            return .realtor
        }
        return .other
    }
    
    /// Remove duplicate listings and resolve conflicts based on configured priorities
    private func deduplicateAndResolveConflicts(_ properties: [Property]) -> [Property] {
        // Group properties by their unique identifier (address + approximate location)
        var propertyGroups: [String: [Property]] = [:]
        
        for property in properties {
            let key = generateDuplicateKey(for: property)
            propertyGroups[key, default: []].append(property)
        }
        
        // For each group, select the best property based on conflict resolution rules
        var deduplicatedProperties: [Property] = []
        
        for (_, group) in propertyGroups {
            if group.count == 1 {
                // No duplicates, add directly
                deduplicatedProperties.append(group[0])
            } else {
                // Multiple properties with same key - resolve conflict
                let resolved = resolveConflict(among: group)
                deduplicatedProperties.append(resolved)
            }
        }
        
        return deduplicatedProperties
    }
    
    /// Generate a key for duplicate detection based on address and location
    private func generateDuplicateKey(for property: Property) -> String {
        // Normalize address components for comparison
        let normalizedStreet = property.address.street.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedCity = property.address.city.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedState = property.address.state.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedZip = property.address.zipCode.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Round coordinates to 4 decimal places (~11 meters precision)
        let roundedLat = String(format: "%.4f", property.location.latitude)
        let roundedLon = String(format: "%.4f", property.location.longitude)
        
        return "\(normalizedStreet)|\(normalizedCity)|\(normalizedState)|\(normalizedZip)|\(roundedLat)|\(roundedLon)"
    }
    
    /// Resolve conflict among duplicate properties by selecting the highest priority source
    private func resolveConflict(among properties: [Property]) -> Property {
        // Sort by priority (highest first)
        let sorted = properties.sorted { property1, property2 in
            let priority1 = conflictResolution.priority(for: property1.source)
            let priority2 = conflictResolution.priority(for: property2.source)
            
            if priority1 != priority2 {
                return priority1 > priority2
            }
            
            // If same priority, prefer more recently updated
            return property1.updatedAt > property2.updatedAt
        }
        
        // Return the highest priority property
        return sorted[0]
    }
    
    /// Convert SearchParameters to PropertyFilters for local data source
    private func convertToPropertyFilters(_ parameters: SearchParameters) -> PropertyFilters {
        var filters = PropertyFilters()
        
        // Convert price range
        filters.priceMin = parameters.minPrice
        filters.priceMax = parameters.maxPrice
        
        // Convert property types
        if let propertyTypes = parameters.propertyTypes {
            filters.propertyTypes = Set(propertyTypes.compactMap { PropertyType(rawValue: $0.lowercased()) })
        }
        
        // Convert location radius
        if let location = parameters.location, let radius = parameters.radius {
            // Parse location string (assuming format like "lat,lon" or city name)
            // For simplicity, we'll skip complex geocoding here
            // In production, you'd use a geocoding service
            filters.locationRadius = nil // Would need geocoding to convert location string to coordinates
        }
        
        return filters
    }
}

// MARK: - Supporting Types

/// Result of fetching from an external API
private struct ExternalFetchResult {
    let source: ListingSource
    let result: Result<[Property], Error>
}
