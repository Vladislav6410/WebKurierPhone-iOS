import Foundation
import Photos

// MARK: - MediaCleanerScanStub
// Privacy-first scanner (metadata only).
// - Reads screenshots count
// - Estimates sizes using PHAssetResource fileSize when possible
// - No image bytes are uploaded anywhere

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

        let batchSize = 150

        // 3) Iterate metadata
        assets.enumerateObjects { asset, _, _ in
            scanned += 1

            let isScreenshot = asset.mediaSubtypes.contains(.photoScreenshot)
            if isScreenshot {
                screenshotCount += 1
            }

            // ✅ Better byte size estimation (no pixels)
            let sizeBytes = MediaCleanerPhotoBytes.fileSizeBytes(for: asset)
                ?? self.approxBytesForAsset(asset)

            if isScreenshot {
                screenshotBytes += max(0, sizeBytes)
            }

            if scanned % batchSize == 0 {
                onProgress?(ScanProgress(scanned: scanned, total: total))
            }
        }

        onProgress?(ScanProgress(scanned: scanned, total: total))

        // 4) Build summary
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

    private func approxBytesForAsset(_ asset: PHAsset) -> Int {
        let pixels = asset.pixelWidth * asset.pixelHeight
        if pixels <= 0 { return 0 }

        // rough midpoint
        let approx = Double(pixels) * 0.35
        return Int(approx)
    }
}