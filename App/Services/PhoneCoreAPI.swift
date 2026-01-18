import Foundation

final class PhoneCoreAPI {

    static let shared = PhoneCoreAPI()
    private init() {}

    // Expected JSON response fields (common variants supported):
    // - translatedText (preferred)
    // - translation
    // - text
    private struct TranslateResponse: Decodable {
        let translatedText: String?
        let translation: String?
        let text: String?
    }

    func translate(
        text: String,
        sourceLang: String?,
        targetLang: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard let url = URL(string: "/translate", relativeTo: Endpoints.phoneCoreBaseURL) else {
            completion(.failure(NetworkError.invalidURL))
            return
        }

        var body: [String: Any] = [
            "text": text,
            "target": targetLang
        ]
        if let sourceLang {
            body["source"] = sourceLang
        } else {
            body["source"] = "auto"
        }

        let req = RequestBuilder.jsonRequest(url: url, method: "POST", body: body)

        HTTPClient.shared.request(req) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let data):
                do {
                    let decoded = try JSONDecoder().decode(TranslateResponse.self, from: data)
                    let value = decoded.translatedText ?? decoded.translation ?? decoded.text
                    if let value {
                        completion(.success(value))
                    } else {
                        completion(.failure(NetworkError.decodingFailed))
                    }
                } catch {
                    completion(.failure(error))
                }
            }
        }
    }
}