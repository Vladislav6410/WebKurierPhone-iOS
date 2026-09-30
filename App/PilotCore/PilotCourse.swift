import Foundation

enum PilotTab: Hashable {
    case course, copilot, project
}

enum PilotLessonStatus: String {
    case available, current, completed

    var titleKey: String { "pilot.status.\(rawValue)" }
}

struct PilotLesson: Identifiable, Equatable, Sendable {
    let id: Int
    var titleKey: String { "pilot.day.\(id).title" }
    var taskKey: String { "pilot.day.\(id).task" }

    static let weekOne = (1...3).map { PilotLesson(id: $0) }
}

struct PilotWeek: Identifiable {
    let id: Int
    var isLocked: Bool { id != 1 }
    var lessons: [PilotLesson] { isLocked ? [] : PilotLesson.weekOne }

    static let roadmap = (1...8).map { PilotWeek(id: $0) }
}

/// Session-only learning UI state. Never claims server progress or project deployment.
struct PilotCourseState {
    private(set) var currentLesson = PilotLesson.weekOne[0]
    private(set) var completedDays: Set<Int> = []
    var selectedTab: PilotTab = .project

    mutating func select(day: Int) {
        guard let lesson = PilotLesson.weekOne.first(where: { $0.id == day }) else { return }
        currentLesson = lesson
        selectedTab = .copilot
    }

    mutating func markCurrentCompleted() {
        completedDays.insert(currentLesson.id)
    }

    func status(for lesson: PilotLesson) -> PilotLessonStatus {
        if completedDays.contains(lesson.id) { return .completed }
        return lesson == currentLesson ? .current : .available
    }
}
