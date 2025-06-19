import SpriteKit

class SparkleScene: SKScene {
    
    private var background: UIImage
    private var completion: () -> Void
    private var isSpecial: Bool
    
    private var emitter: SKEmitterNode?

    init(size: CGSize, background: UIImage, isSpecial: Bool, completion: @escaping () -> Void) {
        self.background = background
        self.isSpecial = isSpecial
        self.completion = completion
        super.init(size: size)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        
        backgroundColor = .clear
        
        // Create a crop node to mask the emitter
        let cropNode = SKCropNode()
        cropNode.maskNode = SKSpriteNode(texture: SKTexture(image: background))
        
        // Create and configure the particle emitter
        let sparkleEmitter = SKEmitterNode()
        sparkleEmitter.particleTexture = SKTexture(imageNamed: "spark") // We will need a 'spark.png' asset
        
        // --- Customization for Special vs. Normal Items ---
        if isSpecial {
            // A more intense, golden-orange burst for special items
            sparkleEmitter.particleBirthRate = 2000
            sparkleEmitter.particleLifetime = 2.5
            sparkleEmitter.particleSpeed = 200
            sparkleEmitter.particleScale = 0.3
            sparkleEmitter.particleColor = UIColor(red: 1.0, green: 0.8, blue: 0.4, alpha: 1.0)
            sparkleEmitter.particleColorBlendFactor = 1.0
            sparkleEmitter.particleBlendMode = .add
        } else {
            // The standard, gentler sparkle effect
            sparkleEmitter.particleBirthRate = 800
            sparkleEmitter.particleLifetime = 2.0
            sparkleEmitter.particleScale = 0.2
            // Use dark gray sparkles for the white background.
            sparkleEmitter.particleColor = .darkGray
            sparkleEmitter.particleColorBlendFactor = 1.0 // Use the particle color
            sparkleEmitter.particleBlendMode = .alpha // Standard alpha blending
        }
        
        sparkleEmitter.particleLifetimeRange = 0.5
        sparkleEmitter.particlePositionRange = CGVector(dx: size.width, dy: size.height)
        
        sparkleEmitter.emissionAngle = .pi
        sparkleEmitter.emissionAngleRange = .pi * 2
        
        sparkleEmitter.particleSpeed = 150
        sparkleEmitter.particleSpeedRange = 50
        
        sparkleEmitter.particleScaleRange = 0.1
        sparkleEmitter.particleScaleSpeed = -0.1
        
        sparkleEmitter.particleAlpha = 0.8
        sparkleEmitter.particleAlphaRange = 0.2
        sparkleEmitter.particleAlphaSpeed = -0.5
        
        self.emitter = sparkleEmitter
        
        cropNode.addChild(sparkleEmitter)
        addChild(cropNode)
        
        // Start the animation
        animate()
    }
    
    private func animate() {
        // Stop emitting after a delay
        let stopEmittingAction = SKAction.run {
            self.emitter?.particleBirthRate = 0
        }
        
        // Wait for particles to die out, then call completion
        // Use a longer wait for the more intense special animation
        let waitDuration = isSpecial ? 3.0 : 2.5
        let waitAction = SKAction.wait(forDuration: waitDuration)
        let completionAction = SKAction.run(completion)
        
        run(SKAction.sequence([stopEmittingAction, waitAction, completionAction]))
    }
} 