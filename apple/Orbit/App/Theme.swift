import SwiftUI

/// Identidad visual de ORBIT: "neón bioluminiscente sobre tinta profunda".
enum Theme {
    // MARK: Paleta
    static let ink = Color(red: 7 / 255, green: 11 / 255, blue: 24 / 255)
    static let aqua = Color(red: 107 / 255, green: 247 / 255, blue: 255 / 255)
    static let gold = Color(red: 255 / 255, green: 201 / 255, blue: 77 / 255)
    static let coral = Color(red: 255 / 255, green: 107 / 255, blue: 94 / 255)
    static let text = Color(red: 234 / 255, green: 242 / 255, blue: 255 / 255)
    static let muted = Color(red: 147 / 255, green: 160 / 255, blue: 196 / 255)
    static let panel = Color(red: 10 / 255, green: 14 / 255, blue: 30 / 255).opacity(0.55)

    static let titleGradient = LinearGradient(
        colors: [Color(red: 0.56, green: 0.98, blue: 1.0), aqua, gold],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let buttonGradient = LinearGradient(
        colors: [aqua, Color(red: 0.62, green: 0.96, blue: 0.78), gold],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    // MARK: Tipografía (Unbounded para display, Chakra Petch para datos)
    static func display(_ size: CGFloat) -> Font { .custom("Unbounded-ExtraBold", size: size) }
    static func displayMedium(_ size: CGFloat) -> Font { .custom("Unbounded-Medium", size: size) }
    static func body(_ size: CGFloat) -> Font { .custom("ChakraPetch-Regular", size: size) }
    static func bodySemi(_ size: CGFloat) -> Font { .custom("ChakraPetch-SemiBold", size: size) }
    static func bodyBold(_ size: CGFloat) -> Font { .custom("ChakraPetch-Bold", size: size) }
}

extension Int {
    var grouped: String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.locale = Locale(identifier: "en_US")
        return f.string(from: NSNumber(value: self)) ?? String(self)
    }
}
