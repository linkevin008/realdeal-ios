import Foundation

// MARK: - PropertyFilters Validation

extension PropertyFilters {
    /// Validates the property filters data
    func validate() throws {
        // Validate price range if both min and max are set
        if let min = priceMin, let max = priceMax {
            guard min <= max else {
                throw ValidationError.invalidPriceRange
            }
            guard min >= 0 else {
                throw ValidationError.invalidPriceRange
            }
        }
        
        // Validate individual price values
        if let min = priceMin {
            guard min >= 0 else {
                throw ValidationError.invalidPriceRange
            }
        }
        
        if let max = priceMax {
            guard max >= 0 else {
                throw ValidationError.invalidPriceRange
            }
        }
        
        // Validate minimum bedrooms
        if let minBedrooms = minBedrooms {
            guard minBedrooms >= 0 else {
                throw ValidationError.invalidFormat("minBedrooms")
            }
        }
        
        // Validate minimum bathrooms
        if let minBathrooms = minBathrooms {
            guard minBathrooms >= 0 else {
                throw ValidationError.invalidFormat("minBathrooms")
            }
        }
        
        // Validate location radius if present
        if let locationRadius = locationRadius {
            try locationRadius.validate()
        }
    }
}

extension LocationRadius {
    func validate() throws {
        // Validate center coordinates
        try center.validate()
        
        // Validate radius (must be positive)
        guard radiusInMiles > 0 else {
            throw ValidationError.invalidLocation
        }
        
        // Reasonable upper limit for radius (e.g., 1000 miles)
        guard radiusInMiles <= 1000 else {
            throw ValidationError.invalidLocation
        }
    }
}
