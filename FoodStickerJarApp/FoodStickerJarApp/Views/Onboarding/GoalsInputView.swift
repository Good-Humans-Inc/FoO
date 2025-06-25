import SwiftUI

struct GoalsInputView: View {
    @Binding var goals: [String]
    var onNext: () -> Void

    private let goalOptions = [
        "Understand my eating habits",
        "Practice mindful eating",
        "Find joy in my food choices",
        "Build a healthier relationship with food",
        "Just for fun! (≧◡≦)"
    ]
    
    @State private var customGoal: String = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Spacer()
                
                VStack(spacing: 30) {
                    Text("What brings you to Jas?")
                        .font(.system(size: 28, weight: .bold, design: .serif))
                        .foregroundColor(.textPrimary)
                        .multilineTextAlignment(.center)
                    
                    Text("Select all that apply.")
                        .font(.body)
                        .foregroundColor(.textSecondary)

                    // Goal selection buttons
                    ForEach(goalOptions, id: \.self) { option in
                        Button(action: { toggleGoal(option) }) {
                            Text(option)
                                .font(.headline)
                                .foregroundColor(goals.contains(option) ? .textOnAccent : .themeAccent)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(goals.contains(option) ? Color.themeAccent : Color.clear)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.themeAccent, lineWidth: 2)
                                )
                        }
                    }
                    
                    // Custom goal text field
                    TextField("Or write your own...", text: $customGoal)
                        .font(.headline)
                        .padding()
                        .background(.thinMaterial)
                        .cornerRadius(12)
                        .submitLabel(.done)
                }
                
                Spacer()

                Button(action: {
                    // Add the custom goal to the list if it's not empty
                    if !customGoal.trimmingCharacters(in: .whitespaces).isEmpty {
                        goals.append(customGoal)
                    }
                    onNext()
                }) {
                    Text("Next")
                        .font(.headline)
                        .foregroundColor(.textOnAccent)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.themeAccent)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                }
                .disabled(goals.isEmpty && customGoal.trimmingCharacters(in: .whitespaces).isEmpty)
                .opacity((goals.isEmpty && customGoal.trimmingCharacters(in: .whitespaces).isEmpty) ? 0.6 : 1.0)
                .animation(.easeInOut, value: goals.isEmpty && customGoal.isEmpty)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 50)
        }
    }
    
    private func toggleGoal(_ goal: String) {
        if let index = goals.firstIndex(of: goal) {
            goals.remove(at: index)
        } else {
            goals.append(goal)
        }
    }
}

struct GoalsInputView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.themeBackground.ignoresSafeArea()
            GoalsInputView(goals: .constant(["Just for fun!"]), onNext: {})
        }
    }
} 