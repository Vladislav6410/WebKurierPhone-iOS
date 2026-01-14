import SwiftUI

struct RomanticView: View {

    @State private var message: String = ""
    @State private var response: String = "Waiting for your message…"

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {

                Text(response)
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.pink.opacity(0.1))
                    .cornerRadius(8)

                TextField("Write something…", text: $message)
                    .textFieldStyle(.roundedBorder)

                Button(action: sendMessage) {
                    Text("Send")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Spacer()
            }
            .padding()
            .navigationTitle("Romantic")
        }
    }

    private func sendMessage() {
        guard !message.isEmpty else { return }

        // Placeholder: RomanticAgent via Core
        response = "💬 You said: \(message)"
        message = ""
    }
}