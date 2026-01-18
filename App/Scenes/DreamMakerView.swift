import SwiftUI

struct DreamMakerView: View {

    @State private var prompt: String = ""
    @State private var statusText: String = "Ready"
    @State private var isGenerating: Bool = false

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {

                TextEditor(text: $prompt)
                    .frame(minHeight: 140)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3))
                    )

                Button {
                    generate()
                } label: {
                    HStack(spacing: 10) {
                        if isGenerating { ProgressView() }
                        Text(isGenerating ? "Generating…" : "Generate")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isGenerating || prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Text(statusText)
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.purple.opacity(0.06))
                    .cornerRadius(8)

                Spacer()
            }
            .padding()
            .navigationTitle("DreamMaker")
        }
    }

    private func generate() {
        let text = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        isGenerating = true
        statusText = "Generating media…"

        // Placeholder: DreamAgent via Core
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            statusText = "Preview ready (mock). Next: Core integration."
            isGenerating = false
        }
    }
}