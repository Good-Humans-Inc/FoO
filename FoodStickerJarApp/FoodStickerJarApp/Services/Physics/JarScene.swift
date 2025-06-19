import SpriteKit
import CoreMotion
import Combine
import Kingfisher

class JarScene: SKScene, SKPhysicsContactDelegate {
    
    // MARK: - Properties
    
    private let motionManager = CMMotionManager()
    
    // A Combine publisher that will send the ID of a tapped sticker.
    // The HomeViewModel will subscribe to this.
    let onStickerTapped = PassthroughSubject<UUID, Never>()
    
    // A hard limit on the speed of any sticker to prevent tunneling and instability.
    private let maxStickerSpeed: CGFloat = 800.0
    
    // Properties to handle dragging stickers
    private var draggedNode: SKNode?
    private var touchStartPos: CGPoint?
    private var nodeStartPos: CGPoint?
    
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
        
        // Find a sticker node at the touch location.
        if let node = self.nodes(at: location).first(where: { $0.physicsBody?.categoryBitMask == PhysicsCategory.sticker }) {
            // Start tracking the node for a potential drag or tap.
            draggedNode = node
            touchStartPos = location
            nodeStartPos = node.position
            // Temporarily disable physics simulation for the dragged node.
            node.physicsBody?.isDynamic = false
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let draggedNode = self.draggedNode, let touchStartPos = self.touchStartPos, let nodeStartPos = self.nodeStartPos else { return }
        
        // Calculate the new position based on the drag distance.
        let location = touch.location(in: self)
        let dx = location.x - touchStartPos.x
        let dy = location.y - touchStartPos.y
        draggedNode.position = CGPoint(x: nodeStartPos.x + dx, y: nodeStartPos.y + dy)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, let draggedNode = self.draggedNode, let touchStartPos = self.touchStartPos else {
            // If nothing was being dragged, do nothing.
            cleanupDrag()
            return
        }

        // Determine if the action was a tap or a drag.
        let location = touch.location(in: self)
        let distance = hypot(location.x - touchStartPos.x, location.y - touchStartPos.y)
        
        if distance < 15 { // Treat as a tap if movement was minimal.
            if let nodeName = draggedNode.name, let itemID = UUID(uuidString: nodeName) {
                onStickerTapped.send(itemID)
            }
        } else {
            // This was a drag. Check if the sticker is outside the jar.
            if !self.frame.contains(draggedNode.position) {
                // If outside, reset its position to the top to drop it back in.
                draggedNode.position = CGPoint(x: self.frame.midX, y: self.frame.maxY)
            }
        }
        
        // Re-enable physics and clean up.
        cleanupDrag()
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        cleanupDrag()
    }
    
    private func cleanupDrag() {
        if let draggedNode = self.draggedNode {
            // Re-enable physics simulation for the node.
            draggedNode.physicsBody?.isDynamic = true
        }
        // Reset tracking properties.
        self.draggedNode = nil
        self.touchStartPos = nil
        self.nodeStartPos = nil
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
        
        // --- PERFORMANCE: Limit the maximum velocity of all stickers ---
        // This prevents objects from gaining excessive speed (e.g., from a violent shake)
        // which can cause them to tunnel through the jar walls or behave erratically.
        for node in self.children {
            if node.physicsBody?.categoryBitMask == PhysicsCategory.sticker {
                guard let physicsBody = node.physicsBody else { continue }
                
                let speed = hypot(physicsBody.velocity.dx, physicsBody.velocity.dy)
                
                if speed > maxStickerSpeed {
                    // Calculate the ratio of the current speed to the max speed.
                    let ratio = maxStickerSpeed / speed
                    // Scale down the velocity vector to match the max speed.
                    physicsBody.velocity = CGVector(dx: physicsBody.velocity.dx * ratio, dy: physicsBody.velocity.dy * ratio)
                }
            }
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
        // Clear existing stickers before adding new ones.
        self.children.filter { $0.physicsBody?.categoryBitMask == PhysicsCategory.sticker }.forEach { $0.removeFromParent() }

        for item in items {
            // Asynchronously load the image and add the sticker.
            addSticker(item: item, isInitialPopulation: true)
        }
    }
    
    /// Adds a single new sticker, animating it falling from the top.
    func addSticker(item: FoodItem, isInitialPopulation: Bool = false) {
        guard let url = URL(string: item.thumbnailURLString) else { return }
        
        // Use Kingfisher to download the image from the URL.
        ImageDownloader.default.downloadImage(with: url) { [weak self] result in
            guard let self = self else { return }
            
            if case .success(let value) = result {
                // Ensure UI updates are on the main thread.
                DispatchQueue.main.async {
                    let node = self.createStickerNode(for: item.id, image: value.image)
                    
                    if isInitialPopulation {
                        // Place existing stickers randomly inside the jar.
                        node.position = CGPoint(
                            x: CGFloat.random(in: self.frame.minX...self.frame.maxX),
                            y: CGFloat.random(in: self.frame.minY...self.frame.maxY)
                        )
                    } else {
                        // Start the new sticker at the top-center of the jar.
                        node.position = CGPoint(x: self.frame.midX, y: self.frame.maxY)
                        // Give the sticker a slight downward push to start its fall.
                        node.physicsBody?.velocity = CGVector(dx: 0, dy: -50)
                    }
                    
                    self.addChild(node)
                }
            }
        }
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
        
        // --- OPTIMIZATION: Create a simplified physics body ---
        // 1. Create a very low-resolution version of the image. This drastically
        //    reduces the vertex count of the resulting physics polygon and makes it
        //    "smoother" and less likely to snag on the thin jar boundary.
        let physicsImage = image.resized(toMaxSize: 30) // Further reduced for stability
        let physicsTexture = SKTexture(image: physicsImage)
        
        // 2. Create the physics body from the LOW-RES texture, but scale it to the
        //    correct visual size of the node. This maintains the sticker's shape
        //    while using a much simpler polygon for calculations.
        node.physicsBody = SKPhysicsBody(texture: physicsTexture, size: node.size)
        
        // Create a more accurate physics body from the texture's shape, using the corrected size.
        node.physicsBody?.categoryBitMask = PhysicsCategory.sticker
        node.physicsBody?.collisionBitMask = PhysicsCategory.sticker | PhysicsCategory.wall
        node.physicsBody?.contactTestBitMask = PhysicsCategory.wall
        node.physicsBody?.usesPreciseCollisionDetection = true // Prevents tunneling through walls.
        
        // Adjust physics properties for stability and feel.
        node.physicsBody?.restitution = 0.1 // Reduced bounciness to prevent jitter.
        node.physicsBody?.friction = 0.4    // Increased friction to help objects settle.
        node.physicsBody?.allowsRotation = true
        
        // --- FIX: Add damping to prevent vibration ---
        // Damping gradually reduces the sticker's linear and angular velocity over
        // time, helping it to come to a complete stop and enter a resting state.
        // This is the key to preventing jittering in a large stack of objects.
        node.physicsBody?.linearDamping = 0.5
        node.physicsBody?.angularDamping = 0.5
        
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
