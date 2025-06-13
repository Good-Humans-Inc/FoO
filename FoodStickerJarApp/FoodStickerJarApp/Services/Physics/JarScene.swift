import SpriteKit
import CoreMotion
import Combine

class JarScene: SKScene, SKPhysicsContactDelegate {
    
    // MARK: - Properties
    
    private let motionManager = CMMotionManager()
    
    // A Combine publisher that will send the ID of a tapped sticker.
    // The HomeViewModel will subscribe to this.
    let onStickerTapped = PassthroughSubject<UUID, Never>()
    
    // Constants for physics categories to identify nodes.
    private struct PhysicsCategory {
        static let sticker: UInt32 = 0x1 << 0 // Bitmask for stickers
        static let wall: UInt32 = 0x1 << 1    // Bitmask for jar walls
    }
    
    // MARK: - Scene Lifecycle
    
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        
        // Basic scene setup
        backgroundColor = .clear
        physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
        physicsWorld.contactDelegate = self
        
        // Start listening for device motion to update gravity.
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 0.2
            motionManager.startDeviceMotionUpdates(to: .main) { [weak self] (data, error) in
                guard let self = self, let data = data else { return }
                let gravity = data.gravity
                self.physicsWorld.gravity = CGVector(dx: gravity.x * 12, dy: gravity.y * 12)
            }
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        
        // Find the node at the touch location.
        if let tappedNode = nodes(at: location).first(where: { $0.name != nil }),
           let nodeName = tappedNode.name,
           let itemID = UUID(uuidString: nodeName) {
            
            // Send the UUID of the tapped sticker through the publisher.
            onStickerTapped.send(itemID)
        }
    }
    
    // This is called automatically when the view's size changes.
    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        // Re-create the walls whenever the size changes to ensure they fit.
        createJarBoundary()
    }
    
    // MARK: - Public Methods
    
    /// Populates the jar with an initial set of stickers when the app loads.
    func populateJar(with items: [FoodItem]) {
        for item in items {
            guard let image = item.thumbnailImage else { continue }
            let node = createStickerNode(for: item.id, image: image)
            // Place existing stickers randomly inside the jar.
            node.position = CGPoint(
                x: CGFloat.random(in: frame.minX...frame.maxX),
                y: CGFloat.random(in: frame.minY...frame.maxY)
            )
            addChild(node)
        }
    }
    
    /// Adds a single new sticker, animating it falling from the top.
    func addSticker(item: FoodItem) {
        // Also use the thumbnail for the newly added sticker in the scene.
        guard let image = item.thumbnailImage else { return }
        let node = createStickerNode(for: item.id, image: image)
        
        // Start the new sticker at the top-center of the jar.
        node.position = CGPoint(x: frame.midX, y: frame.maxY)
        
        // Give the sticker a slight downward push to start its fall.
        node.physicsBody?.velocity = CGVector(dx: 0, dy: -50)
        
        addChild(node)
    }

    // MARK: - Private Helper Methods
    
    private func createStickerNode(for id: UUID, image: UIImage) -> SKNode {
        let texture = SKTexture(image: image)
        let node = SKSpriteNode(texture: texture)
        
        // Use the UUID as the node's name for identification on tap.
        node.name = id.uuidString
        
        // Resize the sticker to a consistent *maximum* dimension, preserving its aspect ratio.
        let maxStickerDimension: CGFloat = 80.0
        let aspectRatio = image.size.width / image.size.height
        var stickerSize: CGSize
        if aspectRatio > 1 { // Wider than tall
            stickerSize = CGSize(width: maxStickerDimension, height: maxStickerDimension / aspectRatio)
        } else { // Taller than wide, or square
            stickerSize = CGSize(width: maxStickerDimension * aspectRatio, height: maxStickerDimension)
        }
        node.size = stickerSize
        
        // Create a more accurate physics body from the texture's shape, using the corrected size.
        node.physicsBody = SKPhysicsBody(texture: texture, size: node.size)
        node.physicsBody?.categoryBitMask = PhysicsCategory.sticker
        node.physicsBody?.collisionBitMask = PhysicsCategory.sticker | PhysicsCategory.wall
        node.physicsBody?.contactTestBitMask = PhysicsCategory.wall
        node.physicsBody?.usesPreciseCollisionDetection = true // Prevents tunneling through walls.
        
        // Adjust physics properties to be less "sticky" and more "bouncy".
        node.physicsBody?.restitution = 0.4 // Increased bounciness
        node.physicsBody?.friction = 0.1    // Reduced friction
        node.physicsBody?.allowsRotation = true
        
        return node
    }
    
    private func createJarBoundary() {
        // Remove old walls before creating new ones.
        self.children.filter { $0.physicsBody?.categoryBitMask == PhysicsCategory.wall }.forEach { $0.removeFromParent() }

        // --- FIX: Create a fully-enclosed, jar-shaped boundary ---
        let rect = self.frame
        
        // Define dimensions for the custom jar shape to match the visual asset
        let bottomRadius: CGFloat = 60.0
        let topRadius: CGFloat = 30.0
        let topOpeningWidthRatio: CGFloat = 0.85 // Mouth of jar is 85% of the total width
        let topShoulderXInset = (rect.width - (rect.width * topOpeningWidthRatio)) / 2
        
        let path = CGMutablePath()
        
        // Start from the bottom-left side
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + bottomRadius))
        
        // Rounded bottom corners and straight bottom line
        path.addArc(tangent1End: CGPoint(x: rect.minX, y: rect.minY), tangent2End: CGPoint(x: rect.minX + bottomRadius, y: rect.minY), radius: bottomRadius)
        path.addLine(to: CGPoint(x: rect.maxX - bottomRadius, y: rect.minY))
        path.addArc(tangent1End: CGPoint(x: rect.maxX, y: rect.minY), tangent2End: CGPoint(x: rect.maxX, y: rect.minY + bottomRadius), radius: bottomRadius)
        
        // Right wall
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - topRadius))
        
        // Top-right "shoulder" of the jar
        path.addArc(tangent1End: CGPoint(x: rect.maxX, y: rect.maxY), tangent2End: CGPoint(x: rect.maxX - topShoulderXInset, y: rect.maxY), radius: topRadius)
        
        // Top opening
        path.addLine(to: CGPoint(x: rect.minX + topShoulderXInset, y: rect.maxY))
        
        // Top-left "shoulder" of the jar
        path.addArc(tangent1End: CGPoint(x: rect.minX, y: rect.maxY), tangent2End: CGPoint(x: rect.minX, y: rect.maxY - topRadius), radius: topRadius)

        // Close the path to form a complete loop (connects back to the starting point via the left wall).
        path.closeSubpath()

        let boundaryNode = SKNode()
        // Use edgeLoopFrom, which is perfect for a closed container.
        boundaryNode.physicsBody = SKPhysicsBody(edgeLoopFrom: path)
        boundaryNode.physicsBody?.categoryBitMask = PhysicsCategory.wall
        boundaryNode.physicsBody?.friction = 0.0
        
        addChild(boundaryNode)
    }
}
