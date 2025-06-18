import SwiftUI
import Combine

@MainActor
class ShelfViewModel: ObservableObject {
    @Published var jars: [JarItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private(set) var userID: String?
    
    private let firestoreService = FirestoreService()
    private let authService = AuthenticationService()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        authService.$user
            .compactMap { $0?.uid }
            .sink { [weak self] userID in
                self?.userID = userID
                self?.fetchJars(for: userID)
            }
            .store(in: &cancellables)
    }
    
    func fetchJars(for userID: String) {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let user = try await firestoreService.fetchUser(with: userID)
                let jarItems = try await firestoreService.fetchJars(with: user.jarIDs)
                self.jars = jarItems
                self.isLoading = false
            } catch {
                self.isLoading = false
                self.errorMessage = "Failed to fetch jars: \(error.localizedDescription)"
                print("Error fetching jars: \(error)")
            }
        }
    }
} 