//
//  AppDelegate.swift
//  FoodStickerJarApp
//
//  Created by Yan on 2023-11-20.
//

import UIKit
import SwiftUI
import FirebaseCore

// This class is the entry point for app-level events.
// We use it to configure Firebase as soon as the app finishes launching.
class AppDelegate: NSObject, UIApplicationDelegate {
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // --- Firebase Core ---
        FirebaseApp.configure()
        
        return true
    }
} 
