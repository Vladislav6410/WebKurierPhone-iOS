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


    func testValidLesson01PassesPackageValidation() throws {
        let lesson = try CanonicalLessonLoader().load(from: canonicalLessonURL)
        XCTAssertEqual(lesson.lessonId, CanonicalLessonMapping.lesson01CanonicalId)
        XCTAssertNoThrow(try lesson.validatePackage())
    }

    func testEmptyLessonIdFailsValidation() throws {
        XCTAssertThrowsError(try loadMutatedPackage { object in
            object["lessonId"] = "   "
        }) { error in
            XCTAssertEqual(error as? CanonicalLessonLoadError, .emptyLessonId)
        }
    }

    func testDuplicateSectionIdFailsValidation() throws {
        XCTAssertThrowsError(try loadMutatedPackage { object in
            var sections = object["sections"] as! [[String: Any]]
            sections.append(sections[0])
            object["sections"] = sections
        }) { error in
            guard case CanonicalLessonLoadError.duplicateSectionId = error else {
                return XCTFail("expected duplicate section, got \(error)")
            }
        }
    }

    func testMissingAssignmentFailsValidation() throws {
        XCTAssertThrowsError(try loadMutatedPackage { object in
            let sections = object["sections"] as! [[String: Any]]
            object["sections"] = sections.filter { ($0["kind"] as? String) != "assignment" }
        }) { error in
            XCTAssertEqual(error as? CanonicalLessonLoadError, .missingAssignment)
        }
    }

    func testDanglingVisualReferenceFailsValidation() throws {
        XCTAssertThrowsError(try loadMutatedPackage { object in
            var sections = object["sections"] as! [[String: Any]]
            sections[0]["visualRefs"] = ["missing-visual"]
            object["sections"] = sections
        }) { error in
            XCTAssertEqual(error as? CanonicalLessonLoadError, .danglingVisualReference("missing-visual"))
        }
    }

    func testDuplicateVisualIdFailsValidation() throws {
        XCTAssertThrowsError(try loadMutatedPackage { object in
            var visuals = object["visuals"] as! [[String: Any]]
            visuals.append(visuals[0])
            object["visuals"] = visuals
        }) { error in
            guard case CanonicalLessonLoadError.duplicateVisualId = error else {
                return XCTFail("expected duplicate visual, got \(error)")
            }
        }
    }

    func testMissingTTSResourceFailsValidation() throws {
        let directory = try packageCopy()
        defer { try? FileManager.default.removeItem(at: directory) }
        try FileManager.default.removeItem(at: directory.appendingPathComponent("lesson01_ru_tts.txt"))
        XCTAssertThrowsError(try CanonicalLessonLoader().load(from: directory.appendingPathComponent("lesson.json"))) { error in
            XCTAssertEqual(error as? CanonicalLessonLoadError, .missingTTSResource)
        }
    }

    func testPilotLesson01MapsOnlyToCanonicalLesson01() {
        XCTAssertEqual(
            CanonicalLessonMapping.canonicalId(forPilotLessonId: CanonicalLessonMapping.lesson01PilotId),
            CanonicalLessonMapping.lesson01CanonicalId
        )
        XCTAssertNil(CanonicalLessonMapping.canonicalId(forPilotLessonId: "wk01-l02-os-input-output"))
        let lesson = try XCTUnwrap(PilotLesson.weekOne.first { $0.lessonId == CanonicalLessonMapping.lesson01PilotId })
        let other = try XCTUnwrap(PilotLesson.weekOne.first { $0.lessonId == "wk01-l02-os-input-output" })
        XCTAssertEqual(lesson.lessonId, CanonicalLessonMapping.lesson01PilotId)
        XCTAssertNotEqual(other.lessonId, CanonicalLessonMapping.lesson01PilotId)
        XCTAssertNil(CanonicalLessonMapping.canonicalId(forPilotLessonId: other.lessonId))
    }

    private func mutatedLesson(_ mutate: (inout [String: Any]) -> Void) throws -> CanonicalLesson {
        let directory = try packageCopy(mutate)
        defer { try? FileManager.default.removeItem(at: directory) }
        return try CanonicalLessonLoader().load(from: directory.appendingPathComponent("lesson.json"))
    }

    private func loadMutatedPackage(_ mutate: (inout [String: Any]) -> Void) throws -> CanonicalLesson {
        try mutatedLesson(mutate)
    }

    private func packageCopy(_ mutate: ((inout [String: Any]) -> Void)? = nil) throws -> URL {
        let source = canonicalLessonURL.deletingLastPathComponent()
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        for name in ["lesson.json", "visuals.json", "lesson01_ru_tts.txt"] {
            try FileManager.default.copyItem(at: source.appendingPathComponent(name), to: directory.appendingPathComponent(name))
        }
        if let mutate {
            let url = directory.appendingPathComponent("lesson.json")
            var object = try JSONSerialization.jsonObject(with: Data(contentsOf: url)) as! [String: Any]
            mutate(&object)
            let data = try JSONSerialization.data(withJSONObject: object)
            try data.write(to: url)
        }
        return directory
    }

    func testWeekOneOrderingAndFutureWeeksRemainLocked() {
        XCTAssertEqual(PilotLesson.weekOne.map(\.order), Array(0...7))
        XCTAssertEqual(PilotLesson.weekOne.count, 8)

        let futureWeeks = Array(PilotWeek.roadmap.dropFirst())
        XCTAssertEqual(futureWeeks.map(\.id), Array(2...8))
        XCTAssertTrue(futureWeeks.allSatisfy { $0.isLocked && $0.lessons.isEmpty })
    }
}
