import SpriteKit

/// El cometa del jugador: núcleo blanco, halo aguamarina y estela de
/// partículas GPU que persiste en el espacio del mundo.
final class CometNode: SKNode {
    private let core: SKShapeNode
    private let halo: SKSpriteNode
    let trail: SKEmitterNode
    private var baselineBirthRate: CGFloat = 130

    override init() {
        core = SKShapeNode(circleOfRadius: 5.4)
        core.fillColor = .white
        core.strokeColor = .clear

        halo = FX.glowSprite(color: Tunables.aqua, radius: 20, alpha: 0.75)

        trail = SKEmitterNode()
        trail.particleTexture = FX.dotTexture
        trail.particleBirthRate = 130
        trail.particleLifetime = 0.42
        trail.particleLifetimeRange = 0.15
        trail.particleSpeed = 4
        trail.particleSpeedRange = 6
        trail.emissionAngleRange = .pi * 2
        trail.particleScale = 0.42
        trail.particleScaleSpeed = -0.9
        trail.particleAlpha = 0.55
        trail.particleAlphaSpeed = -1.3
        trail.particleColor = Tunables.aqua
        trail.particleColorBlendFactor = 1
        trail.particleBlendMode = .add
        trail.zPosition = 9

        super.init()
        zPosition = 10
        addChild(halo)
        addChild(trail)
        addChild(core)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    /// Parpadeo durante la invulnerabilidad post-captura.
    func setBlink(_ blinking: Bool, time: TimeInterval) {
        let a: CGFloat = blinking ? 0.55 + 0.45 * CGFloat(sin(time * 40)) : 1
        core.alpha = a
        halo.alpha = 0.75 * a
    }

    func setTrailActive(_ active: Bool) {
        trail.particleBirthRate = active ? baselineBirthRate : 0
    }

    /// Aplica un skin: color de halo y parámetros/color de la estela.
    func apply(skin: CometSkin) {
        halo.removeAction(forKey: Self.prismKey)
        trail.removeAction(forKey: Self.prismKey)
        halo.color = skin.trailColor
        trail.particleColorSequence = nil
        trail.particleColor = skin.trailColor
        switch skin.style {
        case .classic:
            trail.particleBirthRate = 130
            trail.particleLifetime = 0.42
            trail.particleScale = 0.42
            trail.particleScaleRange = 0
            trail.particleScaleSpeed = -0.9
            trail.particleAlpha = 0.55
            trail.particleAlphaSpeed = -1.3
            trail.particleSpeed = 4
            trail.particleSpeedRange = 6
        case .sparkle:
            trail.particleBirthRate = 210
            trail.particleLifetime = 0.5
            trail.particleScale = 0.26
            trail.particleScaleRange = 0.22
            trail.particleScaleSpeed = -0.5
            trail.particleAlpha = 0.7
            trail.particleAlphaSpeed = -1.4
            trail.particleSpeed = 12
            trail.particleSpeedRange = 22
        case .bubble:
            trail.particleBirthRate = 70
            trail.particleLifetime = 0.7
            trail.particleScale = 0.62
            trail.particleScaleRange = 0.2
            trail.particleScaleSpeed = -0.55
            trail.particleAlpha = 0.45
            trail.particleAlphaSpeed = -0.65
            trail.particleSpeed = 3
            trail.particleSpeedRange = 5
        case .prism:
            trail.particleBirthRate = 165
            trail.particleLifetime = 0.55
            trail.particleScale = 0.44
            trail.particleScaleRange = 0.1
            trail.particleScaleSpeed = -0.75
            trail.particleAlpha = 0.7
            trail.particleAlphaSpeed = -1.15
            trail.particleSpeed = 4
            trail.particleSpeedRange = 6
            // Cinta arcoíris: en vez de teñir cada partícula a lo largo de su
            // vida (se apagarían antes de recorrer la paleta), ciclamos el color
            // de emisión. Cada partícula conserva el tono con el que nació, así
            // la estela queda como una banda de color a lo largo del recorrido.
            let period: TimeInterval = 2.2
            let cycle = SKAction.customAction(withDuration: period) { node, elapsed in
                let color = CometSkin.prismColor(at: Double(elapsed) / period)
                (node as? SKEmitterNode)?.particleColor = color
            }
            trail.run(.repeatForever(cycle), withKey: Self.prismKey)
            let haloCycle = SKAction.customAction(withDuration: period) { node, elapsed in
                (node as? SKSpriteNode)?.color = CometSkin.prismColor(at: Double(elapsed) / period)
            }
            halo.run(.repeatForever(haloCycle), withKey: Self.prismKey)
        }
        baselineBirthRate = trail.particleBirthRate
    }

    private static let prismKey = "prismCycle"
}
