import XCTest
@testable import PilotCore

final class PilotCoreTests: XCTestCase {
    func testWeekOneContainsCanonicalEightLessons() {
        let week = PilotWeek.roadmap[0]
        XCTAssertFalse(week.isLocked)
        XCTAssertEqual(week.lessons.map(\.lessonId), [
            "wk01-l00-intro",
            "wk01-l01-computer-system",
            "wk01-l02-os-input-output",
            "wk01-l03-files-terminal",
            "wk01-l04-hardware-usb",
            "wk01-l05-engineering-method",
            "wk01-l06-practice-device-internals",
            "wk01-l07-practice-telebridge"
        ])
        XCTAssertEqual(week.lessons.map(\.order), Array(0...7))
    }

    func testWeekOneHasExpectedLessonTypes() {
        XCTAssertEqual(PilotLesson.weekOne.filter { $0.type == .intro }.count, 1)
        XCTAssertEqual(PilotLesson.weekOne.filter { $0.type == .theory }.count, 5)
        XCTAssertEqual(PilotLesson.weekOne.filter { $0.type == .practice }.count, 2)
    }

    func testAllPilotLessonsHaveGoogleDrivePDFURLs() {
        for lesson in PilotLesson.weekOne {
            let url = lesson.pdfURL
            XCTAssertEqual(url?.scheme, "https")
            XCTAssertEqual(url?.host, "drive.google.com")
            XCTAssertTrue(url?.path.hasSuffix("/view") == true)
            XCTAssertTrue(url?.path.contains(lesson.driveFileID) == true)
        }
    }

    func testFutureWeeksAreLockedAndHaveNoLessons() {
        let future = Array(PilotWeek.roadmap.dropFirst())
        XCTAssertEqual(future.map(\.id), Array(2...8))
        XCTAssertTrue(future.allSatisfy { $0.isLocked && $0.lessons.isEmpty })
    }

    func testStartsAtGitHubWithFirstLessonCurrent() {
        let state = PilotCourseState()
        XCTAssertEqual(state.selectedTab, .project)
        XCTAssertEqual(state.currentLesson.lessonId, "wk01-l00-intro")
        XCTAssertEqual(state.status(for: PilotLesson.weekOne[0]), .current)
        XCTAssertEqual(state.status(for: PilotLesson.weekOne[1]), .available)
    }

    func testEachPilotLessonCanOpenInCopilot() {
        for lesson in PilotLesson.weekOne {
            var state = PilotCourseState()
            state.select(lessonId: lesson.lessonId)
            XCTAssertEqual(state.currentLesson.lessonId, lesson.lessonId)
            XCTAssertEqual(state.selectedTab, .copilot)
        }
    }

    func testInvalidLessonDoesNotChangeNavigation() {
        var state = PilotCourseState()
        state.select(lessonId: "wk01-missing")
        XCTAssertEqual(state.currentLesson.lessonId, "wk01-l00-intro")
        XCTAssertEqual(state.selectedTab, .project)
    }

    func testCompletionIsLocalAndDoesNotUnlockFutureWeeks() {
        var state = PilotCourseState()
        let lesson = PilotLesson.weekOne[2]
        state.select(lessonId: lesson.lessonId)
        state.markCurrentCompleted()
        state.markCurrentCompleted()
        XCTAssertEqual(state.completedLessonIds, [lesson.lessonId])
        XCTAssertEqual(state.status(for: lesson), .completed)
        XCTAssertTrue(PilotCourseState().completedLessonIds.isEmpty)
        XCTAssertTrue(PilotWeek.roadmap.dropFirst().allSatisfy(\.isLocked))
    }

    func testGitHubConnectingConnectedAndDuplicateSuppression() {
        var connection = PilotGitHubConnection()
        XCTAssertEqual(connection.state, .notConnected)
        XCTAssertTrue(connection.begin())
        XCTAssertEqual(connection.state, .connecting)
        XCTAssertFalse(connection.begin())
        let session = PilotGitHubSession(login: "test-student", repositoryName: nil, verifiedProjectStatus: nil)
        connection.finish(.success(session))
        XCTAssertEqual(connection.state, .connected(session))
        XCTAssertFalse(connection.begin())
    }

    func testGitHubFailureAllowsRetryWithoutInventingIdentity() {
        var connection = PilotGitHubConnection()
        XCTAssertTrue(connection.begin())
        connection.finish(.failure(.notConfigured))
        XCTAssertEqual(connection.state, .error(.notConfigured))
        XCTAssertNil(connection.state.session)
        XCTAssertTrue(connection.begin())
        connection.finish(.failure(.failed))
        XCTAssertEqual(connection.state, .error(.failed))
    }

    func testGitHubIgnoresUnsolicitedResultsAndRejectsEmptyIdentity() {
        var connection = PilotGitHubConnection()
        let session = PilotGitHubSession(login: " ", repositoryName: nil, verifiedProjectStatus: nil)
        connection.finish(.success(session))
        XCTAssertEqual(connection.state, .notConnected)
        XCTAssertTrue(connection.begin())
        connection.finish(.success(session))
        XCTAssertEqual(connection.state, .error(.failed))
    }

    func testMissingSiteConfigurationIsDisabled() {
        XCTAssertNil(PilotProjectConfiguration().siteURL)
        XCTAssertNil(PilotProjectConfiguration(siteURLString: "").siteURL)
    }

    func testHTTPSURLPreservesPathAndFragment() {
        let url = "https://example.org/student/site?preview=1#result"
        XCTAssertEqual(PilotProjectConfiguration(siteURLString: url).siteURL?.absoluteString, url)
    }

    func testUnsafeAndPlaceholderURLsAreRejected() {
        let rejected = [
            "http://example.org", "javascript:alert(1)", "file:///tmp/site",
            "https://", "example.org/site", "//example.org", "https://localhost",
            "https://student.localhost", "https://site.webkurier.example",
            "https://site.invalid", "$(PILOT_PROJECT_SITE_URL)",
            "https://user:password@example.org", "https://example.org:8080",
            " https://example.org", "https://example.org/a b"
        ]
        for value in rejected {
            XCTAssertNil(PilotProjectConfiguration(siteURLString: value).siteURL, value)
        }
    }

    @MainActor
    func testUnavailableGitHubDoesNotAuthenticate() async {
        do {
            _ = try await UnavailablePilotGitHubService().connect()
            XCTFail("Unconfigured service must not return an identity")
        } catch {
            XCTAssertEqual(error as? PilotServiceError, .notConfigured)
        }
    }

    @MainActor
    func testUnavailableCopilotNeverReturnsAFabricatedReply() async {
        let service = UnavailablePilotCopilotService()
        XCTAssertFalse(service.isAvailable)
        let request = PilotCopilotRequest(
            lesson: PilotLesson.weekOne[0],
            project: PilotGitHubSession(login: "test-student", repositoryName: nil, verifiedProjectStatus: nil),
            message: "Test", history: []
        )
        do {
            _ = try await service.send(request)
            XCTFail("Unconfigured service must not fabricate an answer")
        } catch {
            XCTAssertEqual(error as? PilotServiceError, .notConfigured)
        }
    }
}
