import SpriteKit

/// Estrella coleccionable de 4 puntas con brillo y titileo.
final class PickupStarNode: SKNode {
    var isTaken = false

    override init() {
        super.init()
        zPosition = -5

        let glow = FX.glowSprite(color: Tunables.goldUI, radius: 22, alpha: 0.5)
        addChild(glow)

        let path = CGMutablePath()
        for i in 0..<8 {
            let r: CGFloat = i % 2 == 0 ? 9 : 3.8
            let a = CGFloat(i) * .pi / 4
            let p = CGPoint(x: cos(a) * r, y: sin(a) * r)
            i == 0 ? path.move(to: p) : path.addLine(to: p)
        }
        path.closeSubpath()
        let star = SKShapeNode(path: path)
        star.fillColor = UIColor(red: 1, green: 0.88, blue: 0.59, alpha: 1)
        star.strokeColor = .clear
        star.blendMode = .add
        addChild(star)

        star.run(.repeatForever(.rotate(byAngle: .pi * 2, duration: 9)))
        let bob = SKAction.sequence([.moveBy(x: 0, y: 3, duration: 0.9), .moveBy(x: 0, y: -3, duration: 0.9)])
        bob.timingMode = .easeInEaseOut
        run(.repeatForever(bob))
        let twinkle = SKAction.sequence([
            .fadeAlpha(to: 0.7, duration: Double.random(in: 0.5...0.9)),
            .fadeAlpha(to: 1.0, duration: Double.random(in: 0.5...0.9))
        ])
        star.run(.repeatForever(twinkle))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    func collect(in world: SKNode) {
        guard !isTaken else { return }
        isTaken = true
        FX.burst(in: world, at: position, color: Tunables.goldUI, count: 10, speed: 110, scale: 0.4)
        removeFromParent()
    }
}
