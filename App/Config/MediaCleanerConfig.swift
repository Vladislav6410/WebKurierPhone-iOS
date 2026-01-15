import Foundation

// MARK: - MediaCleanerConfig
// Central config for MediaCleaner scanning heuristics.
// Keep all "magic numbers" here.

enum MediaCleanerConfig {

    // MARK: - Duplicates (non-ML heuristic)

    /// Assets created within this time window (seconds) AND same resolution
    /// may be treated as duplicates.
    static let duplicatesMaxSecondsDiff: TimeInterval = 3.0

    // MARK: - Screenshot estimation

    /// Assumption: user deletes ~50% of screenshots found (for estimation only).
    static let screenshotsDeleteRatio: Double = 0.50

    // MARK: - Slim Mode estimation

    /// Assumption: average compression savings ~35% (estimation only).
    static let slimModeSavingsRatio: Double = 0.35

    // MARK: - Progress reporting

    static let progressBatchSize: Int = 150
}