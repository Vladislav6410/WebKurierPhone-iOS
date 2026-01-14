import Foundation
import Combine

final class CoreGateway: ObservableObject {

    static let shared = CoreGateway()
    private init() {}

    @Published var isAuthenticated: Bool = false
    @Published var userId: String?

    private var cancellables = Set<AnyCancellable>()

    func bootstrap() {
        // Placeholder: session validation via WebKurierCore
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            self.isAuthenticated = true
            self.userId = "guest"
        }
    }

    func logout() {
        // Placeholder: invalidate session via Core + Security
        isAuthenticated = false
        userId = nil
    }
}