import Foundation

final class ConfigReader {

    static let shared = ConfigReader()
    private init() {}

    private let infoDictionary: [String: Any] = {
        Bundle.main.infoDictionary ?? [:]
    }()

    // MARK: - Core URLs

    var coreBaseUrlString: String {
        value(forKey: "CORE_BASE_URL", default: "https://core.webkurier.example")
    }

    var phoneCoreBaseUrlString: String {
        value(forKey: "PHONECORE_BASE_URL", default: "https://phonecore.webkurier.example")
    }

    var webSocketBaseUrlString: String {
        value(forKey: "WEBSOCKET_BASE_URL", default: "wss://ws.webkurier.example")
    }

    // MARK: - Feature Flags

    var isWebRTCEnabled: Bool {
        boolValue(forKey: "ENABLE_WEBRTC", default: true)
    }

    var isDreamMakerEnabled: Bool {
        boolValue(forKey: "ENABLE_DREAMMAKER", default: true)
    }

    var isWalletEnabled: Bool {
        boolValue(forKey: "ENABLE_WALLET", default: true)
    }

    // MARK: - Helpers

    private func value(forKey key: String, default defaultValue: String) -> String {
        infoDictionary[key] as? String ?? defaultValue
    }

    private func boolValue(forKey key: String, default defaultValue: Bool) -> Bool {
        infoDictionary[key] as? Bool ?? defaultValue
    }
}