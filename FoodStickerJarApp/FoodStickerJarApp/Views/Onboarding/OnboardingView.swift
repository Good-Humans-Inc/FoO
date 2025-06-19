import SwiftUI

struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    
    /// A callback to inform the parent view that onboarding is finished.
    var onComplete: () -> Void
    
    // An enum to represent the current page in the onboarding flow.
    private enum OnboardingStep {
        case welcome
        case intro
        case name
        case age
        case pronoun
        case goals
        case specialStickers
    }
    
    // The current step in the onboarding flow.
    @State private var currentStep: OnboardingStep = .welcome
    
    var body: some View {
        ZStack {
            // A background for the entire onboarding flow.
            Color.themeBackground
                .ignoresSafeArea()

            // Switch on the current step to show the correct view.
            switch currentStep {
            case .welcome:
                WelcomeView {
                    // When continue is tapped in the welcome view,
                    // advance to the next step with an animation.
                    withAnimation {
                        currentStep = .intro
                    }
                }
            case .intro:
                // Placeholder for the next set of screens
                VStack {
                    Text("Intro Placeholder")
                    Button("Finish Onboarding (Temporary)") {
                        onComplete()
                    }
                }
            default:
                Text("Placeholder for other steps")
            }
        }
    }
} 