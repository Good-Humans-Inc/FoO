import SwiftUI

/// The data model for a single page in the onboarding intro carousel.
struct IntroPage: Identifiable {
    let id = UUID()
    let imageName: String
    let headline: String
    let subheadline: String
}

/// A view that displays a single page of the intro carousel.
struct IntroPageView: View {
    let page: IntroPage

    var body: some View {
        VStack(spacing: 20) {
            Image(page.imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 250, height: 250)
                .padding(.bottom, 30)

            Text(page.headline)
                .font(.system(size: 28, weight: .bold, design: .serif))
                .foregroundColor(.textPrimary)
                .multilineTextAlignment(.center)

            Text(page.subheadline)
                .font(.body)
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 40)
    }
} 