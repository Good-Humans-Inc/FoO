import SwiftUI

struct IntroCarouselView: View {
    /// An action to perform when the user finishes the carousel.
    var onContinue: () -> Void

    // The data for the carousel pages.
    private let pages: [IntroPage] = [
        .init(imageName: "camera.fill", headline: "Snap a food memory.", subheadline: "Turn any meal into a cute sticker."),
        .init(imageName: "sparkles", headline: "Collect your moments.", subheadline: "Fill your jar and see your habits in a new light."),
        .init(imageName: "heart.text.square.fill", headline: "Mindful, not meticulous.", subheadline: "It's about celebrating your journey, not counting calories."),
        .init(imageName: "person.3.fill", headline: "Made with ❤️ by...", subheadline: "An all-female team dedicated to joyful wellness.")
    ]

    // The index of the currently displayed page.
    @State private var currentPageIndex = 0

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            // The swipeable tab view for the carousel pages.
            TabView(selection: $currentPageIndex) {
                ForEach(pages.indices, id: \.self) { index in
                    IntroPageView(page: pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            Spacer()

            // The button to advance to the next page or finish the flow.
            Button(action: handleButtonTap) {
                Text(currentPageIndex < pages.count - 1 ? "Next" : "Continue")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.themeAccent)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
            }
            .padding(.horizontal, 40)
        }
        .padding(.bottom, 50)
    }
    
    /// Handles the logic for the main button tap.
    private func handleButtonTap() {
        if currentPageIndex < pages.count - 1 {
            // If it's not the last page, go to the next one with an animation.
            withAnimation {
                currentPageIndex += 1
            }
        } else {
            // If it is the last page, call the onContinue closure.
            onContinue()
        }
    }
}

struct IntroCarouselView_Previews: PreviewProvider {
    static var previews: some View {
        IntroCarouselView(onContinue: {})
    }
} 