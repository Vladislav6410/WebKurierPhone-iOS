import Foundation
import UIKit

// MARK: - MediaCleanerService
// Orchestrates the flow on iOS:
// 1) startSession (Core)
// 2) run local scan (placeholder now)
// 3) submitResults summary (Core)
// 4) rewardCleanup (optional WebCoins)

final class MediaCleanerService {
    static let shared = MediaCleanerService()

    private let api: MediaCleanerAPI

    init(api: MediaCleanerAPI = .shared) {
        self.api = api
    }

    // MARK: - Public Flow

    /// High-level one-call demo flow:
    /// Start session -> create local summary -> submit -> reward
    func runDemoCleanupFlow(
        userId: String,
        deviceId: String
    ) async throws -> (sessionId: String, summary: MediaCleanerResultsSummary, coinsAwarded: Int) {

        // ✅ 1) Start session in Core
        let start = try await api.startSession(userId: userId, deviceId: deviceId, mode: "local_only")

        guard start.ok, let session = start.session else {
            throw NSError(
                domain: "MediaCleanerService",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: start.error ?? "Failed to start session"]
            )
        }

        // ✅ 2) Local scan (placeholder for now)
        // Later we will scan real gallery via Photos framework and store metadata in SQLite.
        let summary = self.generatePlaceholderSummary()

        // ✅ 3) Submit summary (metadata only) to Core
        let submit = try await api.submitResults(userId: userId, sessionId: session.sessionId, summary: summary)
        if !submit.ok {
            throw NSError(
                domain: "MediaCleanerService",
                code: -2,
                userInfo: [NSLocalizedDescriptionKey: submit.error ?? "Failed to submit results"]
            )
        }

        // ✅ 4) Reward coins (optional)
        // In real life freedBytes is the actually freed space after deletion/compression
        let freedBytes = summary.duplicates.estimatedFreedBytes
            + summary.blur.estimatedFreedBytes
            + summary.screenshots.estimatedFreedBytes
            + summary.slimMode.estimatedFreedBytes

        let reward = try await api.rewardCleanup(
            userId: userId,
            sessionId: session.sessionId,
            freedBytes: freedBytes
        )

        let coins = reward.coinsAwarded ?? 0
        return (sessionId: session.sessionId, summary: summary, coinsAwarded: coins)
    }

    // MARK: - Local Scan Placeholders

    /// Placeholder summary. Replace this with real scan results later.
    private func generatePlaceholderSummary() -> MediaCleanerResultsSummary {
        var s = MediaCleanerResultsSummary()

        // Example numbers
        s.duplicates = .init(groups: 3, items: 18, estimatedFreedBytes: 900_000_000) // ~900MB
        s.blur = .init(items: 5, estimatedFreedBytes: 120_000_000)                  // ~120MB
        s.screenshots = .init(items: 12, estimatedFreedBytes: 250_000_000)          // ~250MB
        s.slimMode = .init(enabled: true, estimatedFreedBytes: 600_000_000)         // ~600MB

        return s
    }
}