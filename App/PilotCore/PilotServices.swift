import Foundation

/// Only trusted deployment configuration or an authenticated backend assignment may
/// supply a site URL. Validation is a scheme/shape check, not proof of ownership.
struct PilotProjectConfiguration: Equatable, Sendable {
    let siteURL: URL?

    init(siteURLString: String? = nil) {
        siteURL = Self.validatedSiteURL(siteURLString)
    }

    static func validatedSiteURL(_ value: String?) -> URL? {
        guard let value, !value.isEmpty,
              !value.contains(where: { $0.isWhitespace }),
              let parts = URLComponents(string: value),
              parts.scheme?.lowercased() == "https",
              let host = parts.host, !host.isEmpty,
              host.contains("."), !host.hasSuffix("."),
              parts.user == nil, parts.password == nil,
              parts.port == nil || parts.port == 443,
              !host.contains("$"), !host.contains("{"),
              !host.lowercased().hasSuffix(".example"),
              !host.lowercased().hasSuffix(".invalid"),
              !host.lowercased().hasSuffix(".localhost"),
              let url = parts.url else { return nil }
        return url
    }
}

/// Returned only after the controlled backend verifies GitHub identity/assignment.
struct PilotGitHubSession: Equatable, Sendable {
    let login: String
    let repositoryName: String?
    let verifiedProjectStatus: String?
}

enum PilotServiceError: Error, Equatable {
    case notConfigured
    case failed
}

enum PilotGitHubState: Equatable {
    case notConnected
    case connecting
    case connected(PilotGitHubSession)
    case error(PilotServiceError)

    var session: PilotGitHubSession? {
        if case .connected(let session) = self { return session }
        return nil
    }
}

struct PilotGitHubConnection {
    private(set) var state: PilotGitHubState = .notConnected

    /// Reject duplicate attempts and attempts to replace a connected identity.
    mutating func begin() -> Bool {
        switch state {
        case .notConnected, .error:
            state = .connecting
            return true
        case .connecting, .connected:
            return false
        }
    }

    mutating func finish(_ result: Result<PilotGitHubSession, PilotServiceError>) {
        guard state == .connecting else { return }
        switch result {
        case .success(let session):
            guard !session.login.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                state = .error(.failed)
                return
            }
            state = .connected(session)
        case .failure(let error): state = .error(error)
        }
    }
}

@MainActor
protocol PilotGitHubConnecting {
    func connect() async throws -> PilotGitHubSession
}

/// No OAuth client, callback, scopes, or backend contract is configured here.
struct UnavailablePilotGitHubService: PilotGitHubConnecting {
    func connect() async throws -> PilotGitHubSession {
        throw PilotServiceError.notConfigured
    }
}

struct PilotMessage: Identifiable, Equatable, Sendable {
    enum Role: Sendable { case student, assistant }
    let id: UUID
    let role: Role
    let text: String

    init(role: Role, text: String) {
        id = UUID()
        self.role = role
        self.text = text
    }
}

struct PilotCopilotRequest: Sendable {
    let lesson: PilotLesson
    let project: PilotGitHubSession
    let message: String
    let history: [PilotMessage]
}

@MainActor
protocol PilotCopilotServing {
    var isAvailable: Bool { get }
    func send(_ request: PilotCopilotRequest) async throws -> String
}

/// An adapter must use the WebKurier-controlled backend through CoreGateway.
/// No direct AI-provider or GitHub write calls belong in the iOS client.
struct UnavailablePilotCopilotService: PilotCopilotServing {
    var isAvailable: Bool { false }
    func send(_ request: PilotCopilotRequest) async throws -> String {
        throw PilotServiceError.notConfigured
    }
}
