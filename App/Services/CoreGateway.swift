import Foundation
import Combine

final class CoreGateway: ObservableObject {

    static let shared = CoreGateway()
    private init() {}

    @Published var isAuthenticated: Bool = false
    @Published var userId: String?

    func bootstrap() {
        // Load stored session tokens (if any)
        SessionStore.shared.load()

        // Placeholder: session validation via WebKurierCore
        // Later: call Core /auth/validate and set isAuthenticated based on response.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            self.isAuthenticated = true
            self.userId = self.userId ?? "guest"
        }
    }

    func logout() {
        // Invalidate local session
        SessionStore.shared.clear()
        isAuthenticated = false
        userId = nil
    }
}