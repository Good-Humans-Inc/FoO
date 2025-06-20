import SwiftUI
import RevenueCat

struct PaywallView: View {
    @Binding var isPresented: Bool
    
    // MARK: - Private Properties
    @StateObject private var purchasesManager = PurchasesManager.shared
    @State private var selectedPackage: Package?
    @State private var isPurchasing = false
    @EnvironmentObject var appState: AppStateManager
    
    // MARK: - View
    var body: some View {
        ZStack {
            Color.themeBackground.ignoresSafeArea()
            
            VStack {
                ScrollView {
                    VStack(alignment: .center, spacing: 20) {
                        header
                        packages
                    }
                    .padding(.horizontal)
                }
                
                footer
            }
            .disabled(isPurchasing)
            
            if isPurchasing {
                Color.black.opacity(0.5).ignoresSafeArea()
                ProgressView()
            }
        }
        .onAppear {
            self.selectedPackage = purchasesManager.offerings?.current?.availablePackages.first
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Subviews
    private var header: some View {
        VStack(spacing: 10) {
            Image("logoIcon")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 80)
            
            Text("Unlock All Features")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Get unlimited sticker captures, and more!")
                .font(.headline)
                .multilineTextAlignment(.center)
        }
    }
    
    private var packages: some View {
        VStack(spacing: 15) {
            if let packages = purchasesManager.offerings?.current?.availablePackages {
                ForEach(packages) { package in
                    PackageButton(package: package, selectedPackage: $selectedPackage)
                }
            } else {
                Text("Loading plans...")
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var footer: some View {
        VStack(spacing: 15) {
            purchaseButton
            restoreButton
            Text("Terms of Use & Privacy Policy")
                .font(.caption)
        }
        .padding()
    }
    
    private var purchaseButton: some View {
        Button(action: purchase) {
            Text("Continue")
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
        .disabled(selectedPackage == nil)
    }
    
    private var restoreButton: some View {
        Button(action: restorePurchases) {
            Text("Restore Purchases")
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Private Methods
    private func purchase() {
        guard let package = selectedPackage else { return }
        isPurchasing = true
        
        Task {
            do {
                let (_, customerInfo, _) = try await purchasesManager.purchase(package: package)
                if customerInfo.entitlements.all["premium"]?.isActive == true {
                    appState.isSubscribed = true
                    isPresented = false
                }
            } catch {
                print("Purchase failed: \(error.localizedDescription)")
            }
            isPurchasing = false
        }
    }
    
    private func restorePurchases() {
        isPurchasing = true
        Task {
            do {
                let customerInfo = try await purchasesManager.restorePurchases()
                if customerInfo.entitlements.all["premium"]?.isActive == true {
                    appState.isSubscribed = true
                    isPresented = false
                }
            } catch {
                print("Restore failed: \(error.localizedDescription)")
            }
            isPurchasing = false
        }
    }
}

struct PackageButton: View {
    let package: Package
    @Binding var selectedPackage: Package?
    
    var body: some View {
        Button(action: {
            selectedPackage = package
        }) {
            HStack {
                VStack(alignment: .leading) {
                    Text(package.storeProduct.localizedTitle)
                        .fontWeight(.semibold)
                    Text(package.storeProduct.localizedDescription)
                        .font(.subheadline)
                }
                Spacer()
                Text(package.storeProduct.localizedPriceString)
                    .fontWeight(.bold)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(selectedPackage == package ? Color.accentColor : Color.gray, lineWidth: 2)
            )
            .foregroundColor(.white)
        }
    }
} 