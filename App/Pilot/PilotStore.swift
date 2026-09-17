import Foundation
import Combine

@MainActor
final class PilotStore: ObservableObject {
    @Published var course = PilotCourseState()
    @Published private(set) var github = PilotGitHubConnection()
    @Published private(set) var conversations: [Int: [PilotMessage]] = [:]
    @Published var drafts: [Int: String] = [:]
    @Published private(set) var sendingDays: Set<Int> = []
    @Published private(set) var failedDays: Set<Int> = []

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

    func canSend(day: Int) -> Bool {
        isCopilotAvailable && hasAssignedProject && !sendingDays.contains(day)
            && !(drafts[day] ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && PilotLesson.weekOne.contains(where: { $0.id == day })
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
        let day = lesson.id
        guard canSend(day: day), let project = github.state.session else { return }
        let text = (drafts[day] ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let history = conversations[day] ?? []
        sendingDays.insert(day)
        failedDays.remove(day)
        defer { sendingDays.remove(day) }
        do {
            let reply = try await copilotService.send(PilotCopilotRequest(
                lesson: lesson, project: project, message: text, history: history
            ))
            // Publish only confirmed exchanges. Failed drafts remain retryable.
            conversations[day, default: []].append(PilotMessage(role: .student, text: text))
            conversations[day, default: []].append(PilotMessage(role: .assistant, text: reply))
            drafts[day] = ""
        } catch {
            failedDays.insert(day)
        }
    }
}
