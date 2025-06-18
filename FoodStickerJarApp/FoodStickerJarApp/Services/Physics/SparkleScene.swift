import SpriteKit

class SparkleScene: SKScene {
    
    private var background: UIImage
    private var completion: () -> Void
    
    private var emitter: SKEmitterNode?

    init(size: CGSize, background: UIImage, completion: @escaping () -> Void) {
        self.background = background
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
        sparkleEmitter.particleBirthRate = 800
        sparkleEmitter.particleLifetime = 2.0
        sparkleEmitter.particleLifetimeRange = 0.5
        
        sparkleEmitter.particlePositionRange = CGVector(dx: size.width, dy: size.height)
        
        sparkleEmitter.emissionAngle = .pi
        sparkleEmitter.emissionAngleRange = .pi * 2
        
        sparkleEmitter.particleSpeed = 150
        sparkleEmitter.particleSpeedRange = 50
        
        sparkleEmitter.particleScale = 0.2
        sparkleEmitter.particleScaleRange = 0.1
        sparkleEmitter.particleScaleSpeed = -0.1
        
        sparkleEmitter.particleAlpha = 0.8
        sparkleEmitter.particleAlphaRange = 0.2
        sparkleEmitter.particleAlphaSpeed = -0.5

        sparkleEmitter.particleColorBlendFactor = 1.0
        sparkleEmitter.particleColor = UIColor(red: 0.9, green: 0.8, blue: 0.4, alpha: 1.0) // A warm, golden sparkle
        sparkleEmitter.particleBlendMode = .add // Additive blending for a bright, glowing effect
        
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
        let waitAction = SKAction.wait(forDuration: 2.5) // particleLifetime + buffer
        let completionAction = SKAction.run(completion)
        
        run(SKAction.sequence([stopEmittingAction, waitAction, completionAction]))
    }
} 