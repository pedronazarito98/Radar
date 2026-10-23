import Foundation

struct RelatedItemsTrigger: Hashable {
    let selection: SelectionToken?
    let invalidation: UUID
    let jiraScope: SourceScope?
    let githubScope: SourceScope?
}

@MainActor
final class RelatedItemsCoordinator {
    private let store: RadarStore
    private let jira: JiraCloudConnection
    private let github: GitHubConnectionController
    private let details: GitHubDetailController
    private var operation: Task<Void, Never>?
    private var queryID: UUID?
    var reportProblems: ([OriginProblem]) -> Void = { _ in }

    init(store: RadarStore, jira: JiraCloudConnection, github: GitHubConnectionController, details: GitHubDetailController) {
        self.store = store; self.jira = jira; self.github = github; self.details = details
    }

    func selectionChanged() {
        stop()
        guard store.isPanelOpen, let selection = store.selection.token else { return }
        let subject: RelationSubject
        switch selection.key.itemID {
        case let .jira(id):
            guard let item = store.jiraItem(id) else { return }
            subject = .jira(item)
        case let .pullRequest(id):
            guard let item = store.pullRequest(id) else { return }
            subject = .pullRequest(item)
            details.configure(item: item, selection: selection)
        }
        // Alias reconciliation is the same user intent; keep its just-qualified result.
        if store.relations.selection == selection, store.relations.observation != nil { return }
        guard let jiraScope = store.jira.scope, let githubScope = store.github.scope,
              store.jira.status.connection == .connected, store.github.status.connection == .connected,
              let connectionID = github.connectionID, let executable = github.executable, let user = github.identity else { return }
        let query = UUID(); queryID = query
        let invalidation = store.relations.invalidation
        store.relations.begin(selection: selection, queryID: query)
        operation = Task { [weak self] in
            guard let self else { return }
            do {
                let qualified = try await jira.currentConnection()
                guard qualified.scope == jiraScope, current(query, selection, invalidation, connectionID, jiraScope, githubScope) else { return }
                let problems = try await RelationResolver(jira: jira, github: github.transport).fetchAndPublish(
                    subject: subject, jiraConnection: qualified, githubConnectionID: connectionID, githubScope: githubScope,
                    executable: executable, expectedUser: user, knownPRs: store.github.items,
                    isCurrent: { [weak self] in
                        self?.current(query, selection, invalidation, connectionID, jiraScope, githubScope) ?? false
                    }, publish: { [weak self] result in
                        guard let self, self.current(query, selection, invalidation, connectionID, jiraScope, githubScope) else { return false }
                        return self.store.publishRelations(result, queryID: query, selection: selection)
                    })
                reportProblems(problems)
            } catch {
                let failure = Self.failure(error)
                let problem = failure.problem
                reportProblems(failure.observedProblems)
                if failure.identityChanged, github.connectionID == connectionID {
                    github.requireRequalification()
                }
                store.relations.fail(problem, queryID: query)
            }
            if queryID == query { operation = nil }
        }
    }

    func stop() {
        queryID = nil; operation?.cancel(); operation = nil
        store.relations.cancel(); details.stop()
    }

    private static func failure(_ error: Error) -> RelationFailure {
        if let failure = error as? RelationFailure { return failure }
        let source: WorkSource
        let problem: SourceProblem
        var changed = false
        switch error {
        case let GitHubCLIError.source(value): source = .github; problem = value
        case GitHubCLIError.identityChanged: source = .github; problem = .authenticationRequired; changed = true
        case let JiraConnectionError.source(value): source = .jira; problem = value
        case is CancellationError: source = .github; problem = .cancelled
        default: source = .github; problem = .transportUnavailable
        }
        return RelationFailure(problem: problem, observedProblems: [OriginProblem(source: source, problem: problem)], identityChanged: changed)
    }

    private func current(_ query: UUID, _ selection: SelectionToken, _ invalidation: UUID,
                         _ connectionID: ConnectionID, _ jiraScope: SourceScope, _ githubScope: SourceScope) -> Bool {
        !Task.isCancelled && queryID == query && store.isPanelOpen && store.selection.isCurrent(selection)
            && store.relations.invalidation == invalidation && github.connectionID == connectionID
            && store.jira.scope == jiraScope && store.github.scope == githubScope
            && store.jira.status.connection == .connected && store.github.status.connection == .connected
    }
}
