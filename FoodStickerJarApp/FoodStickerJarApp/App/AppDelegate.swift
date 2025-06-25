//
//  AppDelegate.swift
//  FoodStickerJarApp
//
//  Created by Yan on 2023-11-20.
//

import UIKit
import SwiftUI
import FirebaseCore
import FirebaseMessaging
import UserNotifications

// This class is the entry point for app-level events.
// We use it to configure Firebase as soon as the app finishes launching.
class AppDelegate: NSObject, UIApplicationDelegate {
    
    let gcmMessageIDKey = "gcm.message_id"
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // --- Firebase Core ---
        FirebaseApp.configure()
        
        // --- Firebase Cloud Messaging ---
        Messaging.messaging().delegate = self
        
        UNUserNotificationCenter.current().delegate = self
        
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: {_, _ in }
        )
        
        application.registerForRemoteNotifications()
        
        return true
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Clear the app icon badge number when the app becomes active.
        UNUserNotificationCenter.current().setBadgeCount(0) { error in
            if let error = error {
                print("-[FCM_DEBUG] Failed to clear application badge number: \(error.localizedDescription)")
            } else {
                print("-[FCM_DEBUG] App became active. Cleared application badge number.")
            }
        }
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        print(userInfo)
        
        completionHandler(UIBackgroundFetchResult.newData)
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        print("-[FCM_DEBUG] Successfully registered for remote notifications. APNS token received: \(token)")

        // Pass the APNS token to Firebase.
        // The MessagingDelegate's `didReceiveRegistrationToken` will be called with the FCM token.
        Messaging.messaging().apnsToken = deviceToken
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("-[FCM_DEBUG] Failed to register for remote notifications: \(error.localizedDescription)")
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    // Receive displayed notifications for iOS 10 devices.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        print(userInfo)
        
        // Change this to your preferred presentation option
        completionHandler([[.banner, .badge, .sound]])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        print(userInfo)
        
        completionHandler()
    }
}

extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let token = fcmToken else {
            print("-[FCM_DEBUG] FCM token received from Firebase is nil.")
            return
        }
        
        print("-[FCM_DEBUG] Received new FCM token: \(token)")
        
        // Save token to UserDefaults immediately.
        UserDefaults.standard.set(token, forKey: "fcmToken")
        print("-[FCM_DEBUG] Saved FCM token to UserDefaults.")
        
        // Attempt to update Firestore if the user is already authenticated.
        // If not, the token will be synced later upon login.
        if let userID = AuthenticationService.shared.user?.uid {
            print("-[FCM_DEBUG] User is already authenticated (\(userID)). Attempting to sync token to Firestore immediately.")
            Task {
                await FirestoreService().updateUserFCMToken(for: userID, token: token)
            }
        } else {
            print("-[FCM_DEBUG] User not authenticated. Token will be synced upon next login.")
        }
    }
} 
