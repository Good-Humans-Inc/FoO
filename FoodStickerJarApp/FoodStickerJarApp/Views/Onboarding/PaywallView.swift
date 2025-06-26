import SwiftUI
import RevenueCat

struct PaywallView: View {
    @Binding var isPresented: Bool
    
    @StateObject private var purchasesManager = PurchasesManager.shared
    
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var selectedPackage: Package?
    @State private var showRedeemSheet = false
    @State private var promoCode: String = ""

    private var sortedPackages: [Package] {
        guard let packages = purchasesManager.offerings?.current?.availablePackages else { return [] }
        
        // Sorts packages with .year first, then .month, then .week
        return packages.sorted { p1, p2 in
            let p1Unit = p1.storeProduct.subscriptionPeriod?.unit ?? .month
            let p2Unit = p2.storeProduct.subscriptionPeriod?.unit ?? .month
            
            // Assuming 0 for year, 1 for month, 2 for week allows sorting
            func order(for unit: RevenueCat.SubscriptionPeriod.Unit) -> Int {
                switch unit {
                case .year: return 0
                case .month: return 1
                case .week: return 2
                default: return 3
                }
            }
            
            return order(for: p1Unit) < order(for: p2Unit)
        }
    }
    
    var body: some View {
        ZStack {
            Color.themeBackground.ignoresSafeArea()
            
            VStack {
                ScrollView {
                    VStack(spacing: 20) {
                        header
                        subscriptionBody
                    }
                }
                footer
            }
            
            closeButton
        }
        .onAppear {
            purchasesManager.fetchOfferings()
        }
        .onChange(of: sortedPackages) { newPackages in
            if selectedPackage == nil {
                selectedPackage = newPackages.first
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .onChange(of: purchasesManager.isSubscribed) { isSubscribed in
            if isSubscribed {
                isPresented = false
            }
        }
        .alert("Redeem Offer", isPresented: $showRedeemSheet, actions: {
            TextField("Enter Code", text: $promoCode)
                .autocapitalization(.none)

            Button("Cancel", role: .cancel) { }
            Button("Redeem") {
                redeemOfferCode()
            }
        }, message: {
            Text("Enter your promotional code below to activate your special offer.")
        })
    }
    
    private var header: some View {
        VStack {
            HStack(alignment: .center, spacing: 10) {
                Image("logoIcon")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 60)
                
                Text("Be NOURISHED\n& INSPIRED")
                    .font(.system(size: 28, weight: .heavy, design: .serif))
                    .foregroundColor(.textPrimary)
                    .lineSpacing(1)
            }
            .padding(.top, 40) // Increased padding to account for close button
            
            Text("Join thousands of users building healthy habits.\nYour subscription helps us create more fun & helpful features for you.")
                .font(.system(size: 15, weight: .regular, design: .default))
                .multilineTextAlignment(.center)
                .foregroundColor(.textSecondary)
                .padding(.top, 10)
        }
        .padding(.horizontal)
    }
    
    private var subscriptionBody: some View {
        VStack(spacing: 20) {
            Image("magicJar")
                .resizable()
                .scaledToFit()
                .frame(height: 150)
                .overlay(
                    Image("spark")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50)
                        .offset(x: -40, y: -30)
                )

            Text("Thank you!")
                .font(.system(size: 24, weight: .bold, design: .serif))
                .padding(.top, -10)

            let packages = sortedPackages
            if !packages.isEmpty {
                // Find packages needed for savings calculation
                let yearlyPkg = packages.first { $0.storeProduct.subscriptionPeriod?.unit == .year }
                let monthlyPkg = packages.first { $0.storeProduct.subscriptionPeriod?.unit == .month }
                let savings = calculateSavings(yearly: yearlyPkg, monthly: monthlyPkg)
                
                VStack(spacing: 12) {
                    ForEach(packages) { package in
                        ExpandablePackageOptionView(
                            package: package,
                            isBestValue: package.identifier == yearlyPkg?.identifier,
                            savings: savings,
                            isSelected: selectedPackage?.identifier == package.identifier
                        )
                        .onTapGesture {
                            withAnimation(.spring()) {
                                selectedPackage = package
                            }
                        }
                    }
                }
                .padding(.horizontal)
            } else {
                ProgressView()
                    .padding(.vertical, 50)
            }
        }
    }
    
    private var footer: some View {
        VStack(spacing: 15) {
            Button(action: purchaseSelectedPackage) {
                Text("Join and Start!")
                    .font(.system(size: 22, weight: .bold, design: .default))
                    .foregroundColor(.textOnAccent)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.themeAccent)
                    .cornerRadius(16)
                    .shadow(color: .themeAccent.opacity(0.4), radius: 5, y: 4)
            }
            .disabled(selectedPackage == nil)
            
            HStack(spacing: 20) {
                Button(action: { showRedeemSheet = true }) {
                    Text("Redeem Offer")
                        .font(.system(size: 16, weight: .medium, design: .default))
                        .foregroundColor(.textSecondary)
                }

                Button(action: restorePurchases) {
                    Text("Restore Purchases")
                        .font(.system(size: 16, weight: .medium, design: .default))
                        .foregroundColor(.textSecondary)
                }
            }
            
            links
        }
        .padding(.horizontal, 30)
        .padding(.bottom, 20).padding(.top, 10)
        .background(Color.themeBackground.edgesIgnoringSafeArea(.bottom))
    }

    private var links: some View {
        HStack(spacing: 20) {
            if let url = URL(string: "https://www.goodhumans.today/jas-privacy") {
                Link("Privacy Policy", destination: url)
                    .font(.system(size: 12, weight: .regular, design: .default))
                    .foregroundColor(.textSecondary)
            }
            
            if let url = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/") {
                Link("Terms of Use", destination: url)
                    .font(.system(size: 12, weight: .regular, design: .default))
                    .foregroundColor(.textSecondary)
            }
        }
    }
    
    private var closeButton: some View {
        VStack {
            HStack {
                Spacer()
                Button(action: {
                    isPresented = false
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.textPrimary)
                        .padding(10)
                        .background(Color.white.opacity(0.5))
                        .clipShape(Circle())
                }
            }
            .padding()
            Spacer()
        }
    }
    
    private func calculateSavings(yearly: Package?, monthly: Package?) -> String? {
        guard let yearly = yearly, let monthly = monthly else { return nil }
        let yearlyPrice = yearly.storeProduct.price
        let monthlyPrice = monthly.storeProduct.price
        let totalMonthlyCost = monthlyPrice * 12
        
        guard totalMonthlyCost > yearlyPrice else { return nil }
        
        let savings = (totalMonthlyCost - yearlyPrice) / totalMonthlyCost
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 0
        return formatter.string(from: savings as NSDecimalNumber)
    }
    
    private func redeemOfferCode() {
        let code = promoCode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !code.isEmpty else {
            alertMessage = "Please enter a valid code."
            showAlert = true
            return
        }

        // The app's unique identifier from App Store Connect.
        let appleAppId = "6747237252"
        guard let url = URL(string: "https://apps.apple.com/redeem?ctx=offercodes&id=\(appleAppId)&code=\(code)") else {
            alertMessage = "There was an error preparing the redemption link."
            showAlert = true
            return
        }

        UIApplication.shared.open(url)
    }
    
    private func purchaseSelectedPackage() {
        guard let package = selectedPackage else { return }
        Task {
            do {
                let (_, customerInfo, userCancelled) = try await Purchases.shared.purchase(package: package)
                if !userCancelled {
                    // Update app state with new subscription status
                    let isSubscribed = customerInfo.entitlements["premium"]?.isActive == true
                    AppStateManager.shared.updateSubscriptionStatus(isSubscribed)
                    isPresented = false
                }
            } catch {
                alertMessage = error.localizedDescription
                showAlert = true
            }
        }
    }
    
    private func restorePurchases() {
        Task {
            do {
                let customerInfo = try await Purchases.shared.restorePurchases()
                let isSubscribed = customerInfo.entitlements["premium"]?.isActive == true
                AppStateManager.shared.updateSubscriptionStatus(isSubscribed)
                
                if isSubscribed {
                    isPresented = false
                } else {
                    alertMessage = "No purchases to restore."
                    showAlert = true
                }
            } catch {
                alertMessage = error.localizedDescription
                showAlert = true
            }
        }
    }
}


// MARK: - Subviews

struct ExpandablePackageOptionView: View {
    let package: Package
    let isBestValue: Bool
    let savings: String?
    let isSelected: Bool
    
    private var priceString: String {
        let price = package.localizedPriceString
        let unit = package.storeProduct.subscriptionPeriod?.unit.displayString ?? ""
        return "\(price) / \(unit)"
    }
    
    var body: some View {
        if isSelected {
            expandedView
        } else {
            collapsedView
        }
    }
    
    private var expandedView: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Text(package.storeProduct.localizedTitle)
                    .font(.system(size: 20, weight: .bold, design: .serif))
                    .foregroundColor(.textPrimary)
                
                if let tagText = tagTextForPackage() {
                    Text(tagText)
                        .font(.system(size: 12, weight: .bold, design: .default))
                        .padding(.horizontal, 8).padding(.vertical, 4)
                        .background(Color(UIColor.systemGray6))
                        .foregroundColor(.themeAccent)
                        .cornerRadius(8)
                }
            }
            
            HStack {
                Text(priceString)
                    .font(.system(size: 22, weight: .bold, design: .serif))
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                if let savings = savings, isBestValue {
                    Text("Save \(savings)")
                        .font(.system(size: 14, weight: .medium, design: .default))
                        .foregroundColor(.specialOffer)
                }
            }
            
            if isBestValue {
                let monthlyPrice = (package.storeProduct.price / 12)
                Text("(~\(monthlyPrice.formatted(.currency(code: package.storeProduct.currencyCode ?? "USD")))/month)")
                    .font(.system(size: 16, weight: .regular, design: .default))
                    .foregroundColor(.textSecondary)
            } else if package.storeProduct.subscriptionPeriod?.unit == .month {
                Text("Did you know? It takes just 21 days to build a habit!")
                    .font(.system(size: 14, weight: .regular, design: .default))
                    .foregroundColor(.textSecondary)
                    .padding(.top, 4)
            } else if package.storeProduct.subscriptionPeriod?.unit == .week {
                Text("Joyful habits begin today!")
                    .font(.system(size: 14, weight: .regular, design: .default))
                    .foregroundColor(.textSecondary)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.themeAccent.opacity(0.2))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.themeAccent, lineWidth: 2)
        )
    }
    
    private var collapsedView: some View {
        HStack {
            Text(package.storeProduct.localizedTitle)
                .font(.system(size: 18, weight: .bold, design: .serif))
                .foregroundColor(.textPrimary)
            Spacer()
            Text(priceString)
                .font(.system(size: 18, weight: .regular, design: .serif))
                .foregroundColor(.textPrimary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16).fill(Color(UIColor.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
    
    private func tagTextForPackage() -> String? {
        switch package.storeProduct.subscriptionPeriod?.unit {
        case .year:
            return "Best Value"
        case .month:
            return "Perfect Routine"
        case .week:
            return "Amazing Start"
        default:
            return nil
        }
    }
}

extension RevenueCat.SubscriptionPeriod.Unit {
    var displayString: String {
        switch self {
        case .day: return "day"
        case .week: return "week"
        case .month: return "month"
        case .year: return "year"
        @unknown default: return ""
        }
    }
}

struct PaywallView_Previews: PreviewProvider {
    static var previews: some View {
        PaywallView(isPresented: .constant(true))
    }
} 