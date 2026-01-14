import SwiftUI

struct DreamMakerView: View {

    @State private var prompt: String = ""
    @State private var statusText: String = "Ready"
    @State private var isGenerating: Bool = false

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {

                TextEditor(text: $prompt)
                    .frame(minHeight: 120)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3))
                    )

                Button(action: generate) {
                    if isGenerating {
                        ProgressView()
                    } else {
                        Text("Generate")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)

                Text(statusText)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer()
            }
            .padding()
            .navigationTitle("DreamMaker")
        }
    }

    private func generate() {
        guard !prompt.isEmpty else { return }

        // Placeholder: DreamAgent via Core
        isGenerating = true
        statusText = "Generating media…"

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            statusText = "Preview ready (mock)"
            isGenerating = false
        }
    }
}