import Foundation

final class PhoneCoreAPI {

    static let shared = PhoneCoreAPI()
    private init() {}

    private let session = URLSession.shared

    func translate(
        text: String,
        sourceLang: String?,
        targetLang: String,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        guard let url = URL(string: "/translate", relativeTo: Endpoints.phoneCoreBaseURL) else {
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = [
            "text": text,
            "source": sourceLang as Any,
            "target": targetLang
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        session.dataTask(with: request) { data, _, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard
                let data = data,
                let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let translated = json["translatedText"] as? String
            else {
                completion(.failure(NSError(domain: "PhoneCoreAPI", code: -1)))
                return
            }

            completion(.success(translated))
        }.resume()
    }
}