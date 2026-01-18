import Foundation

final class HTTPClient {

    static let shared = HTTPClient()
    private init() {}

    private let session = URLSession.shared

    func request(
        _ request: URLRequest,
        completion: @escaping (Result<Data, Error>) -> Void
    ) {
        let authorized = AuthInterceptor.shared.authorizedRequest(request)

        session.dataTask(with: authorized) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let http = response as? HTTPURLResponse else {
                completion(.failure(NetworkError.invalidResponse))
                return
            }

            if http.statusCode == 401 {
                AuthInterceptor.shared.handleUnauthorized(http)
                completion(.failure(NetworkError.unauthorized))
                return
            }

            guard (200...299).contains(http.statusCode) else {
                completion(.failure(NetworkError.serverError(code: http.statusCode)))
                return
            }

            completion(.success(data ?? Data()))
        }.resume()
    }
}