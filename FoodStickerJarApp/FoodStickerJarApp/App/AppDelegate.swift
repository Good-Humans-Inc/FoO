import Foundation
import UIKit
import FirebaseCore
import Firebase
import SwiftUI

// This class is the entry point for app-level events.
// We use it to configure Firebase as soon as the app finishes launching.
class AppDelegate: NSObject, UIApplicationDelegate {
    
    // Keep a strong reference to the hosting controller and the view's bottom constraint.
    private var feedbackHostingController: UIHostingController<FeedbackView>?
    private var feedbackViewBottomConstraint: NSLayoutConstraint?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Configure Firebase services.
        FirebaseApp.configure()
        
        // The view is now added once the scene is active.
        return true
    }
    
    // Use the scene delegate method to ensure the window is available.
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Add observers for window and keyboard notifications.
        NotificationCenter.default.addObserver(self, selector: #selector(keyWindowDidChange), name: UIWindow.didBecomeKeyNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        let sceneConfig = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        sceneConfig.delegateClass = SceneDelegate.self
        return sceneConfig
    }
    
    /// Ensures the feedback view is on the current key window.
    @objc private func keyWindowDidChange(notification: NSNotification) {
        guard let window = notification.object as? UIWindow,
              // Only move the view to app windows, not system windows (like for the keyboard).
              window.isKind(of: NSClassFromString("UITextEffectsWindow")!) == false else {
            return
        }
        addFeedbackView(to: window)
    }
    
    /// Moves the feedback view up when the keyboard appears.
    @objc private func keyboardWillShow(notification: NSNotification) {
        guard let userInfo = notification.userInfo,
              let keyboardFrame = userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
              let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval,
              let window = self.feedbackHostingController?.view.window else { return }
        
        // Calculate the keyboard's height excluding the bottom safe area.
        let keyboardHeight = keyboardFrame.height
        let bottomSafeArea = window.safeAreaInsets.bottom
        
        // Adjust the constraint to move the view right on top of the keyboard, removing any gap.
        feedbackViewBottomConstraint?.constant = -(keyboardHeight - bottomSafeArea)
        
        UIView.animate(withDuration: duration) {
            window.layoutIfNeeded()
        }
    }
    
    /// Moves the feedback view down when the keyboard disappears.
    @objc private func keyboardWillHide(notification: NSNotification) {
        guard let userInfo = notification.userInfo,
              let duration = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval else { return }
        
        feedbackViewBottomConstraint?.constant = -10 // Back to original safe area padding
        
        UIView.animate(withDuration: duration) {
            self.feedbackHostingController?.view.window?.layoutIfNeeded()
        }
    }
    
    /// Creates and adds the FeedbackView to the specified window.
    func addFeedbackView(to window: UIWindow) {
        // If it already exists, just move it.
        if let feedbackView = feedbackHostingController?.view {
            window.addSubview(feedbackView)
            setupConstraints(for: feedbackView, in: window)
            return
        }
        
        // Otherwise, create it for the first time.
        let feedbackView = FeedbackView()
        let hostingController = UIHostingController(rootView: feedbackView)
        self.feedbackHostingController = hostingController
        
        guard let view = hostingController.view else { return }
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear

        window.addSubview(view)
        setupConstraints(for: view, in: window)
    }
    
    private func setupConstraints(for view: UIView, in window: UIWindow) {
        // We remove existing constraints to avoid conflicts when moving the view.
        NSLayoutConstraint.deactivate(window.constraints.filter {
            $0.firstItem === view || $0.secondItem === view
        })
        
        let bottomConstraint = view.bottomAnchor.constraint(equalTo: window.safeAreaLayoutGuide.bottomAnchor, constant: -10)
        self.feedbackViewBottomConstraint = bottomConstraint
        
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: window.leadingAnchor, constant: 10),
            view.trailingAnchor.constraint(equalTo: window.trailingAnchor, constant: -10),
            bottomConstraint
        ])
    }
}

// Create a SceneDelegate to get a callback when the scene is active.
class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    func sceneDidBecomeActive(_ scene: UIScene) {
        if let windowScene = scene as? UIWindowScene, let window = windowScene.windows.first(where: { $0.isKeyWindow }) {
            (UIApplication.shared.delegate as? AppDelegate)?.addFeedbackView(to: window)
        }
    }
} 