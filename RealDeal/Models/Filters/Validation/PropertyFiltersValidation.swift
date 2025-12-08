import Foundation

// MARK: - PropertyFilters Validation

extension PropertyFilters {
    func validate() throws {
        try validatePriceRange()
        try validateNonZeroPriceRange()
        try validateMinBedrooms()
        try validateNonZeroBathrooms()
        try validateSearchRadius()
    }
    
    func validatePriceRange() throws {
        // If both min and max are set, validate 0 < min <= max
        if let min = priceMin, let max = priceMax {
            guard min <= max else {
                throw ValidationError.invalidPriceRange
            }
            guard min > 0 else {
                throw ValidationError.invalidPriceRange
            }
        }
    }
    
    func validateNonZeroPriceRange() throws {
        if let min = priceMin {
            guard min > 0 else {
                throw ValidationError.invalidPriceRange
            }
        }
        
        if let max = priceMax {
            guard max > 0 else {
                throw ValidationError.invalidPriceRange
            }
        }
    }
    
    func validateMinBedrooms() throws {
        if let minBedrooms = minBedrooms {
            guard minBedrooms >= 0 else {
                throw ValidationError.invalidFormat("minBedrooms")
            }
        }
    }
    
    func validateNonZeroBathrooms() throws {
        if let minBathrooms = minBathrooms {
            guard minBathrooms > 0 else {
                throw ValidationError.invalidFormat("minBathrooms")
            }
        }
    }
    
    func validateSearchRadius() throws {
        if let locationRadius = locationRadius {
            try locationRadius.validate()
        }
    }
}

extension LocationRadius {
    func validate() throws {
        try center.validate()
        try validateNonZeroRadius()
        try validateRadiusLimit()
    }
    
    func validateNonZeroRadius() throws {
        guard radiusInMiles > 0 else {
            throw ValidationError.invalidLocation
        }
    }
    
    func validateRadiusLimit() throws {
        guard radiusInMiles <= 1000 else {
            throw ValidationError.invalidLocation
        }
    }
}
