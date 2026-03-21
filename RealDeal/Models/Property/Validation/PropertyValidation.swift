import Foundation

// MARK: - Property Validation

extension Property {
    func validate() throws {
        // Validate address
        try address.validate()
        
        // Validate price (must be positive)
        guard price > 0 else {
            throw ValidationError.invalidFormat("price must be greater than 0")
        }
        
        // Validate description (must not be empty)
        guard !description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError.missingRequiredField("description")
        }
        
        // Validate location coordinates
        try location.validate()
        
        // Validate specifications if present
        try specifications.validate()
    }
}

extension Address {
    func validate() throws {
        // Validate street
        guard !street.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError.missingRequiredField("address.street")
        }
        
        // Validate city
        guard !city.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError.missingRequiredField("address.city")
        }
        
        // Validate province
        guard !province.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError.missingRequiredField("address.province")
        }
        
        // Validate postal code (international format support)
        let postalPattern = "^[A-Za-z0-9][A-Za-z0-9\\s\\-]{1,8}[A-Za-z0-9]$"
        let postalPredicate = NSPredicate(format: "SELF MATCHES %@", postalPattern)
        guard postalPredicate.evaluate(with: postalCode) else {
            throw ValidationError.invalidFormat("Please enter a valid postal code")
        }
        
        // Validate country
        guard !country.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError.missingRequiredField("address.country")
        }
    }
}

extension Coordinate {
    func validate() throws {
        // Validate latitude range (-90 to 90)
        guard latitude >= -90 && latitude <= 90 else {
            throw ValidationError.invalidLocation
        }
        
        // Validate longitude range (-180 to 180)
        guard longitude >= -180 && longitude <= 180 else {
            throw ValidationError.invalidLocation
        }
    }
}

extension PropertySpecifications {
    func validate() throws {
        // Validate bedrooms if present
        if let bedrooms = bedrooms {
            guard bedrooms >= 0 else {
                throw ValidationError.invalidFormat("bedrooms must be non-negative")
            }
        }
        
        // Validate bathrooms if present
        if let bathrooms = bathrooms {
            guard bathrooms >= 0 else {
                throw ValidationError.invalidFormat("bathrooms must be non-negative")
            }
        }
        
        // Validate square feet if present
        if let squareFeet = squareFeet {
            guard squareFeet > 0 else {
                throw ValidationError.invalidFormat("squareFeet must be positive")
            }
        }
        
        // Validate lot size if present
        if let lotSize = lotSize {
            guard lotSize > 0 else {
                throw ValidationError.invalidFormat("lotSize must be positive")
            }
        }
        
        // Validate year built if present
        if let yearBuilt = yearBuilt {
            let currentYear = Calendar.current.component(.year, from: Date())
            guard yearBuilt > 1800 && yearBuilt <= currentYear + 1 else {
                throw ValidationError.invalidFormat("yearBuilt must be between 1800 and \(currentYear + 1)")
            }
        }
    }
}
