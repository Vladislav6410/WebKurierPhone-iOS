import SwiftUI

// MARK: - MediaCleanerView
// UI powered by MediaCleanerViewModel (clean separation of concerns).

struct MediaCleanerView: View {

    @EnvironmentObject private var coreGateway: CoreGateway
    @StateObject private var vm = MediaCleanerViewModel()

    @State private var deviceId: String =
        UIDevice.current.identifierForVendor?.uuidString ?? "ios_device"
    @State private var mode: String = "local_only"

    private var userId: String {
        coreGateway.userId ?? "guest"
    }

    var body: some View {
        NavigationView {
            Form {

                Section(header: Text("Identity")) {
                    HStack {
                        Text("userId")
                        Spacer()
                        Text(userId)
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
                    Text(vm.progressText)
                        .font(.system(.footnote, design: .monospaced))
                }

                Section(header: Text("Actions")) {
                    Button {
                        Task {
                            await vm.run(
                                userId: userId,
                                deviceId: deviceId,
                                mode: mode
                            )
                        }
                    } label: {
                        HStack(spacing: 10) {
                            if vm.isLoading { ProgressView() }
                            Text(vm.isLoading ? "Scanning…" : "Run Scan + Submit Summary")
                        }
                    }
                    .disabled(vm.isLoading)

                    Button {
                        vm.reset()
                    } label: {
                        Text("Clear Output")
                    }
                    .disabled(vm.isLoading)
                }

                Section(header: Text("Output")) {
                    ScrollView {
                        Text(vm.output)
                            .font(.system(.footnote, design: .monospaced))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(minHeight: 220)
                }

                Section {
                    Text("Privacy-first: no raw images are uploaded. Only summary counts and safe metadata.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("MediaCleaner")
        }
    }
}