import Foundation
import Photos

// MARK: - MediaCleanerSlimModeStub
// Privacy-first estimation of savings for "Slim Mode" compression.
// This does NOT modify photos. It only estimates potential freed bytes.
// Later:
// - add real compression via PHImageManager + ImageIO
// - export compressed copies to app sandbox (not replacing originals without explicit user action)

final class MediaCleanerSlimModeStub {

    struct SlimEstimate {
        let enabled: Bool
        let estimatedFreedBytes: Int
    }

    /// Estimate how much space could be freed if we compress images.
    /// Heuristic:
    /// - Use fileSizeBytes when available
    /// - Assume compression saves 35% on average (configurable)
    func estimateSavings(
        assets: [PHAsset],
        enabled: Bool,
        assumedSavingsRatio: Double = 0.35
    ) -> SlimEstimate {

        guard enabled else {
            return SlimEstimate(enabled: false, estimatedFreedBytes: 0)
        }

        var totalBytes = 0

        for a in assets {
            let size = MediaCleanerPhotoBytes.fileSizeBytes(for: a) ?? 0
            totalBytes += max(0, size)
        }

        let estimatedFreed = Int(Double(totalBytes) * max(0.0, min(assumedSavingsRatio, 0.9)))
        return SlimEstimate(enabled: true, estimatedFreedBytes: max(0, estimatedFreed))
    }
}