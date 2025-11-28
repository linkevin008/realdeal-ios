# Core Data Migration Strategy

## Overview

The Core Data persistence layer is configured with automatic migration support to handle schema changes as the application evolves.

## Current Configuration

### Automatic Migration
- **Lightweight Migration**: Enabled via `shouldMigrateStoreAutomatically = true`
- **Automatic Mapping**: Enabled via `shouldInferMappingModelAutomatically = true`
- **Version Tracking**: Persistent history tracking enabled for future sync capabilities

### Model Version
- Current version: 1.0 (defined in `userDefinedModelVersionIdentifier`)
- Model file: `RealEstateListings.xcdatamodeld`

## Migration Process

### Lightweight Migrations (Automatic)
The following changes can be handled automatically without custom migration code:
- Adding new entities
- Adding new attributes with default values
- Removing attributes
- Renaming entities or attributes (using renaming identifiers)
- Changing attribute types (compatible types only)

### Heavy Migrations (Manual)
For complex schema changes, you'll need to:
1. Create a new model version in Xcode
2. Set the new version as current
3. Create a mapping model if needed
4. Test migration with production-like data

## Indexes

The following indexes are configured for optimal query performance:

### PropertyEntity
- `bySellerIndex`: Index on `sellerId` for seller listing queries
- `byStatusIndex`: Index on `status` for filtering active/sold properties
- `byPriceIndex`: Index on `price` for price range queries
- `byLocationIndex`: Compound index on `latitude` and `longitude` for location-based queries

### UserProfileEntity
- `byEmailIndex`: Index on `email` for user lookup

### FavoriteEntity
- `byUserIndex`: Index on `userId` for fetching user favorites
- `byPropertyIndex`: Index on `propertyId` for property favorite lookups
- `byUserPropertyIndex`: Compound index for checking if a specific user favorited a property

## Uniqueness Constraints

All entities have uniqueness constraints on their `id` field to prevent duplicates.

## Recovery Strategy

If a migration fails:
1. The system logs the error
2. Attempts to delete the corrupted store
3. Recreates a fresh store
4. In production, this should trigger a data sync from the backend

## Testing Migrations

When adding new model versions:
1. Create test cases with data in the old schema
2. Run migration
3. Verify data integrity in the new schema
4. Test rollback scenarios if applicable

## Programmatic Model Creation

For testing and development environments where the .xcdatamodeld file may not be available (e.g., Swift Package Manager), the system includes a programmatic model creation fallback that creates the schema in code.
