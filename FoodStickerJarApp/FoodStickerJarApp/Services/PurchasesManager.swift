import Foundation
import RevenueCat
import StoreKit

class PurchasesManager: NSObject, ObservableObject, PurchasesDelegate {

    static let shared = PurchasesManager()

    @Published var offerings: Offerings?
    @Published var isSubscribed: Bool = false
    
    private override init() {
        super.init()
        Purchases.logLevel = .debug
        // The API key should be stored securely, e.g., in a configuration file.
        // For this example, we'll hardcode it but in a real app, please use a secure method.
        if let apiKey = Self.getAPIKey() {
            Purchases.configure(withAPIKey: apiKey, appUserID: nil)
        } else {
            print("Error: Could not find API key for RevenueCat.")
        }
        Purchases.shared.delegate = self
        
        checkSubscriptionStatus()
        fetchOfferings()
    }

    private static func getAPIKey() -> String? {
        guard let path = Bundle.main.path(forResource: "config", ofType: "json") else {
            print("config.json not found")
            return nil
        }
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
            let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
            if let jsonResult = jsonResult as? [String: Any], let apiKey = jsonResult["revenueCatApiKey"] as? String {
                return apiKey
            }
        } catch {
            print("Error parsing config.json: \(error)")
        }
        return nil
    }

    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
        updateSubscriptionStatus(with: customerInfo)
    }

    func fetchOfferings() {
        Purchases.shared.getOfferings { [weak self] (offerings, error) in
            if let offerings = offerings {
                self?.offerings = offerings
            } else if let error = error {
                print("Error fetching offerings: \(error.localizedDescription)")
            }
        }
    }

    func purchase(package: Package) async throws -> (SKPaymentTransaction?, CustomerInfo?, Bool) {
        return try await Purchases.shared.purchase(package: package)
    }

    func restorePurchases() async throws -> CustomerInfo {
        return try await Purchases.shared.restorePurchases()
    }

    private func checkSubscriptionStatus() {
        Purchases.shared.getCustomerInfo { [weak self] (customerInfo, error) in
            if let customerInfo = customerInfo {
                self?.updateSubscriptionStatus(with: customerInfo)
            } else if let error = error {
                print("Error fetching customer info: \(error.localizedDescription)")
            }
        }
    }
    
    private func updateSubscriptionStatus(with customerInfo: CustomerInfo) {
        let isSubscribed = customerInfo.entitlements.all["premium"]?.isActive == true
        self.isSubscribed = isSubscribed
        
        // Also update AppStateManager
        DispatchQueue.main.async {
            AppStateManager.shared.isSubscribed = isSubscribed
        }
    }
} 