import SwiftUI

struct MenuView: View {
    let model: GameModel
    @State private var appeared = false
    @State private var showSkins = MenuView.opensSkinsAtLaunch

    /// Solo en DEBUG: abre la tienda al arrancar para pruebas automatizadas.
    private static var opensSkinsAtLaunch: Bool {
        #if DEBUG
        ProcessInfo.processInfo.arguments.contains("-openskins")
        #else
        false
        #endif
    }

    var body: some View {
        ZStack {
            OverlayBackdrop()

            // total de estrellas, plano, fijo arriba a la derecha
            VStack {
                HStack {
                    Spacer()
                    Text("✦ \(model.cosmetics.wallet.grouped)")
                        .font(Theme.bodyBold(19))
                        .foregroundStyle(Theme.gold)
                        .monospacedDigit()
                        .shadow(color: Theme.gold.opacity(0.45), radius: 6)
                        .padding(.top, 14)
                        .padding(.trailing, 18)
                }
                Spacer()
            }
            .opacity(appeared ? 1 : 0)

            VStack(spacing: 0) {
                EmblemView()
                    .padding(.bottom, 10)
                Text("ORBIT")
                    .font(Theme.display(54))
                    .kerning(9)
                    .foregroundStyle(Theme.titleGradient)
                    .shadow(color: Theme.aqua.opacity(0.35), radius: 18)
                Text("Hop from orbit to orbit into the unknown.\nKeep moving: gravity always wins.")
                    .font(Theme.body(15))
                    .foregroundStyle(Theme.muted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.top, 10)

                VStack(alignment: .leading, spacing: 9) {
                    howToRow("Tap anywhere to let go")
                    howToRow("Every orbit decays — linger and you burn")
                    howToRow("Hop fast to chain combos and stars")
                }
                .padding(.vertical, 26)

                PrimaryButton(title: "Play") { model.startGame() }
                    .padding(.bottom, 14)

                GhostButton(title: "Skins") { showSkins = true }

                if model.best > 0 {
                    Text("Best run: \(model.best.grouped) points")
                        .font(Theme.bodySemi(14))
                        .kerning(1)
                        .foregroundStyle(Theme.muted)
                        .padding(.top, 16)
                }
            }
            .padding(24)
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 16)

            if showSkins {
                SkinsView(model: model, isPresented: $showSkins)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: showSkins)
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.8)) { appeared = true }
        }
    }

    private func howToRow(_ text: String) -> some View {
        HStack(spacing: 10) {
            Text("✦")
                .font(Theme.bodyBold(14))
                .foregroundStyle(Theme.aqua)
                .shadow(color: Theme.aqua.opacity(0.6), radius: 5)
            Text(text)
                .font(Theme.body(14))
                .foregroundStyle(Theme.text.opacity(0.85))
        }
    }
}
