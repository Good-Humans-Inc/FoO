import SwiftUI

extension View {
    /// Renders the view to a `UIImage`.
    /// - Returns: A `UIImage` representation of the view.
    func snapshot() -> UIImage? {
        // We use a UIHostingController to bridge the SwiftUI view to the UIKit world.
        let controller = UIHostingController(rootView: self.ignoresSafeArea())
        let view = controller.view
        
        // The size of the view is set to its intrinsic content size.
        let targetSize = controller.view.intrinsicContentSize
        view?.bounds = CGRect(origin: .zero, size: targetSize)
        view?.backgroundColor = .clear // Make the background clear to respect view's transparency.
        
        // Use a UIGraphicsImageRenderer to capture the view's layer.
        let renderer = UIGraphicsImageRenderer(size: targetSize)
        
        return renderer.image { _ in
            view?.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }
} 