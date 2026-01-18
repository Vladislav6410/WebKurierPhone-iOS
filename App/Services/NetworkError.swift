import Foundation

enum NetworkError: Error, LocalizedError {

    case invalidURL
    case requestFailed
    case invalidResponse
    case decodingFailed
    case unauthorized
    case forbidden
    case serverError(code: Int)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL."
        case .requestFailed:
            return "Network request failed."
        case .invalidResponse:
            return "Invalid server response."
        case .decodingFailed:
            return "Failed to decode server data."
        case .unauthorized:
            return "Unauthorized. Please log in again."
        case .forbidden:
            return "Access forbidden."
        case .serverError(let code):
            return "Server error (\(code))."
        }
    }
}