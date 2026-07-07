import SpriteKit

/// El cometa del jugador: núcleo blanco, halo aguamarina y estela de
/// partículas GPU que persiste en el espacio del mundo.
final class CometNode: SKNode {
    private let core: SKShapeNode
    private let halo: SKSpriteNode
    let trail: SKEmitterNode

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
        trail.particleBirthRate = active ? 130 : 0
    }
}
