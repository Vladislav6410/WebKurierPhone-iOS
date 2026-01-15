import Foundation
import Photos

// MARK: - MediaCleanerDuplicatesStub
// Simple non-ML duplicate heuristic (privacy-first):
// - group by (pixelWidth x pixelHeight)
// - within each group, cluster by close creationDate
//
// This is NOT perfect, but it's a safe starter to produce real "duplicates" numbers.

final class MediaCleanerDuplicatesStub {

    struct DuplicateGroup {
        let key: String
        let assets: [PHAsset]
        let estimatedFreedBytes: Int
    }

    /// Find possible duplicates using a lightweight heuristic.
    /// - Parameters:
    ///   - assets: list of PHAsset (images)
    ///   - maxSecondsDiff: assets created within this time window may be considered duplicates
    func findDuplicates(
        assets: [PHAsset],
        maxSecondsDiff: TimeInterval = 3.0
    ) -> [DuplicateGroup] {

        // 1) Group by resolution
        var byRes: [String: [PHAsset]] = [:]
        byRes.reserveCapacity(64)

        for a in assets {
            let key = "\(a.pixelWidth)x\(a.pixelHeight)"
            byRes[key, default: []].append(a)
        }

        // 2) For each resolution group, sort by date and cluster close items
        var groups: [DuplicateGroup] = []

        for (key, arr) in byRes {
            if arr.count < 2 { continue }

            let sorted = arr.sorted { (lhs, rhs) -> Bool in
                (lhs.creationDate ?? .distantPast) < (rhs.creationDate ?? .distantPast)
            }

            var cluster: [PHAsset] = []
            var lastDate: Date?

            func flushClusterIfNeeded() {
                guard cluster.count >= 2 else {
                    cluster.removeAll()
                    return
                }

                // Estimate freed bytes: sum sizes except keep 1 item
                let sizes = cluster.map { MediaCleanerPhotoBytes.fileSizeBytes(for: $0) ?? 0 }
                let total = sizes.reduce(0, +)
                let keep = sizes.max() ?? 0 // keep the largest
                let freed = max(0, total - keep)

                groups.append(DuplicateGroup(key: key, assets: cluster, estimatedFreedBytes: freed))
                cluster.removeAll()
            }

            for a in sorted {
                let d = a.creationDate ?? .distantPast
                if let ld = lastDate {
                    if d.timeIntervalSince(ld) <= maxSecondsDiff {
                        cluster.append(a)
                    } else {
                        flushClusterIfNeeded()
                        cluster.append(a)
                    }
                } else {
                    cluster.append(a)
                }
                lastDate = d
            }

            flushClusterIfNeeded()
        }

        return groups
    }
}