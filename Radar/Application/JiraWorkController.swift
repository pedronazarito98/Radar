import Foundation

/// Minimal real composition. The integrated lifecycle/sleep coordinator follows in T32.
@MainActor
final class JiraWorkController {
    private let store: RadarStore
    private let client: JiraCloudSearchClient
    private let scheduler: RefreshScheduler
    private var configuredKey: RefreshScheduleKey?

    init(store: RadarStore, connection: JiraCloudConnection, scheduler: RefreshScheduler) {
        self.store = store
        self.scheduler = scheduler
        client = JiraCloudSearchClient(connection: connection)
    }

    func requestAfterUserAction() {
        guard let scope = store.jira.scope, store.jira.status.connection == .connected else { return }
        let key = RefreshScheduleKey(contextID: store.contextID, scope: scope, kind: .personalList)
        if configuredKey != key {
            stop()
            configuredKey = key
            scheduler.configure(key, eligible: true) { [weak self] in
                guard let self else { return RefreshOutcome(problems: []) }
                return await self.refresh()
            }
        } else { scheduler.request(key) }
    }

    func stop() {
        if let configuredKey { scheduler.remove(configuredKey) }
        configuredKey = nil
    }

    private func refresh() async -> RefreshOutcome {
        guard let token = store.beginRefresh(for: .jira) else { return RefreshOutcome(problems: []) }
        do {
            let snapshot = try await client.fetch(contextID: token.contextID, scope: token.scope)
            guard !Task.isCancelled, store.isCurrent(token) else { return RefreshOutcome(problems: snapshot.allProblems) }
            store.publish(snapshot, for: token)
            return RefreshOutcome(problems: snapshot.allProblems)
        } catch {
            let problem: SourceProblem
            let observedProblems: [SourceProblem]
            if let failure = error as? JiraSearchFailure {
                problem = failure.problem
                observedProblems = failure.observedProblems
            } else if case let JiraConnectionError.source(value) = error {
                problem = value
                observedProblems = []
            } else if error is CancellationError { problem = .cancelled; observedProblems = [] }
            else { problem = .invalidResponse; observedProblems = [] }
            store.finishRefresh(with: problem, for: token)
            return RefreshOutcome(problems: observedProblems + [problem])
        }
    }
}
