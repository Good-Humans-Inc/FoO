import Foundation

@MainActor
class OnboardingViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var age: Int = 25
} 