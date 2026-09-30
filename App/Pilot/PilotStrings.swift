import Foundation

/// Respects LocalizationManager's language. The base Copilot table is Russian
/// for this pilot; future <language>.lproj/Copilot.strings override it per key.
/// Lesson 01 title/task are sourced from the bundled canonical package instead
/// of duplicated localization metadata.
struct PilotStrings {
    let language: String

    func callAsFunction(_ key: String) -> String {
        if key == "pilot.lesson.01.title" || key == "pilot.lesson.01.task" {
            do {
                let lesson = try CanonicalLessonLoader().loadLesson01()
                if key == "pilot.lesson.01.title" { return lesson.title }
                guard let assignment = lesson.assignmentSection else {
                    return "ERROR: canonical Lesson 01 assignment is missing"
                }
                return assignment.narration
            } catch {
                return "ERROR: canonical Lesson 01 resource is unavailable"
            }
        }

        let fallback = Bundle.main.localizedString(forKey: key, value: key, table: "Copilot")
        guard let path = Bundle.main.path(forResource: language, ofType: "lproj"),
              let bundle = Bundle(path: path) else { return fallback }
        return bundle.localizedString(forKey: key, value: fallback, table: "Copilot")
    }
}
