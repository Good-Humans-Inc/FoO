import SwiftUI
import SpriteKit

/// A `UIViewControllerRepresentable` that bridges a SpriteKit `SKView` into the SwiftUI view hierarchy.
struct SpriteView: UIViewControllerRepresentable {
    // We pass the scene instance directly to ensure we are always using the same physics world.
    let scene: SKScene
    
    func makeUIViewController(context: Context) -> UIViewController {
        // Create a standard UIViewController to host the SKView.
        let viewController = UIViewController()
        
        // Create the SKView.
        let skView = SKView()
        skView.translatesAutoresizingMaskIntoConstraints = false
        skView.backgroundColor = .clear // Make the background transparent
        skView.allowsTransparency = true
        
        // Present the scene.
        scene.scaleMode = .resizeFill
        scene.backgroundColor = .clear
        skView.presentScene(scene)
        
        // Add the SKView to the view controller's view.
        viewController.view.addSubview(skView)
        
        // Set up constraints for the SKView to fill its parent.
        NSLayoutConstraint.activate([
            skView.topAnchor.constraint(equalTo: viewController.view.topAnchor),
            skView.bottomAnchor.constraint(equalTo: viewController.view.bottomAnchor),
            skView.leadingAnchor.constraint(equalTo: viewController.view.leadingAnchor),
            skView.trailingAnchor.constraint(equalTo: viewController.view.trailingAnchor)
        ])
        
        return viewController
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        // This is called when SwiftUI state changes.
        // We can use it to update the scene's size to match the view's frame.
        if let view = uiViewController.view {
            scene.size = view.bounds.size
        }
    }
}
