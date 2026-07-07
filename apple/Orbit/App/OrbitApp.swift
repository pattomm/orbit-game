import SwiftUI
import SpriteKit

@main
struct OrbitApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @State private var model = GameModel()
    @Environment(\.scenePhase) private var scenePhase
    private let isAutopilot = ProcessInfo.processInfo.arguments.contains("-autopilot")

    var body: some View {
        ZStack {
            SpriteView(scene: model.scene,
                       isPaused: model.state == .paused,
                       preferredFramesPerSecond: 120,
                       options: [.ignoresSiblingOrder])
                .ignoresSafeArea()

            // viñeta atmosférica
            RadialGradient(colors: [.clear, .black.opacity(0.38)],
                           center: .center, startRadius: 180, endRadius: 560)
                .ignoresSafeArea()
                .allowsHitTesting(false)

            switch model.state {
            case .menu:
                MenuView(model: model)
                    .transition(.opacity)
            case .playing, .dying:
                HUDView(model: model)
                    .transition(.opacity)
            case .paused:
                HUDView(model: model)
                PauseView(model: model)
                    .transition(.opacity)
            case .gameOver:
                if let summary = model.summary {
                    GameOverView(model: model, summary: summary)
                        .transition(.opacity)
                }
            }
        }
        .animation(.easeInOut(duration: 0.28), value: model.state)
        .statusBarHidden()
        .persistentSystemOverlays(.hidden)
        .preferredColorScheme(.dark)
        .onChange(of: scenePhase) {
            if scenePhase != .active { model.pause() }
        }
        .onAppear {
            GameCenterManager.shared.authenticate()
            if isAutopilot { model.startGame() }
        }
        .onChange(of: model.state) {
            // en modo autopilot, reintenta solo: prueba de larga duración
            guard isAutopilot, model.state == .gameOver else { return }
            let delay = ProcessInfo.processInfo.arguments.contains("-slowretry") ? 4.0 : 1.2
            Task {
                try? await Task.sleep(for: .seconds(delay))
                if model.state == .gameOver { model.startGame() }
            }
        }
    }
}
