import SwiftUI

struct NameInputView: View {
    @Binding var name: String
    var onNext: () -> Void
    
    // A state to programmatically control keyboard focus.
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            VStack(spacing: 30) {
                Text("What should we call you?")
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .multilineTextAlignment(.center)
                
                TextField("Your Name", text: $name)
                    .font(.title2)
                    .padding()
                    .background(.thinMaterial)
                    .cornerRadius(12)
                    .multilineTextAlignment(.center)
                    .submitLabel(.done)
                    // Bind the text field's focus to our state variable.
                    .focused($isTextFieldFocused)
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
            .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            .opacity(name.trimmingCharacters(in: .whitespaces).isEmpty ? 0.6 : 1.0)
            .animation(.easeInOut, value: name.isEmpty)
        }
        .padding(.horizontal, 40)
        .padding(.bottom, 50)
        .onAppear {
            // After a short delay to allow the view transition to complete,
            // automatically focus the text field to bring up the keyboard.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isTextFieldFocused = true
            }
        }
    }
}

struct NameInputView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.themeBackground.ignoresSafeArea()
            NameInputView(name: .constant("Jas"), onNext: {})
        }
    }
} 