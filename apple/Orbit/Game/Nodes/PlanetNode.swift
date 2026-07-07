import SpriteKit

/// Planeta con su anillo orbital punteado, brillo, y peligros opcionales
/// (asteroide guardián, deriva lateral, estrella inestable con mecha).
final class PlanetNode: SKNode {
    let bodyRadius: CGFloat
    let ringRadius: CGFloat
    let color: UIColor
    let isUnstable: Bool

    // deriva lateral (planetas errantes)
    let moverAmplitude: CGFloat
    let moverPeriod: CGFloat
    let moverPhase: CGFloat
    let baseX: CGFloat

    // asteroide guardián
    var asteroidAngle: CGFloat
    let asteroidSpeed: CGFloat
    var asteroidRadius: CGFloat
    let hasAsteroid: Bool

    // estrella inestable
    var fuse: TimeInterval = Tunables.fuseTime
    var isLit = false
    var isDead = false

    private let body: SKShapeNode
    private let highlight: SKShapeNode
    private let ring: SKShapeNode
    private let glow: SKSpriteNode
    private let asteroidNode: SKNode?
    private var fuseArc: SKShapeNode?

    init(x: CGFloat, y: CGFloat, bodyRadius: CGFloat, ringRadius: CGFloat,
         color: UIColor, unstable: Bool,
         mover: (amp: CGFloat, per: CGFloat, phase: CGFloat)?,
         asteroid: (angle: CGFloat, speed: CGFloat)?) {
        self.bodyRadius = bodyRadius
        self.ringRadius = ringRadius
        self.color = unstable ? Tunables.unstableColor : color
        self.isUnstable = unstable
        self.baseX = x
        self.moverAmplitude = mover?.amp ?? 0
        self.moverPeriod = mover?.per ?? 1
        self.moverPhase = mover?.phase ?? 0
        self.asteroidAngle = asteroid?.angle ?? 0
        self.asteroidSpeed = asteroid?.speed ?? 0
        self.asteroidRadius = ringRadius
        self.hasAsteroid = asteroid != nil

        glow = FX.glowSprite(color: self.color, radius: ringRadius * 1.15, alpha: 0.22)

        let circle = CGPath(ellipseIn: CGRect(x: -ringRadius, y: -ringRadius,
                                              width: ringRadius * 2, height: ringRadius * 2),
                            transform: nil)
        ring = SKShapeNode(path: circle.copy(dashingWithPhase: CGFloat.random(in: 0...20),
                                             lengths: [4, 9]))
        ring.strokeColor = UIColor.white.withAlphaComponent(0.30)
        ring.lineWidth = 1.4
        ring.fillColor = .clear

        body = SKShapeNode(circleOfRadius: bodyRadius)
        body.fillColor = self.color
        body.strokeColor = .clear

        highlight = SKShapeNode(circleOfRadius: bodyRadius * 0.5)
        highlight.fillColor = UIColor.white.withAlphaComponent(0.22)
        highlight.strokeColor = .clear
        highlight.position = CGPoint(x: -bodyRadius * 0.32, y: bodyRadius * 0.32)

        if asteroid != nil {
            let container = SKNode()
            let rockGlow = FX.glowSprite(color: Tunables.planetColors[0], radius: 16, alpha: 0.5)
            let rock = SKShapeNode(circleOfRadius: 7.5)
            rock.fillColor = UIColor(red: 0.85, green: 0.88, blue: 0.95, alpha: 1)
            rock.strokeColor = .clear
            let crater = SKShapeNode(circleOfRadius: 2.6)
            crater.fillColor = UIColor(red: 0.12, green: 0.16, blue: 0.27, alpha: 0.55)
            crater.strokeColor = .clear
            crater.position = CGPoint(x: 2, y: -1.5)
            container.addChild(rockGlow)
            container.addChild(rock)
            container.addChild(crater)
            container.zPosition = 3
            asteroidNode = container
        } else {
            asteroidNode = nil
        }

        super.init()
        position = CGPoint(x: x, y: y)
        zPosition = 0
        addChild(glow)
        addChild(ring)
        addChild(body)
        addChild(highlight)
        if let asteroidNode { addChild(asteroidNode) }

        // rotación del anillo punteado + respiración sutil del cuerpo
        let spin = SKAction.rotate(byAngle: Bool.random() ? .pi * 2 : -.pi * 2,
                                   duration: Double.random(in: 22...30))
        ring.run(.repeatForever(spin))
        let breathe = SKAction.sequence([
            .scale(to: 1.025, duration: Double.random(in: 1.1...1.6)),
            .scale(to: 0.985, duration: Double.random(in: 1.1...1.6))
        ])
        breathe.timingMode = .easeInEaseOut
        body.run(.repeatForever(breathe))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    /// Avanza deriva, asteroide y mecha. Devuelve true si la mecha llegó a cero.
    func step(_ h: TimeInterval, simTime: TimeInterval, cometOnMe: Bool, cometOrbitRadius: CGFloat) -> Bool {
        if moverAmplitude > 0 {
            position.x = baseX + sin(CGFloat(simTime) / moverPeriod * .pi * 2 + moverPhase) * moverAmplitude
        }
        if hasAsteroid, let asteroidNode {
            asteroidAngle += CGFloat(h) * asteroidSpeed
            let target = cometOnMe ? cometOrbitRadius : ringRadius
            asteroidRadius += (target - asteroidRadius) * min(1, CGFloat(h) * 3)
            asteroidNode.position = CGPoint(x: cos(asteroidAngle) * asteroidRadius,
                                            y: sin(asteroidAngle) * asteroidRadius)
        }
        if isLit && !isDead {
            fuse -= h
            updateFuseArc()
            if fuse <= 0 { return true }
        }
        return false
    }

    func light() {
        guard isUnstable, !isLit else { return }
        isLit = true
        fuse = Tunables.fuseTime
        glow.run(.repeatForever(.sequence([
            .fadeAlpha(to: 0.5, duration: 0.12),
            .fadeAlpha(to: 0.25, duration: 0.12)
        ])))
        let pulse = SKAction.sequence([.scale(to: 1.09, duration: 0.09), .scale(to: 0.96, duration: 0.09)])
        body.run(.repeatForever(pulse), withKey: "litPulse")
    }

    private func updateFuseArc() {
        fuseArc?.removeFromParent()
        let frac = max(0, min(1, CGFloat(fuse / Tunables.fuseTime)))
        let path = CGMutablePath()
        path.addArc(center: .zero, radius: bodyRadius + 11,
                    startAngle: .pi / 2, endAngle: .pi / 2 + .pi * 2 * frac, clockwise: false)
        let arc = SKShapeNode(path: path)
        arc.strokeColor = Tunables.unstableColor.mixed(with: Tunables.goldUI, t: frac)
        arc.lineWidth = 4
        arc.lineCap = .round
        arc.fillColor = .clear
        arc.zPosition = 4
        addChild(arc)
        fuseArc = arc
    }

    func explode(in world: SKNode) {
        guard !isDead else { return }
        isDead = true
        FX.burst(in: world, at: position, color: Tunables.unstableColor, count: 26, speed: 240, scale: 0.5)
        FX.burst(in: world, at: position, color: Tunables.goldUI, count: 14, speed: 160, scale: 0.38)
        removeFromParent()
    }

    var asteroidWorldPosition: CGPoint? {
        guard hasAsteroid else { return nil }
        return CGPoint(x: position.x + cos(asteroidAngle) * asteroidRadius,
                       y: position.y + sin(asteroidAngle) * asteroidRadius)
    }
}
