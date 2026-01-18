import Foundation

enum Endpoints {

    // MARK: - Public Base URLs (computed once)

    static let coreBaseURL: URL = {
        URL(string: ConfigReader.shared.coreBaseUrlString) ?? URL(string: "https://core.webkurier.example")!
    }()

    static let phoneCoreBaseURL: URL = {
        URL(string: ConfigReader.shared.phoneCoreBaseUrlString) ?? URL(string: "https://phonecore.webkurier.example")!
    }()

    static let webSocketBaseURL: URL = {
        URL(string: ConfigReader.shared.webSocketBaseUrlString) ?? URL(string: "wss://ws.webkurier.example")!
    }()
}