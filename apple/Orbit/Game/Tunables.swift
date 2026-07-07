import CoreGraphics
import UIKit

/// Constantes de gameplay. Son el mismo tuning validado de la versión web:
/// el mundo mide 480 unidades de ancho y 10 unidades equivalen a 1 metro.
enum Tunables {
    static let worldWidth: CGFloat = 480
    static let referenceHeight: CGFloat = 820
    static let flightSpeed: CGFloat = 300          // u/s en vuelo libre
    static let omegaMin: CGFloat = 1.7             // rad/s
    static let omegaMax: CGFloat = 4.4
    static let unitsPerMeter: CGFloat = 10
    static let quickHopWindow: TimeInterval = 1.5  // s para mantener el combo
    static let flyTimeout: TimeInterval = 4.6
    static let fuseTime: TimeInterval = 2.4
    static let captureGrace: TimeInterval = 0.28
    static let captureInvul: TimeInterval = 0.5
    static let substep: TimeInterval = 1.0 / 120.0
    static let maxSpeed: CGFloat = 480
    static let starValueBase = 30
    static let starComboCap = 10
    static let fallBehindLimit: CGFloat = 700      // u por debajo del máximo alcanzado

    static let planetColors: [UIColor] = [
        UIColor(red: 1.00, green: 0.42, blue: 0.37, alpha: 1),   // coral
        UIColor(red: 1.00, green: 0.79, blue: 0.30, alpha: 1),   // oro
        UIColor(red: 0.69, green: 0.48, blue: 1.00, alpha: 1),   // violeta
        UIColor(red: 0.33, green: 0.90, blue: 0.66, alpha: 1),   // menta
        UIColor(red: 0.35, green: 0.65, blue: 1.00, alpha: 1)    // azul
    ]
    static let unstableColor = UIColor(red: 1.00, green: 0.30, blue: 0.42, alpha: 1)
    static let aqua = UIColor(red: 0.42, green: 0.97, blue: 1.00, alpha: 1)
    static let goldUI = UIColor(red: 1.00, green: 0.79, blue: 0.30, alpha: 1)
    static let violet = UIColor(red: 0.69, green: 0.48, blue: 1.00, alpha: 1)

    /// Bandas de color del fondo por altitud (inferior, superior) — cada 800 m.
    static let bgBands: [(bottom: UIColor, top: UIColor)] = [
        (UIColor(hex6: 0x070B18), UIColor(hex6: 0x0C1026)),
        (UIColor(hex6: 0x0D0A26), UIColor(hex6: 0x131033)),
        (UIColor(hex6: 0x160B2E), UIColor(hex6: 0x1B0F3A)),
        (UIColor(hex6: 0x1D0A2E), UIColor(hex6: 0x241238)),
        (UIColor(hex6: 0x220A22), UIColor(hex6: 0x2A1132)),
        (UIColor(hex6: 0x240814), UIColor(hex6: 0x2C102A))
    ]
}

/// Parámetros de dificultad en función de los metros alcanzados.
struct Difficulty {
    let ring: CGFloat
    let decay: CGFloat
    let gapMin: CGFloat
    let gapMax: CGFloat
    let pAsteroid: Double
    let pMover: Double
    let pUnstable: Double

    init(meters m: CGFloat) {
        func t(_ x: CGFloat) -> CGFloat { min(max(x, 0), 1) }
        ring = min(max(86 - m * 0.010, 56), 86)
        decay = 6.5 + 9 * t(m / 3200)
        gapMin = 175 + min(70, m * 0.02)
        gapMax = 250 + min(90, m * 0.03)
        pAsteroid = m < 250 ? 0 : Double(0.08 + 0.30 * t((m - 250) / 1800))
        pMover = m < 600 ? 0 : Double(0.10 + 0.32 * t((m - 600) / 2000))
        pUnstable = m < 1100 ? 0 : Double(0.08 + 0.24 * t((m - 1100) / 2000))
    }
}

enum DeathReason: String {
    case burn, asteroid, void, blackHole, explosion

    var message: String {
        switch self {
        case .burn: return "Your orbit decayed too far and you burned up in the atmosphere."
        case .asteroid: return "A guardian asteroid caught you mid-orbit."
        case .void: return "You drifted into the void, far from any gravity."
        case .blackHole: return "A black hole swallowed you whole."
        case .explosion: return "The unstable star collapsed with you on it."
        }
    }
}

enum HazardToast: String, CaseIterable {
    case asteroid, mover, unstable, blackHole

    var message: String {
        switch self {
        case .asteroid: return "☄️ Guardian asteroids: dodge their path"
        case .mover: return "🪐 Wandering planets ahead"
        case .unstable: return "💥 Unstable stars! Don't linger on them"
        case .blackHole: return "🕳️ Black holes: they bend your flight"
        }
    }
}

extension UIColor {
    convenience init(hex6: Int) {
        self.init(
            red: CGFloat((hex6 >> 16) & 0xFF) / 255,
            green: CGFloat((hex6 >> 8) & 0xFF) / 255,
            blue: CGFloat(hex6 & 0xFF) / 255,
            alpha: 1
        )
    }

    func mixed(with other: UIColor, t: CGFloat) -> UIColor {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        other.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        return UIColor(red: r1 + (r2 - r1) * t, green: g1 + (g2 - g1) * t,
                       blue: b1 + (b2 - b1) * t, alpha: a1 + (a2 - a1) * t)
    }
}
