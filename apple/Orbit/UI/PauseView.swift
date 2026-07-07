import SwiftUI

struct PauseView: View {
    let model: GameModel

    var body: some View {
        ZStack {
            OverlayBackdrop()
            VStack(spacing: 26) {
                Text("PAUSED")
                    .font(Theme.display(28))
                    .kerning(4)
                    .foregroundStyle(Theme.text)
                HStack(spacing: 14) {
                    PrimaryButton(title: "Resume") { model.resume() }
                    GhostButton(title: "Quit") { model.quitToMenuFromPause() }
                }
            }
            .padding(24)
        }
    }
}
