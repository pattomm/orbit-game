import AVFAudio

/// Sintetizador de efectos: todos los sonidos se generan por código en
/// buffers PCM al arrancar (cero assets de audio). Usa la categoría
/// `.ambient` para respetar el switch de silencio y mezclarse con la
/// música del usuario — el comportamiento correcto para un juego casual.
final class SoundEngine {
    static let shared = SoundEngine()

    private let engine = AVAudioEngine()
    private let fxPlayer = AVAudioPlayerNode()
    private let pitchedPlayer = AVAudioPlayerNode()
    private let ambientPlayer = AVAudioPlayerNode()
    private var format: AVAudioFormat!

    private var whooshBuffer: AVAudioPCMBuffer?
    private var boomBuffer: AVAudioPCMBuffer?
    private var milestoneBuffer: AVAudioPCMBuffer?
    private var pluckBuffers: [AVAudioPCMBuffer] = []
    private var dingBuffers: [AVAudioPCMBuffer] = []

    private var prepared = false
    private var muted = false
    private let sampleRate = 44100.0

    func prepare() {
        guard !prepared else { return }
        prepared = true
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            return
        }
        format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)
        for player in [fxPlayer, pitchedPlayer, ambientPlayer] {
            engine.attach(player)
            engine.connect(player, to: engine.mainMixerNode, format: format)
        }
        renderBuffers()
        do {
            try engine.start()
        } catch {
            return
        }
        engine.mainMixerNode.outputVolume = muted ? 0 : 1
        fxPlayer.play()
        pitchedPlayer.play()
        if let pad = makeAmbientBuffer() {
            ambientPlayer.scheduleBuffer(pad, at: nil, options: .loops)
            ambientPlayer.play()
        }
    }

    func setMuted(_ value: Bool) {
        muted = value
        guard prepared, engine.isRunning else { return }
        engine.mainMixerNode.outputVolume = value ? 0 : 1
    }

    // MARK: - API de reproducción
    func playWhoosh() { play(whooshBuffer, on: fxPlayer) }
    func playBoom() { play(boomBuffer, on: fxPlayer) }
    func playMilestone() { play(milestoneBuffer, on: fxPlayer) }

    func playPluck(combo: Int) {
        let index = min(max(combo, 0), pluckBuffers.count - 1)
        play(pluckBuffers.indices.contains(index) ? pluckBuffers[index] : nil, on: pitchedPlayer)
    }

    func playDing(combo: Int) {
        let index = min(max(combo, 0), dingBuffers.count - 1)
        play(dingBuffers.indices.contains(index) ? dingBuffers[index] : nil, on: pitchedPlayer)
    }

    private func play(_ buffer: AVAudioPCMBuffer?, on player: AVAudioPlayerNode) {
        guard prepared, engine.isRunning, let buffer else { return }
        player.scheduleBuffer(buffer, at: nil, options: .interrupts)
    }

    // MARK: - Síntesis
    private func renderBuffers() {
        whooshBuffer = makeBuffer(duration: 0.28) { samples, sr in
            var x1: Double = 0, x2: Double = 0, y1: Double = 0, y2: Double = 0
            var b0 = 0.0, b1 = 0.0, b2 = 0.0, a1 = 0.0, a2 = 0.0
            let n = samples.count
            for i in 0..<n {
                let t = Double(i) / sr
                if i % 32 == 0 {
                    let f = 380 * pow(1600 / 380, min(t / 0.22, 1))
                    let w0 = 2 * .pi * f / sr
                    let alpha = sin(w0) / (2 * 3)
                    let a0 = 1 + alpha
                    b0 = alpha / a0; b1 = 0; b2 = -alpha / a0
                    a1 = -2 * cos(w0) / a0; a2 = (1 - alpha) / a0
                }
                let x = Double.random(in: -1...1)
                let y = b0 * x + b1 * x1 + b2 * x2 - a1 * y1 - a2 * y2
                x2 = x1; x1 = x; y2 = y1; y1 = y
                samples[i] = Float(y * Self.envelope(t: t, peak: 0.55, duration: 0.26))
            }
        }

        boomBuffer = makeBuffer(duration: 0.65) { samples, sr in
            var phase = 0.0
            var lp = 0.0
            for i in 0..<samples.count {
                let t = Double(i) / sr
                let f = 140 * pow(40 / 140, min(t / 0.55, 1))
                phase += 2 * .pi * f / sr
                let body = sin(phase) * Self.envelope(t: t, peak: 0.5, duration: 0.6)
                lp += (Double.random(in: -1...1) - lp) * 0.06
                let rumble = lp * Self.envelope(t: t, peak: 0.55, duration: 0.35)
                samples[i] = Float(body + rumble)
            }
        }

        milestoneBuffer = makeBuffer(duration: 0.62) { samples, sr in
            for (offset, freq) in [(0.0, 523.25), (0.09, 659.25), (0.18, 783.99)] {
                for i in 0..<samples.count {
                    let t = Double(i) / sr - offset
                    guard t >= 0, t < 0.34 else { continue }
                    let tri = Self.triangle(t * freq)
                    samples[i] += Float(tri * Self.envelope(t: t, peak: 0.13, duration: 0.3))
                }
            }
        }

        pluckBuffers = (0...12).map { semitone in
            let f0 = 290 * pow(2, Double(semitone) / 12)
            return makeBuffer(duration: 0.26) { samples, sr in
                for i in 0..<samples.count {
                    let t = Double(i) / sr
                    let env = Self.envelope(t: t, peak: 0.22, duration: 0.22)
                    let tone = Self.triangle(t * f0) + 0.35 * sin(2 * .pi * f0 * 2 * t)
                    samples[i] = Float(tone * env)
                }
            } ?? AVAudioPCMBuffer()
        }.compactMap { $0 }

        dingBuffers = (0...8).map { step in
            let f = 740 * pow(1.1225, Double(step))
            return makeBuffer(duration: 0.2) { samples, sr in
                for i in 0..<samples.count {
                    let t = Double(i) / sr
                    let env = Self.envelope(t: t, peak: 0.16, duration: 0.16)
                    samples[i] = Float(sin(2 * .pi * f * t) * env)
                }
            } ?? AVAudioPCMBuffer()
        }.compactMap { $0 }
    }

    private func makeAmbientBuffer() -> AVAudioPCMBuffer? {
        makeBuffer(duration: 2.0) { samples, sr in
            var lp = 0.0
            for i in 0..<samples.count {
                let t = Double(i) / sr
                lp += (Double.random(in: -1...1) - lp) * 0.031
                let swell = 1 + 0.25 * sin(2 * .pi * t / 2.0)
                samples[i] = Float(lp * 0.015 * swell)
            }
        }
    }

    private func makeBuffer(duration: Double, fill: (inout [Float], Double) -> Void) -> AVAudioPCMBuffer? {
        guard let format else { return nil }
        let frames = AVAudioFrameCount(sampleRate * duration)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frames) else { return nil }
        buffer.frameLength = frames
        var samples = [Float](repeating: 0, count: Int(frames))
        fill(&samples, sampleRate)
        guard let channels = buffer.floatChannelData else { return nil }
        for i in 0..<Int(frames) {
            channels[0][i] = samples[i]
            channels[1][i] = samples[i]
        }
        return buffer
    }

    private static func envelope(t: Double, peak: Double, duration: Double) -> Double {
        guard t >= 0, t < duration else { return 0 }
        let attack = 0.012
        if t < attack { return peak * (t / attack) }
        let k = log(peak / 0.0001) / (duration - attack)
        return peak * exp(-k * (t - attack))
    }

    private static func triangle(_ phase: Double) -> Double {
        let p = phase - floor(phase)
        return 2 * abs(2 * p - 1) - 1
    }
}
