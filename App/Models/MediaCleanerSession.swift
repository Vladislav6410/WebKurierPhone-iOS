import Foundation

// MARK: - MediaCleanerSession
// Represents a single MediaCleaner run lifecycle on the client side.

struct MediaCleanerSession: Identifiable, Codable {

    let id: String               // sessionId from Core
    let userId: String
    let deviceId: String
    let startedAt: Date
    let mode: String             // local_only | sync_enabled

    // Client-side only (not sent to Core)
    var completedAt: Date?
    var coinsAwarded: Int?

    var isCompleted: Bool {
        completedAt != nil
    }
}