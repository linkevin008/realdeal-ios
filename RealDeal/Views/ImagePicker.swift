import SwiftUI
#if canImport(UIKit)
import UIKit
import PhotosUI

/// SwiftUI wrapper for UIImagePickerController
@available(iOS 15.0, macOS 12.0, *)
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var imageData: Data?
    @Environment(\.presentationMode) var presentationMode
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1
        
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
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.presentationMode.wrappedValue.dismiss()
            
            guard let provider = results.first?.itemProvider else {
                return
            }
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, error in
                    if let uiImage = image as? UIImage {
                        // Convert to JPEG data with compression
                        DispatchQueue.main.async {
                            self.parent.imageData = uiImage.jpegData(compressionQuality: 0.8)
                        }
                    }
                }
            }
        }
    }
}
#endif
