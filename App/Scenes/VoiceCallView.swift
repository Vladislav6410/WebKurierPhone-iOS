import SwiftUI

struct VoiceCallView: View {

    @State private var isCalling: Bool = false
    @State private var statusText: String = "Idle"

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {

                Text(statusText)
                    .font(.headline)

                Button {
                    toggleCall()
                } label: {
                    Text(isCalling ? "End Call" : "Start Call")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(isCalling ? .red : .blue)

                Spacer()
            }
            .padding()
            .navigationTitle("Voice Call")
        }
    }

    private func toggleCall() {
        if isCalling {
            WebRTCClient.shared.endCall()
            statusText = "Idle"
        } else {
            statusText = "Connecting…"
            WebRTCClient.shared.startCall()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                statusText = "Call Active"
            }
        }
        isCalling.toggle()
    }
}