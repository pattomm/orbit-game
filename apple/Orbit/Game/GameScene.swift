import SpriteKit
import simd
import UIKit

/// Motor del juego. Port 1:1 del motor original ya validado:
/// simulación determinista con substeps fijos de 1/120 s sobre un mundo
/// de 480 unidades de ancho (10 u = 1 m), con SpriteKit/Metal como renderer.
final class GameScene: SKScene {
    // MARK: - Referencias
    private(set) weak var model: GameModel?
    private let world = SKNode()
    private let cam = SKCameraNode()
    private let comet = CometNode()
    private var backgroundSprite: SKSpriteNode!
    private var starfield: StarfieldNode!
    private var guideLine: SKShapeNode!

    // MARK: - Entidades vivas
    private var planets: [PlanetNode] = []
    private var pickups: [PickupStarNode] = []
    private var blackHoles: [BlackHoleNode] = []

    // MARK: - Estado del cometa
    private enum CometMode { case orbit, fly }
    private var cometMode: CometMode = .orbit
    private var currentPlanet: PlanetNode!
    private var orbitAngle: CGFloat = 0
    private var orbitRadius: CGFloat = 92
    private var orbitDirection: CGFloat = 1
    private var orbitTime: TimeInterval = 0
    private var invulnerability: TimeInterval = 0
    private var velocity = CGVector.zero
    private var flyTime: TimeInterval = 0
    private var grace: (planet: PlanetNode, t: TimeInterval)?
    private var wasQuickHop = false
    private var cometPosition = CGPoint.zero

    // MARK: - Estado de la partida
    private var metersMax: CGFloat = 0
    private var starPoints = 0
    private var starCount = 0
    private var combo = 0
    private var hopCount = 0
    private var lastMilestone = 0
    private var spawnY: CGFloat = 0
    private var blackHoleDebt: CGFloat = 9999
    private var deathReason: DeathReason = .void

    // MARK: - Tiempo
    private var lastTime: TimeInterval = 0
    private var accumulator: TimeInterval = 0
    private var simTime: TimeInterval = 0
    private var timeScale: Double = 1
    private var dieTimer: TimeInterval = 0
    private var shake: CGFloat = 0
    private var cameraY: CGFloat = 0
    private var fpsAverage: Double = 60

    // MARK: - Depuración (launch arguments)
    private(set) var autopilot = false
    private var turbo: Double = 1
    private var debugPrintTimer: TimeInterval = 0

    private let reduceMotion = UIAccessibility.isReduceMotionEnabled

    // MARK: - Setup
    override init(size: CGSize) {
        super.init(size: size)
        scaleMode = .resizeFill
        anchorPoint = .zero
        let args = ProcessInfo.processInfo.arguments
        autopilot = args.contains("-autopilot")
        if let i = args.firstIndex(of: "-turbo"), i + 1 < args.count, let v = Double(args[i + 1]) {
            turbo = min(max(v, 1), 8)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    func configure(model: GameModel) {
        self.model = model
    }

    override func didMove(to view: SKView) {
        backgroundColor = Tunables.bgBands[0].bottom
        addChild(world)
        addChild(cam)
        camera = cam

        backgroundSprite = makeBackgroundSprite()
        backgroundSprite.zPosition = -100
        cam.addChild(backgroundSprite)

        starfield = StarfieldNode()
        starfield.zPosition = -90
        cam.addChild(starfield)

        guideLine = SKShapeNode()
        guideLine.strokeColor = UIColor.white.withAlphaComponent(0.5)
        guideLine.lineWidth = 1.5
        guideLine.lineCap = .round
        guideLine.zPosition = 8
        world.addChild(guideLine)

        world.addChild(comet)
        layoutForCurrentSize()
        resetWorld(startMeters: 0)
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        guard cam.parent != nil else { return }
        layoutForCurrentSize()
    }

    private var camScale: CGFloat { Tunables.worldWidth / max(size.width, 1) }
    private var visibleHeight: CGFloat { size.height * camScale }

    private func layoutForCurrentSize() {
        cam.setScale(camScale)
        backgroundSprite.size = CGSize(width: Tunables.worldWidth, height: visibleHeight)
        starfield.regenerate(width: Tunables.worldWidth, height: visibleHeight)
    }

    private func makeBackgroundSprite() -> SKSpriteNode {
        let sprite = SKSpriteNode(texture: FX.dotTexture, size: CGSize(width: 10, height: 10))
        let source = """
        void main() {
            gl_FragColor = mix(u_bottom, u_top, v_tex_coord.y);
        }
        """
        let shader = SKShader(source: source)
        shader.uniforms = [
            SKUniform(name: "u_bottom", vectorFloat4: colorVector(Tunables.bgBands[0].bottom)),
            SKUniform(name: "u_top", vectorFloat4: colorVector(Tunables.bgBands[0].top))
        ]
        sprite.shader = shader
        return sprite
    }

    private func colorVector(_ color: UIColor) -> vector_float4 {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        return vector_float4(Float(r), Float(g), Float(b), 1)
    }

    // MARK: - Ciclo de vida de la partida
    func resetWorld(startMeters: CGFloat) {
        planets.forEach { $0.removeFromParent() }
        pickups.forEach { $0.removeFromParent() }
        blackHoles.forEach { $0.removeFromParent() }
        world.children.filter { $0 is SKEmitterNode || $0 is SKLabelNode }.forEach { $0.removeFromParent() }
        planets = []; pickups = []; blackHoles = []

        combo = 0; starPoints = 0; starCount = 0; hopCount = 0
        lastMilestone = Int(startMeters / 500)
        metersMax = startMeters
        timeScale = 1; shake = 0; accumulator = 0; dieTimer = 0

        let p0 = PlanetNode(x: Tunables.worldWidth / 2, y: startMeters * Tunables.unitsPerMeter,
                            bodyRadius: 22, ringRadius: 92,
                            color: Tunables.planetColors[1], unstable: false, mover: nil, asteroid: nil)
        world.addChild(p0)
        planets = [p0]
        spawnY = p0.position.y
        blackHoleDebt = CGFloat.random(in: 420...700)

        currentPlanet = p0
        cometMode = .orbit
        orbitAngle = .pi / 2
        orbitRadius = 92
        orbitDirection = 1
        orbitTime = 0
        invulnerability = 0
        wasQuickHop = false
        grace = nil
        cometPosition = CGPoint(x: p0.position.x, y: p0.position.y + 92)
        comet.position = cometPosition
        comet.isHidden = false
        comet.setTrailActive(true)

        cameraY = cometPosition.y + visibleHeight * 0.10
        cam.position = CGPoint(x: Tunables.worldWidth / 2, y: cameraY)
        ensureSpawns()
        applyCurrentSkin()
        model?.hudUpdate(meters: Int(metersMax), stars: starCount)
    }

    func applyCurrentSkin() {
        comet.apply(skin: model?.cosmetics.equippedSkin ?? .default)
    }

    // MARK: - Entrada
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard model?.state == .playing else { return }
        jump()
    }

    private func jump() {
        guard model?.state == .playing, cometMode == .orbit else { return }
        wasQuickHop = orbitTime < Tunables.quickHopWindow
        let ux = -sin(orbitAngle) * orbitDirection
        let uy = cos(orbitAngle) * orbitDirection
        velocity = CGVector(dx: ux * Tunables.flightSpeed, dy: uy * Tunables.flightSpeed)
        cometMode = .fly
        flyTime = 0
        grace = (currentPlanet, Tunables.captureGrace)
        FX.burst(in: world, at: cometPosition, color: Tunables.aqua, count: 7, speed: 90, scale: 0.36)
        shake = min(shake + 0.12, 0.5)
        SoundEngine.shared.playWhoosh()
    }

    // MARK: - Bucle principal
    override func update(_ currentTime: TimeInterval) {
        guard let model else { return }
        if lastTime == 0 { lastTime = currentTime; return }
        let raw = min(currentTime - lastTime, 0.05)
        lastTime = currentTime
        if raw > 0 { fpsAverage += (1 / raw - fpsAverage) * 0.04 }

        if model.state == .dying {
            dieTimer += raw
            timeScale += (0.16 - timeScale) * min(1, 9 * raw)
            if dieTimer > 0.85 { completeDeath() }
        }

        var simDt = raw
        if model.state == .playing { simDt *= turbo }
        if model.state == .playing || model.state == .dying { simDt *= timeScale }

        if model.state == .playing || model.state == .menu || model.state == .dying {
            accumulator += simDt
            var iterations = 0
            while accumulator >= Tunables.substep && iterations < 60 {
                step(Tunables.substep)
                accumulator -= Tunables.substep
                iterations += 1
            }
            if model.state == .playing || model.state == .menu { ensureSpawns() }
            updateCamera(dt: max(simDt, raw * 0.4))
        }

        housekeeping(raw)
    }

    private func step(_ h: TimeInterval) {
        guard let model else { return }
        simTime += h

        // animación de planetas (siempre, incluso durante la muerte)
        for p in planets where !p.isDead {
            let onMe = cometMode == .orbit && p === currentPlanet && model.state == .playing
            if p.step(h, simTime: simTime, cometOnMe: onMe, cometOrbitRadius: orbitRadius) {
                explodePlanet(p)
            }
        }
        guard model.state == .playing || model.state == .menu else { return }

        if invulnerability > 0 { invulnerability -= h }

        if model.state == .menu {
            orbitAngle += 1.5 * CGFloat(h)
            cometPosition = CGPoint(x: currentPlanet.position.x + cos(orbitAngle) * orbitRadius,
                                    y: currentPlanet.position.y + sin(orbitAngle) * orbitRadius)
            comet.position = cometPosition
            return
        }

        let metersNow = max(0, cometPosition.y / Tunables.unitsPerMeter)

        switch cometMode {
        case .orbit:
            let p = currentPlanet!
            orbitTime += h
            orbitRadius -= Difficulty(meters: metersNow).decay * CGFloat(h)
            if orbitRadius <= p.bodyRadius + 7 { die(.burn); return }
            let omega = min(max(Tunables.flightSpeed / orbitRadius, Tunables.omegaMin), Tunables.omegaMax) * orbitDirection
            orbitAngle += omega * CGFloat(h)
            cometPosition = CGPoint(x: p.position.x + cos(orbitAngle) * orbitRadius,
                                    y: p.position.y + sin(orbitAngle) * orbitRadius)
            if p.hasAsteroid, invulnerability <= 0, let ast = p.asteroidWorldPosition,
               distanceSquared(cometPosition, ast) < 18 * 18 {
                die(.asteroid); return
            }
            if autopilot { autopilotStep() }

        case .fly:
            flyTime += h
            if var g = grace {
                g.t -= h
                let gp = g.planet
                if g.t <= 0 && (gp.isDead || distanceSquared(cometPosition, gp.position) > pow(gp.ringRadius + 12, 2)) {
                    grace = nil
                } else {
                    grace = g
                }
            }
            for bh in blackHoles {
                let dx = bh.position.x - cometPosition.x
                let dy = bh.position.y - cometPosition.y
                let d2 = dx * dx + dy * dy
                if d2 < BlackHoleNode.reach * BlackHoleNode.reach {
                    let d = sqrt(d2)
                    if d < BlackHoleNode.coreRadius + 6 { die(.blackHole); return }
                    let force = min(90000 / d2, 900)
                    velocity.dx += dx / d * force * CGFloat(h)
                    velocity.dy += dy / d * force * CGFloat(h)
                }
            }
            applyAimAssist(h)
            let speed = hypot(velocity.dx, velocity.dy)
            if speed > Tunables.maxSpeed {
                velocity.dx *= Tunables.maxSpeed / speed
                velocity.dy *= Tunables.maxSpeed / speed
            }
            cometPosition.x += velocity.dx * CGFloat(h)
            cometPosition.y += velocity.dy * CGFloat(h)

            var captured: PlanetNode?
            var capturedDistance: CGFloat = .greatestFiniteMagnitude
            for p in planets where !p.isDead {
                if let g = grace, g.planet === p { continue }
                let d = hypot(p.position.x - cometPosition.x, p.position.y - cometPosition.y)
                if d < p.ringRadius && d < capturedDistance {
                    capturedDistance = d
                    captured = p
                }
            }
            if let captured {
                capture(captured, distance: capturedDistance)
            } else {
                if let g = grace, !g.planet.isDead,
                   distanceSquared(cometPosition, g.planet.position) < pow(g.planet.bodyRadius + 7, 2) {
                    die(.burn); return
                }
                if flyTime > Tunables.flyTimeout
                    || cometPosition.x < -70 || cometPosition.x > Tunables.worldWidth + 70
                    || cometPosition.y < metersMax * Tunables.unitsPerMeter - Tunables.fallBehindLimit {
                    die(.void); return
                }
            }
        }

        comet.position = cometPosition

        // recolección de estrellas (en órbita y en vuelo)
        for s in pickups where !s.isTaken {
            if distanceSquared(cometPosition, s.position) < 30 * 30 { collectStar(s) }
        }

        metersMax = max(metersMax, cometPosition.y / Tunables.unitsPerMeter)
        let milestone = Int(metersMax / 500)
        if milestone > lastMilestone {
            lastMilestone = milestone
            FX.floatingLabel(in: world, at: CGPoint(x: cometPosition.x, y: cometPosition.y + 55),
                             text: "\((milestone * 500).grouped) m",
                             color: UIColor(red: 0.56, green: 0.91, blue: 1, alpha: 1), size: 22)
            SoundEngine.shared.playMilestone()
            HapticsEngine.shared.milestone()
        }
        model.hudUpdate(meters: Int(metersMax), stars: starCount)
    }

    // MARK: - Mecánicas
    private func capture(_ p: PlanetNode, distance: CGFloat) {
        cometMode = .orbit
        currentPlanet = p
        orbitRadius = min(max(distance, p.bodyRadius + 16), p.ringRadius)
        orbitAngle = atan2(cometPosition.y - p.position.y, cometPosition.x - p.position.x)
        let rx = cometPosition.x - p.position.x
        let ry = cometPosition.y - p.position.y
        orbitDirection = (rx * velocity.dy - ry * velocity.dx) >= 0 ? 1 : -1
        orbitTime = 0
        invulnerability = Tunables.captureInvul
        combo = wasQuickHop ? combo + 1 : 1
        wasQuickHop = false
        hopCount += 1
        if p.isUnstable { p.light() }
        FX.ringPulse(in: world, at: p.position, radius: p.ringRadius)
        FX.burst(in: world, at: cometPosition, color: p.color, count: 6, speed: 60, scale: 0.33)
        shake = min(shake + 0.18, 0.6)
        SoundEngine.shared.playPluck(combo: combo)
        HapticsEngine.shared.capture(combo: combo)
        model?.comboChanged(combo)
        if combo >= 2 {
            FX.floatingLabel(in: world, at: CGPoint(x: cometPosition.x, y: cometPosition.y + 30),
                             text: "×\(combo)", color: Tunables.goldUI, size: 18)
        }
    }

    private func collectStar(_ s: PickupStarNode) {
        let value = Tunables.starValueBase * min(max(combo, 1), Tunables.starComboCap)
        starPoints += value
        starCount += 1
        FX.floatingLabel(in: world, at: CGPoint(x: s.position.x, y: s.position.y + 6),
                         text: "+\(value)", color: Tunables.goldUI, size: 15)
        s.collect(in: world)
        SoundEngine.shared.playDing(combo: combo)
        HapticsEngine.shared.star()
    }

    private func explodePlanet(_ p: PlanetNode) {
        guard !p.isDead else { return }
        let wasMine = cometMode == .orbit && p === currentPlanet
        p.explode(in: world)
        shake = min(shake + 0.7, 1)
        if wasMine && model?.state == .playing {
            die(.explosion)
        } else {
            SoundEngine.shared.playBoom()
        }
    }

    private func die(_ reason: DeathReason) {
        guard model?.state == .playing else { return }
        deathReason = reason
        dieTimer = 0
        FX.burst(in: world, at: cometPosition, color: Tunables.aqua, count: 26, speed: 260, scale: 0.5)
        FX.burst(in: world, at: cometPosition, color: .white, count: 12, speed: 160, scale: 0.34)
        FX.burst(in: world, at: cometPosition, color: Tunables.planetColors[0], count: 10, speed: 200, scale: 0.42)
        shake = 1
        comet.isHidden = true
        comet.setTrailActive(false)
        guideLine.path = nil
        SoundEngine.shared.playBoom()
        HapticsEngine.shared.death()
        model?.beginDying(reason: reason)
    }

    private func completeDeath() {
        guard model?.state == .dying else { return }
        let summary = RunSummary(
            score: Int(metersMax) + starPoints,
            meters: Int(metersMax),
            stars: starCount,
            starPoints: starPoints,
            reason: deathReason
        )
        model?.finishDeath(summary)
    }

    private func applyAimAssist(_ h: TimeInterval) {
        let speed = hypot(velocity.dx, velocity.dy)
        guard speed > 1 else { return }
        let ux = velocity.dx / speed, uy = velocity.dy / speed
        var bestScore: CGFloat = 0
        var bestDx: CGFloat = 0, bestDy: CGFloat = 0
        for p in planets where !p.isDead {
            if let g = grace, g.planet === p { continue }
            let dx = p.position.x - cometPosition.x
            let dy = p.position.y - cometPosition.y
            let d = hypot(dx, dy)
            if d > p.ringRadius * 2.4 || d < 1 { continue }
            let alignment = (dx * ux + dy * uy) / d
            if alignment < 0.45 { continue }
            let score = alignment * (1 - d / (p.ringRadius * 2.4))
            if score > bestScore { bestScore = score; bestDx = dx; bestDy = dy }
        }
        guard bestScore > 0 else { return }
        let desired = atan2(bestDy, bestDx)
        let current = atan2(uy, ux)
        var delta = desired - current
        while delta > .pi { delta -= .pi * 2 }
        while delta < -.pi { delta += .pi * 2 }
        let maxRotation = 3.2 * bestScore * CGFloat(h)
        let rotation = min(max(delta, -maxRotation), maxRotation)
        let cs = cos(rotation), sn = sin(rotation)
        velocity = CGVector(dx: velocity.dx * cs - velocity.dy * sn,
                            dy: velocity.dx * sn + velocity.dy * cs)
    }

    private func autopilotStep() {
        let p = currentPlanet!
        guard orbitTime > 0.15 else { return }
        let emergency = orbitRadius < p.bodyRadius + 15 || (p.isLit && p.fuse < 0.55)
        var target: PlanetNode?
        var bestD: CGFloat = .greatestFiniteMagnitude
        for q in planets where q !== p && !q.isDead && q.position.y > p.position.y + 40 {
            let d = distanceSquared(q.position, cometPosition)
            if d < bestD { bestD = d; target = q }
        }
        guard let target else { if emergency { jump() }; return }
        let ux = -sin(orbitAngle) * orbitDirection
        let uy = cos(orbitAngle) * orbitDirection
        let dx = target.position.x - cometPosition.x
        let dy = target.position.y - cometPosition.y
        let d = hypot(dx, dy)
        let dot = (ux * dx + uy * dy) / d
        if dot > 0.985 || (emergency && dot > 0.55) { jump() }
    }

    // MARK: - Generación del mundo
    private func ensureSpawns() {
        let cameraTop = cameraY + visibleHeight / 2
        var guard_ = 0
        while spawnY < cameraTop + 520 && guard_ < 80 {
            spawnPlanet()
            guard_ += 1
        }
        if planets.count > 34 {
            let cutoff = cameraY - visibleHeight / 2 - 500
            planets.removeAll { p in
                guard p !== currentPlanet, p.position.y < cutoff || p.isDead else { return false }
                p.removeFromParent()
                return true
            }
            pickups.removeAll { s in
                guard s.isTaken || s.position.y < cutoff else { return false }
                s.removeFromParent()
                return true
            }
            blackHoles.removeAll { b in
                guard b.position.y < cutoff else { return false }
                b.removeFromParent()
                return true
            }
        }
    }

    private func spawnPlanet() {
        guard let last = planets.last else { return }
        let meters = max(0, spawnY / Tunables.unitsPerMeter)
        let d = Difficulty(meters: meters)
        let early = hopCount < 1 && planets.count < 5

        let gap = early ? CGFloat.random(in: 160...190) : CGFloat.random(in: d.gapMin...d.gapMax)
        let newY = spawnY + gap
        let dx = early ? CGFloat.random(in: -90...90) : CGFloat.random(in: -235...235)
        let newX = min(max(last.position.x + dx, 85), Tunables.worldWidth - 85)
        let ring = early ? CGFloat.random(in: 84...92)
                         : min(max(d.ring + CGFloat.random(in: -6...8), 54), 94)

        var unstable = false
        var mover: (CGFloat, CGFloat, CGFloat)?
        var asteroid: (CGFloat, CGFloat)?
        if !early {
            if Double.random(in: 0...1) < d.pUnstable {
                unstable = true
                model?.showToast(.unstable)
            } else if Double.random(in: 0...1) < d.pAsteroid {
                let speed = (Bool.random() ? -1.0 : 1.0) * Double.random(in: 0.9...1.5)
                asteroid = (CGFloat.random(in: 0...(2 * .pi)), CGFloat(speed))
                model?.showToast(.asteroid)
            }
            if !unstable && Double.random(in: 0...1) < d.pMover {
                mover = (CGFloat.random(in: 28...52), CGFloat.random(in: 2.8...4.4), CGFloat.random(in: 0...(2 * .pi)))
                model?.showToast(.mover)
            }
        }

        let planet = PlanetNode(
            x: newX, y: newY,
            bodyRadius: CGFloat.random(in: 15...23), ringRadius: ring,
            color: Tunables.planetColors.randomElement()!,
            unstable: unstable,
            mover: mover.map { (amp: $0.0, per: $0.1, phase: $0.2) },
            asteroid: asteroid.map { (angle: $0.0, speed: $0.1) }
        )
        world.addChild(planet)
        planets.append(planet)

        // estrellas del corredor
        var starTotal = 1
        if Double.random(in: 0...1) < 0.55 { starTotal += 1 }
        if Double.random(in: 0...1) < 0.2 { starTotal += 1 }
        for i in 0..<starTotal {
            let t = CGFloat(i + 1) / CGFloat(starTotal + 1)
            let sx = last.position.x + (newX - last.position.x) * t + CGFloat.random(in: -34...34)
            let sy = last.position.y + (newY - last.position.y) * t + CGFloat.random(in: -22...22)
            let pos = CGPoint(x: sx, y: sy)
            if distanceSquared(pos, last.position) > pow(last.bodyRadius + 30, 2)
                && distanceSquared(pos, planet.position) > pow(planet.bodyRadius + 30, 2) {
                let star = PickupStarNode()
                star.position = pos
                world.addChild(star)
                pickups.append(star)
            }
        }

        // agujeros negros
        blackHoleDebt -= gap / Tunables.unitsPerMeter
        if meters > 1800 && blackHoleDebt <= 0 {
            blackHoleDebt = CGFloat.random(in: 420...780)
            let side: CGFloat = Bool.random() ? -1 : 1
            let bx = min(max((last.position.x + newX) / 2 + side * CGFloat.random(in: 125...185), 45),
                         Tunables.worldWidth - 45)
            let by = (last.position.y + newY) / 2 + CGFloat.random(in: -40...40)
            let pos = CGPoint(x: bx, y: by)
            if distanceSquared(pos, planet.position) > pow(planet.ringRadius + 95, 2)
                && distanceSquared(pos, last.position) > pow(last.ringRadius + 95, 2) {
                let bh = BlackHoleNode()
                bh.position = pos
                world.addChild(bh)
                blackHoles.append(bh)
                model?.showToast(.blackHole)
            }
        }
        spawnY = newY
    }

    // MARK: - Cámara y housekeeping
    private func updateCamera(dt: TimeInterval) {
        let target = cometPosition.y + visibleHeight * 0.10
        cameraY += (target - cameraY) * (1 - exp(-5 * dt))
        var pos = CGPoint(x: Tunables.worldWidth / 2, y: cameraY)
        if shake > 0 && !reduceMotion {
            let magnitude = shake * shake * 9
            pos.x += CGFloat.random(in: -magnitude...magnitude)
            pos.y += CGFloat.random(in: -magnitude...magnitude)
        }
        cam.position = pos
    }

    private func housekeeping(_ raw: TimeInterval) {
        shake = max(0, shake - CGFloat(raw) * 2.4)
        starfield.updateParallax(cameraY: cameraY)
        comet.setBlink(invulnerability > 0, time: simTime)

        let visibleRange = (cameraY - visibleHeight)...(cameraY + visibleHeight)
        for bh in blackHoles where visibleRange.contains(bh.position.y) {
            bh.stepSpiral(raw)
        }

        // guía de tangente mientras orbitas
        if model?.state == .playing && cometMode == .orbit {
            let ux = -sin(orbitAngle) * orbitDirection
            let uy = cos(orbitAngle) * orbitDirection
            let length: CGFloat = hopCount < 2 ? 235 : 36
            let path = CGMutablePath()
            path.move(to: CGPoint(x: cometPosition.x + ux * 13, y: cometPosition.y + uy * 13))
            path.addLine(to: CGPoint(x: cometPosition.x + ux * length, y: cometPosition.y + uy * length))
            guideLine.path = hopCount < 2
                ? path.copy(dashingWithPhase: 0, lengths: [5, 8])
                : path
            guideLine.alpha = hopCount < 2 ? 0.5 : 0.4
        } else {
            guideLine.path = nil
        }

        if autopilot {
            debugPrintTimer -= raw
            if debugPrintTimer <= 0 {
                debugPrintTimer = 2
                let state = model?.state.rawValue ?? "?"
                print("[AUTO] state=\(state) m=\(Int(metersMax)) score=\(Int(metersMax) + starPoints) " +
                      "stars=\(starCount) combo=\(combo) hops=\(hopCount) planets=\(planets.count) " +
                      "wallet=\(model?.cosmetics.wallet ?? 0) fps=\(Int(fpsAverage))")
            }
        }
    }

    /// Actualiza los uniforms del shader de fondo según la altitud.
    func refreshBackground() {
        let bands = Tunables.bgBands
        let band = min(max(Double(metersMax) / 800, 0), Double(bands.count) - 1.001)
        let index = Int(band)
        let fraction = CGFloat(band - Double(index))
        let next = min(index + 1, bands.count - 1)
        let bottom = bands[index].bottom.mixed(with: bands[next].bottom, t: fraction)
        let top = bands[index].top.mixed(with: bands[next].top, t: fraction)
        backgroundSprite.shader?.uniformNamed("u_bottom")?.vectorFloat4Value = colorVector(bottom)
        backgroundSprite.shader?.uniformNamed("u_top")?.vectorFloat4Value = colorVector(top)
    }

    override func didFinishUpdate() {
        refreshBackground()
    }
}

// MARK: - Utilidades
private func distanceSquared(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
    let dx = b.x - a.x, dy = b.y - a.y
    return dx * dx + dy * dy
}

/// Campo de estrellas en 3 capas con parallax, fijo a la cámara.
final class StarfieldNode: SKNode {
    private struct Layer {
        let parallax: CGFloat
        var dots: [(node: SKSpriteNode, baseY: CGFloat)]
    }
    private var layers: [Layer] = []
    private var height: CGFloat = 800

    func regenerate(width: CGFloat, height: CGFloat) {
        removeAllChildren()
        layers = []
        self.height = height
        let parallaxes: [CGFloat] = [0.12, 0.26, 0.48]
        let radii: [CGFloat] = [0.9, 1.4, 2.1]
        for layerIndex in 0..<3 {
            var dots: [(SKSpriteNode, CGFloat)] = []
            let count = Int(width * height / 27000)
            for _ in 0..<count {
                let dot = SKSpriteNode(texture: FX.dotTexture)
                let r = radii[layerIndex] * CGFloat.random(in: 0.7...1.3)
                dot.size = CGSize(width: r * 2.6, height: r * 2.6)
                dot.color = UIColor(red: 0.81, green: 0.89, blue: 1, alpha: 1)
                dot.colorBlendFactor = 1
                dot.alpha = CGFloat.random(in: 0.25...0.6)
                dot.blendMode = .add
                dot.position = CGPoint(x: CGFloat.random(in: -width / 2...width / 2), y: 0)
                let baseY = CGFloat.random(in: 0...height)
                addChild(dot)
                dots.append((dot, baseY))
                let twinkle = SKAction.sequence([
                    .fadeAlpha(to: CGFloat.random(in: 0.15...0.3), duration: Double.random(in: 0.6...1.6)),
                    .fadeAlpha(to: CGFloat.random(in: 0.5...0.75), duration: Double.random(in: 0.6...1.6))
                ])
                dot.run(.repeatForever(twinkle))
            }
            layers.append(Layer(parallax: parallaxes[layerIndex], dots: dots))
        }
    }

    func updateParallax(cameraY: CGFloat) {
        for layer in layers {
            for (node, baseY) in layer.dots {
                var y = (baseY - cameraY * layer.parallax).truncatingRemainder(dividingBy: height)
                if y < 0 { y += height }
                node.position.y = y - height / 2
            }
        }
    }
}
