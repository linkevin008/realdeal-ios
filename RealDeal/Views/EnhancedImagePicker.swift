import SwiftUI
import PhotosUI

/// Enhanced image picker that integrates with the image handling and caching system
@available(iOS 15.0, *)
struct EnhancedImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImages: [UIImage]
    @Environment(\.presentationMode) var presentationMode
    
    let selectionLimit: Int
    let compressionSettings: ImageCompression.CompressionSettings?
    let onImagesSelected: (([UIImage]) -> Void)?
    
    init(
        selectedImages: Binding<[UIImage]>,
        selectionLimit: Int = 10,
        compressionSettings: ImageCompression.CompressionSettings? = nil,
        onImagesSelected: (([UIImage]) -> Void)? = nil
    ) {
        self._selectedImages = selectedImages
        self.selectionLimit = selectionLimit
        self.compressionSettings = compressionSettings
        self.onImagesSelected = onImagesSelected
    }
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = selectionLimit
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {
        // No updates needed
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: EnhancedImagePicker
        
        init(_ parent: EnhancedImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.presentationMode.wrappedValue.dismiss()
            
            guard !results.isEmpty else {
                return
            }
            
            Task {
                await loadImages(from: results)
            }
        }
        
        @MainActor
        private func loadImages(from results: [PHPickerResult]) async {
            var loadedImages: [(index: Int, image: UIImage)] = []
            
            await withTaskGroup(of: (Int, UIImage?).self) { group in
                for (index, result) in results.enumerated() {
                    group.addTask {
                        let image = await self.loadImage(from: result.itemProvider)
                        return (index, image)
                    }
                }
                
                for await (index, image) in group {
                    if let image = image {
                        loadedImages.append((index: index, image: image))
                    }
                }
            }
            
            // Sort by original index to maintain order
            let sortedImages = loadedImages.sorted { $0.index < $1.index }.map { $0.image }
            
            // Apply compression if specified
            let finalImages: [UIImage]
            if let settings = parent.compressionSettings {
                finalImages = await compressImages(sortedImages, settings: settings)
            } else {
                finalImages = sortedImages
            }
            
            // Update binding and call completion handler
            parent.selectedImages = finalImages
            parent.onImagesSelected?(finalImages)
        }
        
        private func loadImage(from provider: NSItemProvider) async -> UIImage? {
            return await withCheckedContinuation { continuation in
                if provider.canLoadObject(ofClass: UIImage.self) {
                    provider.loadObject(ofClass: UIImage.self) { image, error in
                        continuation.resume(returning: image as? UIImage)
                    }
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
        
        private func compressImages(_ images: [UIImage], settings: ImageCompression.CompressionSettings) async -> [UIImage] {
            return await withTaskGroup(of: (Int, UIImage?).self) { group in
                var compressedImages: [(index: Int, image: UIImage)] = []
                
                for (index, image) in images.enumerated() {
                    group.addTask {
                        let result = ImageCompression.compress(image: image, settings: settings)
                        let compressedImage = UIImage(data: result.data)
                        return (index, compressedImage)
                    }
                }
                
                for await (index, image) in group {
                    if let image = image {
                        compressedImages.append((index: index, image: image))
                    }
                }
                
                return compressedImages.sorted { $0.index < $1.index }.map { $0.image }
            }
        }
    }
}

// MARK: - Convenience Initializers

@available(iOS 15.0, *)
extension EnhancedImagePicker {
    
    /// Initialize for property images with appropriate compression
    static func forPropertyImages(
        selectedImages: Binding<[UIImage]>,
        selectionLimit: Int = 10,
        onImagesSelected: (([UIImage]) -> Void)? = nil
    ) -> EnhancedImagePicker {
        return EnhancedImagePicker(
            selectedImages: selectedImages,
            selectionLimit: selectionLimit,
            compressionSettings: .property,
            onImagesSelected: onImagesSelected
        )
    }
    
    /// Initialize for profile photo with appropriate compression
    static func forProfilePhoto(
        selectedImages: Binding<[UIImage]>,
        onImageSelected: ((UIImage) -> Void)? = nil
    ) -> EnhancedImagePicker {
        return EnhancedImagePicker(
            selectedImages: selectedImages,
            selectionLimit: 1,
            compressionSettings: .profile,
            onImagesSelected: { images in
                if let image = images.first {
                    onImageSelected?(image)
                }
            }
        )
    }
    
    /// Initialize for thumbnails with appropriate compression
    static func forThumbnails(
        selectedImages: Binding<[UIImage]>,
        selectionLimit: Int = 5,
        onImagesSelected: (([UIImage]) -> Void)? = nil
    ) -> EnhancedImagePicker {
        return EnhancedImagePicker(
            selectedImages: selectedImages,
            selectionLimit: selectionLimit,
            compressionSettings: .thumbnail,
            onImagesSelected: onImagesSelected
        )
    }
}

// MARK: - Image Picker Button

@available(iOS 15.0, *)
struct ImagePickerButton: View {
    @State private var selectedImages: [UIImage] = []
    @State private var showingPicker = false
    
    let title: String
    let systemImage: String
    let pickerType: PickerType
    let onImagesSelected: ([UIImage]) -> Void
    
    enum PickerType {
        case property
        case profile
        case thumbnail
        
        var selectionLimit: Int {
            switch self {
            case .property: return 10
            case .profile: return 1
            case .thumbnail: return 5
            }
        }
        
        var compressionSettings: ImageCompression.CompressionSettings {
            switch self {
            case .property: return .property
            case .profile: return .profile
            case .thumbnail: return .thumbnail
            }
        }
    }
    
    init(
        title: String,
        systemImage: String = "photo.on.rectangle.angled",
        type: PickerType,
        onImagesSelected: @escaping ([UIImage]) -> Void
    ) {
        self.title = title
        self.systemImage = systemImage
        self.pickerType = type
        self.onImagesSelected = onImagesSelected
    }
    
    var body: some View {
        Button(action: {
            showingPicker = true
        }) {
            HStack {
                Image(systemName: systemImage)
                Text(title)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .sheet(isPresented: $showingPicker) {
            EnhancedImagePicker(
                selectedImages: $selectedImages,
                selectionLimit: pickerType.selectionLimit,
                compressionSettings: pickerType.compressionSettings,
                onImagesSelected: { images in
                    onImagesSelected(images)
                }
            )
        }
    }
}

// MARK: - Image Upload Button with Progress

@available(iOS 15.0, *)
struct ImageUploadButton: View {
    @StateObject private var imageManager = ImageManager.shared
    @State private var selectedImages: [UIImage] = []
    @State private var showingPicker = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    let title: String
    let uploadType: UploadType
    let onUploadComplete: ([URL]) -> Void
    
    enum UploadType {
        case property(String) // propertyId
        case profile(String)  // userId
        
        var pickerType: ImagePickerButton.PickerType {
            switch self {
            case .property: return .property
            case .profile: return .profile
            }
        }
    }
    
    init(
        title: String,
        uploadType: UploadType,
        onUploadComplete: @escaping ([URL]) -> Void
    ) {
        self.title = title
        self.uploadType = uploadType
        self.onUploadComplete = onUploadComplete
    }
    
    var body: some View {
        VStack(spacing: 12) {
            ImagePickerButton(
                title: title,
                type: uploadType.pickerType,
                onImagesSelected: { images in
                    selectedImages = images
                    uploadImages()
                }
            )
            
            if imageManager.isProcessing {
                VStack(spacing: 8) {
                    Text("Uploading...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ForEach(Array(imageManager.uploadProgress.keys), id: \.self) { uploadId in
                        if let progress = imageManager.uploadProgress[uploadId] {
                            ProgressView(value: progress)
                                .progressViewStyle(LinearProgressViewStyle())
                        }
                    }
                }
            }
        }
        .alert("Upload Status", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func uploadImages() {
        guard !selectedImages.isEmpty else { return }
        
        Task {
            do {
                let urls: [URL]
                
                switch uploadType {
                case .property(let propertyId):
                    let results = try await imageManager.uploadPropertyImages(selectedImages, propertyId: propertyId)
                    urls = results.map(\.url)
                    
                case .profile(let userId):
                    guard let image = selectedImages.first else { return }
                    let result = try await imageManager.uploadProfilePhoto(image, userId: userId)
                    urls = [result.url]
                }
                
                await MainActor.run {
                    onUploadComplete(urls)
                    alertMessage = "Successfully uploaded \(urls.count) image(s)!"
                    showingAlert = true
                    selectedImages.removeAll()
                }
                
            } catch {
                await MainActor.run {
                    alertMessage = "Upload failed: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }
}

// MARK: - Preview

@available(iOS 15.0, *)
struct EnhancedImagePicker_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            ImagePickerButton(
                title: "Select Property Images",
                type: .property,
                onImagesSelected: { images in
                    print("Selected \(images.count) property images")
                }
            )
            
            ImagePickerButton(
                title: "Select Profile Photo",
                systemImage: "person.crop.circle",
                type: .profile,
                onImagesSelected: { images in
                    print("Selected profile photo")
                }
            )
            
            ImageUploadButton(
                title: "Upload Property Images",
                uploadType: .property("property123"),
                onUploadComplete: { urls in
                    print("Uploaded images: \(urls)")
                }
            )
        }
        .padding()
    }
}