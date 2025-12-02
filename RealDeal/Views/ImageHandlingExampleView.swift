import SwiftUI
import PhotosUI

/// Example view demonstrating the image handling and caching system
@available(iOS 15.0, *)
struct ImageHandlingExampleView: View {
    
    @StateObject private var imageManager = ImageManager.shared
    @State private var selectedImages: [UIImage] = []
    @State private var uploadedImageUrls: [URL] = []
    @State private var showingImagePicker = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    
                    // Upload Section
                    uploadSection
                    
                    // Progress Section
                    if imageManager.isProcessing {
                        progressSection
                    }
                    
                    // Uploaded Images Section
                    if !uploadedImageUrls.isEmpty {
                        uploadedImagesSection
                    }
                    
                    // Cache Info Section
                    cacheInfoSection
                }
                .padding()
            }
            .navigationTitle("Image Handling Demo")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Clear Cache") {
                        Task {
                            await imageManager.clearCache()
                        }
                    }
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(selectedImages: $selectedImages)
            }
            .alert("Image Processing", isPresented: $showingAlert) {
                Button("OK") { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    // MARK: - Upload Section
    
    private var uploadSection: some View {
        VStack(spacing: 16) {
            Text("Upload Images")
                .font(.headline)
            
            Button(action: {
                showingImagePicker = true
            }) {
                HStack {
                    Image(systemName: "photo.on.rectangle.angled")
                    Text("Select Images")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
            }
            
            if !selectedImages.isEmpty {
                Text("Selected: \(selectedImages.count) images")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 12) {
                    Button("Upload as Property Images") {
                        uploadPropertyImages()
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Upload as Profile Photo") {
                        uploadProfilePhoto()
                    }
                    .buttonStyle(.bordered)
                    .disabled(selectedImages.count != 1)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Progress Section
    
    private var progressSection: some View {
        VStack(spacing: 12) {
            Text("Processing Images...")
                .font(.headline)
            
            ForEach(Array(imageManager.uploadProgress.keys), id: \.self) { uploadId in
                if let progress = imageManager.uploadProgress[uploadId] {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Upload \(uploadId.prefix(8))...")
                                .font(.caption)
                            Spacer()
                            Text("\(Int(progress * 100))%")
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                        
                        ProgressView(value: progress)
                            .progressViewStyle(LinearProgressViewStyle())
                    }
                }
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Uploaded Images Section
    
    private var uploadedImagesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Uploaded Images")
                .font(.headline)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(uploadedImageUrls, id: \.absoluteString) { url in
                    LazyImageView(url: url)
                        .aspectRatio(1, contentMode: .fit)
                        .cornerRadius(8)
                        .onTapGesture {
                            deleteImage(url: url)
                        }
                }
            }
            
            Text("Tap images to delete")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Cache Info Section
    
    private var cacheInfoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Cache Information")
                .font(.headline)
            
            CacheInfoView()
        }
        .padding()
        .background(Color.purple.opacity(0.1))
        .cornerRadius(12)
    }
    
    // MARK: - Actions
    
    private func uploadPropertyImages() {
        guard !selectedImages.isEmpty else { return }
        
        Task {
            do {
                let propertyId = UUID().uuidString
                let results = try await imageManager.uploadPropertyImages(selectedImages, propertyId: propertyId)
                
                await MainActor.run {
                    uploadedImageUrls.append(contentsOf: results.map(\.url))
                    selectedImages.removeAll()
                    alertMessage = "Successfully uploaded \(results.count) property images!"
                    showingAlert = true
                }
            } catch {
                await MainActor.run {
                    alertMessage = "Failed to upload images: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }
    
    private func uploadProfilePhoto() {
        guard let image = selectedImages.first else { return }
        
        Task {
            do {
                let userId = UUID().uuidString
                let result = try await imageManager.uploadProfilePhoto(image, userId: userId)
                
                await MainActor.run {
                    uploadedImageUrls.append(result.url)
                    selectedImages.removeAll()
                    alertMessage = "Successfully uploaded profile photo!"
                    showingAlert = true
                }
            } catch {
                await MainActor.run {
                    alertMessage = "Failed to upload profile photo: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }
    
    private func deleteImage(url: URL) {
        Task {
            do {
                try await imageManager.deleteImage(url: url)
                
                await MainActor.run {
                    uploadedImageUrls.removeAll { $0 == url }
                    alertMessage = "Image deleted successfully!"
                    showingAlert = true
                }
            } catch {
                await MainActor.run {
                    alertMessage = "Failed to delete image: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }
}

// MARK: - Cache Info View

@available(iOS 15.0, *)
struct CacheInfoView: View {
    @State private var cacheInfo: CacheInfo?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let info = cacheInfo {
                HStack {
                    Text("Items:")
                    Spacer()
                    Text("\(info.itemCount)")
                        .fontWeight(.medium)
                }
                
                HStack {
                    Text("Disk Size:")
                    Spacer()
                    Text(info.formattedDiskSize)
                        .fontWeight(.medium)
                }
            } else {
                Text("Loading cache info...")
                    .foregroundColor(.secondary)
            }
        }
        .font(.caption)
        .task {
            cacheInfo = await ImageCache.shared.getCacheInfo()
        }
    }
}

// MARK: - Simple Image Picker

@available(iOS 15.0, *)
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImages: [UIImage]
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.selectedImages.append(image)
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}

// MARK: - Preview

@available(iOS 15.0, *)
struct ImageHandlingExampleView_Previews: PreviewProvider {
    static var previews: some View {
        ImageHandlingExampleView()
    }
}