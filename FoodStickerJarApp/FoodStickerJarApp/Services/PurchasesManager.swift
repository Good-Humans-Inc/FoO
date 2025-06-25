import Foundation
import RevenueCat
import SwiftUI

class PurchasesManager: NSObject, ObservableObject, PurchasesDelegate {
    static let shared = PurchasesManager()
    
    @Published var offerings: Offerings?
    @Published var isSubscribed = false
    
    private override init() {
        super.init()
        // Replace with your actual RevenueCat API key
        Purchases.configure(withAPIKey: "appl_QhWURUGaxJyyRIYremfEAOdoSXM")
        Purchases.shared.delegate = self
        checkSubscriptionStatus()
        fetchOfferings()
    }
    
    func purchases(_ purchases: Purchases, receivedUpdated purchaserInfo: CustomerInfo) {
        updateSubscriptionStatus(with: purchaserInfo)
    }
    
    func fetchOfferings() {
        Purchases.shared.getOfferings { (offerings, error) in
            if let offerings = offerings {
                self.offerings = offerings
            } else if let error = error {
                print("Error fetching offerings: \(error.localizedDescription)")
            }
        }
    }
    
    func purchase(package: Package) async throws {
        let result = try await Purchases.shared.purchase(package: package)
        updateSubscriptionStatus(with: result.customerInfo)
    }
    
    func restorePurchases() async {
        do {
            let customerInfo = try await Purchases.shared.restorePurchases()
            updateSubscriptionStatus(with: customerInfo)
        } catch {
            print("Error restoring purchases: \(error)")
        }
    }
    
    private func checkSubscriptionStatus() {
        Purchases.shared.getCustomerInfo { (purchaserInfo, error) in
            if let purchaserInfo = purchaserInfo {
                self.updateSubscriptionStatus(with: purchaserInfo)
            }
        }
    }
    
    private func updateSubscriptionStatus(with customerInfo: CustomerInfo) {
        // Replace "premium" with your entitlement identifier from RevenueCat
        let isSubscribed = customerInfo.entitlements["premium"]?.isActive == true
        
        // --- Enhanced Logging ---
        print("[PurchasesManager] Updating subscription status.")
        print("[PurchasesManager] Is user subscribed: \(isSubscribed)")
        if let premiumEntitlement = customerInfo.entitlements["premium"] {
            print("[PurchasesManager]   - Entitlement 'premium' found.")
            print("[PurchasesManager]   - Is active: \(premiumEntitlement.isActive)")
            print("[PurchasesManager]   - Will renew: \(premiumEntitlement.willRenew)")
        } else {
            print("[PurchasesManager]   - Entitlement 'premium' not found.")
        }
        print("[PurchasesManager] Full entitlements object: \(customerInfo.entitlements)")
        // --- End Enhanced Logging ---
        
        DispatchQueue.main.async {
            self.isSubscribed = isSubscribed
            AppStateManager.shared.updateSubscriptionStatus(isSubscribed)
        }
    }
    
    func refreshStatus() {
        Task {
            do {
                print("[PurchasesManager] Refreshing status via restore to sync App Store receipt...")
                let customerInfo = try await Purchases.shared.restorePurchases()
                updateSubscriptionStatus(with: customerInfo)
                print("[PurchasesManager] Status refresh successful.")
            } catch {
                print("[PurchasesManager] Status refresh failed with error: \(error)")
            }
        }
    }
} 
