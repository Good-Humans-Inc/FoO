import Foundation
import UIKit
import FirebaseCore
import Firebase
import SwiftUI

// This class is the entry point for app-level events.
// We use it to configure Firebase as soon as the app finishes launching.
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Configure Firebase services.
        FirebaseApp.configure()
        
        // Use a small delay to ensure the scene and window are fully set up
        // before we add our custom view.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.addFeedbackView()
        }
        
        return true
    }
    
    /// Creates and adds the FeedbackView to the main application window.
    private func addFeedbackView() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) else {
            print("Could not find key window.")
            return
        }

        let feedbackView = FeedbackView()
        let hostingController = UIHostingController(rootView: feedbackView)
        
        guard let view = hostingController.view else { return }
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear

        window.addSubview(view)

        // Add constraints to pin the view to the bottom.
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: window.leadingAnchor, constant: 10),
            view.trailingAnchor.constraint(equalTo: window.trailingAnchor, constant: -10),
            view.bottomAnchor.constraint(equalTo: window.safeAreaLayoutGuide.bottomAnchor, constant: -10)
        ])
    }
} 