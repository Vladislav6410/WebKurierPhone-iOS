import SwiftUI

struct LessonsView: View {

    @State private var selectedLanguage: String = "de"
    @State private var selectedLevel: String = "A1"

    private let languages = ["de", "en", "pl", "ru", "uk"]
    private let levels = ["A1", "A2", "B1", "B2", "C1"]

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {

                HStack(spacing: 12) {
                    Picker("Language", selection: $selectedLanguage) {
                        ForEach(languages, id: \.self) { lang in
                            Text(lang.uppercased()).tag(lang)
                        }
                    }
                    .pickerStyle(.menu)

                    Picker("Level", selection: $selectedLevel) {
                        ForEach(levels, id: \.self) { level in
                            Text(level).tag(level)
                        }
                    }
                    .pickerStyle(.menu)
                }

                List {
                    Section(header: Text("Available Lessons")) {
                        LessonRow(title: "Unit 1 – Basics", description: "Greetings, alphabet, numbers")
                        LessonRow(title: "Unit 2 – Everyday Speech", description: "Shopping, transport, time")
                        LessonRow(title: "Unit 3 – Listening", description: "Short dialogues and audio")
                    }
                }
                .listStyle(.insetGrouped)

            }
            .padding()
            .navigationTitle("Lessons")
        }
    }
}

private struct LessonRow: View {
    let title: String
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
            Text(description)
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}