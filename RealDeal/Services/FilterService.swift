import Foundation
import CoreLocation

/// Service for filtering property listings based on multiple criteria
/// Implements AND logic for combining multiple filters
@available(iOS 15.0, macOS 12.0, *)
class FilterService {
    
    // MARK: - Public Methods
    
    /// Apply filters to a collection of properties
    /// All filters are combined with AND logic - properties must match ALL criteria
    /// - Parameters:
    ///   - properties: The properties to filter
    ///   - filters: The filter criteria to apply
    /// - Returns: Properties that match all filter criteria
    func applyFilters(_ properties: [Property], filters: PropertyFilters?) throws -> [Property] {
        // If no filters provided, return all properties
        guard let filters = filters else {
            return properties
        }
        
        // Validate filters before applying
        try filters.validate()
        
        // Apply each filter criterion sequentially (AND logic)
        var filteredProperties = properties
        
        // Filter by price range
        filteredProperties = try applyPriceFilter(filteredProperties, filters: filters)
        
        // Filter by property types
        filteredProperties = applyPropertyTypeFilter(filteredProperties, filters: filters)
        
        // Filter by location radius
        filteredProperties = try applyLocationRadiusFilter(filteredProperties, filters: filters)
        
        // Filter by minimum bedrooms
        filteredProperties = applyMinBedroomsFilter(filteredProperties, filters: filters)
        
        // Filter by minimum bathrooms
        filteredProperties = applyMinBathroomsFilter(filteredProperties, filters: filters)
        
        // Filter by sources
        filteredProperties = applySourcesFilter(filteredProperties, filters: filters)
        
        // Filter by seller ID
        filteredProperties = applySellerIdFilter(filteredProperties, filters: filters)
        
        return filteredProperties
    }
    
    // MARK: - Private Filter Methods
    
    /// Apply price range filter
    private func applyPriceFilter(_ properties: [Property], filters: PropertyFilters) throws -> [Property] {
        let minPrice = filters.priceMin
        let maxPrice = filters.priceMax
        
        // If no price filters, return all
        guard minPrice != nil || maxPrice != nil else {
            return properties
        }
        
        return properties.filter { property in
            var matchesMin = true
            var matchesMax = true
            
            if let min = minPrice {
                matchesMin = property.price >= min
            }
            
            if let max = maxPrice {
                matchesMax = property.price <= max
            }
            
            return matchesMin && matchesMax
        }
    }
    
    /// Apply property type filter
    private func applyPropertyTypeFilter(_ properties: [Property], filters: PropertyFilters) -> [Property] {
        guard let types = filters.propertyTypes, !types.isEmpty else {
            return properties
        }
        
        return properties.filter { property in
            types.contains(property.propertyType)
        }
    }
    
    /// Apply location radius filter
    private func applyLocationRadiusFilter(_ properties: [Property], filters: PropertyFilters) throws -> [Property] {
        guard let locationRadius = filters.locationRadius else {
            return properties
        }
        
        let centerLocation = CLLocation(
            latitude: locationRadius.center.latitude,
            longitude: locationRadius.center.longitude
        )
        
        let radiusInMeters = locationRadius.radiusInMiles * 1609.34 // Convert miles to meters
        
        return properties.filter { property in
            let propertyLocation = CLLocation(
                latitude: property.location.latitude,
                longitude: property.location.longitude
            )
            
            let distance = centerLocation.distance(from: propertyLocation)
            return distance <= radiusInMeters
        }
    }
    
    /// Apply minimum bedrooms filter
    private func applyMinBedroomsFilter(_ properties: [Property], filters: PropertyFilters) -> [Property] {
        guard let minBedrooms = filters.minBedrooms else {
            return properties
        }
        
        return properties.filter { property in
            guard let bedrooms = property.specifications.bedrooms else {
                return false // Properties without bedroom info don't match
            }
            return bedrooms >= minBedrooms
        }
    }
    
    /// Apply minimum bathrooms filter
    private func applyMinBathroomsFilter(_ properties: [Property], filters: PropertyFilters) -> [Property] {
        guard let minBathrooms = filters.minBathrooms else {
            return properties
        }
        
        return properties.filter { property in
            guard let bathrooms = property.specifications.bathrooms else {
                return false // Properties without bathroom info don't match
            }
            return bathrooms >= minBathrooms
        }
    }
    
    /// Apply sources filter
    private func applySourcesFilter(_ properties: [Property], filters: PropertyFilters) -> [Property] {
        guard let sources = filters.sources, !sources.isEmpty else {
            return properties
        }
        
        return properties.filter { property in
            sources.contains(property.source)
        }
    }
    
    /// Apply seller ID filter
    private func applySellerIdFilter(_ properties: [Property], filters: PropertyFilters) -> [Property] {
        guard let sellerId = filters.sellerId else {
            return properties
        }
        
        return properties.filter { property in
            property.sellerId == sellerId
        }
    }
}
