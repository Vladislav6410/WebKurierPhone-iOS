import Foundation
import Photos

// MARK: - MediaCleanerPhotoBytes
// Reads byte size from PHAssetResource without loading image pixels.
// This improves "estimatedFreedBytes" accuracy while staying privacy-safe.

enum MediaCleanerPhotoBytes {

    /// Best-effort file size for a PHAsset image.
    /// Returns nil if size can't be determined.
    static func fileSizeBytes(for asset: PHAsset) -> Int? {
        let resources = PHAssetResource.assetResources(for: asset)
        guard let r = resources.first else { return nil }

        // Apple does not expose a direct public fileSize API on PHAssetResource,
        // but KVC often returns "fileSize" on-device.
        // If it fails, we return nil and caller can fallback to approximation.
        if let size = (r.value(forKey: "fileSize") as? NSNumber)?.intValue {
            return size
        }

        return nil
    }
}