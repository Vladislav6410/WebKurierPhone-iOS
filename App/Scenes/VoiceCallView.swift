import SwiftUI

struct VoiceCallView: View {

    @State private var isCalling: Bool = false
    @State private var statusText: String = "Idle"

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {

                Text(statusText)
                    .font(.headline)

                Button(action: toggleCall) {
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
        isCalling.toggle()
        statusText = isCalling ? "Connecting…" : "Idle"

        // Placeholder: WebRTCClient integration via PhoneCore
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            if isCalling {
                statusText = "Call Active"
            }
        }
    }
}