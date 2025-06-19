import SwiftUI

struct IntroCarouselView: View {
    /// An action to perform when the user finishes the carousel.
    var onContinue: () -> Void

    // The data for the carousel pages.
    private let pages: [IntroPage] = [
        .init(imageName: "snapFood", headline: "Snap your food", subheadline: "Turn any meal or snack into a cute sticker."),
        .init(imageName: "fillJar", headline: "Collect your moments", subheadline: "Fill your jar and see your food journey in a new light."),
        .init(imageName: "mindful", headline: "Mindful, not meticulous", subheadline: "You won't find calorie math here. Only a healthy, sustainable relationship with food built on mindfulness, positivity, and curiosity."),
        .init(imageName: "person.3.fill", headline: "Made with ❤️ by two friends", subheadline: "We couldn't find a food app that celebrates every bite, so we built our own.")
    ]

    // The index of the currently displayed page.
    @State private var currentPageIndex = 0

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            // The swipeable tab view for the carousel pages.
            TabView(selection: $currentPageIndex) {
                ForEach(pages.indices, id: \.self) { index in
                    // Use a special layout for the final "founders" page.
                    if index == pages.count - 1 {
                        FoundersIntroView(page: pages[index])
                            .tag(index)
                    } else {
                        IntroPageView(page: pages[index])
                            .tag(index)
                    }
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

/// A special view for the final "founders" page of the intro carousel.
private struct FoundersIntroView: View {
    let page: IntroPage
    
    var body: some View {
        VStack(spacing: 20) {
            // Display the two founder stickers side-by-side.
            HStack {
                Image("lanruoSticker")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150)
                
                Image("yanSticker")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 150)
            }
            .padding(.bottom, 30)

            Text(page.headline)
                .font(.system(size: 28, weight: .bold, design: .serif))
                .multilineTextAlignment(.center)

            Text(page.subheadline)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 40)
    }
}

struct IntroCarouselView_Previews: PreviewProvider {
    static var previews: some View {
        IntroCarouselView(onContinue: {})
    }
} 