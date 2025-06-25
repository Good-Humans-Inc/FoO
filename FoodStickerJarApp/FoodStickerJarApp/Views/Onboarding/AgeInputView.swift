import SwiftUI

struct AgeInputView: View {
    @Binding var age: Int
    var onNext: () -> Void
    
    // A reasonable range for age selection.
    private let ageRange = 13...100

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            VStack(spacing: 30) {
                Text("How old are you?")
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)

                Picker("Age", selection: $age) {
                    ForEach(ageRange, id: \.self) { number in
                        Text("\(number)")
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 150) // Give the picker a fixed height
            }
            
            Spacer()

            Button(action: onNext) {
                Text("Next")
                    .font(.headline)
                    .foregroundColor(.textOnAccent)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.themeAccent)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
            }
        }
        .padding(.horizontal, 40)
        .padding(.bottom, 50)
    }
}

struct AgeInputView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.themeBackground.ignoresSafeArea()
            AgeInputView(age: .constant(25), onNext: {})
        }
    }
} 