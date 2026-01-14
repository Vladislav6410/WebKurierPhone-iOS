import SwiftUI

struct HRView: View {

    @State private var inputText: String = ""
    @State private var resultText: String = "Awaiting input…"

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {

                TextEditor(text: $inputText)
                    .frame(minHeight: 120)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3))
                    )

                Button(action: analyze) {
                    Text("Analyze")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Text(resultText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(Color.blue.opacity(0.05))
                    .cornerRadius(8)

                Spacer()
            }
            .padding()
            .navigationTitle("HR")
        }
    }

    private func analyze() {
        guard !inputText.isEmpty else { return }

        // Placeholder: HRAgent via Core
        resultText = "Candidate analysis in progress…"
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            resultText = "Basic match detected. Further review recommended."
        }
    }
}