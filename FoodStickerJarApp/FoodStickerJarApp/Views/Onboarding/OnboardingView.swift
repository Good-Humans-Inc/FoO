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
                    withAnimation { currentStep = .intro }
                }
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                
            case .intro:
                IntroCarouselView {
                    withAnimation { currentStep = .name }
                }
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                
            case .name:
                NameInputView(name: $viewModel.name) {
                    withAnimation { currentStep = .age }
                }
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                
            case .age:
                AgeInputView(age: $viewModel.age) {
                    withAnimation { currentStep = .pronoun }
                }
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                
            default:
                // A single placeholder for all subsequent steps.
                VStack {
                    Text("Placeholder for: \(String(describing: currentStep))")
                    Button("Finish Onboarding (Temporary)") {
                        onComplete()
                    }
                }
            }
        }
    }
} 