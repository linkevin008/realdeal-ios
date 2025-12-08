import Foundation

// MARK: - Favorite Validation

extension Favorite {
    func validate() throws {
        try validateUserId()
        try validatePropertyId()
        try validateSavedAt()
    }
    
    func validateUserId() throws {
        // Validate userId (must not be empty)
        guard !userId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError.missingRequiredField("userId")
        }
    }
    
    func validatePropertyId() throws {
        // Validate propertyId (must not be empty)
        guard !propertyId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError.missingRequiredField("propertyId")
        }
    }
    
    func validateSavedAt() throws {
        // Validate savedAt date (should not be in the future)
        guard savedAt <= Date() else {
            throw ValidationError.invalidFormat("savedAt")
        }
    }
}
