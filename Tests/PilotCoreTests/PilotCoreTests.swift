import XCTest
@testable import PilotCore

final class PilotCoreTests: XCTestCase {
    func testWeekOneContainsThreeAvailableLessons() {
        let week = PilotWeek.roadmap[0]
        XCTAssertFalse(week.isLocked)
        XCTAssertEqual(week.lessons.map(\.id), [1, 2, 3])
        XCTAssertEqual(week.lessons.map(\.titleKey), [
            "pilot.day.1.title", "pilot.day.2.title", "pilot.day.3.title"
        ])
    }

    func testFutureWeeksAreLockedAndHaveNoLessons() {
        let future = Array(PilotWeek.roadmap.dropFirst())
        XCTAssertEqual(future.map(\.id), Array(2...8))
        XCTAssertTrue(future.allSatisfy { $0.isLocked && $0.lessons.isEmpty })
    }

    func testStartsAtGitHubWithDayOneCurrent() {
        let state = PilotCourseState()
        XCTAssertEqual(state.selectedTab, .project)
        XCTAssertEqual(state.status(for: PilotLesson.weekOne[0]), .current)
        XCTAssertEqual(state.status(for: PilotLesson.weekOne[1]), .available)
        XCTAssertEqual(state.status(for: PilotLesson.weekOne[2]), .available)
    }

    func testEachPilotDayCanOpenInCopilot() {
        for day in 1...3 {
            var state = PilotCourseState()
            state.select(day: day)
            XCTAssertEqual(state.currentLesson.id, day)
            XCTAssertEqual(state.selectedTab, .copilot)
        }
    }

    func testInvalidDayDoesNotChangeNavigation() {
        var state = PilotCourseState()
        for day in [-1, 0, 4, 8] { state.select(day: day) }
        XCTAssertEqual(state.currentLesson.id, 1)
        XCTAssertEqual(state.selectedTab, .project)
    }

    func testCompletionIsLocalAndDoesNotUnlockFutureWeeks() {
        var state = PilotCourseState()
        state.select(day: 2)
        state.markCurrentCompleted()
        state.markCurrentCompleted()
        XCTAssertEqual(state.completedDays, [2])
        XCTAssertEqual(state.status(for: PilotLesson.weekOne[1]), .completed)
        XCTAssertTrue(PilotCourseState().completedDays.isEmpty)
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
        // Reserved documentation domain: validation fixture only, never app config.
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
