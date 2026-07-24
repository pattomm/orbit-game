import Foundation
import Observation
import UIKit

/// Skin de cometa: color de estela/halo y estilo de partículas.
struct CometSkin: Identifiable, Equatable {
    enum TrailStyle {
        case classic    // estela continua
        case sparkle    // chispas finas y vivas
        case bubble     // orbes suaves y lentos
        case prism      // arcoíris (secuencia de color por partícula)
    }

    let id: String
    let name: String
    let price: Int
    let trailColor: UIColor
    let style: TrailStyle

    static let `default` = CometSkin(id: "classic", name: "Comet", price: 0,
                                     trailColor: Tunables.aqua, style: .classic)

    /// Catálogo completo. Los precios forman la curva de progresión:
    /// el primero cae en 2-4 partidas; Prism es la meta de largo plazo.
    static let catalog: [CometSkin] = [
        .default,
        CometSkin(id: "ember", name: "Ember", price: 90,
                  trailColor: UIColor(red: 1.00, green: 0.42, blue: 0.37, alpha: 1), style: .classic),
        CometSkin(id: "solar", name: "Solar Flare", price: 90,
                  trailColor: Tunables.goldUI, style: .classic),
        CometSkin(id: "nebula", name: "Nebula", price: 90,
                  trailColor: Tunables.violet, style: .classic),
        CometSkin(id: "emerald", name: "Emerald", price: 90,
                  trailColor: UIColor(red: 0.33, green: 0.90, blue: 0.66, alpha: 1), style: .sparkle),
        CometSkin(id: "rose", name: "Rose Quartz", price: 90,
                  trailColor: UIColor(red: 1.00, green: 0.55, blue: 0.78, alpha: 1), style: .bubble),
        CometSkin(id: "starlight", name: "Starlight", price: 90,
                  trailColor: UIColor(red: 0.96, green: 0.98, blue: 1.00, alpha: 1), style: .sparkle),
        CometSkin(id: "prism", name: "Prism", price: 90,
                  trailColor: Tunables.aqua, style: .prism)
    ]

    static let prismColors: [UIColor] = [
        UIColor(red: 0.42, green: 0.97, blue: 1.00, alpha: 1),
        UIColor(red: 0.69, green: 0.48, blue: 1.00, alpha: 1),
        UIColor(red: 1.00, green: 0.55, blue: 0.78, alpha: 1),
        UIColor(red: 1.00, green: 0.79, blue: 0.30, alpha: 1),
        UIColor(red: 0.33, green: 0.90, blue: 0.66, alpha: 1)
    ]

    /// Color del arcoíris en el punto `t` (0...1) del ciclo, interpolado
    /// y cerrando el bucle contra el primer tono.
    static func prismColor(at t: Double) -> UIColor {
        let n = prismColors.count
        let wrapped = t - floor(t)
        let scaled = wrapped * Double(n)
        let i = min(Int(scaled), n - 1)
        let next = (i + 1) % n
        return prismColors[i].mixed(with: prismColors[next], t: CGFloat(scaled - Double(i)))
    }
}

/// Cartera de estrellas y colección de skins. Persistencia en UserDefaults.
@MainActor
@Observable
final class CosmeticsStore {
    private(set) var wallet: Int
    private(set) var ownedIDs: Set<String>
    private(set) var equippedID: String

    var equippedSkin: CometSkin {
        CometSkin.catalog.first { $0.id == equippedID } ?? .default
    }

    init() {
        let defaults = UserDefaults.standard
        wallet = defaults.integer(forKey: "orbita_wallet")
        ownedIDs = Set(defaults.stringArray(forKey: "orbita_owned_skins") ?? [])
        equippedID = defaults.string(forKey: "orbita_equipped_skin") ?? CometSkin.default.id
        ownedIDs.insert(CometSkin.default.id)
        #if DEBUG
        // -seedstars deja la cartera en un estado conocido y hermético:
        // reinicia también la colección para que cada prueba parta de cero.
        let args = ProcessInfo.processInfo.arguments
        if let i = args.firstIndex(of: "-seedstars"), i + 1 < args.count, let n = Int(args[i + 1]) {
            wallet = n
            ownedIDs = [CometSkin.default.id]
            equippedID = CometSkin.default.id
        }
        #endif
    }

    func owns(_ skin: CometSkin) -> Bool { ownedIDs.contains(skin.id) }
    func canAfford(_ skin: CometSkin) -> Bool { wallet >= skin.price }

    func earn(_ stars: Int) {
        guard stars > 0 else { return }
        wallet += stars
        save()
    }

    @discardableResult
    func buy(_ skin: CometSkin) -> Bool {
        guard !owns(skin), canAfford(skin) else { return false }
        wallet -= skin.price
        ownedIDs.insert(skin.id)
        equippedID = skin.id
        save()
        return true
    }

    func equip(_ skin: CometSkin) {
        guard owns(skin) else { return }
        equippedID = skin.id
        save()
    }

    #if DEBUG
    func debugUnlock(_ skin: CometSkin) {
        ownedIDs.insert(skin.id)
        equippedID = skin.id
    }
    #endif

    private func save() {
        let defaults = UserDefaults.standard
        defaults.set(wallet, forKey: "orbita_wallet")
        defaults.set(Array(ownedIDs), forKey: "orbita_owned_skins")
        defaults.set(equippedID, forKey: "orbita_equipped_skin")
    }
}
