import SwiftUI

// MARK: - Botones

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct PrimaryButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title.uppercased())
                .font(Theme.displayMedium(16))
                .kerning(2.2)
                .foregroundStyle(Theme.ink)
                .padding(.vertical, 17)
                .padding(.horizontal, 44)
                .background(Capsule().fill(Theme.buttonGradient))
                .shadow(color: Theme.aqua.opacity(0.45), radius: 16, y: 2)
                .shadow(color: .black.opacity(0.45), radius: 14, y: 8)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct GhostButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title.uppercased())
                .font(Theme.displayMedium(13))
                .kerning(1.8)
                .foregroundStyle(Theme.text.opacity(0.85))
                .padding(.vertical, 16)
                .padding(.horizontal, 26)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.06))
                        .overlay(Capsule().stroke(Color.white.opacity(0.16), lineWidth: 1))
                )
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

struct IconButton: View {
    let systemName: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Theme.text)
                .frame(width: 42, height: 42)
                .background(
                    RoundedRectangle(cornerRadius: 13, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 13, style: .continuous)
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )
                )
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel(label)
    }
}

// MARK: - Emblema animado (planeta + anillo + cometa orbitando)

struct EmblemView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: reduceMotion)) { context in
            let angle = context.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: 7) / 7
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(colors: [Theme.gold.opacity(0.45), .clear],
                                       center: .center, startRadius: 6, endRadius: 52)
                    )
                    .frame(width: 104, height: 104)
                Circle()
                    .fill(Theme.gold)
                    .frame(width: 34, height: 34)
                    .overlay(
                        Circle()
                            .fill(Color.white.opacity(0.35))
                            .frame(width: 15, height: 15)
                            .offset(x: -6, y: -6)
                    )
                Circle()
                    .stroke(Color.white.opacity(0.35), style: StrokeStyle(lineWidth: 2, dash: [4, 9]))
                    .frame(width: 88, height: 88)
                Circle()
                    .fill(Theme.aqua)
                    .frame(width: 11, height: 11)
                    .shadow(color: Theme.aqua.opacity(0.9), radius: 6)
                    .offset(x: 44)
                    .rotationEffect(.radians(-angle * 2 * .pi))
            }
        }
        .frame(width: 104, height: 104)
        .accessibilityHidden(true)
    }
}

// MARK: - Fondo de pantallas superpuestas

struct OverlayBackdrop: View {
    var body: some View {
        Rectangle()
            .fill(.ultraThinMaterial)
            .overlay(Theme.ink.opacity(0.45))
            .ignoresSafeArea()
    }
}
