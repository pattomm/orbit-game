import SwiftUI

struct HUDView: View {
    let model: GameModel
    @State private var comboScale: CGFloat = 1

    var body: some View {
        ZStack(alignment: .top) {
            // altitud arriba a la izquierda
            HStack(alignment: .top) {
                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Text("\(model.meters.grouped)")
                        .font(Theme.display(30))
                        .foregroundStyle(Theme.text)
                        .shadow(color: Theme.aqua.opacity(0.35), radius: 9)
                        .monospacedDigit()
                    Text("m")
                        .font(Theme.bodySemi(15))
                        .foregroundStyle(Theme.muted)
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .allowsHitTesting(false)

            // estrellas (plano) + botones, siempre arriba a la derecha
            HStack(alignment: .top) {
                Spacer()
                VStack(alignment: .trailing, spacing: 12) {
                    Text("✦ \(model.stars)")
                        .font(Theme.bodyBold(19))
                        .foregroundStyle(Theme.gold)
                        .shadow(color: Theme.gold.opacity(0.45), radius: 6)
                        .monospacedDigit()
                        .allowsHitTesting(false)
                    HStack(spacing: 10) {
                        IconButton(systemName: "pause.fill", label: "Pause") { model.pause() }
                        IconButton(systemName: model.muted ? "speaker.slash.fill" : "speaker.wave.2.fill",
                                   label: model.muted ? "Unmute" : "Mute") {
                            model.muted.toggle()
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)

            // combo
            if model.combo >= 2 {
                Text("COMBO ×\(model.combo)")
                    .font(Theme.display(19))
                    .foregroundStyle(Theme.gold)
                    .shadow(color: Theme.gold.opacity(0.6), radius: 8)
                    .scaleEffect(comboScale)
                    .padding(.top, 16)
                    .allowsHitTesting(false)
                    .transition(.scale(scale: 2.1).combined(with: .opacity))
            }

            // aviso de peligro nuevo
            VStack {
                Spacer()
                if let toast = model.toast {
                    Text(toast)
                        .font(Theme.bodySemi(14))
                        .kerning(0.5)
                        .foregroundStyle(Theme.text)
                        .padding(.vertical, 11)
                        .padding(.horizontal, 22)
                        .background(
                            Capsule()
                                .fill(.ultraThinMaterial)
                                .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 1))
                        )
                        .padding(.bottom, 30)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .allowsHitTesting(false)
                }
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: model.toast)
        .animation(.spring(response: 0.35, dampingFraction: 0.65), value: model.combo >= 2)
        .onChange(of: model.comboPulse) {
            comboScale = 1.9
            withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) { comboScale = 1 }
        }
    }
}
