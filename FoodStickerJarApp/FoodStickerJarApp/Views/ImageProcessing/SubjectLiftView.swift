import SwiftUI
import VisionKit

/// A `UIViewRepresentable` to wrap `UIImageView` with a VisionKit `ImageAnalysisInteraction`.
struct SubjectLiftView: UIViewRepresentable {
    let image: UIImage
    let interaction: ImageAnalysisInteraction
    
    func makeUIView(context: Context) -> UIView {
        // --- FIX: Wrap the UIImageView in a container with Auto Layout constraints ---
        let containerView = UIView()
        
        let imageView = UIImageView(image: image)
        // By using .scaleAspectFill, the image will fill the view, matching the
        // user's expectation from the "Use Photo" screen.
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        // Enable user interaction for the VisionKit interaction to work.
        imageView.isUserInteractionEnabled = true
        
        // This is the key part: adding the interaction to the image view.
        imageView.addInteraction(interaction)
        
        // Use Auto Layout to ensure the imageView always fills the containerView.
        imageView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(imageView)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: containerView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
        
        // Return the container, which SwiftUI will correctly size.
        return containerView
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // No update logic needed for this simple case.
    }
}