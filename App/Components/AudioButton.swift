import SwiftUI

struct AudioButton: View {

    let isRecording: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: isRecording ? "stop.circle.fill" : "mic.circle.fill")
                .font(.system(size: 44))
        }
        .buttonStyle(.plain)
    }
}