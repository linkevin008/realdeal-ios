import Foundation

// MARK: - Favorite Validation

extension Favorite {
    /// Validates the favorite data
    func validate() throws {
        // Validate userId (must not be empty)
        guard !userId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError.missingRequiredField("userId")
        }
        
        // Validate propertyId (must not be empty)
        guard !propertyId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ValidationError.missingRequiredField("propertyId")
        }
        
        // Validate savedAt date (should not be in the future)
        guard savedAt <= Date() else {
            throw ValidationError.invalidFormat("savedAt")
        }
    }
}
