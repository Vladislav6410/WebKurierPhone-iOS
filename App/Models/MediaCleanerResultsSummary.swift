import Foundation

// MARK: - MediaCleanerResultsSummary
// This is the ONLY data we send to Core (privacy-first).
// No raw images are uploaded here. Only summary counts + safe metadata.

struct MediaCleanerResultsSummary: Codable {
    var duplicates: DuplicateSummary
    var blur: BlurSummary
    var screenshots: ScreenshotSummary
    var slimMode: SlimModeSummary

    init(
        duplicates: DuplicateSummary = .init(),
        blur: BlurSummary = .init(),
        screenshots: ScreenshotSummary = .init(),
        slimMode: SlimModeSummary = .init()
    ) {
        self.duplicates = duplicates
        self.blur = blur
        self.screenshots = screenshots
        self.slimMode = slimMode
    }

    // MARK: - Nested Models

    struct DuplicateSummary: Codable {
        var groups: Int
        var items: Int
        var estimatedFreedBytes: Int

        init(groups: Int = 0, items: Int = 0, estimatedFreedBytes: Int = 0) {
            self.groups = groups
            self.items = items
            self.estimatedFreedBytes = estimatedFreedBytes
        }
    }

    struct BlurSummary: Codable {
        var items: Int
        var estimatedFreedBytes: Int

        init(items: Int = 0, estimatedFreedBytes: Int = 0) {
            self.items = items
            self.estimatedFreedBytes = estimatedFreedBytes
        }
    }

    struct ScreenshotSummary: Codable {
        var items: Int
        var estimatedFreedBytes: Int

        init(items: Int = 0, estimatedFreedBytes: Int = 0) {
            self.items = items
            self.estimatedFreedBytes = estimatedFreedBytes
        }
    }

    struct SlimModeSummary: Codable {
        var enabled: Bool
        var estimatedFreedBytes: Int

        init(enabled: Bool = false, estimatedFreedBytes: Int = 0) {
            self.enabled = enabled
            self.estimatedFreedBytes = estimatedFreedBytes
        }
    }
}