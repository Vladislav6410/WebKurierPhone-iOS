import SwiftUI

// MARK: - MediaCleanerView
// Minimal UI to run privacy-first scan (metadata only) + submit summary to Core.

struct MediaCleanerView: View {
    @State private var userId: String = "demo_user"
    @State private var deviceId: String = UIDevice.current.identifierForVendor?.uuidString ?? "ios_device"
    @State private var mode: String = "local_only"

    @State private var output: String = "Ready."
    @State private var isLoading: Bool = false

    @State private var progressText: String = "—"

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Identity")) {
                    TextField("userId", text: $userId)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)

                    TextField("deviceId", text: $deviceId)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)

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
                        HStack {
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
        isLoading = true
        progressText = "Starting…"
        defer { isLoading = false }

        do {
            let result = try await MediaCleanerService.shared.runCleanupFlow(
                userId: userId,
                deviceId: deviceId,
                mode: mode,
                onProgress: { p in
                    DispatchQueue.main.async {
                        self.progressText = "scanned \(p.scanned) / \(p.total)"
                    }
                }
            )

            let summary = result.summary
            let freedBytes = summary.duplicates.estimatedFreedBytes
                + summary.blur.estimatedFreedBytes
                + summary.screenshots.estimatedFreedBytes
                + summary.slimMode.estimatedFreedBytes

            output = """
            ✅ Session: \(result.sessionId)

            Summary:
            - Duplicates: groups=\(summary.duplicates.groups), items=\(summary.duplicates.items), freed=\(summary.duplicates.estimatedFreedBytes)
            - Blur: items=\(summary.blur.items), freed=\(summary.blur.estimatedFreedBytes)
            - Screenshots: items=\(summary.screenshots.items), freed=\(summary.screenshots.estimatedFreedBytes)
            - SlimMode: enabled=\(summary.slimMode.enabled), freed=\(summary.slimMode.estimatedFreedBytes)

            Total Freed (estimated): \(freedBytes) bytes
            WebCoins Awarded: \(result.coinsAwarded)
            """

            progressText = "Done."
        } catch {
            output = "❌ Error: \(error.localizedDescription)"
            progressText = "Failed."
        }
    }
}