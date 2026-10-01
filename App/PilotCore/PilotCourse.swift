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

enum PilotLessonLinkState: Equatable, Sendable {
    case configured
    case notConfigured
}

struct PilotLesson: Identifiable, Equatable, Sendable {
    let lessonId: String
    /// Position inside the week, preserved from the Week 1 runtime. 0...7.
    let order: Int
    /// Sequential course slot. Exactly 1...64. Independent of presentation medium.
    let courseNumber: Int
    let weekNumber: Int
    let type: PilotLessonType
    let titleKey: String
    let taskKey: String
    let driveFileID: String

    var id: String { lessonId }
    var positionInWeek: Int { order + 1 }

    var linkState: PilotLessonLinkState {
        driveFileID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .notConfigured : .configured
    }

    /// TEST ONLY: Google Drive browser fallback for the owner pilot.
    /// The file ID is temporary content metadata and will be replaced by PhoneCore asset resolution.
    var pdfURL: URL? {
        let fileID = driveFileID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !fileID.isEmpty else { return nil }
        var parts = URLComponents()
        parts.scheme = "https"
        parts.host = "drive.google.com"
        parts.path = "/file/d/\(fileID)/view"
        return parts.url
    }

    static func acceptsDocumentURL(_ url: URL) -> Bool {
        guard let parts = URLComponents(url: url, resolvingAgainstBaseURL: false),
              parts.scheme?.lowercased() == "https",
              let host = parts.host?.trimmingCharacters(in: .whitespacesAndNewlines),
              !host.isEmpty,
              !host.contains(" "),
              url.user == nil else { return false }
        return true
    }

    static let weekOne: [PilotLesson] = [
        PilotLesson(
            lessonId: "wk01-l00-intro", order: 0, courseNumber: 1, weekNumber: 1, type: .intro,
            titleKey: "pilot.lesson.00.title", taskKey: "pilot.lesson.00.task",
            driveFileID: "1ulIXKzbicd67C6tE4JCmvPm3YD_pHmmA"
        ),
        PilotLesson(
            lessonId: "wk01-l01-computer-system", order: 1, courseNumber: 2, weekNumber: 1, type: .theory,
            titleKey: "pilot.lesson.01.title", taskKey: "pilot.lesson.01.task",
            driveFileID: "1avmoQQ7U6H0rSzY5nwmww0qeT_4xlNQl"
        ),
        PilotLesson(
            lessonId: "wk01-l02-os-input-output", order: 2, courseNumber: 3, weekNumber: 1, type: .theory,
            titleKey: "pilot.lesson.02.title", taskKey: "pilot.lesson.02.task",
            driveFileID: "1wW8gkm0pdsAsu2YkRaf4OciDX-UIT5sA"
        ),
        PilotLesson(
            lessonId: "wk01-l03-files-terminal", order: 3, courseNumber: 4, weekNumber: 1, type: .theory,
            titleKey: "pilot.lesson.03.title", taskKey: "pilot.lesson.03.task",
            driveFileID: "1XNeUyApAymFx3zsH-WKScdwpTbeVM5Na"
        ),
        PilotLesson(
            lessonId: "wk01-l04-hardware-usb", order: 4, courseNumber: 5, weekNumber: 1, type: .theory,
            titleKey: "pilot.lesson.04.title", taskKey: "pilot.lesson.04.task",
            driveFileID: "1Pp1KeMZwwFWei2TJyp_6YIRmVI_VLsWz"
        ),
        PilotLesson(
            lessonId: "wk01-l05-engineering-method", order: 5, courseNumber: 6, weekNumber: 1, type: .theory,
            titleKey: "pilot.lesson.05.title", taskKey: "pilot.lesson.05.task",
            driveFileID: "16Z-zfr4m27yFFGgLTu3IZOltGwfcqRoD"
        ),
        PilotLesson(
            lessonId: "wk01-l06-practice-device-internals", order: 6, courseNumber: 7, weekNumber: 1, type: .practice,
            titleKey: "pilot.lesson.06.title", taskKey: "pilot.lesson.06.task",
            driveFileID: "1m_njgjTjSsuwFJvVrv5Yj-wJ2SsEmNjn"
        ),
        PilotLesson(
            lessonId: "wk01-l07-practice-telebridge", order: 7, courseNumber: 8, weekNumber: 1, type: .practice,
            titleKey: "pilot.lesson.07.title", taskKey: "pilot.lesson.07.task",
            driveFileID: "1oJfA4cGtBwEr2HfzSfzkp5sEMWS3WBDZ"
        )
    ]

    /// Historical Week 1 card that presents the canonical Lesson 01 package.
    /// Course slot 2, because the existing intro card is course slot 1.
    static let canonicalLesson01Id = "wk01-l01-computer-system"

    static let all: [PilotLesson] = PilotWeek.roadmap.flatMap(\.lessons)

    static func lesson(courseNumber: Int) -> PilotLesson? {
        all.first { $0.courseNumber == courseNumber }
    }
}

struct PilotWeek: Identifiable, Equatable {
    let id: Int
    let lessons: [PilotLesson]

    /// Initial lock only. Runtime unlock is completion-based on PilotCourseState.
    var isLocked: Bool { id != 1 }

    static let roadmap: [PilotWeek] = (1...8).map { weekNumber in
        let lessons: [PilotLesson]
        if weekNumber == 1 {
            lessons = PilotLesson.weekOne
        } else {
            let start = (weekNumber - 1) * 8
            lessons = (1...8).map { position in
                let courseNumber = start + position
                return PilotLesson(
                    lessonId: String(format: "wk%02d-l%02d", weekNumber, position),
                    order: position - 1,
                    courseNumber: courseNumber,
                    weekNumber: weekNumber,
                    type: .theory,
                    titleKey: "pilot.lesson.slot.title",
                    taskKey: "pilot.lesson.slot.task",
                    driveFileID: ""
                )
            }
        }
        return PilotWeek(id: weekNumber, lessons: lessons)
    }
}

/// Session-only learning UI state. Never claims server progress or project deployment.
struct PilotCourseState {
    private(set) var currentLesson = PilotLesson.weekOne[0]
    private(set) var completedLessonIds: Set<String> = []
    var selectedTab: PilotTab = .project

    func isWeekUnlocked(_ weekNumber: Int) -> Bool {
        guard (1...8).contains(weekNumber) else { return false }
        if weekNumber == 1 { return true }
        return completedCount(forWeek: weekNumber - 1) == 8
    }

    func completedCount(forWeek weekNumber: Int) -> Int {
        guard let week = PilotWeek.roadmap.first(where: { $0.id == weekNumber }) else { return 0 }
        return week.lessons.filter { completedLessonIds.contains($0.lessonId) }.count
    }

    var isCourseComplete: Bool { completedCount(forWeek: 8) == 8 }

    mutating func select(lessonId: String) {
        guard let lesson = PilotLesson.all.first(where: { $0.lessonId == lessonId }),
              isWeekUnlocked(lesson.weekNumber) else { return }
        currentLesson = lesson
        selectedTab = .copilot
    }

    mutating func markCurrentCompleted() {
        markCompleted(lessonId: currentLesson.lessonId)
    }

    mutating func markCompleted(lessonId: String) {
        guard let lesson = PilotLesson.all.first(where: { $0.lessonId == lessonId }),
              isWeekUnlocked(lesson.weekNumber) else { return }
        completedLessonIds.insert(lesson.lessonId)
    }

    func status(for lesson: PilotLesson) -> PilotLessonStatus {
        if completedLessonIds.contains(lesson.lessonId) { return .completed }
        return lesson == currentLesson ? .current : .available
    }
}
