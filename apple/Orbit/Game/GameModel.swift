import Foundation
import Observation
import SwiftUI

struct RunSummary: Equatable {
    let score: Int
    let meters: Int
    let stars: Int
    let starPoints: Int
    let reason: DeathReason
}

/// Fuente de verdad del estado del juego. La escena SpriteKit reporta
/// eventos aquí; SwiftUI observa y pinta las pantallas.
@MainActor
@Observable
final class GameModel {
    enum GameState: String {
        case menu, playing, dying, paused, gameOver
    }

    private(set) var state: GameState = .menu
    private(set) var meters = 0
    private(set) var stars = 0
    private(set) var combo = 0
    private(set) var comboPulse = 0
    private(set) var toast: String?
    private(set) var summary: RunSummary?
    private(set) var best: Int
    private(set) var newBest = false

    var muted: Bool {
        didSet {
            UserDefaults.standard.set(muted, forKey: "orbita_muted")
            SoundEngine.shared.setMuted(muted)
        }
    }

    let scene: GameScene
    let cosmetics = CosmeticsStore()

    @ObservationIgnored private var shownToasts: Set<HazardToast> = []
    @ObservationIgnored private var toastTask: Task<Void, Never>?

    init() {
        best = UserDefaults.standard.integer(forKey: "orbita_best")
        muted = UserDefaults.standard.bool(forKey: "orbita_muted")
        scene = GameScene(size: CGSize(width: 390, height: 844))
        scene.configure(model: self)
        SoundEngine.shared.setMuted(muted)
    }

    // MARK: - Transiciones
    func startGame() {
        SoundEngine.shared.prepare()
        summary = nil
        newBest = false
        combo = 0
        comboPulse = 0
        scene.resetWorld(startMeters: 0)
        state = .playing
        GameCenterManager.shared.setAccessPointVisible(false)
    }

    func toMenu() {
        scene.resetWorld(startMeters: 0)
        summary = nil
        state = .menu
        GameCenterManager.shared.setAccessPointVisible(true)
    }

    func pause() {
        guard state == .playing else { return }
        state = .paused
        scene.isPaused = true
    }

    func resume() {
        guard state == .paused else { return }
        scene.isPaused = false
        state = .playing
    }

    func quitToMenuFromPause() {
        scene.isPaused = false
        toMenu()
    }

    // MARK: - Eventos desde la escena
    func beginDying(reason: DeathReason) {
        guard state == .playing else { return }
        state = .dying
    }

    func finishDeath(_ summary: RunSummary) {
        guard state == .dying else { return }
        self.summary = summary
        newBest = summary.score > best
        if newBest {
            best = summary.score
            UserDefaults.standard.set(best, forKey: "orbita_best")
        }
        GameCenterManager.shared.submit(score: summary.score)
        cosmetics.earn(summary.stars)
        state = .gameOver
    }

    // MARK: - Cosméticos
    /// Compra (si hace falta y alcanza) o equipa el skin, y lo aplica en escena.
    func selectSkin(_ skin: CometSkin) {
        SoundEngine.shared.prepare()
        if cosmetics.owns(skin) {
            cosmetics.equip(skin)
            SoundEngine.shared.playPluck(combo: 3)
        } else if cosmetics.buy(skin) {
            SoundEngine.shared.playDing(combo: 5)
            HapticsEngine.shared.milestone()
        } else {
            return
        }
        scene.applyCurrentSkin()
    }

    #if DEBUG
    func debugEquip(id: String) {
        guard let skin = CometSkin.catalog.first(where: { $0.id == id }) else { return }
        cosmetics.debugUnlock(skin)
        scene.applyCurrentSkin()
    }
    #endif

    func hudUpdate(meters: Int, stars: Int) {
        if meters != self.meters { self.meters = meters }
        if stars != self.stars { self.stars = stars }
    }

    func comboChanged(_ value: Int) {
        combo = value
        if value >= 2 { comboPulse += 1 }
    }

    func showToast(_ hazard: HazardToast) {
        guard !shownToasts.contains(hazard) else { return }
        shownToasts.insert(hazard)
        toastTask?.cancel()
        toast = hazard.message
        toastTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(2.8))
            guard !Task.isCancelled else { return }
            self?.toast = nil
        }
    }
}
