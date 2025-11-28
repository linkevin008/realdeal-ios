# Real Estate Listings iOS App

## Project Structure

```
RealEstateListings/
├── Models/                      # Data models
│   ├── Property.swift
│   ├── UserProfile.swift
│   ├── PropertyFilters.swift
│   └── Favorite.swift
├── Views/                       # SwiftUI views
├── ViewModels/                  # View models (MVVM pattern)
├── Repositories/                # Repository protocols
│   ├── PropertyRepositoryProtocol.swift
│   ├── UserProfileRepositoryProtocol.swift
│   └── FavoritesRepositoryProtocol.swift
├── Services/                    # Service layer protocols
│   ├── RemoteDataSourceProtocol.swift
│   ├── LocalDataSourceProtocol.swift
│   ├── AuthenticationServiceProtocol.swift
│   ├── LocationServiceProtocol.swift
│   └── ExternalListingAPIProtocol.swift
├── Utilities/                   # Utility classes
│   └── PersistenceController.swift
├── RealEstateListings.xcdatamodeld/  # Core Data model
├── Assets.xcassets/             # Asset catalog
├── Info.plist                   # App configuration
├── RealEstateListingsApp.swift  # App entry point
└── ContentView.swift            # Main view

RealEstateListingsTests/         # Test target
└── RealEstateListingsTests.swift
```

## Architecture

- **MVVM Pattern**: Model-View-ViewModel architecture
- **Repository Pattern**: Abstracts data sources
- **Protocol-Oriented**: All services and repositories use protocols for flexibility
- **Core Data**: Local persistence and caching
- **SwiftUI**: Modern declarative UI framework

## Dependencies

- **SwiftCheck**: Property-based testing framework (v0.12.0+)

## Core Data Stack

The app uses Core Data for local persistence with:
- Automatic merging of changes from parent context
- Property object trump merge policy
- In-memory store option for testing

## Testing

Property-based tests use SwiftCheck and should:
- Run minimum 100 iterations
- Tag tests with format: `// Feature: real-estate-listings, Property X: [description]`
- Reference specific correctness properties from design document
