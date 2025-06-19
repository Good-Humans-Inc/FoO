import SwiftUI
import Combine

@MainActor
class ShelfViewModel: ObservableObject {
    @Published var jars: [JarItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private(set) var userID: String?
    
    private let firestoreService = FirestoreService()
    private let feedbackService = FeedbackService()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        AuthenticationService.shared.$user
            .compactMap { $0?.uid }
            .sink { [weak self] userID in
                self?.userID = userID
                self?.fetchJars()
            }
            .store(in: &cancellables)
    }
    
    @MainActor
    func fetchJars() {
        guard let userID = self.userID else {
            errorMessage = "Error: Not authenticated."
            return
        }
        
        isLoading = true
        
        Task {
            do {
                let fetchedJars = try await firestoreService.fetchJars(for: userID)
                // Sort jars chronologically, oldest to newest.
                self.jars = fetchedJars.sorted { $0.timestamp.dateValue() < $1.timestamp.dateValue() }
                self.errorMessage = nil
            } catch {
                self.errorMessage = "Error fetching jars: \(error.localizedDescription)"
                print(self.errorMessage ?? "")
            }
            isLoading = false
        }
    }
    
    func submitFeedback(_ text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        feedbackService.submitFeedback(message: text)
    }
} 