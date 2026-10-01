import XCTest
@testable import PilotCore

final class Course64Tests: XCTestCase {
    func testCourseHasEightWeeksOfEightLessons() {
        XCTAssertEqual(PilotWeek.roadmap.count, 8)
        XCTAssertEqual(PilotLesson.numbered.count, 64)
        XCTAssertEqual(PilotLesson.all.count, 65)
        XCTAssertTrue(PilotWeek.roadmap.allSatisfy { $0.lessons.count == 8 })
        XCTAssertEqual(PilotLesson.numbered.compactMap(\.courseNumber), Array(1...64))
        XCTAssertEqual(Set(PilotLesson.all.map(\.lessonId)).count, 65)
        XCTAssertEqual(Set(PilotLesson.numbered.compactMap(\.courseNumber)).count, 64)
        for week in PilotWeek.roadmap {
            XCTAssertEqual(week.lessons.map(\.weekNumber), Array(repeating: week.id, count: 8))
            let expected = Array(((week.id - 1) * 8 + 1)...(week.id * 8))
            XCTAssertEqual(week.lessons.compactMap(\.courseNumber), expected)
        }
    }

    func testAllLessonsAreSelectableWithoutCompletion() throws {
        var state = PilotCourseState()
        for number in [1, 9, 32, 64] {
            let lesson = try XCTUnwrap(PilotLesson.lesson(courseNumber: number))
            state.select(lessonId: lesson.lessonId)
            XCTAssertEqual(state.currentLesson.courseNumber, number)
            XCTAssertTrue(state.completedLessonIds.isEmpty)
        }
    }

    func testCompletionDoesNotControlAccess() throws {
        var state = PilotCourseState()
        state.markCompleted(lessonId: PilotLesson.introduction.lessonId)
        XCTAssertEqual(state.completedCount, 0)
        state.markCompleted(lessonId: PilotLesson.weekOne[0].lessonId)
        XCTAssertEqual(state.completedCount, 1)
        XCTAssertEqual(PilotLesson.weekOne[0].lessonId, PilotLesson.canonicalLesson01Id)
        state.select(lessonId: try XCTUnwrap(PilotLesson.lesson(courseNumber: 64)).lessonId)
        XCTAssertEqual(state.currentLesson.courseNumber, 64)
        XCTAssertFalse(state.completedLessonIds.contains(state.currentLesson.lessonId))
    }

    func testWeekOneKeepsVerifiedDriveLinksAndCanonicalLesson01() {
        XCTAssertEqual(PilotLesson.introduction.driveFileID, "1ulIXKzbicd67C6tE4JCmvPm3YD_pHmmA")
        XCTAssertEqual(PilotLesson.weekOne.map(\.driveFileID), [
            "1avmoQQ7U6H0rSzY5nwmww0qeT_4xlNQl",
            "1wW8gkm0pdsAsu2YkRaf4OciDX-UIT5sA",
            "1XNeUyApAymFx3zsH-WKScdwpTbeVM5Na",
            "1Pp1KeMZwwFWei2TJyp_6YIRmVI_VLsWz",
            "16Z-zfr4m27yFFGgLTu3IZOltGwfcqRoD",
            "1m_njgjTjSsuwFJvVrv5Yj-wJ2SsEmNjn",
            "1oJfA4cGtBwEr2HfzSfzkp5sEMWS3WBDZ",
            ""
        ])
        let canonical = PilotLesson.all.first { $0.lessonId == PilotLesson.canonicalLesson01Id }
        XCTAssertEqual(canonical?.courseNumber, 1)
        XCTAssertNil(PilotLesson.introduction.courseNumber)
        XCTAssertEqual(canonical?.weekNumber, 1)
        XCTAssertEqual(canonical?.linkState, .configured)
        XCTAssertEqual(PilotLesson.weekOne.filter { $0.linkState == .configured }.count, 7)
        XCTAssertEqual(PilotLesson.weekOne.last?.linkState, .notConfigured)
    }

    func testLaterLessonsStayUnconfiguredWithoutInventedURLs() {
        let later = PilotLesson.numbered.filter { ($0.courseNumber ?? 0) > 8 }
        XCTAssertEqual(later.count, 56)
        XCTAssertTrue(later.allSatisfy { $0.linkState == .notConfigured && $0.pdfURL == nil && $0.driveFileID.isEmpty })
    }

    func testDocumentURLRejectsUnsafeSchemes() {
        XCTAssertTrue(PilotLesson.acceptsDocumentURL(URL(string: "https://drive.google.com/file/d/abc/view")!))
        XCTAssertFalse(PilotLesson.acceptsDocumentURL(URL(string: "http://drive.google.com/file/d/abc/view")!))
        XCTAssertFalse(PilotLesson.acceptsDocumentURL(URL(string: "javascript:alert(1)")!))
        XCTAssertFalse(PilotLesson.acceptsDocumentURL(URL(string: "file:///tmp/lesson.pdf")!))
        XCTAssertFalse(PilotLesson.acceptsDocumentURL(URL(string: "data:text/html,hi")!))
    }
}
