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
        
        DispatchQueue.main.async {
            self.isSubscribed = isSubscribed
            AppStateManager.shared.updateSubscriptionStatus(isSubscribed)
        }
    }
} 