import SwiftUI

struct TranslatorView: View {

    @State private var sourceText: String = ""
    @State private var translatedText: String = ""
    @State private var isTranslating: Bool = false

    @State private var sourceLang: String = "auto"
    @State private var targetLang: String = "en"

    private let languages = ["auto", "de", "en", "pl", "ru", "uk"]

    var body: some View {
        NavigationView {
            VStack(spacing: 14) {

                HStack(spacing: 12) {
                    Picker("source", selection: $sourceLang) {
                        ForEach(languages, id: \.self) { Text($0.uppercased()).tag($0) }
                    }
                    .pickerStyle(.menu)

                    Image(systemName: "arrow.right")

                    Picker("target", selection: $targetLang) {
                        ForEach(languages.filter { $0 != "auto" }, id: \.self) { Text($0.uppercased()).tag($0) }
                    }
                    .pickerStyle(.menu)
                }

                TextEditor(text: $sourceText)
                    .frame(minHeight: 120)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3))
                    )

                Button(action: translate) {
                    if isTranslating {
                        ProgressView()
                    } else {
                        Text("Translate")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isTranslating || sourceText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                TextEditor(text: $translatedText)
                    .frame(minHeight: 120)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3))
                    )

                Spacer()
            }
            .padding()
            .navigationTitle("Translator")
        }
    }

    private func translate() {
        let text = sourceText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        isTranslating = true
        translatedText = ""

        let src: String? = (sourceLang == "auto") ? nil : sourceLang

        PhoneCoreAPI.shared.translate(
            text: text,
            sourceLang: src,
            targetLang: targetLang
        ) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let translated):
                    self.translatedText = translated
                case .failure(let error):
                    self.translatedText = "Error: \(error.localizedDescription)"
                }
                self.isTranslating = false
            }
        }
    }
}