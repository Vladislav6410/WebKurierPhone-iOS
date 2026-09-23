import Foundation
import Combine

@MainActor
final class PilotStore: ObservableObject {
    @Published var course = PilotCourseState()
    @Published private(set) var github = PilotGitHubConnection()
    @Published private(set) var conversations: [String: [PilotMessage]] = [:]
    @Published var drafts: [String: String] = [:]
    @Published private(set) var sendingLessonIds: Set<String> = []
    @Published private(set) var failedLessonIds: Set<String> = []

    let configuration: PilotProjectConfiguration
    private let githubService: any PilotGitHubConnecting
    private let copilotService: any PilotCopilotServing

    init(
        configuration: PilotProjectConfiguration = PilotProjectConfiguration(
            siteURLString: Bundle.main.object(forInfoDictionaryKey: "PILOT_PROJECT_SITE_URL") as? String
        ),
        githubService: any PilotGitHubConnecting,
        copilotService: any PilotCopilotServing
    ) {
        self.configuration = configuration
        self.githubService = githubService
        self.copilotService = copilotService
    }

    var isCopilotAvailable: Bool { copilotService.isAvailable }
    var hasAssignedProject: Bool {
        guard let name = github.state.session?.repositoryName else { return false }
        return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func canSend(lessonId: String) -> Bool {
        isCopilotAvailable && hasAssignedProject && !sendingLessonIds.contains(lessonId)
            && !(drafts[lessonId] ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && PilotLesson.weekOne.contains(where: { $0.lessonId == lessonId })
    }

    func connect() async {
        guard github.begin() else { return }
        do {
            let session = try await githubService.connect()
            github.finish(.success(session))
            if github.state.session != nil { course.selectedTab = .course }
        } catch {
            github.finish(.failure(error as? PilotServiceError ?? .failed))
        }
    }

    func send() async {
        let lesson = course.currentLesson
        let lessonId = lesson.lessonId
        guard canSend(lessonId: lessonId), let project = github.state.session else { return }
        let text = (drafts[lessonId] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let history = conversations[lessonId] ?? []
        sendingLessonIds.insert(lessonId)
        failedLessonIds.remove(lessonId)
        defer { sendingLessonIds.remove(lessonId) }
        do {
            let reply = try await copilotService.send(PilotCopilotRequest(
                lesson: lesson, project: project, message: text, history: history
            ))
            conversations[lessonId, default: []].append(PilotMessage(role: .student, text: text))
            conversations[lessonId, default: []].append(PilotMessage(role: .assistant, text: reply))
            drafts[lessonId] = ""
        } catch {
            failedLessonIds.insert(lessonId)
        }
    }
}
