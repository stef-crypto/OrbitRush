import AVFoundation

final class SoundManager {
    static let shared = SoundManager()

    enum Effect: String, CaseIterable {
        case start, launch, coin, shoot, explosion, shield, turn, gameOver
    }

    private var effects: [Effect: AVAudioPlayer] = [:]
    private var musicPlayer: AVAudioPlayer?

    private var soundEnabled = UserDefaults.standard.object(forKey: "soundEnabled") == nil
        ? true : UserDefaults.standard.bool(forKey: "soundEnabled")
    private var musicEnabled = UserDefaults.standard.object(forKey: "musicEnabled") == nil
        ? true : UserDefaults.standard.bool(forKey: "musicEnabled")

    private init() {
        configureSession()
        preload()
    }

    private func configureSession() {
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    private func preload() {
        for effect in Effect.allCases {
            guard let url = Bundle.main.url(forResource: effect.rawValue, withExtension: "wav"),
                  let player = try? AVAudioPlayer(contentsOf: url) else { continue }
            player.prepareToPlay()
            effects[effect] = player
        }

        if let url = Bundle.main.url(forResource: "music", withExtension: "wav"),
           let player = try? AVAudioPlayer(contentsOf: url) {
            player.numberOfLoops = -1
            player.volume = 0.28
            player.prepareToPlay()
            musicPlayer = player
        }
    }

    func play(_ effect: Effect) {
        guard soundEnabled, let player = effects[effect] else { return }
        player.currentTime = 0
        player.play()
    }

    func startMusic() {
        guard musicEnabled else { return }
        musicPlayer?.play()
    }

    func setSoundEnabled(_ enabled: Bool) {
        soundEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "soundEnabled")
        if !enabled {
            effects.values.forEach { $0.stop() }
        }
    }

    func setMusicEnabled(_ enabled: Bool) {
        musicEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "musicEnabled")
        if musicEnabled { startMusic() } else { musicPlayer?.pause() }
    }
}
