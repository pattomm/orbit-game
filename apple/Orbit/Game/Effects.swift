import SpriteKit

/// Texturas generadas por código y efectos reutilizables.
/// Un solo sprite radial blanco se tiñe por nodo (colorBlendFactor),
/// evitando shaders de blur por-frame: mismo truco de rendimiento
/// que la versión original, pero acelerado por Metal.
enum FX {
    static let glowTexture: SKTexture = {
        let size = 128
        let space = CGColorSpace(name: CGColorSpace.sRGB)!
        let ctx = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8,
                            bytesPerRow: 0, space: space,
                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        let colors = [CGColor(gray: 1, alpha: 1), CGColor(gray: 1, alpha: 0)] as CFArray
        let grad = CGGradient(colorsSpace: space, colors: colors, locations: [0, 1])!
        ctx.drawRadialGradient(grad,
                               startCenter: CGPoint(x: 64, y: 64), startRadius: 2,
                               endCenter: CGPoint(x: 64, y: 64), endRadius: 62, options: [])
        return SKTexture(cgImage: ctx.makeImage()!)
    }()

    static let dotTexture: SKTexture = {
        let size = 32
        let space = CGColorSpace(name: CGColorSpace.sRGB)!
        let ctx = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8,
                            bytesPerRow: 0, space: space,
                            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        let colors = [CGColor(gray: 1, alpha: 1), CGColor(gray: 1, alpha: 0.9), CGColor(gray: 1, alpha: 0)] as CFArray
        let grad = CGGradient(colorsSpace: space, colors: colors, locations: [0, 0.45, 1])!
        ctx.drawRadialGradient(grad,
                               startCenter: CGPoint(x: 16, y: 16), startRadius: 1,
                               endCenter: CGPoint(x: 16, y: 16), endRadius: 15, options: [])
        return SKTexture(cgImage: ctx.makeImage()!)
    }()

    static func glowSprite(color: UIColor, radius: CGFloat, alpha: CGFloat) -> SKSpriteNode {
        let node = SKSpriteNode(texture: glowTexture)
        node.size = CGSize(width: radius * 2, height: radius * 2)
        node.color = color
        node.colorBlendFactor = 1
        node.alpha = alpha
        node.blendMode = .add
        return node
    }

    /// Ráfaga de partículas one-shot (GPU vía SKEmitterNode).
    static func burst(in parent: SKNode, at position: CGPoint, color: UIColor,
                      count: Int, speed: CGFloat, scale: CGFloat, lifetime: CGFloat = 0.7) {
        let e = SKEmitterNode()
        e.particleTexture = dotTexture
        e.position = position
        e.numParticlesToEmit = count
        e.particleBirthRate = CGFloat(count) * 60
        e.particleLifetime = lifetime
        e.particleLifetimeRange = lifetime * 0.5
        e.particleSpeed = speed
        e.particleSpeedRange = speed * 0.8
        e.emissionAngleRange = .pi * 2
        e.particleScale = scale
        e.particleScaleRange = scale * 0.5
        e.particleScaleSpeed = -scale / lifetime
        e.particleAlpha = 0.9
        e.particleAlphaSpeed = -1.1 / lifetime
        e.particleColor = color
        e.particleColorBlendFactor = 1
        e.particleBlendMode = .add
        e.zPosition = 15
        parent.addChild(e)
        e.run(.sequence([.wait(forDuration: TimeInterval(lifetime) * 1.6), .removeFromParent()]))
    }

    /// Onda expansiva circular al capturar una órbita.
    static func ringPulse(in parent: SKNode, at position: CGPoint, radius: CGFloat) {
        let ring = SKShapeNode(circleOfRadius: radius)
        ring.position = position
        ring.strokeColor = .white
        ring.lineWidth = 2.5
        ring.fillColor = .clear
        ring.alpha = 0.7
        ring.blendMode = .add
        ring.zPosition = 14
        parent.addChild(ring)
        ring.run(.sequence([
            .group([.scale(to: 1.45, duration: 0.45), .fadeOut(withDuration: 0.45)]),
            .removeFromParent()
        ]))
    }

    /// Texto flotante que sube y se desvanece (+30, hitos, etc.).
    static func floatingLabel(in parent: SKNode, at position: CGPoint,
                              text: String, color: UIColor, size: CGFloat) {
        let label = SKLabelNode(fontNamed: "ChakraPetch-Bold")
        label.text = text
        label.fontSize = size
        label.fontColor = color
        label.position = position
        label.zPosition = 20
        label.verticalAlignmentMode = .center
        parent.addChild(label)
        label.run(.sequence([
            .group([.moveBy(x: 0, y: 30, duration: 0.9),
                    .sequence([.wait(forDuration: 0.35), .fadeOut(withDuration: 0.55)])]),
            .removeFromParent()
        ]))
    }
}
