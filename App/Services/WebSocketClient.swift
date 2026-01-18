import Foundation

final class WebSocketClient: ObservableObject {

    static let shared = WebSocketClient()
    private init() {}

    private var webSocketTask: URLSessionWebSocketTask?
    private let session = URLSession(configuration: .default)

    @Published private(set) var isConnected: Bool = false

    func connect(path: String) {
        guard webSocketTask == nil else { return }

        let url = Endpoints.webSocketBaseURL.appendingPathComponent(path)
        webSocketTask = session.webSocketTask(with: url)
        webSocketTask?.resume()
        isConnected = true

        listen()
    }

    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        isConnected = false
    }

    func send(text: String) {
        let message = URLSessionWebSocketTask.Message.string(text)
        webSocketTask?.send(message) { error in
            if let error = error {
                print("WebSocket send error:", error)
            }
        }
    }

    private func listen() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .failure(let error):
                print("WebSocket receive error:", error)
                self?.disconnect()
            case .success:
                // Incoming message handling delegated to feature services
                break
            }
            self?.listen()
        }
    }
}