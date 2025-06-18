import SwiftUI

/// A view that encapsulates the glass jar and the sticker physics scene.
struct JarContainerView: View {
    let jarScene: JarScene
    let size: CGSize
    
    var body: some View {
        let jarVisualWidth: CGFloat = size.width
        // Make the jar taller by adjusting the aspect ratio multiplier
        let jarVisualHeight: CGFloat = jarVisualWidth * 1.8
        
        let spriteViewWidth = jarVisualWidth * 0.78
        let spriteViewHeight = jarVisualHeight * 0.72
        let spriteViewSize = CGSize(width: spriteViewWidth, height: spriteViewHeight)
        
        ZStack {
            Image("glassJar")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: jarVisualWidth, height: jarVisualHeight)
            
            SpriteView(scene: jarScene)
                .frame(width: spriteViewSize.width, height: spriteViewSize.height)
                .offset(y: 1)
        }
    }
} 