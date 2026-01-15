import Foundation

// MARK: - MediaCleanerAPI (Core Gateway)
// Calls WebKurierCore endpoints:
//  POST /api/media-cleaner/session/start
//  POST /api/media-cleaner/session/submit
//  GET  /api/media-cleaner/sessions?userId=...
//  POST /api/media-cleaner/reward

final class MediaCleanerAPI {
    static let shared = MediaCleanerAPI()

    // Configure this from your App config later (Info.plist / config.json / remote config)
    var baseURL: URL = URL(string: "http://localhost:3000")!

    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: - DTOs

    struct StartSessionRequest: Codable {
        let userId: String
        let deviceId: String
        let mode: String // "local_only" | "sync_enabled"
    }

    struct StartSessionResponse: Codable {
        struct Session: Codable {
            let sessionId: String
            let userId: String
            let deviceId: String
            let mode: String
            let createdAt: String
            let status: String
        }

        let ok: Bool
        let session: Session?
        let error: String?
    }

    struct SubmitResultsRequest: Codable {
        let userId: String
        let sessionId: String
        let resultsSummary: MediaCleanerResultsSummary
    }

    struct SubmitResultsResponse: Codable {
        let ok: Bool
        let error: String?
    }

    struct RewardRequest: Codable {
        let userId: String
        let sessionId: String
        let freedBytes: Int
    }

    struct RewardResponse: Codable {
        let ok: Bool
        let coinsAwarded: Int?
        let error: String?
    }

    struct SessionsResponse: Codable {
        struct Session: Codable {
            let sessionId: String
            let userId: String
            let deviceId: String
            let mode: String
            let createdAt: String
            let status: String
        }

        let ok: Bool
        let sessions: [Session]?
        let error: String?
    }

    // MARK: - Public API

    func startSession(
        userId: String,
        deviceId: String,
        mode: String = "local_only"
    ) async throws -> StartSessionResponse {
        let req = StartSessionRequest(userId: userId, deviceId: deviceId, mode: mode)
        return try await post(path: "/api/media-cleaner/session/start", body: req, as: StartSessionResponse.self)
    }

    func submitResults(
        userId: String,
        sessionId: String,
        summary: MediaCleanerResultsSummary
    ) async throws -> SubmitResultsResponse {
        let req = SubmitResultsRequest(userId: userId, sessionId: sessionId, resultsSummary: summary)
        return try await post(path: "/api/media-cleaner/session/submit", body: req, as: SubmitResultsResponse.self)
    }

    func listSessions(userId: String) async throws -> SessionsResponse {
        var comps = URLComponents(url: baseURL.appendingPathComponent("/api/media-cleaner/sessions"), resolvingAgainstBaseURL: false)
        comps?.queryItems = [URLQueryItem(name: "userId", value: userId)]
        guard let url = comps?.url else { throw URLError(.badURL) }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, resp) = try await session.data(for: request)
        try validateHTTP(resp)
        return try decode(SessionsResponse.self, from: data)
    }

    func rewardCleanup(
        userId: String,
        sessionId: String,
        freedBytes: Int
    ) async throws -> RewardResponse {
        let req = RewardRequest(userId: userId, sessionId: sessionId, freedBytes: freedBytes)
        return try await post(path: "/api/media-cleaner/reward", body: req, as: RewardResponse.self)
    }

    // MARK: - Internals

    private func post<TReq: Encodable, TRes: Decodable>(
        path: String,
        body: TReq,
        as type: TRes.Type
    ) async throws -> TRes {
        let url = baseURL.appendingPathComponent(path)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        request.httpBody = try JSONEncoder().encode(body)

        let (data, resp) = try await session.data(for: request)
        try validateHTTP(resp)
        return try decode(type, from: data)
    }

    private func validateHTTP(_ resp: URLResponse) throws {
        guard let http = resp as? HTTPURLResponse else { return }
        guard (200..<300).contains(http.statusCode) else {
            throw NSError(domain: "MediaCleanerAPI",
                          code: http.statusCode,
                          userInfo: [NSLocalizedDescriptionKey: "HTTP \(http.statusCode)"])
        }
    }

    private func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            // Helpful fallback for debugging
            let raw = String(data: data, encoding: .utf8) ?? "<non-utf8>"
            throw NSError(domain: "MediaCleanerAPI",
                          code: -1,
                          userInfo: [NSLocalizedDescriptionKey: "Decode error: \(error)\nRaw: \(raw)"])
        }
    }
}