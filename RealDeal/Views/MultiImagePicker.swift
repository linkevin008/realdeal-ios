import SwiftUI

#if canImport(UIKit)
import UIKit
import PhotosUI

/// SwiftUI wrapper for PHPickerViewController with multi-select support
@available(iOS 15.0, *)
struct MultiImagePicker: UIViewControllerRepresentable {
    @Binding var imageDataArray: [Data]
    @Environment(\.presentationMode) var presentationMode
    var selectionLimit: Int = 10
    
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
        let parent: MultiImagePicker
        
        init(_ parent: MultiImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.presentationMode.wrappedValue.dismiss()
            
            guard !results.isEmpty else {
                return
            }
            
            let group = DispatchGroup()
            var loadedImages: [(index: Int, data: Data)] = []
            
            for (index, result) in results.enumerated() {
                let provider = result.itemProvider
                
                if provider.canLoadObject(ofClass: UIImage.self) {
                    group.enter()
                    provider.loadObject(ofClass: UIImage.self) { image, error in
                        defer { group.leave() }
                        
                        if let uiImage = image as? UIImage,
                           let imageData = uiImage.jpegData(compressionQuality: 0.8) {
                            loadedImages.append((index: index, data: imageData))
                        }
                    }
                }
            }
            
            group.notify(queue: .main) {
                // Sort by original index to maintain order
                let sortedImages = loadedImages.sorted { $0.index < $1.index }
                self.parent.imageDataArray = sortedImages.map { $0.data }
            }
        }
    }
}
#endif
