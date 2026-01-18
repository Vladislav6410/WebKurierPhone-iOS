import SwiftUI

// MARK: - MediaCleanerView
// Privacy-first UI to run metadata-only scan + submit summary to Core (via MediaCleanerService).
// Updated:
// - userId is read-only from CoreGateway (no manual edit by default)
// - deviceId is read-only (stable per vendor)
// - mode kept (local_only / sync_enabled)
// - better output formatting + byte formatting
// - safe main-thread updates

struct MediaCleanerView: View {

    @EnvironmentObject private var coreGateway: CoreGateway

    @State private var deviceId: String = UIDevice.current.identifierForVendor?.uuidString ?? "ios_device"
    @State private var mode: String = "local_only"

    @State private var output: String = "Ready."
    @State private var isLoading: Bool = false
    @State private var progressText: String = "—"

    private var resolvedUserId: String {
        coreGateway.userId ?? "guest"
    }

    var body: some View {
        NavigationView {
            Form {

                Section(header: Text("Identity")) {
                    HStack {
                        Text("userId")
                        Spacer()
                        Text(resolvedUserId)
                            .font(.system(.footnote, design: .monospaced))
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("deviceId")
                        Spacer()
                        Text(deviceId)
                            .font(.system(.footnote, design: .monospaced))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }

                    Picker("mode", selection: $mode) {
                        Text("local_only").tag("local_only")
                        Text("sync_enabled").tag("sync_enabled")
                    }
                }

                Section(header: Text("Scan Progress")) {
                    Text(progressText)
                        .font(.system(.footnote, design: .monospaced))
                }

                Section(header: Text("Actions")) {
                    Button {
                        Task { await runScan() }
                    } label: {
                        HStack(spacing: 10) {
                            if isLoading { ProgressView() }
                            Text(isLoading ? "Scanning..." : "Run Scan + Submit Summary")
                        }
                    }
                    .disabled(isLoading)

                    Button {
                        output = "Ready."
                        progressText = "—"
                    } label: {
                        Text("Clear Output")
                    }
                    .disabled(isLoading)
                }

                Section(header: Text("Output")) {
                    ScrollView {
                        Text(output)
                            .font(.system(.footnote, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(minHeight: 220)
                }

                Section {
                    Text("Privacy-first: no raw images are uploaded. Only summary counts + safe metadata.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("MediaCleaner")
        }
    }

    private func runScan() async {
        await MainActor.run {
            isLoading = true
            progressText = "Starting…"
        }
        defer {
            Task { @MainActor in
                isLoading = false
            }
        }

        do {
            let result = try await MediaCleanerService.shared.runCleanupFlow(
                userId: resolvedUserId,
                deviceId: deviceId,
                mode: mode,
                onProgress: { p in
                    Task { @MainActor in
                        self.progressText = "scanned \(p.scanned) / \(p.total)"
                    }
                }
            )

            let summary = result.summary
            let freedBytes =
                summary.duplicates.estimatedFreedBytes +
                summary.blur.estimatedFreedBytes +
                summary.screenshots.estimatedFreedBytes +
                summary.slimMode.estimatedFreedBytes

            let freedHuman = ByteCountFormatter.string(fromByteCount: Int64(freedBytes), countStyle: .file)

            let out = """
            ✅ Session: \(result.sessionId)

            Summary:
            - Duplicates: groups=\(summary.duplicates.groups), items=\(summary.duplicates.items), freed=\(summary.duplicates.estimatedFreedBytes) bytes
            - Blur: items=\(summary.blur.items), freed=\(summary.blur.estimatedFreedBytes) bytes
            - Screenshots: items=\(summary.screenshots.items), freed=\(summary.screenshots.estimatedFreedBytes) bytes
            - SlimMode: enabled=\(summary.slimMode.enabled), freed=\(summary.slimMode.estimatedFreedBytes) bytes

            Total Freed (estimated): \(freedBytes) bytes (\(freedHuman))
            WebCoins Awarded: \(result.coinsAwarded)
            """

            await MainActor.run {
                output = out
                progressText = "Done."
            }
        } catch {
            await MainActor.run {
                output = "❌ Error: \(error.localizedDescription)"
                progressText = "Failed."
            }
        }
    }
}