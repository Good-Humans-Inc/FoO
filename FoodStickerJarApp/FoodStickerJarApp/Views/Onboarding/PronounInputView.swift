import SwiftUI

struct PronounInputView: View {
    @Binding var pronoun: String
    var onNext: () -> Void
    
    private let pronounOptions = ["She/Her", "He/Him", "They/Them", "Custom"]
    @State private var showCustomField = false
    private let customFieldID = "customPronounField"

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 20) {
                    Spacer()
                    
                    VStack(spacing: 30) {
                        Text("What are your pronouns?")
                            .font(.system(size: 28, weight: .bold, design: .serif))
                            .multilineTextAlignment(.center)
                        
                        // Pronoun selection buttons
                        ForEach(pronounOptions, id: \.self) { option in
                            Button(action: { selectPronoun(option, proxy: proxy) }) {
                                Text(option)
                                    .font(.headline)
                                    .foregroundColor(isPronounSelected(option) ? .white : .themeAccent)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(isPronounSelected(option) ? Color.themeAccent : Color.clear)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.themeAccent, lineWidth: 2)
                                    )
                            }
                        }
                        
                        // Custom pronoun text field
                        if showCustomField {
                            TextField("Your Pronouns", text: $pronoun)
                                .font(.title2)
                                .padding()
                                .background(.thinMaterial)
                                .cornerRadius(12)
                                .multilineTextAlignment(.center)
                                .submitLabel(.done)
                                .id(customFieldID)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    
                    Spacer()

                    Button(action: onNext) {
                        Text("Next")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.themeAccent)
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
                    }
                    .disabled(pronoun.trimmingCharacters(in: .whitespaces).isEmpty)
                    .opacity(pronoun.trimmingCharacters(in: .whitespaces).isEmpty ? 0.6 : 1.0)
                    .animation(.easeInOut, value: pronoun.isEmpty)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 50)
            }
        }
    }
    
    /// Checks if a given option is the currently selected one.
    private func isPronounSelected(_ option: String) -> Bool {
        if option == "Custom" {
            return showCustomField
        }
        return pronoun == option
    }
    
    private func selectPronoun(_ option: String, proxy: ScrollViewProxy) {
        withAnimation {
            if option == "Custom" {
                showCustomField = true
                pronoun = "" // Clear previous selection
                // After a short delay to let the UI update, scroll to the new field.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    withAnimation {
                        proxy.scrollTo(customFieldID, anchor: .bottom)
                    }
                }
            } else {
                showCustomField = false
                pronoun = option
            }
        }
    }
}

struct PronounInputView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.themeBackground.ignoresSafeArea()
            PronounInputView(pronoun: .constant("They/Them"), onNext: {})
        }
    }
} 