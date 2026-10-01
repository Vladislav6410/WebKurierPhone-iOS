import XCTest
@testable import WebKurierPilot

final class PilotStoreTests: XCTestCase {
    private let intro = "wk01-l00-intro"
    private let lessonOne = "wk01-l01-computer-system"

    @MainActor
    func testUnconfiguredConnectionShowsErrorAndStaysOnProject() async {
        let store = PilotStore(githubService: UnavailablePilotGitHubService(),
                               copilotService: UnavailablePilotCopilotService())
        await store.connect()
        XCTAssertEqual(store.github.state, .error(.notConfigured))
        XCTAssertEqual(store.course.selectedTab, .project)
        store.drafts[intro] = "Question"
        XCTAssertFalse(store.canSend(lessonId: intro))
        await store.send()
        XCTAssertEqual(store.drafts[intro], "Question")
        XCTAssertTrue(store.conversations.isEmpty)
    }

    @MainActor
    func testVerifiedConnectionOpensCourseAndWhitespaceCannotSend() async {
        let store = makeStore(copilot: DeferredCopilot())
        await store.connect()
        XCTAssertEqual(store.github.state.session?.login, "test-student")
        XCTAssertEqual(store.course.selectedTab, .course)
        store.drafts[intro] = " \n "
        XCTAssertFalse(store.canSend(lessonId: intro))
    }

    @MainActor
    func testMissingAssignmentCannotSendEvenAfterConnection() async {
        let github = DeferredGitHub()
        let store = PilotStore(githubService: github, copilotService: DeferredCopilot())
        let pending = Task { await store.connect() }
        await github.waitUntilStarted()
        github.complete()
        await pending.value
        store.drafts[intro] = "Question"
        XCTAssertNotNil(store.github.state.session)
        XCTAssertFalse(store.canSend(lessonId: intro))
    }

    @MainActor
    func testDuplicateConnectionsAreSuppressedWhilePending() async {
        let github = DeferredGitHub()
        let store = PilotStore(githubService: github, copilotService: UnavailablePilotCopilotService())
        let first = Task { await store.connect() }
        await github.waitUntilStarted()
        XCTAssertEqual(store.github.state, .connecting)
        await store.connect()
        XCTAssertEqual(github.calls, 1)
        github.complete()
        await first.value
        XCTAssertEqual(store.course.selectedTab, .course)
    }

    @MainActor
    func testReplyStaysInOriginalLessonWhenStudentNavigates() async {
        let service = DeferredCopilot()
        let store = makeStore(copilot: service)
        await store.connect()
        store.drafts[intro] = "Intro question"
        let pending = Task { await store.send() }
        await service.waitUntilStarted()
        XCTAssertFalse(store.canSend(lessonId: intro))
        await store.send()
        XCTAssertEqual(service.calls, 1)

        store.course.select(lessonId: lessonOne)
        store.drafts[lessonOne] = "Lesson one draft"

        service.complete(.success("Confirmed test response"))
        await pending.value

        XCTAssertEqual(store.conversations[intro]?.map(\.text), ["Intro question", "Confirmed test response"])
        XCTAssertNil(store.conversations[lessonOne])
        XCTAssertEqual(store.drafts[lessonOne], "Lesson one draft")
        XCTAssertEqual(service.request?.lesson.lessonId, intro)
        XCTAssertEqual(service.request?.project.repositoryName, "test-student/training")
        XCTAssertTrue(store.sendingLessonIds.isEmpty)
    }

    @MainActor
    func testFailureRetainsDraftAndRetryDoesNotDuplicateMessages() async {
        let service = DeferredCopilot()
        let store = makeStore(copilot: service)
        await store.connect()
        store.drafts[intro] = "Question"

        let first = Task { await store.send() }
        await service.waitUntilStarted()
        service.complete(.failure(PilotServiceError.failed))
        await first.value

        XCTAssertEqual(store.drafts[intro], "Question")
        XCTAssertTrue(store.conversations.isEmpty)
        XCTAssertTrue(store.failedLessonIds.contains(intro))
        XCTAssertTrue(store.canSend(lessonId: intro))

        let retry = Task { await store.send() }
        await service.waitUntilStarted()
        service.complete(.success("Confirmed test response"))
        await retry.value

        XCTAssertEqual(store.conversations[intro]?.count, 2)
        XCTAssertEqual(store.drafts[intro], "")
        XCTAssertTrue(store.failedLessonIds.isEmpty)
    }

    @MainActor
    func testBuiltAppBundleContainsCanonicalLesson01AtLoaderPath() throws {
        let url = try XCTUnwrap(
            Bundle.main.url(
                forResource: "lesson",
                withExtension: "json",
                subdirectory: CanonicalLessonLoader.lesson01Subdirectory
            ),
            "lesson.json missing at \(CanonicalLessonLoader.lesson01Subdirectory)"
        )
        let lesson = try CanonicalLessonLoader().loadLesson01(from: Bundle.main)
        XCTAssertEqual(url.lastPathComponent, "lesson.json")
        XCTAssertEqual(lesson.lessonId, "week01.lesson01.computer-as-system")
        XCTAssertEqual(lesson.title, "Компьютер как система")
        XCTAssertNotNil(lesson.assignmentSection)
    }

    @MainActor
    func testLesson01PresentationUsesStoreCanonicalDataWithoutRawError() throws {
        let store = PilotStore(githubService: UnavailablePilotGitHubService(),
                               copilotService: UnavailablePilotCopilotService())
        let strings = PilotStrings(language: "ru")
        let lesson = try XCTUnwrap(PilotLesson.weekOne.first { $0.lessonId == lessonOne })
        let introLesson = try XCTUnwrap(PilotLesson.weekOne.first { $0.lessonId == intro })

        XCTAssertNil(store.canonicalLesson01Error)
        let canonical = try XCTUnwrap(store.canonicalLesson01)
        XCTAssertEqual(store.presentedTitle(for: lesson, strings: strings), canonical.title)
        XCTAssertEqual(store.presentedTask(for: lesson, strings: strings), canonical.assignmentSection?.narration)
        XCTAssertNotEqual(store.presentedTitle(for: lesson, strings: strings), strings(lesson.titleKey))
        XCTAssertFalse(store.presentedTitle(for: lesson, strings: strings).contains("ERROR:"))
        XCTAssertFalse(store.presentedTask(for: lesson, strings: strings).contains("ERROR:"))

        XCTAssertEqual(store.presentedTitle(for: introLesson, strings: strings), strings(introLesson.titleKey))
        XCTAssertEqual(store.presentedTask(for: introLesson, strings: strings), strings(introLesson.taskKey))

        let fallbackTitle = PilotStore.presentedTitle(for: lesson, canonical: nil, localized: strings(lesson.titleKey))
        let fallbackTask = PilotStore.presentedTask(for: lesson, canonical: nil, localized: strings(lesson.taskKey))
        XCTAssertEqual(fallbackTitle, strings(lesson.titleKey))
        XCTAssertEqual(fallbackTask, strings(lesson.taskKey))
        XCTAssertFalse(fallbackTitle.contains("ERROR:"))
        XCTAssertFalse(fallbackTask.contains("ERROR:"))
    }

    @MainActor
    private func makeStore(copilot: any PilotCopilotServing) -> PilotStore {
        PilotStore(githubService: TestGitHub(), copilotService: copilot)
    }
}

private struct TestGitHub: PilotGitHubConnecting {
    func connect() async throws -> PilotGitHubSession {
        PilotGitHubSession(login: "test-student", repositoryName: "test-student/training", verifiedProjectStatus: nil)
    }
}

@MainActor
private final class DeferredGitHub: PilotGitHubConnecting {
    var calls = 0
    private var continuation: CheckedContinuation<PilotGitHubSession, Never>?
    private var started: CheckedContinuation<Void, Never>?

    func connect() async throws -> PilotGitHubSession {
        calls += 1
        return await withCheckedContinuation {
            continuation = $0
            started?.resume()
            started = nil
        }
    }

    func waitUntilStarted() async {
        if continuation != nil { return }
        await withCheckedContinuation { started = $0 }
    }

    func complete() {
        continuation?.resume(returning: PilotGitHubSession(login: "test-student", repositoryName: nil,
                                                          verifiedProjectStatus: nil))
        continuation = nil
    }
}

@MainActor
private final class DeferredCopilot: PilotCopilotServing {
    let isAvailable = true
    var calls = 0
    var request: PilotCopilotRequest?
    private var continuation: CheckedContinuation<String, Error>?
    private var started: CheckedContinuation<Void, Never>?

    func send(_ request: PilotCopilotRequest) async throws -> String {
        calls += 1
        self.request = request
        return try await withCheckedThrowingContinuation {
            continuation = $0
            started?.resume()
            started = nil
        }
    }

    func waitUntilStarted() async {
        if continuation != nil { return }
        await withCheckedContinuation { started = $0 }
    }

    func complete(_ result: Result<String, Error>) {
        continuation?.resume(with: result)
        continuation = nil
    }
}
