import Foundation
import UIKit

// MARK: - MediaCleanerService
// Orchestrates the flow on iOS:
// 1) startSession (Core)
// 2) run local scan (privacy-first; metadata only)
// 3) submitResults summary (Core)
// 4) rewardCleanup (optional WebCoins)

final class MediaCleanerService {
    static let shared = MediaCleanerService()

    private let api: MediaCleanerAPI
    private let scanner: MediaCleanerScanStub

    init(
        api: MediaCleanerAPI = .shared,
        scanner: MediaCleanerScanStub = MediaCleanerScanStub()
    ) {
        self.api = api
        self.scanner = scanner
    }

    // MARK: - Public Flow

    /// Full flow:
    /// Start session -> scan Photos (metadata) -> submit -> reward (optional)
    func runCleanupFlow(
        userId: String,
        deviceId: String,
        mode: String = "local_only",
        onProgress: ((MediaCleanerScanStub.ScanProgress) -> Void)? = nil
    ) async throws -> (sessionId: String, summary: MediaCleanerResultsSummary, coinsAwarded: Int) {

        // ✅ 1) Start session in Core
        let start = try await api.startSession(userId: userId, deviceId: deviceId, mode: mode)

        guard start.ok, let session = start.session else {
            throw NSError(
                domain: "MediaCleanerService",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: start.error ?? "Failed to start session"]
            )
        }

        // ✅ 2) Local scan (privacy-first)
        let summary = try await scanner.scanLibrary(onProgress: onProgress)

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
        // Here we use "estimated freed bytes" as a proxy.
        // Later: compute real freed bytes after actual deletion/compression.
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
}
