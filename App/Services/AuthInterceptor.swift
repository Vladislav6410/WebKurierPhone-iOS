import Foundation

final class AuthInterceptor {

    static let shared = AuthInterceptor()
    private init() {}

    func authorizedRequest(_ request: URLRequest) -> URLRequest {
        var req = request

        if let token = SessionStore.shared.accessToken {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        return req
    }

    func handleUnauthorized(_ response: HTTPURLResponse) {
        guard response.statusCode == 401 else { return }
        // Session invalidation is delegated to CoreGateway
        SessionStore.shared.clear()
        DispatchQueue.main.async {
            CoreGateway.shared.logout()
        }
    }
}