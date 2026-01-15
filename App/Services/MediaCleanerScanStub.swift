import Foundation
import Photos

// MARK: - MediaCleanerScanStub
// This is a SAFE starter scanner (privacy-first).
// It reads ONLY metadata from Photos library.
// No image bytes are uploaded anywhere.
//
// Next steps later:
// - add hashing / near-duplicate detection
// - blur scoring (ML)
// - SQLite indexing

final class MediaCleanerScanStub {

    struct ScanProgress {
        let scanned: Int
        let total: Int
    }

    enum ScanError: Error {
        case permissionDenied
        case unknown
    }

    // MARK: - Public

    /// Minimal scan:
    /// - counts screenshots
    /// - estimates sizes
    /// - creates summary placeholders
    func scanLibrary(
        onProgress: ((ScanProgress) -> Void)? = nil
    ) async throws -> MediaCleanerResultsSummary {

        // 1) Permission check
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)

        if status == .notDetermined {
            let newStatus = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            if newStatus != .authorized && newStatus != .limited {
                throw ScanError.permissionDenied
            }
        } else if status != .authorized && status != .limited {
            throw ScanError.permissionDenied
        }

        // 2) Fetch assets (images only)
        let options = PHFetchOptions()
        options.includeHiddenAssets = false
        options.predicate = NSPredicate(format: "mediaType == %d", PHAssetMediaType.image.rawValue)

        let assets = PHAsset.fetchAssets(with: options)

        let total = assets.count
        var scanned = 0

        var screenshotCount = 0
        var screenshotBytes = 0

        // We do small batches to keep UI responsive.
        let batchSize = 200

        // 3) Iterate metadata
        assets.enumerateObjects { asset, _, _ in
            scanned += 1

            // Detect screenshots (Apple built-in subtype)
            if asset.mediaSubtypes.contains(.photoScreenshot) {
                screenshotCount += 1
            }

            // Size estimation: we need resource metadata (no pixel data)
            // It’s async, so we do a safe approximate fallback here.
            // Real byte size will be improved later via PHAssetResource.
            // For now: rough estimate based on pixel count (very approximate).
            let approxBytes = self.approxBytesForAsset(asset)
            if asset.mediaSubtypes.contains(.photoScreenshot) {
                screenshotBytes += approxBytes
            }

            if scanned % batchSize == 0 {
                onProgress?(ScanProgress(scanned: scanned, total: total))
            }
        }

        onProgress?(ScanProgress(scanned: scanned, total: total))

        // 4) Build summary (duplicates/blur are placeholders for now)
        var summary = MediaCleanerResultsSummary()

        summary.screenshots = .init(
            items: screenshotCount,
            estimatedFreedBytes: max(0, screenshotBytes / 2) // assume user deletes ~50%
        )

        // placeholders
        summary.duplicates = .init(groups: 0, items: 0, estimatedFreedBytes: 0)
        summary.blur = .init(items: 0, estimatedFreedBytes: 0)

        // SlimMode placeholder
        summary.slimMode = .init(enabled: false, estimatedFreedBytes: 0)

        return summary
    }

    // MARK: - Helpers

    /// Very rough estimate for asset size.
    /// We will replace it later with PHAssetResource byte size.
    private func approxBytesForAsset(_ asset: PHAsset) -> Int {
        let pixels = asset.pixelWidth * asset.pixelHeight
        if pixels <= 0 { return 0 }

        // Typical compressed JPEG: ~0.2–0.6 bytes per pixel (varies a lot)
        // We pick 0.35 B/px as a safe midpoint.
        let approx = Double(pixels) * 0.35
        return Int(approx)
    }
}