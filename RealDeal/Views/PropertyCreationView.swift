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
            ScrollViewReader { proxy in
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
                    
                    // Dropdown when the selected country defines subdivisions
                    // (backend-served); free text for countries without a list
                    if viewModel.currentSubdivisions.isEmpty {
                        TextField(viewModel.usesZipCode ? "State" : "Province", text: $viewModel.province)
                    } else {
                        Picker(viewModel.usesZipCode ? "State" : "Province", selection: $viewModel.province) {
                            Text("Select").tag("")
                            ForEach(viewModel.currentSubdivisions, id: \.code) { subdivision in
                                Text(subdivision.name).tag(subdivision.code)
                            }
                        }
                    }
                    if let error = viewModel.provinceValidationError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }

                    // Stores the ISO code; shows the localized country name.
                    // The list comes from the backend (supported markets only).
                    Picker("Country", selection: $viewModel.country) {
                        ForEach(viewModel.supportedCountries, id: \.code) { option in
                            Text(option.name).tag(option.code)
                        }
                    }

                    // Label, keyboard, and validation adapt to the country
                    TextField(viewModel.usesZipCode ? "ZIP Code" : "Postal Code", text: $viewModel.postalCode)
                        #if os(iOS)
                        .keyboardType(viewModel.usesZipCode ? .numbersAndPunctuation : .default)
                        #endif
                    if let error = viewModel.postalCodeValidationError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                .id(PropertyCreationViewModel.FormSection.address)

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
                .id(PropertyCreationViewModel.FormSection.basicInfo)

                // Specifications Section — required on every listing
                Section(header: Text("Specifications")) {
                    Picker("Bedrooms", selection: $viewModel.bedrooms) {
                        Text("Select").tag("")
                        ForEach(0...10, id: \.self) { n in
                            Text("\(n)").tag("\(n)")
                        }
                    }

                    Picker("Bathrooms", selection: $viewModel.bathrooms) {
                        Text("Select").tag("")
                        ForEach(Array(stride(from: 0.0, through: 6.0, by: 0.5)), id: \.self) { n in
                            Text(n.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(n))" : String(format: "%.1f", n))
                                .tag(n.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(n))" : String(format: "%.1f", n))
                        }
                    }

                    TextField("Square Feet", text: $viewModel.squareFeet)
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #endif

                    Picker("Year Built", selection: $viewModel.yearBuilt) {
                        Text("Select").tag("")
                        // Newest first — next year allows new construction
                        ForEach(PropertyCreationViewModel.selectableYears, id: \.self) { year in
                            Text(String(year)).tag("\(year)")
                        }
                    }

                    if let error = viewModel.specificationsValidationError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                .id(PropertyCreationViewModel.FormSection.specifications)

                // Coordinates are geocoded from the address on save — the user
                // never enters them. Only surfaced when geocoding fails.
                if let error = viewModel.locationValidationError {
                    Section {
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
            .task { await viewModel.loadSupportedCountries() }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    // Always tappable (except mid-save): tapping with missing
                    // fields scrolls to the first incomplete section and marks
                    // its header in red instead of silently doing nothing.
                    Button(viewModel.isEditMode ? "Update" : "Create") {
                        Task {
                            if viewModel.isEditMode {
                                await viewModel.updateProperty()
                            } else {
                                await viewModel.createProperty()
                            }

                            if let target = viewModel.firstInvalidSection {
                                withAnimation {
                                    proxy.scrollTo(target, anchor: .top)
                                }
                            }

                            // Dismiss on success
                            if viewModel.successMessage != nil {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                    dismiss()
                                }
                            }
                        }
                    }
                    .disabled(viewModel.isLoading)
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


