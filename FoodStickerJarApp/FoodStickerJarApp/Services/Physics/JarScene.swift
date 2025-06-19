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
    var foodItemsById: [UUID: FoodItem] = [:]
    
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
    
    // This is called automatically when the view's size changes.
    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        // Re-create the walls whenever the size changes to ensure they fit.
        createJarBoundary()
    }
    
    // MARK: - Public Methods
    
    /// Removes all sticker nodes from the scene.
    func clear() {
        // Remove all sticker nodes from the scene
        removeChildren(in: children.filter { $0.name?.starts(with: "sticker-") == true })
        foodItemsById.removeAll()
    }
    
    /// Populates the jar with an initial set of stickers when the app loads.
    func populateJar(with items: [FoodItem]) {
        // Clear existing stickers before adding new ones.
        clear()

        for item in items {
            // Asynchronously load the image and add the sticker.
            addSticker(foodItem: item)
        }
    }
    
    /// Adds a new sticker to the scene, either from a provided UIImage or by downloading from a URL.
    func addSticker(foodItem: FoodItem, image: UIImage? = nil) {
        foodItemsById[foodItem.id] = foodItem
        
        if let providedImage = image {
            // If an image is provided directly (e.g., for the report scroll), use it.
            let texture = SKTexture(image: providedImage)
            let node = createStickerNode(for: foodItem, with: texture)
            self.addChild(node)
            // Start the new sticker at the top-center of the jar.
            node.position = CGPoint(x: self.frame.midX, y: self.frame.maxY)
            // Give the sticker a slight downward push to start its fall.
            node.physicsBody?.velocity = CGVector(dx: 0, dy: -50)

        } else {
            // Otherwise, download the thumbnail from the URL for performance.
            guard let url = URL(string: foodItem.thumbnailURLString) else { return }
            KingfisherManager.shared.retrieveImage(with: url) { result in
                switch result {
                case .success(let value):
                    let texture = SKTexture(image: value.image)
                    let node = self.createStickerNode(for: foodItem, with: texture)
                    
                    // Place existing stickers randomly inside the jar.
                    node.position = CGPoint(
                        x: CGFloat.random(in: self.frame.minX...self.frame.maxX),
                        y: CGFloat.random(in: self.frame.minY...self.frame.maxY)
                    )
                    
                    self.addChild(node)
                case .failure(let error):
                    print("Error downloading image for sticker: \(error)")
                }
            }
        }
    }

    /// Animates all stickers to shrink and fade out, then calls a completion handler.
    func animateStickersVanishing(completion: @escaping () -> Void) {
        let stickerNodes = children.filter { $0.name?.starts(with: "sticker-") == true }
        
        guard !stickerNodes.isEmpty else {
            completion()
            return
        }
        
        let shrinkAction = SKAction.scale(to: 0, duration: 0.5)
        let fadeOutAction = SKAction.fadeOut(withDuration: 0.5)
        let groupAction = SKAction.group([shrinkAction, fadeOutAction])
        
        // We want to call the completion only after the last sticker has finished animating.
        let lastNode = stickerNodes.last
        let completionAction = SKAction.run(completion)
        let sequence = SKAction.sequence([groupAction, completionAction])
        
        for node in stickerNodes {
            if node == lastNode {
                node.run(sequence)
            } else {
                node.run(groupAction)
            }
        }
    }

    // MARK: - Private Helper Methods
    
    private func createStickerNode(for foodItem: FoodItem, with texture: SKTexture) -> SKNode {
        let node = SKSpriteNode(texture: texture)
        
        // Use the UUID as the node's name for identification on tap.
        node.name = "sticker-\(foodItem.id.uuidString)"
        
        // Downsize the sticker slightly for a better fit in the jar.
        let scale: CGFloat = 0.9
        node.setScale(scale)
        
        // Resize the sticker to a consistent *maximum* dimension, preserving its aspect ratio.
        let maxStickerDimension: CGFloat = 80.0
        let aspectRatio = texture.size().width / texture.size().height
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

        let rect = self.frame
        
        // Define dimensions for the custom jar shape
        let bottomRadius: CGFloat = 60.0
        let topRadius: CGFloat = 30.0
        let topOpeningWidthRatio: CGFloat = 0.85
        let topShoulderXInset = (rect.width - (rect.width * topOpeningWidthRatio)) / 2
        
        let path = CGMutablePath()
        
        // Start from the bottom-left side
        path.move(to: CGPoint(x: rect.minX, y: rect.minY + bottomRadius))
        
        // Add arcs and lines for the jar shape
        path.addArc(tangent1End: CGPoint(x: rect.minX, y: rect.minY), tangent2End: CGPoint(x: rect.minX + bottomRadius, y: rect.minY), radius: bottomRadius)
        path.addLine(to: CGPoint(x: rect.maxX - bottomRadius, y: rect.minY))
        path.addArc(tangent1End: CGPoint(x: rect.maxX, y: rect.minY), tangent2End: CGPoint(x: rect.maxX, y: rect.minY + bottomRadius), radius: bottomRadius)
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - topRadius))
        path.addArc(tangent1End: CGPoint(x: rect.maxX, y: rect.maxY), tangent2End: CGPoint(x: rect.maxX - topShoulderXInset, y: rect.maxY), radius: topRadius)
        path.addLine(to: CGPoint(x: rect.minX + topShoulderXInset, y: rect.maxY))
        path.addArc(tangent1End: CGPoint(x: rect.minX, y: rect.maxY), tangent2End: CGPoint(x: rect.minX, y: rect.maxY - topRadius), radius: topRadius)
        path.closeSubpath()

        // Create a transformation to move the entire path up by 20 points.
        // var transform = CGAffineTransform(translationX: 0, y: 40)
        // let shiftedPath = path.copy(using: &transform)!
        
        let boundaryNode = SKNode()
        //boundaryNode.physicsBody = SKPhysicsBody(edgeLoopFrom: shiftedPath)
        boundaryNode.physicsBody = SKPhysicsBody(edgeLoopFrom: path)
        boundaryNode.physicsBody?.categoryBitMask = PhysicsCategory.wall
        boundaryNode.physicsBody?.friction = 0.0
        
        addChild(boundaryNode)
    }
    
    // MARK: - Physics Contact Delegate
    
    func didBegin(_ contact: SKPhysicsContact) {
        // Implement the logic for handling contact events
    }
}
