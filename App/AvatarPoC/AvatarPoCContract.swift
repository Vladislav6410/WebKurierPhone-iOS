import Foundation

/// Adapter-facing contract. The rest of the app must not import Expression2.
enum AvatarAudioContract {
    static let sampleRate = 16_000
    static let channelCount = 1
    static let demoAgentCode = "A23WJF0199"
    static let demoAvatarName = "wise-pup"
    static let frameWidth = 416
    static let frameHeight = 720
    static let framesPerSecond = 20

    static let avatarDownloadURL = URL(string: "https://api.bithuman.ai/v1/agent/A23WJF0199/model/download?model=expression-2")!
    static let sharedEngineDownloadURL = URL(string: "https://github.com/bithuman-product/homebrew-bithuman/releases/download/expression2-engine-mac-arm64-1.0.0/mac-arm64-1.0.0.engine")!
    static let speechDownloadURL = URL(string: "https://api.bithuman.ai/v1/agent/A23WJF0199/model/download?model=expression-2&member=demo_speech_16k.wav")!

    static func validate(samples: [Float], sampleRate: Int, channels: Int) -> AvatarPoCError? {
        if sampleRate != Self.sampleRate || channels != channelCount {
            return .invalidAudio(reason: "Expression2 requires \(Self.sampleRate) Hz mono PCM, got \(sampleRate) Hz / \(channels) ch")
        }
        if samples.isEmpty {
            return .invalidAudio(reason: "audio buffer is empty")
        }
        if samples.contains(where: { !$0.isFinite }) {
            return .invalidAudio(reason: "audio contains non-finite samples")
        }
        return nil
    }
}

enum AvatarPoCError: Error, Equatable {
    case missingSecret
    case missingAvatar(String)
    case missingEngine(String)
    case missingSpeech(String)
    case invalidAudio(reason: String)
    case engineInitializationFailed(String)
    case playbackFailed(String)

    var message: String {
        switch self {
        case .missingSecret:
            return "BITHUMAN_API_SECRET is not set. Put it in the scheme environment. Do not commit it."
        case .missingAvatar(let detail):
            return "Demo avatar is unavailable: \(detail)"
        case .missingEngine(let detail):
            return "Shared Expression 2 engine is unavailable: \(detail)"
        case .missingSpeech(let detail):
            return "Prepared test speech is unavailable: \(detail)"
        case .invalidAudio(let reason):
            return "Invalid audio: \(reason)"
        case .engineInitializationFailed(let detail):
            return "Expression2 initialization failed: \(detail)"
        case .playbackFailed(let detail):
            return "Playback failed: \(detail)"
        }
    }
}

struct AvatarFrame: Equatable {
    let bgr: [UInt8]
    let width: Int
    let height: Int
    let audioTime: Double
    let endsReply: Bool
}

struct AvatarAssetSet: Equatable {
    let avatarURL: URL
    let sharedEngineURL: URL
    let speechURL: URL
    let stagingURL: URL
}

enum AvatarSecretSource {
    /// Local development only. Production must come from an authorized backend into Keychain.
    static func developmentSecret() -> String? {
        let value = ProcessInfo.processInfo.environment["BITHUMAN_API_SECRET"]?
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard let value, !value.isEmpty else { return nil }
        return value
    }
}
