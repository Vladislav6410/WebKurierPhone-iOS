import Foundation

// MARK: - MediaCleanerResultsSummary
// Lightweight, privacy-safe summary sent to Core (no raw media data).

struct MediaCleanerResultsSummary: Codable {

    struct Duplicates: Codable {
        let groups: Int
        let items: Int
        let estimatedFreedBytes: Int
    }

    struct Blur: Codable {
        let items: Int
        let estimatedFreedBytes: Int
    }

    struct Screenshots: Codable {
        let items: Int
        let estimatedFreedBytes: Int
    }

    struct SlimMode: Codable {
        let enabled: Bool
        let estimatedFreedBytes: Int
    }

    let duplicates: Duplicates
    let blur: Blur
    let screenshots: Screenshots
    let slimMode: SlimMode

    // MARK: - Helpers

    func toDictionary() -> [String: Any] {
        [
            "duplicates": [
                "groups": duplicates.groups,
                "items": duplicates.items,
                "estimatedFreedBytes": duplicates.estimatedFreedBytes
            ],
            "blur": [
                "items": blur.items,
                "estimatedFreedBytes": blur.estimatedFreedBytes
            ],
            "screenshots": [
                "items": screenshots.items,
                "estimatedFreedBytes": screenshots.estimatedFreedBytes
            ],
            "slimMode": [
                "enabled": slimMode.enabled,
                "estimatedFreedBytes": slimMode.estimatedFreedBytes
            ]
        ]
    }
}