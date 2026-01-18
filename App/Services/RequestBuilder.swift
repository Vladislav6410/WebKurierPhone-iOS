import Foundation

struct RequestBuilder {

    static func jsonRequest(
        url: URL,
        method: String = "GET",
        body: [String: Any]? = nil,
        headers: [String: String] = [:]
    ) -> URLRequest {

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        headers.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        if let body = body {
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        }

        return request
    }
}