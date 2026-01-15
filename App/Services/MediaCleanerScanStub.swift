import Foundation
import Photos

// MARK: - MediaCleanerScanStub
// Privacy-first scanner (metadata only).
// Includes:
// ✅ screenshots count + bytes estimate
// ✅ simple duplicate heuristic (no ML)
// ✅ slim-mode savings estimate (optional)
// Still NO image pixels are uploaded anywhere.

final class MediaCleanerScanStub {

    struct ScanProgress {
        let scanned: Int
        let total: Int
    }

    enum ScanError: Error {
        case permissionDenied
        case unknown
    }

    private let duplicatesFinder = MediaCleanerDuplicatesStub()
    private let slimEstimator = MediaCleanerSlimModeStub()

    // MARK: - Public

    func scanLibrary(
        slimModeEnabled: Bool = false,
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

        let fetch = PHAsset.fetchAssets(with: options)
        let total = fetch.count

        var scanned = 0
        var screenshotCount = 0
        var screenshotBytes = 0

        var allAssets: [PHAsset] = []
        allAssets.reserveCapacity(min(total, 50000))

        let batchSize = 150

        // 3) Iterate metadata
        fetch.enumerateObjects { asset, _, _ in
            scanned += 1
            allAssets.append(asset)

            let isScreenshot = asset.mediaSubtypes.contains(.photoScreenshot)
            if isScreenshot {
                screenshotCount += 1
            }

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

        // 4) Duplicate analysis (simple heuristic)
        let duplicateGroups = duplicatesFinder.findDuplicates(assets: allAssets, maxSecondsDiff: 3.0)

        let duplicateItems = duplicateGroups.reduce(0) { $0 + $1.assets.count }
        let duplicateFreed = duplicateGroups.reduce(0) { $0 + $1.estimatedFreedBytes }

        // 5) Slim mode estimate (optional)
        let slim = slimEstimator.estimateSavings(
            assets: allAssets,
            enabled: slimModeEnabled,
            assumedSavingsRatio: 0.35
        )

        // 6) Build summary
        var summary = MediaCleanerResultsSummary()

        summary.screenshots = .init(
            items: screenshotCount,
            estimatedFreedBytes: max(0, screenshotBytes / 2) // assume user deletes ~50%
        )

        summary.duplicates = .init(
            groups: duplicateGroups.count,
            items: duplicateItems,
            estimatedFreedBytes: duplicateFreed
        )

        // placeholder (next step: blur/quality scoring)
        summary.blur = .init(items: 0, estimatedFreedBytes: 0)

        summary.slimMode = .init(
            enabled: slim.enabled,
            estimatedFreedBytes: slim.estimatedFreedBytes
        )

        return summary
    }

    // MARK: - Helpers

    private func approxBytesForAsset(_ asset: PHAsset) -> Int {
        let pixels = asset.pixelWidth * asset.pixelHeight
        if pixels <= 0 { return 0 }

        let approx = Double(pixels) * 0.35
        return Int(approx)
    }
}