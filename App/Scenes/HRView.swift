import SwiftUI

struct HRView: View {

    @State private var inputText: String = ""
    @State private var resultText: String = "Awaiting input…"
    @State private var isAnalyzing: Bool = false

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {

                TextEditor(text: $inputText)
                    .frame(minHeight: 140)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3))
                    )

                Button {
                    analyze()
                } label: {
                    HStack(spacing: 10) {
                        if isAnalyzing { ProgressView() }
                        Text(isAnalyzing ? "Analyzing…" : "Analyze")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isAnalyzing || inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                ScrollView {
                    Text(resultText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.blue.opacity(0.06))
                        .cornerRadius(8)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("HR")
        }
    }

    private func analyze() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        isAnalyzing = true
        resultText = "Candidate analysis in progress…"

        // Placeholder: HRAgent via Core
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            resultText = """
            Result (mock):
            - Strengths: communication, consistency
            - Risks: missing portfolio links
            - Recommendation: request examples + schedule interview
            """
            isAnalyzing = false
        }
    }
}