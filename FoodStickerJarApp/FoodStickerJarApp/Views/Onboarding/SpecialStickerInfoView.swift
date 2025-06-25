import SwiftUI

struct SpecialStickerInfoView: View {
    var onStart: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            VStack(spacing: 30) {
                Text("Discover Rare Stickers!")
                    .font(.system(size: 28, weight: .bold, design: .serif))
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)

                (Text("Every sticker you create has a chance of being ")
                    + Text("rare")
                        .bold()
                        .foregroundColor(.themeAccent)
                    + Text(". These special stickers have a unique holographic look and unlock a fun story just for you."))
                    .font(.body)
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                
                // Visual comparison of stickers
                HStack(spacing: 30) {
                    VStack {
                        Image("normalToastSticker")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                        Text("Normal")
                            .font(.headline)
                            .foregroundColor(.textPrimary)
                    }
                    
                    VStack {
                        Image("rareToastSticker")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 100, height: 100)
                        Text("Rare!")
                            .font(.headline)
                            .foregroundColor(.textPrimary)
                    }
                }
                
                Text("There's a \(Int(AppConfig.specialItemProbability * 100))% chance for each sticker to be rare!")
                    .font(.caption)
                    .foregroundColor(.textSecondary)
            }
            
            Spacer()

            Button(action: onStart) {
                Text("Let's Start!")
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

struct SpecialStickerInfoView_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.themeBackground.ignoresSafeArea()
            SpecialStickerInfoView(onStart: {})
        }
    }
} 