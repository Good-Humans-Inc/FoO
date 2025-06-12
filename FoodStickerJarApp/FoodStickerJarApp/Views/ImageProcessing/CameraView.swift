import SwiftUI

/// A `UIViewControllerRepresentable` that wraps the native `UIImagePickerController` for use in SwiftUI.
struct CameraView: UIViewControllerRepresentable {
    
    var onImagePicked: (UIImage) -> Void
    @Environment(\.dismiss) var dismiss

    // The coordinator acts as the delegate for the UIImagePickerController.
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        #if targetEnvironment(simulator)
        // Use photo library if on simulator, as camera is not available.
        picker.sourceType = .photoLibrary
        #else
        // Use camera on a real device.
        picker.sourceType = .camera
        #endif
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {
        // No updates needed.
    }
    
    // MARK: - Coordinator
    
    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: CameraView
        
        init(parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            // We use .originalImage as we will be cropping it ourselves later.
            if let image = info[.originalImage] as? UIImage {
                parent.onImagePicked(image)
            } else {
                // If we can't get an image, dismiss the sheet.
                parent.dismiss()
            }
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            // The user cancelled, so we dismiss the sheet.
            parent.dismiss()
        }
    }
}