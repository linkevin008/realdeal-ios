# Core Data Persistence Layer

## Overview

This directory contains the Core Data persistence layer implementation for the Real Estate Listings application. The implementation provides local storage for properties, user profiles, and favorites with full CRUD operations.

## Components

### Core Data Model
- **File**: `RealEstateListings.xcdatamodeld/RealEstateListings.xcdatamodel/contents`
- **Entities**: PropertyEntity, UserProfileEntity, FavoriteEntity
- **Version**: 1.0

### Entity Classes
- `PropertyEntity+CoreDataClass.swift` / `PropertyEntity+CoreDataProperties.swift`
- `UserProfileEntity+CoreDataClass.swift` / `UserProfileEntity+CoreDataProperties.swift`
- `FavoriteEntity+CoreDataClass.swift` / `FavoriteEntity+CoreDataProperties.swift`

### Data Access Layer
- **LocalDataSource.swift**: Implements `LocalDataSourceProtocol` with full CRUD operations
- **PersistenceController.swift**: Manages Core Data stack initialization and configuration

## Features

### 1. Property Management
- Save and retrieve property listings
- Batch save operations for multiple properties
- Filter properties by:
  - Price range
  - Property type
  - Location radius (with Haversine distance calculation)
  - Minimum bedrooms/bathrooms
  - Listing source
  - Status (excludes deleted by default)
- Delete properties

### 2. User Profile Management
- Save and retrieve user profiles
- Update profile information
- Delete profiles
- Support for profile photos and visibility settings

### 3. Favorites Management
- Add properties to favorites
- Retrieve user's favorite properties
- Check if a property is favorited
- Remove favorites
- Cascade delete when properties are removed

### 4. Performance Optimizations
- **Indexes**: Configured on frequently queried fields
  - Property: sellerId, status, price, location (lat/lon)
  - UserProfile: email
  - Favorite: userId, propertyId, compound (userId + propertyId)
- **Uniqueness Constraints**: Prevent duplicate entries by ID
- **Batch Operations**: Efficient bulk saves
- **Location Filtering**: Two-stage filtering (bounding box + precise distance)

### 5. Migration Strategy
- Automatic lightweight migrations enabled
- Automatic mapping model inference
- Persistent history tracking for future sync
- Recovery mechanism for corrupted stores
- Programmatic model creation fallback for testing

## Usage Example

```swift
// Initialize
let persistenceController = PersistenceController.shared
let localDataSource = LocalDataSource(persistenceController: persistenceController)

// Save a property
let property = Property(
    address: Address(street: "123 Main St", city: "SF", state: "CA", zipCode: "94102", country: "USA"),
    price: 1000000,
    propertyType: .house,
    description: "Beautiful house",
    location: Coordinate(latitude: 37.7749, longitude: -122.4194)
)
try await localDataSource.saveProperty(property)

// Fetch with filters
let filters = PropertyFilters(priceMin: 500000, priceMax: 1500000)
let properties = try await localDataSource.fetchProperties(filters: filters)

// Save a favorite
let favorite = Favorite(userId: "user123", propertyId: property.id)
try await localDataSource.saveFavorite(favorite)
```

## Testing

Comprehensive test suite in `LocalDataSourceTests.swift` covers:
- Property CRUD operations
- User profile CRUD operations
- Favorites CRUD operations
- Filter functionality
- Data persistence and retrieval

All tests use in-memory stores for isolation and speed.

## Requirements Validated

This implementation satisfies the following requirements:
- **1.4**: Property listing persistence
- **2.3**: Property update persistence
- **7.1**: User profile creation and storage
- **7.2**: User profile updates

## Future Enhancements

- Background context for heavy operations
- Batch delete operations
- Query result caching
- Full-text search support
- Relationship management between entities
