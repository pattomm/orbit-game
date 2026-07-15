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
            #if DEBUG
            runDebugHooks()
            #endif
            if isAutopilot { model.startGame() }
        }
        #if DEBUG
        .onChange(of: model.state) {
            guard model.state == .gameOver,
                  ProcessInfo.processInfo.arguments.contains("-walletcheck") else { return }
            print("[WALLET] run stars=\(model.summary?.stars ?? 0) wallet=\(model.cosmetics.wallet)")
        }
        #endif
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

    #if DEBUG
    /// Hooks para pruebas automatizadas vía launch arguments. No existen en Release.
    private func runDebugHooks() {
        let args = ProcessInfo.processInfo.arguments

        // -buyskin <id>: ejercita la compra por el código real (cartera, propiedad, equipar)
        if let i = args.firstIndex(of: "-buyskin"), i + 1 < args.count,
           let skin = CometSkin.catalog.first(where: { $0.id == args[i + 1] }) {
            let before = model.cosmetics.wallet
            let ownedBefore = model.cosmetics.owns(skin)
            model.selectSkin(skin)
            print("[SHOP] buy=\(skin.id) price=\(skin.price) wallet:\(before)→\(model.cosmetics.wallet) " +
                  "owned:\(ownedBefore)→\(model.cosmetics.owns(skin)) equipped=\(model.cosmetics.equippedID)")
        }

        // -equipskin <id>: fuerza un skin para inspeccionar su estela en pantalla
        if let i = args.firstIndex(of: "-equipskin"), i + 1 < args.count {
            model.debugEquip(id: args[i + 1])
            print("[SHOP] force-equipped=\(model.cosmetics.equippedID)")
        }
    }
    #endif
}
