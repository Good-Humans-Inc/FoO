import SwiftUI

struct SpecialStickerInfoView: View {
    var onStart: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            VStack(spacing: 30) {
                Text("Discover Rare Stickers!")
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .multilineTextAlignment(.center)

                (Text("Every sticker you create has a chance of being ")
                    + Text("rare")
                        .bold()
                        .foregroundColor(.themeAccent)
                    + Text(". These special stickers have a unique holographic look and unlock a fun story or poem just for you."))
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                // Visual comparison of stickers
                HStack(spacing: 30) {
                    VStack {
                        Image(systemName: "face.smiling.fill")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.gray)
                        Text("Normal")
                            .font(.headline)
                    }
                    
                    VStack {
                        Image(systemName: "sparkles")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .foregroundColor(.themeAccent)
                        Text("Rare!")
                            .font(.headline)
                    }
                }
                
                Text("There's currently a \(Int(AppConfig.specialItemProbability * 100))% chance for each sticker!")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()

            Button(action: onStart) {
                Text("Let's Start!")
                    .font(.headline)
                    .foregroundColor(.white)
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

struct SpecialStickerInfoView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.themeBackground.ignoresSafeArea()
            SpecialStickerInfoView(onStart: {})
        }
    }
} 