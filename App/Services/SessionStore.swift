import Foundation
import Combine

final class SessionStore: ObservableObject {

    static let shared = SessionStore()
    private init() {}

    @Published private(set) var accessToken: String?
    @Published private(set) var refreshToken: String?
    @Published private(set) var expiresAt: Date?

    private let accessKey = "wk.accessToken"
    private let refreshKey = "wk.refreshToken"
    private let expiresKey = "wk.expiresAt"

    func load() {
        accessToken = SecureStore.shared.load(for: accessKey)
        refreshToken = SecureStore.shared.load(for: refreshKey)
        if let ts = SecureStore.shared.load(for: expiresKey),
           let time = TimeInterval(ts) {
            expiresAt = Date(timeIntervalSince1970: time)
        }
    }

    func save(access: String, refresh: String?, expiresAt: Date?) {
        SecureStore.shared.save(access, for: accessKey)
        if let refresh {
            SecureStore.shared.save(refresh, for: refreshKey)
        }
        if let expiresAt {
            SecureStore.shared.save(String(expiresAt.timeIntervalSince1970), for: expiresKey)
        }
        load()
    }

    func clear() {
        SecureStore.shared.delete(for: accessKey)
        SecureStore.shared.delete(for: refreshKey)
        SecureStore.shared.delete(for: expiresKey)
        accessToken = nil
        refreshToken = nil
        expiresAt = nil
    }

    var isExpired: Bool {
        guard let expiresAt else { return true }
        return Date() >= expiresAt
    }
}