import GameKit
import UIKit

/// Integración con Game Center: autenticación estándar al arrancar,
/// leaderboard global y Access Point en el menú. Todo es opcional y
/// silencioso — el juego funciona igual sin sesión.
@MainActor
final class GameCenterManager {
    static let shared = GameCenterManager()

    /// Debe coincidir con el ID configurado en App Store Connect.
    static let leaderboardID = "orbit.best.score"

    private(set) var authenticated = false
    private let disabled = ProcessInfo.processInfo.arguments.contains("-gcoff")

    private init() {}

    func authenticate() {
        guard !disabled else { return }
        GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, _ in
            Task { @MainActor in
                guard let self else { return }
                if let viewController {
                    self.present(viewController)
                }
                self.authenticated = GKLocalPlayer.local.isAuthenticated
                if self.authenticated {
                    GKAccessPoint.shared.location = .topLeading
                    GKAccessPoint.shared.showHighlights = false
                    GKAccessPoint.shared.isActive = true
                }
            }
        }
    }

    func setAccessPointVisible(_ visible: Bool) {
        guard !disabled else { return }
        GKAccessPoint.shared.isActive = visible && authenticated
    }

    func submit(score: Int) {
        guard authenticated else { return }
        GKLeaderboard.submitScore(score, context: 0, player: GKLocalPlayer.local,
                                  leaderboardIDs: [Self.leaderboardID]) { _ in }
    }

    private func present(_ viewController: UIViewController) {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene }).first,
            let root = scene.keyWindow?.rootViewController else { return }
        root.present(viewController, animated: true)
    }
}
