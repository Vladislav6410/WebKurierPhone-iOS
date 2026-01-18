import Foundation
import Photos

// MARK: - MediaCleanerPhotoBytes
// Optional helper to estimate media sizes using metadata-only APIs.
// Does NOT read image/video bytes. Safe for privacy-first operation.

final class MediaCleanerPhotoBytes {

    static let shared = MediaCleanerPhotoBytes()
    private init() {}

    /// Estimates file size (bytes) from PHAssetResource metadata when available.
    /// Falls back to a conservative heuristic if metadata is missing.
    func estimatedSizeBytes(for asset: PHAsset) -> Int {
        let resources = PHAssetResource.assetResources(for: asset)

        // Prefer original resource
        if let original = resources.first(where: { $0.type == .photo || $0.type == .video }) {
            if let size = original.value(forKey: "fileSize") as? Int {
                return size
            }
        }

        // Heuristic fallback (privacy-safe)
        if asset.mediaType == .image {
            return 2_500_000 // ~2.5 MB
        } else if asset.mediaType == .video {
            return 20_000_000 // ~20 MB
        } else {
            return 1_000_000
        }
    }
}