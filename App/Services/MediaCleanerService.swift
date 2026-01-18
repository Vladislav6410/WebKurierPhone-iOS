import Foundation
import UIKit

// MARK: - MediaCleanerService
// Orchestrates the iOS flow:
// 1) create session (Core)
// 2) run local scan (privacy-first; metadata only)
// 3) submit summary (Core) -> coinsAwarded
//
// Updated to match the NEW MediaCleanerAPI:
// - createSession(userId, deviceId) -> sessionId
// - submitSummary(sessionId, userId, deviceId, summary) -> coinsAwarded
// Removed legacy endpoints: startSession/submitResults/rewardCleanup

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

    struct FlowResult {
        let sessionId: String
        let summary: MediaCleanerResultsSummary
        let coinsAwarded: Int
    }

    // MARK: - Public Flow

    /// Full flow:
    /// Create session -> scan Photos (metadata) -> submit summary -> coinsAwarded
    func runCleanupFlow(
        userId: String,
        deviceId: String,
        mode: String = "local_only",
        onProgress: ((MediaCleanerScanStub.ScanProgress) -> Void)? = nil
    ) async throws -> FlowResult {

        // Mode is accepted for forward compatibility (sync_enabled / local_only).
        // In the current API version mode can be handled server-side or ignored safely.
        _ = mode

        // ✅ 1) Create session in Core
        let sessionId = try await api.createSession(userId: userId, deviceId: deviceId)

        // ✅ 2) Local scan (privacy-first)
        let summary = try await scanner.scanLibrary(onProgress: onProgress)

        // ✅ 3) Submit summary (metadata only) to Core -> reward
        let coinsAwarded = try await api.submitSummary(
            sessionId: sessionId,
            userId: userId,
            deviceId: deviceId,
            summary: summary
        )

        return FlowResult(sessionId: sessionId, summary: summary, coinsAwarded: coinsAwarded)
    }
}