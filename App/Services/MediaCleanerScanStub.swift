import Foundation
import Photos

// MARK: - MediaCleanerScanStub
// Privacy-first scanner: reads metadata only (no image bytes).
// Produces a lightweight summary used for UI + Core submission.

final class MediaCleanerScanStub {

    struct ScanProgress {
        let scanned: Int
        let total: Int
    }

    func scanLibrary(
        onProgress: ((ScanProgress) -> Void)? = nil
    ) async throws -> MediaCleanerResultsSummary {

        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        if status != .authorized && status != .limited {
            throw NSError(
                domain: "MediaCleanerScanStub",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Photo access not granted."]
            )
        }

        let fetch = PHAsset.fetchAssets(with: .image, options: nil)
        let total = fetch.count

        var screenshots = 0
        var scanned = 0

        // Placeholder heuristics
        var duplicatesItems = 0
        var duplicatesGroups = 0
        var blurItems = 0

        // Very rough space estimates (bytes) for demo purposes
        // Later: compute using actual file sizes if permission allows, or via local index.
        var estScreenshotFreed: Int = 0
        var estDuplicatesFreed: Int = 0
        var estBlurFreed: Int = 0
        var estSlimFreed: Int = 0

        fetch.enumerateObjects { asset, _, _ in
            scanned += 1

            // Screenshot detection (metadata only)
            if asset.mediaSubtypes.contains(.photoScreenshot) {
                screenshots += 1
                estScreenshotFreed += 2_000_000 // ~2MB heuristic
            }

            // Mock duplicate heuristic (placeholder):
            // every 50 images assume 1 duplicate group of 2 items
            if scanned % 50 == 0 {
                duplicatesGroups += 1
                duplicatesItems += 2
                estDuplicatesFreed += 3_000_000 // ~3MB heuristic
            }

            // Mock blur heuristic:
            // every 120 images assume 1 blurry image
            if scanned % 120 == 0 {
                blurItems += 1
                estBlurFreed += 2_500_000 // ~2.5MB heuristic
            }

            if let onProgress {
                onProgress(ScanProgress(scanned: scanned, total: max(total, 1)))
            }
        }

        // Slim mode is a placeholder flag — later can be based on “large videos” or “burst photos”
        let slimEnabled = true
        if slimEnabled {
            estSlimFreed = min(20_000_000, total * 50_000) // capped heuristic
        }

        return MediaCleanerResultsSummary(
            duplicates: .init(
                groups: duplicatesGroups,
                items: duplicatesItems,
                estimatedFreedBytes: estDuplicatesFreed
            ),
            blur: .init(
                items: blurItems,
                estimatedFreedBytes: estBlurFreed
            ),
            screenshots: .init(
                items: screenshots,
                estimatedFreedBytes: estScreenshotFreed
            ),
            slimMode: .init(
                enabled: slimEnabled,
                estimatedFreedBytes: estSlimFreed
            )
        )
    }
}