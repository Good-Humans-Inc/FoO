import Foundation
import UIKit
import FirebaseCore

// This class is the entry point for app-level events.
// We use it to configure Firebase as soon as the app finishes launching.
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // This is the line that configures Firebase from your GoogleService-Info.plist file.
        FirebaseApp.configure()
        return true
    }
} 