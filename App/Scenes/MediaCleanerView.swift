import SwiftUI

// MARK: - MediaCleanerView
// Minimal UI to test MediaCleaner flow on iOS.

struct MediaCleanerView: View {
    @State private var userId: String = "demo_user"
    @State private var deviceId: String = UIDevice.current.identifierForVendor?.uuidString ?? "ios_device"
    @State private var output: String = "Ready."
    @State private var isLoading: Bool = false

    var body: some View {
        NavigationView {
            VStack(spacing: 12) {
                Form {
                    Section(header: Text("Identity")) {
                        TextField("userId", text: $userId)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)

                        TextField("deviceId", text: $deviceId)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                    }

                    Section(header: Text("Actions")) {
                        Button {
                            Task { await runDemo() }
                        } label: {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                }
                                Text(isLoading ? "Running..." : "Start Demo Cleanup Flow")
                            }
                        }
                        .disabled(isLoading)

                        Button {
                            output = "Ready."
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
                        .frame(minHeight: 160)
                    }
                }

                Text("Privacy-first: no raw images are uploaded. Only summary counts.")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            }
            .navigationTitle("MediaCleaner")
        }
    }

    private func runDemo() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await MediaCleanerService.shared.runDemoCleanupFlow(
                userId: userId,
                deviceId: deviceId
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
        } catch {
            output = "❌ Error: \(error.localizedDescription)"
        }
    }
}