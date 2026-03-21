import SwiftUI

/// Filter UI for property search
@available(iOS 15.0, macOS 12.0, *)
struct PropertyFiltersView: View {
    @ObservedObject var viewModel: PropertyListViewModel
    @Environment(\.dismiss) private var dismiss
    
    // Local state for filter controls
    @State private var minPrice: Double = 0
    @State private var maxPrice: Double = 5_000_000
    @State private var selectedTypes: Set<PropertyType> = []
    @State private var locationRadius: Double = 25
    @State private var useLocationFilter: Bool = false
    @State private var minBedrooms: Int = 0
    @State private var minBathrooms: Double = 0
    
    var body: some View {
        NavigationView {
            Form {
                // Price Range Section
                Section(header: Text("Price Range")) {
                    let priceFormatter = NumberFormatter()
                    
                    LabeledSlider(
                        label: "Minimum Price",
                        range: 0...5_000_000,
                        value: $minPrice,
                        step: 50_000,
                        formatter: {
                            let formatter = NumberFormatter()
                            formatter.numberStyle = .currency
                            formatter.maximumFractionDigits = 0
                            return formatter
                        }()
                    )
                    
                    LabeledSlider(
                        label: "Maximum Price",
                        range: 0...5_000_000,
                        value: $maxPrice,
                        step: 50_000,
                        formatter: {
                            let formatter = NumberFormatter()
                            formatter.numberStyle = .currency
                            formatter.maximumFractionDigits = 0
                            return formatter
                        }()
                    )
                }
                
                // Property Type Section
                Section(header: Text("Property Type")) {
                    CheckboxGroup(
                        options: PropertyType.allCases.map { ($0, $0.rawValue.capitalized) },
                        selection: $selectedTypes
                    )
                }
                
                // Location Section
                Section(header: Text("Location")) {
                    RealDealToggle(
                        label: "Filter by location",
                        description: "Use your current location to filter nearby properties",
                        isOn: $useLocationFilter
                    )
                    
                    if useLocationFilter {
                        LabeledSlider(
                            label: "Search Radius",
                            range: 1...100,
                            value: $locationRadius,
                            step: 1,
                            formatter: {
                                let formatter = NumberFormatter()
                                formatter.numberStyle = .none
                                formatter.positiveSuffix = " miles"
                                return formatter
                            }()
                        )
                    }
                }
                
                // Specifications Section
                Section(header: Text("Specifications")) {
                    Stepper("Min Bedrooms: \(minBedrooms)", value: $minBedrooms, in: 0...10)
                    
                    Stepper("Min Bathrooms: \(String(format: "%.1f", minBathrooms))", 
                            value: $minBathrooms, 
                            in: 0...10, 
                            step: 0.5)
                }
                
                // Action Buttons
                Section {
                    Button(action: applyFilters) {
                        Text("Apply Filters")
                            .fontWeight(.semibold)
                    }
                    .primaryButtonStyle(isLoading: viewModel.isLoading)
                    
                    Button(action: clearFilters) {
                        Text("Clear All Filters")
                    }
                    .secondaryButtonStyle()
                }
            }
            .navigationTitle("Filters")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadCurrentFilters()
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func loadCurrentFilters() {
        // Load current filter values from view model
        if let min = viewModel.filters.priceMin {
            minPrice = Double(truncating: min as NSDecimalNumber)
        }
        if let max = viewModel.filters.priceMax {
            maxPrice = Double(truncating: max as NSDecimalNumber)
        }
        if let types = viewModel.filters.propertyTypes {
            selectedTypes = types
        }
        if let radius = viewModel.filters.locationRadius {
            locationRadius = radius.radiusInMiles
            useLocationFilter = true
        }
        if let beds = viewModel.filters.minBedrooms {
            minBedrooms = beds
        }
        if let baths = viewModel.filters.minBathrooms {
            minBathrooms = baths
        }
    }
    
    private func applyFilters() {
        // Update view model filters
        viewModel.updatePriceRange(
            min: minPrice > 0 ? Decimal(minPrice) : nil,
            max: maxPrice < 5_000_000 ? Decimal(maxPrice) : nil
        )
        
        viewModel.updatePropertyTypes(selectedTypes)
        
        if useLocationFilter {
            // TODO: replace with the user's actual device location
            let defaultCenter = Coordinate(latitude: 49.2827, longitude: -123.1207) // Vancouver
            viewModel.updateLocationRadius(center: defaultCenter, radiusInMiles: locationRadius)
        } else {
            viewModel.updateLocationRadius(center: nil, radiusInMiles: nil)
        }
        
        viewModel.filters.minBedrooms = minBedrooms > 0 ? minBedrooms : nil
        viewModel.filters.minBathrooms = minBathrooms > 0 ? minBathrooms : nil
        
        // Apply filters
        Task {
            await viewModel.applyFilters()
            dismiss()
        }
    }
    
    private func clearFilters() {
        // Reset all filter values
        minPrice = 0
        maxPrice = 5_000_000
        selectedTypes = []
        locationRadius = 25
        useLocationFilter = false
        minBedrooms = 0
        minBathrooms = 0
        
        // Clear filters in view model
        Task {
            await viewModel.clearFilters()
            dismiss()
        }
    }
    
    private func formatPrice(_ price: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "CAD"
        formatter.locale = Locale(identifier: "en_CA")
        formatter.maximumFractionDigits = 0
        return formatter.string(from: price as NSDecimalNumber) ?? "$0"
    }
}
