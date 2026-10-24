import AppKit
import Observation

/// One lifecycle owner observes connection intent, not remote payloads or credentials.
@MainActor
final class SourceRefreshCoordinator {
    private let store: RadarStore
    private let scheduler: RefreshScheduler
    private let jira: JiraWorkController
    private let github: GitHubWorkController
    private var observers: [NSObjectProtocol] = []
    private struct Configuration: Equatable {
        let context: WorkContextID
        let identity: UUID
        let scope: SourceScope?
        let connection: SourceConnectionState
    }
    private var lastJira: Configuration?
    private var lastGitHub: Configuration?
    private var active = false
    private var observationGeneration = UUID()

    init(store: RadarStore, scheduler: RefreshScheduler, jira: JiraWorkController, github: GitHubWorkController) {
        self.store = store; self.scheduler = scheduler; self.jira = jira; self.github = github
    }

    func start() {
        guard !active else { return }
        active = true
        let center = NSWorkspace.shared.notificationCenter
        observers = [
            center.addObserver(forName: NSWorkspace.willSleepNotification, object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor in self?.scheduler.suspendForSleep() }
            },
            center.addObserver(forName: NSWorkspace.didWakeNotification, object: nil, queue: .main) { [weak self] _ in
                Task { @MainActor in self?.scheduler.resumeAfterWake() }
            }
        ]
        reconcile(); observe()
    }

    func stop() {
        active = false; observationGeneration = UUID()
        for observer in observers { NSWorkspace.shared.notificationCenter.removeObserver(observer) }
        observers = []; lastJira = nil; lastGitHub = nil
        jira.stop(); github.stop(); scheduler.removeAll()
    }

    private func reconcile() {
        guard active else { return }
        let jiraConfiguration = Configuration(context: store.contextID, identity: store.jira.configurationID, scope: store.jira.scope, connection: store.jira.status.connection)
        let githubConfiguration = Configuration(context: store.contextID, identity: store.github.configurationID, scope: store.github.scope, connection: store.github.status.connection)
        if jiraConfiguration != lastJira {
            lastJira = jiraConfiguration
            if jiraConfiguration.connection == .connected { jira.requestAfterUserAction() } else { jira.stop() }
        }
        if githubConfiguration != lastGitHub {
            lastGitHub = githubConfiguration
            if githubConfiguration.connection == .connected { github.requestAfterUserAction() } else { github.stop() }
        }
    }

    private func observe() {
        guard active else { return }
        let generation = UUID(); observationGeneration = generation
        withObservationTracking {
            _ = store.contextID
            _ = store.jira.configurationID; _ = store.github.configurationID
            _ = store.jira.scope; _ = store.github.scope
            _ = store.jira.status.connection; _ = store.github.status.connection
        } onChange: { [weak self] in
            Task { @MainActor in
                guard let self, self.active, self.observationGeneration == generation else { return }
                self.reconcile(); self.observe()
            }
        }
    }
}
