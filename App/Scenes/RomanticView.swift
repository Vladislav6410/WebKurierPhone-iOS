import SwiftUI

struct RomanticView: View {

    @State private var input: String = ""
    @State private var response: String = "Waiting for your message…"
    @State private var isSending: Bool = false

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {

                ScrollView {
                    Text(response)
                        .font(.body)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.pink.opacity(0.08))
                        .cornerRadius(8)
                }

                HStack(spacing: 10) {
                    TextField("Write something…", text: $input)
                        .textFieldStyle(.roundedBorder)

                    Button {
                        send()
                    } label: {
                        if isSending {
                            ProgressView()
                        } else {
                            Image(systemName: "paperplane.fill")
                        }
                    }
                    .disabled(isSending || input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Romantic")
        }
    }

    private func send() {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        isSending = true
        input = ""

        // Placeholder: RomanticAgent via Core
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            response = "💬 You said: \(text)\n\n❤️ Response: I’m here with you."
            isSending = false
        }
    }
}