import SpriteKit

/// Agujero negro: núcleo letal, arcos giratorios y espirales de materia
/// cayendo (partículas que siguen trayectorias espirales).
final class BlackHoleNode: SKNode {
    static let coreRadius: CGFloat = 20
    static let reach: CGFloat = 270

    private var spiralTimer: TimeInterval = 0

    override init() {
        super.init()
        zPosition = -20

        let glow = FX.glowSprite(color: Tunables.violet, radius: 85, alpha: 0.5)
        addChild(glow)

        let core = SKShapeNode(circleOfRadius: Self.coreRadius)
        core.fillColor = UIColor(red: 0.01, green: 0.01, blue: 0.04, alpha: 1)
        core.strokeColor = Tunables.violet.withAlphaComponent(0.8)
        core.lineWidth = 1.5
        addChild(core)

        for (radius, duration, clockwise) in [(CGFloat(34), 4.6, true), (CGFloat(46), 7.4, false)] {
            let circle = CGPath(ellipseIn: CGRect(x: -radius, y: -radius, width: radius * 2, height: radius * 2),
                                transform: nil)
            let arc = SKShapeNode(path: circle.copy(dashingWithPhase: 0, lengths: [10, 16]))
            arc.strokeColor = Tunables.violet.withAlphaComponent(0.6)
            arc.lineWidth = 1.6
            arc.fillColor = .clear
            arc.blendMode = .add
            addChild(arc)
            arc.run(.repeatForever(.rotate(byAngle: clockwise ? -.pi * 2 : .pi * 2, duration: duration)))
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    /// Emite motas que caen en espiral hacia el núcleo.
    func stepSpiral(_ h: TimeInterval) {
        spiralTimer -= h
        guard spiralTimer <= 0 else { return }
        spiralTimer = Double.random(in: 0.10...0.22)

        let a0 = CGFloat.random(in: 0...(2 * .pi))
        let r0 = CGFloat.random(in: 48...68)
        let path = CGMutablePath()
        path.move(to: CGPoint(x: cos(a0) * r0, y: sin(a0) * r0))
        var a = a0, r = r0
        for _ in 0..<14 {
            a += 0.42
            r *= 0.82
            path.addLine(to: CGPoint(x: cos(a) * r, y: sin(a) * r))
        }
        let mote = SKSpriteNode(texture: FX.dotTexture)
        mote.size = CGSize(width: 5, height: 5)
        mote.color = Tunables.violet
        mote.colorBlendFactor = 1
        mote.blendMode = .add
        mote.alpha = 0.85
        addChild(mote)
        mote.run(.sequence([
            .group([.follow(path, asOffset: false, orientToPath: false, duration: 0.8),
                    .fadeOut(withDuration: 0.8)]),
            .removeFromParent()
        ]))
    }
}
