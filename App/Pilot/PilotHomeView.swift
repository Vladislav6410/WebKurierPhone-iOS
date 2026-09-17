import SwiftUI

@MainActor
struct PilotHomeView: View {
    @StateObject private var store = PilotStore(
        githubService: UnavailablePilotGitHubService(),
        copilotService: UnavailablePilotCopilotService()
    )
    @EnvironmentObject private var localization: LocalizationManager
    private var strings: PilotStrings { PilotStrings(language: localization.currentLanguage) }

    var body: some View {
        TabView(selection: $store.course.selectedTab) {
            PilotCourseView()
                .tabItem { Label(strings("pilot.course"), systemImage: "book.closed") }
                .tag(PilotTab.course)
            PilotCopilotView()
                .tabItem { Label(strings("pilot.copilot"), systemImage: "bubble.left.and.bubble.right") }
                .tag(PilotTab.copilot)
            PilotProjectView()
                .tabItem { Label(strings("pilot.project"), systemImage: "folder") }
                .tag(PilotTab.project)
        }
        .tint(.indigo)
        .environmentObject(store)
    }
}

@MainActor
private struct PilotProjectView: View {
    @EnvironmentObject private var store: PilotStore
    @EnvironmentObject private var localization: LocalizationManager
    private var strings: PilotStrings { PilotStrings(language: localization.currentLanguage) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    HStack(spacing: 16) {
                        Text("WK")
                            .font(.title.bold())
                            .padding(16)
                            .background(.indigo.opacity(0.12), in: RoundedRectangle(cornerRadius: 18))
                            .accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(strings("pilot.brand")).font(.title2.bold())
                            Text(strings("pilot.edition")).foregroundStyle(.secondary)
                        }
                    }
                    Text(strings("pilot.welcome"))
                    GroupBox {
                        VStack(alignment: .leading, spacing: 14) {
                            Label(strings("pilot.github.title"), systemImage: "person.crop.circle")
                                .font(.headline)
                            connectionContent
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    Button(strings("pilot.course.open")) { store.course.selectedTab = .course }
                        .buttonStyle(.borderedProminent)
                    Text(strings("pilot.preview.note"))
                        .font(.footnote).foregroundStyle(.secondary)
                    PilotResultButton()
                }
                .padding()
            }
            .navigationTitle(strings("pilot.project"))
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    @ViewBuilder private var connectionContent: some View {
        switch store.github.state {
        case .notConnected:
            Text(strings("pilot.github.notConnected"))
            Text(strings("pilot.github.prerequisite")).font(.footnote).foregroundStyle(.secondary)
            connectButton
        case .connecting:
            ProgressView(strings("pilot.github.connecting"))
        case .connected(let session):
            Label(strings("pilot.github.connected"), systemImage: "checkmark.circle.fill")
            Text(verbatim: "@\(session.login)")
            Text(verbatim: session.repositoryName ?? strings("pilot.project.unassigned"))
            if let status = session.verifiedProjectStatus {
                Text(verbatim: status).font(.footnote)
            }
        case .error(let error):
            Label(strings("pilot.github.error"), systemImage: "exclamationmark.circle")
            Text(strings(error == .notConfigured ? "pilot.github.prerequisite" : "pilot.github.retryMessage"))
                .font(.footnote)
            connectButton
        }
    }

    private var connectButton: some View {
        Button(strings("pilot.github.connect")) {
            Task { await store.connect() }
        }
        .buttonStyle(.borderedProminent)
    }
}

@MainActor
private struct PilotCourseView: View {
    @EnvironmentObject private var store: PilotStore
    @EnvironmentObject private var localization: LocalizationManager
    private var strings: PilotStrings { PilotStrings(language: localization.currentLanguage) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(strings("pilot.weekOne")).font(.title2.bold())
                    Label(strings("pilot.status.available"), systemImage: "checkmark.circle")
                        .foregroundStyle(.secondary)
                    Text(strings("pilot.progress.note")).font(.footnote).foregroundStyle(.secondary)
                    ForEach(PilotLesson.weekOne) { lesson in
                        GroupBox {
                            VStack(alignment: .leading, spacing: 12) {
                                Text(strings(lesson.titleKey)).font(.headline)
                                Text(strings(store.course.status(for: lesson).titleKey))
                                    .font(.caption).foregroundStyle(.secondary)
                                Text(strings(lesson.taskKey))
                                Button(strings("pilot.lesson.open")) { store.course.select(day: lesson.id) }
                                    .buttonStyle(.borderedProminent)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    PilotResultButton()
                    Text(strings("pilot.roadmap")).font(.title2.bold())
                    ForEach(PilotWeek.roadmap.filter(\.isLocked)) { week in
                        HStack(alignment: .top) {
                            Image(systemName: "lock.fill").accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(String(format: strings("pilot.week.format"), week.id)).font(.headline)
                                Text(strings("pilot.locked")).foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding()
                        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                        .accessibilityElement(children: .combine)
                    }
                }
                .padding()
            }
            .navigationTitle(strings("pilot.course"))
        }
    }
}

@MainActor
private struct PilotCopilotView: View {
    @EnvironmentObject private var store: PilotStore
    @EnvironmentObject private var localization: LocalizationManager
    private var strings: PilotStrings { PilotStrings(language: localization.currentLanguage) }
    private var day: Int { store.course.currentLesson.id }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        Text(strings(store.course.currentLesson.titleKey)).font(.title2.bold())
                        Text(strings(store.course.currentLesson.taskKey))
                        Label(store.github.state.session?.repositoryName ?? strings("pilot.project.unassigned"),
                              systemImage: "folder")
                            .font(.footnote).foregroundStyle(.secondary)
                        if !store.isCopilotAvailable {
                            Label(strings("pilot.copilot.unavailable"), systemImage: "info.circle")
                        } else if store.github.state.session == nil {
                            Text(strings("pilot.copilot.connectFirst"))
                        } else if !store.hasAssignedProject {
                            Text(strings("pilot.project.unassigned"))
                        }
                        Text(strings("pilot.conversation")).font(.headline)
                        if (store.conversations[day] ?? []).isEmpty {
                            Text(strings("pilot.conversation.empty"))
                                .foregroundStyle(.secondary)
                        }
                        ForEach(store.conversations[day] ?? []) { message in
                            VStack(alignment: .leading, spacing: 6) {
                                Text(strings(message.role == .student ? "pilot.you" : "pilot.copilot"))
                                    .font(.caption.bold())
                                Text(verbatim: message.text).textSelection(.enabled)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.indigo.opacity(message.role == .student ? 0.12 : 0.05),
                                        in: RoundedRectangle(cornerRadius: 12))
                        }
                        if store.sendingDays.contains(day) { ProgressView(strings("pilot.sending")) }
                        if store.failedDays.contains(day) {
                            Text(strings("pilot.send.failed")).foregroundStyle(.red)
                        }
                        VStack(alignment: .leading, spacing: 10) {
                            TextField(strings("pilot.input"), text: Binding(
                                get: { store.drafts[day] ?? "" },
                                set: { store.drafts[day] = $0 }
                            ), axis: .vertical)
                            .lineLimit(2...6)
                            .textFieldStyle(.roundedBorder)
                            .disabled(store.sendingDays.contains(day))
                            Button(strings("pilot.send")) { Task { await store.send() } }
                                .buttonStyle(.borderedProminent)
                                .disabled(!store.canSend(day: day))
                        }
                        .id("composer")
                        PilotResultButton()
                        Button(strings("pilot.lesson.complete")) { store.course.markCurrentCompleted() }
                            .buttonStyle(.bordered)
                            .disabled(store.course.completedDays.contains(day))
                        Text(strings("pilot.progress.note")).font(.footnote).foregroundStyle(.secondary)
                    }
                    .padding()
                }
                .onChange(of: store.conversations[day]?.count) { _ in
                    withAnimation { proxy.scrollTo("composer", anchor: .bottom) }
                }
            }
            .navigationTitle(strings("pilot.copilot"))
        }
    }
}

@MainActor
private struct PilotResultButton: View {
    @EnvironmentObject private var store: PilotStore
    @EnvironmentObject private var localization: LocalizationManager
    @Environment(\.openURL) private var openURL
    @State private var openFailed = false
    private var strings: PilotStrings { PilotStrings(language: localization.currentLanguage) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                guard let url = store.configuration.siteURL else { return }
                openURL(url) { accepted in openFailed = !accepted }
            } label: {
                Label(strings("pilot.result"), systemImage: "safari")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(store.configuration.siteURL == nil)
            if store.configuration.siteURL == nil {
                Text(strings("pilot.result.unconfigured")).font(.footnote).foregroundStyle(.secondary)
            }
            if openFailed {
                Text(strings("pilot.result.failed")).font(.footnote).foregroundStyle(.red)
            }
        }
    }
}
