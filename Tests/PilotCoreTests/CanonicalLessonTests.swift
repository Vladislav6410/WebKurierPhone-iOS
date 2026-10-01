import XCTest
@testable import PilotCore

final class CanonicalLessonTests: XCTestCase {
    private var canonicalLessonURL: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("Resources/Education/Lessons/week01/lesson01/lesson.json")
    }

    func testCanonicalLesson01DecodesRequiredMetadata() throws {
        let lesson = try CanonicalLessonLoader().load(from: canonicalLessonURL)

        XCTAssertEqual(lesson.lessonId, "week01.lesson01.computer-as-system")
        XCTAssertEqual(lesson.language, "ru")
        XCTAssertEqual(lesson.title, "Компьютер как система")
        XCTAssertFalse(lesson.objectives.isEmpty)
        XCTAssertFalse(lesson.sections.isEmpty)
        XCTAssertNotNil(lesson.assignmentSection)
        XCTAssertEqual(lesson.tts.scriptFile, "lesson01_ru_tts.txt")
        XCTAssertFalse(lesson.visuals.isEmpty)
        XCTAssertTrue(lesson.sections.contains { !$0.visualRefs.isEmpty })
    }

    func testMalformedJSONFailsExplicitly() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("json")
        try Data("{not-json".utf8).write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }

        XCTAssertThrowsError(try CanonicalLessonLoader().load(from: url)) { error in
            XCTAssertEqual(error as? CanonicalLessonLoadError, .malformedJSON)
        }
    }

    func testMissingResourceFailsExplicitly() {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("missing-\(UUID().uuidString).json")

        XCTAssertThrowsError(try CanonicalLessonLoader().load(from: url)) { error in
            XCTAssertEqual(
                error as? CanonicalLessonLoadError,
                .missingResource(url.lastPathComponent)
            )
        }
    }

    func testWeekOneOrderingAndFutureWeeksRemainLocked() {
        XCTAssertEqual(PilotLesson.weekOne.map(\.order), Array(0...7))
        XCTAssertEqual(PilotLesson.weekOne.count, 8)

        let futureWeeks = Array(PilotWeek.roadmap.dropFirst())
        XCTAssertEqual(futureWeeks.map(\.id), Array(2...8))
        XCTAssertTrue(futureWeeks.allSatisfy { $0.isLocked && $0.lessons.count == 8 })
    }
}
