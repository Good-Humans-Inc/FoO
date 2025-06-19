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
    
    // A flag to show a loading indicator while saving.
    @State private var isSaving = false
    
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
                
            case .pronoun:
                PronounInputView(pronoun: $viewModel.pronoun) {
                    withAnimation { currentStep = .goals }
                }
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                
            case .goals:
                GoalsInputView(goals: $viewModel.goals) {
                    withAnimation { currentStep = .specialStickers }
                }
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                
            case .specialStickers:
                SpecialStickerInfoView {
                    Task {
                        isSaving = true
                        do {
                            try await viewModel.completeOnboarding()
                            // The onComplete closure will trigger the AppState to change,
                            // which dismisses the onboarding view.
                            onComplete()
                        } catch {
                            // In a real app, you would show an error alert to the user.
                            print("Error completing onboarding: \(error.localizedDescription)")
                            isSaving = false
                        }
                    }
                }
                .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                
            default:
                // An empty view for any unimplemented cases.
                EmptyView()
            }
            
            // Show a loading overlay if we are saving.
            if isSaving {
                Color.black.opacity(0.4).ignoresSafeArea()
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(2)
            }
        }
    }
} 