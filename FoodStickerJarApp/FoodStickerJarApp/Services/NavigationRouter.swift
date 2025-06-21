import Foundation
import Combine

@MainActor
class NavigationRouter: ObservableObject {
    @Published var selectedFoodItem: FoodItem? = nil
} 