import CoreHaptics
import UIKit

/// Hápticos con Core Haptics (patrones ricos) y fallback a
/// UIFeedbackGenerator. Todos los fallos degradan en silencio.
final class HapticsEngine {
    static let shared = HapticsEngine()

    private var engine: CHHapticEngine?
    private let supportsCore = CHHapticEngine.capabilitiesForHardware().supportsHaptics
    private let impactLight = UIImpactFeedbackGenerator(style: .light)
    private let impactHeavy = UIImpactFeedbackGenerator(style: .heavy)

    private init() {
        guard supportsCore else { return }
        engine = try? CHHapticEngine()
        engine?.playsHapticsOnly = true
        engine?.resetHandler = { [weak self] in try? self?.engine?.start() }
        engine?.stoppedHandler = { _ in }
        try? engine?.start()
    }

    /// Toque suave al capturar una órbita; crece con el combo.
    func capture(combo: Int) {
        let intensity = min(0.35 + 0.05 * Float(combo), 0.9)
        if !playCore([transient(intensity: intensity, sharpness: 0.55)]) {
            impactLight.impactOccurred(intensity: CGFloat(intensity))
        }
    }

    func star() {
        if !playCore([transient(intensity: 0.3, sharpness: 0.9)]) {
            impactLight.impactOccurred(intensity: 0.5)
        }
    }

    func death() {
        let events = [
            transient(intensity: 1.0, sharpness: 0.4),
            CHHapticEvent(eventType: .hapticContinuous,
                          parameters: [
                            CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.5),
                            CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.25)
                          ],
                          relativeTime: 0.02, duration: 0.35)
        ]
        if !playCore(events) {
            impactHeavy.impactOccurred()
        }
    }

    func milestone() {
        let events = [
            transient(intensity: 0.5, sharpness: 0.6),
            transient(intensity: 0.7, sharpness: 0.7, delay: 0.09)
        ]
        if !playCore(events) {
            impactLight.impactOccurred()
        }
    }

    private func transient(intensity: Float, sharpness: Float, delay: TimeInterval = 0) -> CHHapticEvent {
        CHHapticEvent(eventType: .hapticTransient,
                      parameters: [
                        CHHapticEventParameter(parameterID: .hapticIntensity, value: intensity),
                        CHHapticEventParameter(parameterID: .hapticSharpness, value: sharpness)
                      ],
                      relativeTime: delay)
    }

    @discardableResult
    private func playCore(_ events: [CHHapticEvent]) -> Bool {
        guard supportsCore, let engine else { return false }
        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
            return true
        } catch {
            return false
        }
    }
}
