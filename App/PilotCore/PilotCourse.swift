import Foundation

enum PilotTab: Hashable {
    case course, copilot, project
}

enum PilotLessonStatus: String {
    case available, current, completed

    var titleKey: String { "pilot.status.\(rawValue)" }
}

enum PilotLessonType: String, Equatable, Sendable {
    case intro, theory, practice

    var titleKey: String { "pilot.lesson.type.\(rawValue)" }
}

struct PilotLesson: Identifiable, Equatable, Sendable {
    let lessonId: String
    let order: Int
    let type: PilotLessonType
    let titleKey: String
    let taskKey: String
    let driveFileID: String

    var id: String { lessonId }

    /// TEST ONLY: Google Drive browser fallback for the owner pilot.
    /// The file ID is temporary content metadata and will be replaced by PhoneCore asset resolution.
    var pdfURL: URL? {
        guard !driveFileID.isEmpty else { return nil }
        var parts = URLComponents()
        parts.scheme = "https"
        parts.host = "drive.google.com"
        parts.path = "/file/d/\(driveFileID)/view"
        return parts.url
    }

    static let weekOne: [PilotLesson] = [
        PilotLesson(
            lessonId: "wk01-l00-intro", order: 0, type: .intro,
            titleKey: "pilot.lesson.00.title", taskKey: "pilot.lesson.00.task",
            driveFileID: "1ulIXKzbicd67C6tE4JCmvPm3YD_pHmmA"
        ),
        PilotLesson(
            lessonId: "wk01-l01-computer-system", order: 1, type: .theory,
            titleKey: "pilot.lesson.01.title", taskKey: "pilot.lesson.01.task",
            driveFileID: "1avmoQQ7U6H0rSzY5nwmww0qeT_4xlNQl"
        ),
        PilotLesson(
            lessonId: "wk01-l02-os-input-output", order: 2, type: .theory,
            titleKey: "pilot.lesson.02.title", taskKey: "pilot.lesson.02.task",
            driveFileID: "1wW8gkm0pdsAsu2YkRaf4OciDX-UIT5sA"
        ),
        PilotLesson(
            lessonId: "wk01-l03-files-terminal", order: 3, type: .theory,
            titleKey: "pilot.lesson.03.title", taskKey: "pilot.lesson.03.task",
            driveFileID: "1XNeUyApAymFx3zsH-WKScdwpTbeVM5Na"
        ),
        PilotLesson(
            lessonId: "wk01-l04-hardware-usb", order: 4, type: .theory,
            titleKey: "pilot.lesson.04.title", taskKey: "pilot.lesson.04.task",
            driveFileID: "1Pp1KeMZwwFWei2TJyp_6YIRmVI_VLsWz"
        ),
        PilotLesson(
            lessonId: "wk01-l05-engineering-method", order: 5, type: .theory,
            titleKey: "pilot.lesson.05.title", taskKey: "pilot.lesson.05.task",
            driveFileID: "16Z-zfr4m27yFFGgLTu3IZOltGwfcqRoD"
        ),
        PilotLesson(
            lessonId: "wk01-l06-practice-device-internals", order: 6, type: .practice,
            titleKey: "pilot.lesson.06.title", taskKey: "pilot.lesson.06.task",
            driveFileID: "1m_njgjTjSsuwFJvVrv5Yj-wJ2SsEmNjn"
        ),
        PilotLesson(
            lessonId: "wk01-l07-practice-telebridge", order: 7, type: .practice,
            titleKey: "pilot.lesson.07.title", taskKey: "pilot.lesson.07.task",
            driveFileID: "1oJfA4cGtBwEr2HfzSfzkp5sEMWS3WBDZ"
        )
    ]
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
    private(set) var completedLessonIds: Set<String> = []
    var selectedTab: PilotTab = .project

    mutating func select(lessonId: String) {
        guard let lesson = PilotLesson.weekOne.first(where: { $0.lessonId == lessonId }) else { return }
        currentLesson = lesson
        selectedTab = .copilot
    }

    mutating func markCurrentCompleted() {
        completedLessonIds.insert(currentLesson.lessonId)
    }

    func status(for lesson: PilotLesson) -> PilotLessonStatus {
        if completedLessonIds.contains(lesson.lessonId) { return .completed }
        return lesson == currentLesson ? .current : .available
    }
}
