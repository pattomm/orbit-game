import SwiftUI

/// Tienda de skins de cometa. Se paga con las estrellas recolectadas
/// en las partidas — sin dinero real.
struct SkinsView: View {
    let model: GameModel
    @Binding var isPresented: Bool

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var body: some View {
        ZStack {
            OverlayBackdrop()
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    Text("COMET SKINS")
                        .font(Theme.display(17))
                        .kerning(2.5)
                        .foregroundStyle(Theme.text)
                    Spacer()
                    Text("✦ \(model.cosmetics.wallet.grouped)")
                        .font(Theme.bodyBold(16))
                        .foregroundStyle(Theme.gold)
                        .shadow(color: Theme.gold.opacity(0.45), radius: 6)
                    IconButton(systemName: "xmark", label: "Close") { isPresented = false }
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)

                Text("Earn ✦ by collecting stars in your runs")
                    .font(Theme.body(13))
                    .foregroundStyle(Theme.muted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 22)
                    .padding(.top, 6)

                ScrollView {
                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(CometSkin.catalog) { skin in
                            SkinCard(model: model, skin: skin)
                        }
                    }
                    .padding(20)
                }
            }
        }
    }
}

private struct SkinCard: View {
    let model: GameModel
    let skin: CometSkin

    var body: some View {
        let owned = model.cosmetics.owns(skin)
        let equipped = model.cosmetics.equippedID == skin.id
        let affordable = model.cosmetics.canAfford(skin)

        Button {
            model.selectSkin(skin)
        } label: {
            VStack(spacing: 10) {
                SkinPreview(skin: skin)
                    .frame(width: 64, height: 64)
                Text(skin.name)
                    .font(Theme.bodySemi(14))
                    .foregroundStyle(Theme.text)
                Group {
                    if equipped {
                        Text("EQUIPPED").foregroundStyle(Theme.aqua)
                    } else if owned {
                        Text("TAP TO EQUIP").foregroundStyle(Theme.muted)
                    } else {
                        Text("✦ \(skin.price.grouped)")
                            .foregroundStyle(affordable ? Theme.gold : Theme.muted.opacity(0.6))
                    }
                }
                .font(Theme.bodyBold(11.5))
                .kerning(1.2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(equipped ? Theme.aqua.opacity(0.65) : Color.white.opacity(0.1),
                                    lineWidth: equipped ? 1.5 : 1)
                    )
            )
            .opacity(!owned && !affordable ? 0.55 : 1)
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel("\(skin.name), \(equipped ? "equipped" : owned ? "owned" : "\(skin.price) stars")")
    }
}

private struct SkinPreview: View {
    let skin: CometSkin

    var body: some View {
        ZStack {
            if skin.style == .prism {
                Circle()
                    .fill(AngularGradient(
                        colors: (CometSkin.prismColors + [CometSkin.prismColors[0]]).map { Color(uiColor: $0) },
                        center: .center
                    ))
                    .blur(radius: 9)
                    .opacity(0.85)
            } else {
                Circle()
                    .fill(RadialGradient(
                        colors: [Color(uiColor: skin.trailColor).opacity(0.9), .clear],
                        center: .center, startRadius: 2, endRadius: 32
                    ))
            }
            Circle()
                .fill(.white)
                .frame(width: 12, height: 12)
                .shadow(color: Color(uiColor: skin.trailColor), radius: 6)
        }
    }
}
