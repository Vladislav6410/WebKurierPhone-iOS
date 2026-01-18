import Foundation
import Network
import Combine

final class Reachability: ObservableObject {

    static let shared = Reachability()
    private init() {
        startMonitoring()
    }

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "ReachabilityQueue")

    @Published private(set) var isOnline: Bool = true
    @Published private(set) var isExpensive: Bool = false

    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isOnline = path.status == .satisfied
                self?.isExpensive = path.isExpensive
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}