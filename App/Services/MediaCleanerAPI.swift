import Foundation

final class MediaCleanerAPI {

    static let shared = MediaCleanerAPI()
    private init() {}

    // MARK: - DTO

    struct CreateSessionResponse: Decodable {
        let sessionId: String
    }

    struct SubmitSummaryResponse: Decodable {
        let coinsAwarded: Int
    }

    // MARK: - Endpoints

    func createSession(
        userId: String,
        deviceId: String
    ) async throws -> String {
        guard let url = URL(string: "/api/mediacleaner/session/create", relativeTo: Endpoints.coreBaseURL) else {
            throw NetworkError.invalidURL
        }

        let body: [String: Any] = [
            "userId": userId,
            "deviceId": deviceId
        ]

        let req = RequestBuilder.jsonRequest(url: url, method: "POST", body: body)
        let data = try await requestData(req)

        let decoded = try JSONDecoder().decode(CreateSessionResponse.self, from: data)
        return decoded.sessionId
    }

    func submitSummary(
        sessionId: String,
        userId: String,
        deviceId: String,
        summary: MediaCleanerResultsSummary
    ) async throws -> Int {
        guard let url = URL(string: "/api/mediacleaner/session/summary", relativeTo: Endpoints.coreBaseURL) else {
            throw NetworkError.invalidURL
        }

        let body: [String: Any] = [
            "sessionId": sessionId,
            "userId": userId,
            "deviceId": deviceId,
            "summary": summary.toDictionary()
        ]

        let req = RequestBuilder.jsonRequest(url: url, method: "POST", body: body)
        let data = try await requestData(req)

        let decoded = try JSONDecoder().decode(SubmitSummaryResponse.self, from: data)
        return decoded.coinsAwarded
    }

    // MARK: - Helpers

    private func requestData(_ request: URLRequest) async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            HTTPClient.shared.request(request) { result in
                continuation.resume(with: result)
            }
        }
    }
}