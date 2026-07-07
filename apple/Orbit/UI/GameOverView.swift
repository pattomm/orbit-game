import SwiftUI

struct GameOverView: View {
    let model: GameModel
    let summary: RunSummary
    @State private var canTapThrough = false
    @State private var recordPulse = false

    var body: some View {
        ZStack {
            OverlayBackdrop()
                .contentShape(Rectangle())
                .onTapGesture {
                    guard canTapThrough else { return }
                    model.startGame()
                }

            VStack(spacing: 0) {
                Text("JOURNEY'S END")
                    .font(Theme.display(26))
                    .kerning(4)
                    .foregroundStyle(Theme.text)
                Text(summary.reason.message)
                    .font(Theme.body(14.5))
                    .foregroundStyle(Theme.muted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .frame(maxWidth: 320)
                    .padding(.top, 12)

                Text("\(summary.score.grouped)")
                    .font(Theme.display(62))
                    .foregroundStyle(Theme.text)
                    .shadow(color: Theme.aqua.opacity(0.4), radius: 18)
                    .padding(.top, 22)
                Text("POINTS")
                    .font(Theme.bodySemi(13))
                    .kerning(5)
                    .foregroundStyle(Theme.muted)
                    .padding(.top, 6)

                Text("Height \(summary.meters.grouped) m  ·  ✦ \(summary.stars) \(summary.stars == 1 ? "star" : "stars") (+\(summary.starPoints.grouped))")
                    .font(Theme.body(15))
                    .foregroundStyle(Theme.text.opacity(0.8))
                    .padding(.top, 14)

                Group {
                    if model.newBest {
                        Text("★ NEW BEST! ★")
                            .font(Theme.bodyBold(17))
                            .kerning(2.4)
                            .foregroundStyle(Theme.gold)
                            .shadow(color: Theme.gold.opacity(0.6), radius: 10)
                            .scaleEffect(recordPulse ? 1.06 : 1)
                    } else {
                        Text("Best run: \(model.best.grouped) points")
                            .font(Theme.bodySemi(14))
                            .kerning(1)
                            .foregroundStyle(Theme.muted)
                    }
                }
                .padding(.top, 16)

                HStack(spacing: 14) {
                    PrimaryButton(title: "Retry") { model.startGame() }
                    GhostButton(title: "Menu") { model.toMenu() }
                }
                .padding(.top, 26)

                Text("OR TAP ANYWHERE")
                    .font(Theme.bodySemi(12))
                    .kerning(2.4)
                    .foregroundStyle(Theme.muted.opacity(0.6))
                    .padding(.top, 18)
                    .opacity(canTapThrough ? 1 : 0)
            }
            .padding(24)
            .allowsHitTesting(true)
        }
        .task {
            try? await Task.sleep(for: .seconds(0.6))
            withAnimation(.easeIn(duration: 0.3)) { canTapThrough = true }
            withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
                recordPulse = true
            }
        }
    }
}
