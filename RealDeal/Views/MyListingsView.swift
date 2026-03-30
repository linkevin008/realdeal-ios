import SwiftUI

/// View displaying seller's property listings
@available(iOS 15.0, macOS 12.0, *)
struct MyListingsView: View {
    @StateObject var viewModel: MyListingsViewModel
    @State private var showCreateProperty = false
    @State private var selectedProperty: Property?
    @State private var propertyToDelete: Property?
    @State private var showDeleteAlert = false
    
    var body: some View {
        NavigationView {
            VStack {
                // Status filter
                if !viewModel.properties.isEmpty {
                    statusFilterView
                }
                
                // Property list
                if viewModel.isLoading && viewModel.properties.isEmpty {
                    ProgressView()
                        .scaleEffect(1.5)
                } else if viewModel.properties.isEmpty {
                    emptyStateView
                } else {
                    propertyListView
                }
                
                // Error message
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding()
                }
            }
            .navigationTitle("My Listings")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button(action: {
                        showCreateProperty = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showCreateProperty) {
                PropertyCreationView(
                    viewModel: PropertyCreationViewModel(
                        service: viewModel.service,
                        currentUserId: viewModel.currentUserId
                    )
                )
            }
            .sheet(item: $selectedProperty) { property in
                PropertyCreationView(
                    viewModel: PropertyCreationViewModel(
                        service: viewModel.service,
                        currentUserId: viewModel.currentUserId,
                        property: property
                    )
                )
            }
            .alert("Delete Property", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) {
                    propertyToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    if let property = propertyToDelete {
                        Task {
                            await viewModel.deleteProperty(property)
                            propertyToDelete = nil
                        }
                    }
                }
            } message: {
                Text("Are you sure you want to delete this property listing? This action cannot be undone.")
            }
            .task {
                await viewModel.loadProperties()
            }
            .refreshable {
                await viewModel.loadProperties()
            }
        }
    }
    
    // MARK: - Subviews
    
    private var statusFilterView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                FilterChip(
                    title: "All (\(viewModel.properties.count))",
                    isSelected: viewModel.selectedStatus == nil
                ) {
                    viewModel.selectedStatus = nil
                }
                
                FilterChip(
                    title: "Active (\(viewModel.activeCount))",
                    isSelected: viewModel.selectedStatus == .active
                ) {
                    viewModel.selectedStatus = .active
                }
                
                FilterChip(
                    title: "Pending (\(viewModel.pendingCount))",
                    isSelected: viewModel.selectedStatus == .pending
                ) {
                    viewModel.selectedStatus = .pending
                }
                
                FilterChip(
                    title: "Sold (\(viewModel.soldCount))",
                    isSelected: viewModel.selectedStatus == .sold
                ) {
                    viewModel.selectedStatus = .sold
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "house.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Listings Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Create your first property listing to get started")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: {
                showCreateProperty = true
            }) {
                Text("Create Listing")
                    .fontWeight(.semibold)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding()
    }
    
    private var propertyListView: some View {
        List {
            ForEach(viewModel.filteredProperties) { property in
                PropertyListingCard(property: property)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedProperty = property
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            propertyToDelete = property
                            showDeleteAlert = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                        
                        Button {
                            selectedProperty = property
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }
                        .tint(.blue)
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: false) {
                        if property.status != .sold {
                            Button {
                                Task {
                                    await viewModel.updatePropertyStatus(property, status: .sold)
                                }
                            } label: {
                                Label("Mark Sold", systemImage: "checkmark.circle")
                            }
                            .tint(.green)
                        }
                        
                        if property.status != .active {
                            Button {
                                Task {
                                    await viewModel.updatePropertyStatus(property, status: .active)
                                }
                            } label: {
                                Label("Mark Active", systemImage: "arrow.clockwise")
                            }
                            .tint(.orange)
                        }
                    }
            }
        }
        .listStyle(.plain)
    }
}

// MARK: - Supporting Views

@available(iOS 15.0, macOS 12.0, *)
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(20)
        }
    }
}

@available(iOS 15.0, macOS 12.0, *)
struct PropertyListingCard: View {
    let property: Property
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(property.address.street)
                        .font(.headline)
                    
                    Text("\(property.address.city), \(property.address.province)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(CurrencyFormatter.format(
                        property.price,
                        storageCurrency: property.currency,
                        displayCurrency: DisplayCurrencyPreference.shared.displayCurrency
                    ))
                        .font(.headline)
                        .foregroundColor(.blue)
                    
                    StatusBadge(status: property.status)
                }
            }
            
            if let bedrooms = property.specifications.bedrooms,
               let bathrooms = property.specifications.bathrooms {
                HStack(spacing: 16) {
                    Label("\(bedrooms) bed", systemImage: "bed.double.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Label("\(String(format: "%.1f", bathrooms)) bath", systemImage: "shower.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let sqft = property.specifications.squareFeet {
                        Label("\(sqft) sqft", systemImage: "square.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Text("Created: \(formattedDate(property.createdAt))")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}

@available(iOS 15.0, macOS 12.0, *)
struct StatusBadge: View {
    let status: PropertyStatus
    
    var body: some View {
        Text(status.rawValue.capitalized)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(backgroundColor)
            .foregroundColor(.white)
            .cornerRadius(4)
    }
    
    private var backgroundColor: Color {
        switch status {
        case .active:
            return .green
        case .pending:
            return .orange
        case .sold:
            return .gray
        case .deleted:
            return .red
        }
    }
}

// MARK: - Preview

@available(iOS 15.0, macOS 12.0, *)
struct MyListingsView_Previews: PreviewProvider {
    static var previews: some View {
        let mockService = PropertyListingService(
            repository: MockPropertyRepository(),
            imageStorage: MockImageStorage()
        )
        
        MyListingsView(
            viewModel: MyListingsViewModel(
                service: mockService,
                currentUserId: "user123"
            )
        )
    }
}
