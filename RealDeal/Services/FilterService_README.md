# FilterService

## Overview

The `FilterService` provides a centralized way to apply multiple filter criteria to property listings using AND logic. All filters must be satisfied for a property to be included in the results.

## Usage

```swift
let filterService = FilterService()

// Create filter criteria
let filters = PropertyFilters(
    priceMin: 300000,
    priceMax: 600000,
    propertyTypes: [.house, .condo],
    locationRadius: LocationRadius(
        center: Coordinate(latitude: 37.7749, longitude: -122.4194),
        radiusInMiles: 10.0
    ),
    minBedrooms: 2,
    minBathrooms: 1.5
)

// Apply filters to property collection
let filteredProperties = try filterService.applyFilters(properties, filters: filters)
```

## Filter Criteria

### Price Range
- `priceMin`: Minimum price (inclusive)
- `priceMax`: Maximum price (inclusive)
- Both, either, or neither can be specified

### Property Types
- `propertyTypes`: Set of property types to include
- Options: `.house`, `.apartment`, `.condo`, `.land`, `.commercial`
- If empty or nil, all types are included

### Location Radius
- `locationRadius`: Filter by distance from a center point
- Requires center coordinate and radius in miles
- Uses precise Haversine distance calculation

### Specifications
- `minBedrooms`: Minimum number of bedrooms
- `minBathrooms`: Minimum number of bathrooms
- Properties without these specifications are excluded

### Source
- `sources`: Set of listing sources to include
- Options: `.userGenerated`, `.mls`, `.zillow`, `.realtor`, `.other`

### Seller
- `sellerId`: Filter by specific seller ID

## Filter Combination Logic

All filters use AND logic - properties must satisfy ALL specified criteria:

```swift
// This will only return properties that are:
// - Between $300k and $600k AND
// - Either house or condo AND
// - Within 10 miles of SF AND
// - Have at least 2 bedrooms AND
// - Have at least 1.5 bathrooms
let filters = PropertyFilters(
    priceMin: 300000,
    priceMax: 600000,
    propertyTypes: [.house, .condo],
    locationRadius: LocationRadius(
        center: Coordinate(latitude: 37.7749, longitude: -122.4194),
        radiusInMiles: 10.0
    ),
    minBedrooms: 2,
    minBathrooms: 1.5
)
```

## Validation

Filters are automatically validated before being applied:
- Price range must be valid (min ≤ max, both ≥ 0)
- Location radius must be positive and ≤ 1000 miles
- Coordinates must be valid (latitude: -90 to 90, longitude: -180 to 180)

Invalid filters will throw a `ValidationError`.

## Integration with Repository

The `FilterService` can be used alongside the repository pattern:

```swift
// Fetch properties from repository (with or without filters)
let properties = try await propertyRepository.fetchProperties(filters: nil)

// Apply additional client-side filtering
let filterService = FilterService()
let refinedFilters = PropertyFilters(minBedrooms: 3)
let filteredProperties = try filterService.applyFilters(properties, filters: refinedFilters)
```

## Testing

Comprehensive unit tests are available in `FilterServiceTests.swift` covering:
- Individual filter criteria
- Multiple filter combinations
- Edge cases (empty arrays, missing specifications)
- Validation errors
