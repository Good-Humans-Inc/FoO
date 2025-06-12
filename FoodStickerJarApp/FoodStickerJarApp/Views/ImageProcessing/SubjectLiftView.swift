import SwiftUI
import VisionKit

/// A `UIViewRepresentable` to wrap `UIImageView` with a VisionKit `ImageAnalysisInteraction`.
struct SubjectLiftView: UIViewRepresentable {
    let image: UIImage
    let interaction: ImageAnalysisInteraction
    
    func makeUIView(context: Context) -> UIView {
        let imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        
        // This is the key part: adding the interaction to the image view.
        imageView.addInteraction(interaction)
        
        return imageView
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // No update logic needed for this simple case.
    }
}