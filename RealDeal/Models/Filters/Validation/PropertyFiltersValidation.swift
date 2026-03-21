import Foundation

// MARK: - PropertyFilters Validation

extension PropertyFilters {
    func validate() throws {
        try validatePriceRange()
        try validateMinBedrooms()
        try validateNonZeroBathrooms()
        try validateSearchRadius()
    }

    /// Validates that price values are positive and, when both are set, min does not exceed max.
    func validatePriceRange() throws {
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

        if let min = priceMin, let max = priceMax {
            guard min <= max else {
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
        try validateRadius()
    }

    /// Validates that the radius is positive and does not exceed the maximum allowed value.
    func validateRadius() throws {
        guard radiusInMiles > 0 else {
            throw ValidationError.invalidLocation
        }
        guard radiusInMiles <= 1000 else {
            throw ValidationError.invalidLocation
        }
    }
}
