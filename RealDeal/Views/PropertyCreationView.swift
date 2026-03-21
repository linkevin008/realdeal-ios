import SwiftUI

/// View for creating and editing property listings
@available(iOS 15.0, macOS 12.0, *)
struct PropertyCreationView: View {
    @StateObject var viewModel: PropertyCreationViewModel
    @Environment(\.dismiss) var dismiss
    
    @State private var showImagePicker = false
    @State private var showDeleteAlert = false
    
    var body: some View {
        NavigationView {
            Form {
                // Address Section
                Section(header: Text("Address")) {
                    TextField("Street Address", text: $viewModel.street)
                    if let error = viewModel.streetValidationError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    
                    TextField("City", text: $viewModel.city)
                    if let error = viewModel.cityValidationError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    
                    TextField("Province", text: $viewModel.province)
                    if let error = viewModel.provinceValidationError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    
                    TextField("Postal Code", text: $viewModel.postalCode)
                    if let error = viewModel.postalCodeValidationError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    
                    TextField("Country", text: $viewModel.country)
                }
                
                // Basic Information Section
                Section(header: Text("Basic Information")) {
                    TextField("Price", text: $viewModel.price)
                    if let error = viewModel.priceValidationError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    
                    Picker("Property Type", selection: $viewModel.propertyType) {
                        ForEach(PropertyType.allCases, id: \.self) { type in
                            Text(type.rawValue.capitalized).tag(type)
                        }
                    }
                    
                    TextEditor(text: $viewModel.propertyDescription)
                        .frame(minHeight: 100)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                        )
                    if let error = viewModel.descriptionValidationError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                
                // Specifications Section
                Section(header: Text("Specifications (Optional)")) {
                    TextField("Bedrooms", text: $viewModel.bedrooms)
                    
                    TextField("Bathrooms", text: $viewModel.bathrooms)
                    
                    TextField("Square Feet", text: $viewModel.squareFeet)
                    
                    TextField("Lot Size (acres)", text: $viewModel.lotSize)
                    
                    TextField("Year Built", text: $viewModel.yearBuilt)
                }
                
                // Location Section
                Section(header: Text("Location Coordinates")) {
                    TextField("Latitude", text: $viewModel.latitude)
                    
                    TextField("Longitude", text: $viewModel.longitude)
                    
                    if let error = viewModel.locationValidationError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                
                // Images Section
                Section(header: Text("Property Images")) {
                    Button(action: {
                        showImagePicker = true
                    }) {
                        HStack {
                            Image(systemName: "photo.on.rectangle.angled")
                            Text("Add Images")
                        }
                    }
                    
                    if !viewModel.propertyImages.isEmpty {
                        Text("\(viewModel.propertyImages.count) new image(s) selected")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Show existing images in edit mode
                    if let property = viewModel.property, !property.images.isEmpty {
                        ForEach(property.images) { image in
                            HStack {
                                Text("Existing image")
                                    .font(.caption)
                                Spacer()
                                Button("Delete") {
                                    Task {
                                        await viewModel.deleteExistingImage(image.url)
                                    }
                                }
                                .foregroundColor(.red)
                                .font(.caption)
                            }
                        }
                    }
                }
                
                // Status Section (Edit mode only)
                if viewModel.isEditMode {
                    Section(header: Text("Status")) {
                        Picker("Property Status", selection: $viewModel.propertyStatus) {
                            Text("Active").tag(PropertyStatus.active)
                            Text("Pending").tag(PropertyStatus.pending)
                            Text("Sold").tag(PropertyStatus.sold)
                        }
                        .pickerStyle(.segmented)
                        
                        if viewModel.propertyStatus != viewModel.property?.status {
                            Button("Update Status") {
                                Task {
                                    await viewModel.updateStatus(viewModel.propertyStatus)
                                }
                            }
                            .secondaryButtonStyle(isLoading: viewModel.isLoading)
                        }
                    }
                }
                
                // Error/Success Messages
                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                
                if let successMessage = viewModel.successMessage {
                    Section {
                        Text(successMessage)
                            .foregroundColor(.green)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle(viewModel.isEditMode ? "Edit Property" : "Create Property")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(viewModel.isEditMode ? "Update" : "Create") {
                        Task {
                            if viewModel.isEditMode {
                                await viewModel.updateProperty()
                            } else {
                                await viewModel.createProperty()
                            }
                            
                            // Dismiss on success
                            if viewModel.successMessage != nil {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                    dismiss()
                                }
                            }
                        }
                    }
                    .primaryButtonStyle(isLoading: viewModel.isLoading, isDisabled: !viewModel.canSave)
                }
            }
            .sheet(isPresented: $showImagePicker) {
                #if canImport(UIKit)
                MultiImagePicker(imageDataArray: $viewModel.propertyImages, selectionLimit: 10)
                #else
                Text("Image picker not available on this platform")
                #endif
            }
            .alert("Delete Property", isPresented: $showDeleteAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    Task {
                        await viewModel.deleteProperty()
                        dismiss()
                    }
                }
            } message: {
                Text("Are you sure you want to delete this property listing? This action cannot be undone.")
            }
            .safeAreaInset(edge: .bottom) {
                if viewModel.isEditMode {
                    Button(role: .destructive) {
                        showDeleteAlert = true
                    } label: {
                        Label("Delete Property", systemImage: "trash")
                    }
                    .destructiveButtonStyle(isLoading: viewModel.isLoading)
                    .padding()
                }
            }
            .overlay {
                if viewModel.isLoading {
                    LoadingIndicator(style: .overlay, message: "Saving...")
                        .fadeInOnAppear()
                }
            }
        }
    }
}

// MARK: - Preview

@available(iOS 15.0, macOS 12.0, *)
struct PropertyCreationView_Previews: PreviewProvider {
    static var previews: some View {
        let mockService = PropertyListingService(
            repository: MockPropertyRepository(),
            imageStorage: MockImageStorage()
        )
        
        PropertyCreationView(
            viewModel: PropertyCreationViewModel(
                service: mockService,
                currentUserId: "user123"
            )
        )
    }
}


