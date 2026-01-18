import Foundation
import Combine

// MARK: - MediaCleanerViewModel
// Thin ViewModel layer between MediaCleanerView and MediaCleanerService.
// Keeps UI logic clean and testable.

@MainActor
final class MediaCleanerViewModel: ObservableObject {

    @Published var output: String = "Ready."
    @Published var progressText: String = "—"
    @Published var isLoading: Bool = false

    private let service: MediaCleanerService

    init(service: MediaCleanerService = .shared) {
        self.service = service
    }

    func reset() {
        output = "Ready."
        progressText = "—"
    }

    func run(
        userId: String,
        deviceId: String,
        mode: String = "local_only"
    ) async {
        isLoading = true
        progressText = "Starting…"
        defer { isLoading = false }

        do {
            let result = try await service.runCleanupFlow(
                userId: userId,
                deviceId: deviceId,
                mode: mode,
                onProgress: { progress in
                    Task { @MainActor in
                        self.progressText = "scanned \(progress.scanned) / \(progress.total)"
                    }
                }
            )

            let summary = result.summary
            let freedBytes =
                summary.duplicates.estimatedFreedBytes +
                summary.blur.estimatedFreedBytes +
                summary.screenshots.estimatedFreedBytes +
                summary.slimMode.estimatedFreedBytes

            let freedHuman = ByteCountFormatter.string(
                fromByteCount: Int64(freedBytes),
                countStyle: .file
            )

            output = """
            ✅ Session: \(result.sessionId)

            Summary:
            - Duplicates: groups=\(summary.duplicates.groups), items=\(summary.duplicates.items)
            - Blur: items=\(summary.blur.items)
            - Screenshots: items=\(summary.screenshots.items)
            - SlimMode: enabled=\(summary.slimMode.enabled)

            Total Freed (estimated): \(freedHuman)
            WebCoins Awarded: \(result.coinsAwarded)
            """

            progressText = "Done."
        } catch {
            output = "❌ Error: \(error.localizedDescription)"
            progressText = "Failed."
        }
    }
}