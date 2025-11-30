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
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Min: \(formatPrice(Decimal(minPrice)))")
                            Spacer()
                            Text("Max: \(formatPrice(Decimal(maxPrice)))")
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        
                        VStack(spacing: 16) {
                            VStack(alignment: .leading) {
                                Text("Minimum Price")
                                    .font(.caption)
                                Slider(value: $minPrice, in: 0...5_000_000, step: 50_000)
                            }
                            
                            VStack(alignment: .leading) {
                                Text("Maximum Price")
                                    .font(.caption)
                                Slider(value: $maxPrice, in: 0...5_000_000, step: 50_000)
                            }
                        }
                    }
                }
                
                // Property Type Section
                Section(header: Text("Property Type")) {
                    ForEach(PropertyType.allCases, id: \.self) { type in
                        Toggle(type.rawValue.capitalized, isOn: Binding(
                            get: { selectedTypes.contains(type) },
                            set: { isSelected in
                                if isSelected {
                                    selectedTypes.insert(type)
                                } else {
                                    selectedTypes.remove(type)
                                }
                            }
                        ))
                    }
                }
                
                // Location Section
                Section(header: Text("Location")) {
                    Toggle("Filter by location", isOn: $useLocationFilter)
                    
                    if useLocationFilter {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Radius: \(Int(locationRadius)) miles")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            Slider(value: $locationRadius, in: 1...100, step: 1)
                        }
                        
                        Text("Location filter will use your current location")
                            .font(.caption)
                            .foregroundColor(.secondary)
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
                        HStack {
                            Spacer()
                            Text("Apply Filters")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button(action: clearFilters) {
                        HStack {
                            Spacer()
                            Text("Clear All Filters")
                            Spacer()
                        }
                    }
                    .foregroundColor(.red)
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
            // For now, use a default location (San Francisco)
            // In a real app, you'd get the user's actual location
            let defaultCenter = Coordinate(latitude: 37.7749, longitude: -122.4194)
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
        formatter.currencyCode = "USD"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: price as NSDecimalNumber) ?? "$0"
    }
}
