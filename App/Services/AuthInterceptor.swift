import Foundation

// MARK: - AuthInterceptor
// Central place to attach Authorization header + trace headers.
// Uses SecureStore (Keychain) as a source of truth.

final class AuthInterceptor {

    static let shared = AuthInterceptor()

    private let secureStore: SecureStore
    private let deviceIdProvider: () -> String

    init(
        secureStore: SecureStore = .shared,
        deviceIdProvider: @escaping () -> String = {
            UIDevice.current.identifierForVendor?.uuidString ?? "ios_device"
        }
    ) {
        self.secureStore = secureStore
        self.deviceIdProvider = deviceIdProvider
    }

    // Builds final headers merged with auth + tracing.
    func apply(to request: URLRequest, userId: String?) -> URLRequest {
        var req = request

        // Always attach device id for audit/debug on backend side
        req.setValue(deviceIdProvider(), forHTTPHeaderField: "X-Device-Id")

        if let userId, !userId.isEmpty {
            req.setValue(userId, forHTTPHeaderField: "X-User-Id")
        }

        // Authorization token (Bearer)
        if let token = secureStore.readString(.accessToken), !token.isEmpty {
            // Never log token anywhere.
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        return req
    }

    // Optional: clear tokens if backend says unauthorized.
    func handleUnauthorized() {
        secureStore.delete(.accessToken)
        secureStore.delete(.refreshToken)
    }
}

// MARK: - SecureStore Keys
// Keep keys centralized to avoid typos across the app.

extension SecureStore {
    enum Key: String {
        case accessToken = "wk_access_token"
        case refreshToken = "wk_refresh_token"
    }

    func readString(_ key: Key) -> String? {
        read(key.rawValue)
    }

    func writeString(_ value: String, key: Key) {
        write(value, key: key.rawValue)
    }

    func delete(_ key: Key) {
        delete(key.rawValue)
    }
}