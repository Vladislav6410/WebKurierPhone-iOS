import SwiftUI

struct LessonsView: View {

    @State private var selectedLevel: String = "A1"
    private let levels = ["A1", "A2", "B1", "B2", "C1"]

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {

                Picker("Level", selection: $selectedLevel) {
                    ForEach(levels, id: \.self) { level in
                        Text(level).tag(level)
                    }
                }
                .pickerStyle(.segmented)

                List {
                    Text("Lesson 1 – Basics")
                    Text("Lesson 2 – Everyday phrases")
                    Text("Lesson 3 – Listening practice")
                }

            }
            .padding()
            .navigationTitle("Lessons")
        }
    }
}