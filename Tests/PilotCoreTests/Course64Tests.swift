import XCTest
@testable import PilotCore

final class Course64Tests: XCTestCase {
    func testCourseHasEightWeeksOfEightLessons() {
        XCTAssertEqual(PilotWeek.roadmap.count, 8)
        XCTAssertEqual(PilotLesson.all.count, 64)
        XCTAssertTrue(PilotWeek.roadmap.allSatisfy { $0.lessons.count == 8 })
        XCTAssertEqual(PilotLesson.all.map(\.courseNumber), Array(1...64))
        XCTAssertEqual(Set(PilotLesson.all.map(\.lessonId)).count, 64)
        XCTAssertEqual(Set(PilotLesson.all.map(\.courseNumber)).count, 64)
        for week in PilotWeek.roadmap {
            XCTAssertEqual(week.lessons.map(\.weekNumber), Array(repeating: week.id, count: 8))
            let expected = Array(((week.id - 1) * 8 + 1)...(week.id * 8))
            XCTAssertEqual(week.lessons.map(\.courseNumber), expected)
        }
    }

    func testWeekOneKeepsVerifiedDriveLinksAndCanonicalLesson01() {
        XCTAssertEqual(PilotLesson.weekOne.map(\.driveFileID), [
            "1ulIXKzbicd67C6tE4JCmvPm3YD_pHmmA",
            "1avmoQQ7U6H0rSzY5nwmww0qeT_4xlNQl",
            "1wW8gkm0pdsAsu2YkRaf4OciDX-UIT5sA",
            "1XNeUyApAymFx3zsH-WKScdwpTbeVM5Na",
            "1Pp1KeMZwwFWei2TJyp_6YIRmVI_VLsWz",
            "16Z-zfr4m27yFFGgLTu3IZOltGwfcqRoD",
            "1m_njgjTjSsuwFJvVrv5Yj-wJ2SsEmNjn",
            "1oJfA4cGtBwEr2HfzSfzkp5sEMWS3WBDZ"
        ])
        let canonical = PilotLesson.all.first { $0.lessonId == PilotLesson.canonicalLesson01Id }
        XCTAssertEqual(canonical?.courseNumber, 2)
        XCTAssertEqual(canonical?.weekNumber, 1)
        XCTAssertEqual(canonical?.linkState, .configured)
        XCTAssertTrue(PilotLesson.weekOne.allSatisfy { $0.linkState == .configured && $0.pdfURL?.scheme == "https" })
    }

    func testLaterLessonsStayUnconfiguredWithoutInventedURLs() {
        let later = PilotLesson.all.filter { $0.courseNumber > 8 }
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

    func testProgressionUnlocksNextWeekOnlyAtEightOfEight() {
        var state = PilotCourseState()
        XCTAssertTrue(state.isWeekUnlocked(1))
        XCTAssertFalse(state.isWeekUnlocked(2))
        XCTAssertFalse(state.isWeekUnlocked(3))
        for lesson in PilotLesson.weekOne.dropLast() {
            state.markCompleted(lessonId: lesson.lessonId)
        }
        XCTAssertEqual(state.completedCount(forWeek: 1), 7)
        XCTAssertFalse(state.isWeekUnlocked(2))
        state.markCompleted(lessonId: PilotLesson.weekOne.last!.lessonId)
        XCTAssertTrue(state.isWeekUnlocked(2))
        XCTAssertFalse(state.isWeekUnlocked(3))
        XCTAssertFalse(state.isCourseComplete)
    }

    func testOpeningLessonDoesNotCompleteItAndWeekEightCompletionFinishesCourse() {
        var state = PilotCourseState()
        state.select(lessonId: PilotLesson.weekOne[0].lessonId)
        XCTAssertTrue(state.completedLessonIds.isEmpty)
        for week in PilotWeek.roadmap {
            for lesson in week.lessons {
                state.markCompleted(lessonId: lesson.lessonId)
            }
        }
        XCTAssertEqual(state.completedLessonIds.count, 64)
        XCTAssertTrue(state.isWeekUnlocked(8))
        XCTAssertTrue(state.isCourseComplete)
    }

    func testLockedWeekCannotBeSelectedOrCompleted() {
        var state = PilotCourseState()
        let lesson = PilotWeek.roadmap[1].lessons[0]
        state.select(lessonId: lesson.lessonId)
        XCTAssertEqual(state.currentLesson.lessonId, PilotLesson.weekOne[0].lessonId)
        state.markCompleted(lessonId: lesson.lessonId)
        XCTAssertFalse(state.completedLessonIds.contains(lesson.lessonId))
    }
}
