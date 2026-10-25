import Foundation

@MainActor
final class GitHubDetailController {
    private let connection: GitHubConnectionController
    private let scheduler: RefreshScheduler
    private var configuredKey: RefreshScheduleKey?
    private var selection: SelectionToken?

    init(connection: GitHubConnectionController, scheduler: RefreshScheduler) {
        self.connection = connection; self.scheduler = scheduler
    }

    func selectionChanged() {
        let store = connection.store
        guard let token = store.selection.token, case let .pullRequest(id) = token.key.itemID,
              let item = store.github.items.first(where: { $0.id == id }) else { stop(); return }
        configure(item: item, selection: token)
    }

    /// Contextual PRs may use this entry point without entering the personal snapshot.
    func configure(item: PullRequestItem, selection token: SelectionToken) {
        let store = connection.store
        guard store.isPanelOpen, store.selection.isCurrent(token), token.key.itemID == .pullRequest(item.id),
              let scope = store.github.scope, case let .github(repos) = scope.resources,
              repos.contains(item.repositoryName), let id = connection.connectionID else { stop(); return }
        let key = RefreshScheduleKey(contextID: store.contextID, scope: scope, kind: .detail(token.key))
        guard configuredKey != key || selection != token else { return }
        stop(); configuredKey = key; selection = token
        scheduler.configure(key, eligible: true) { [weak self] in
            guard let self else { return RefreshOutcome(problems: []) }
            return await self.refresh(item: item, selection: token, connectionID: id)
        }
    }

    func stop() {
        if let configuredKey { scheduler.remove(configuredKey) }
        configuredKey = nil; selection = nil
    }

    private func refresh(item: PullRequestItem, selection: SelectionToken, connectionID: ConnectionID) async -> RefreshOutcome {
        let store = connection.store
        let details = store.selection.prDetails
        guard store.isPanelOpen, store.selection.isCurrent(selection), connection.connectionID == connectionID,
              let sessionReference = connection.sessionReference, let user = connection.identity,
              let request = details.beginRefresh() else { return RefreshOutcome(problems: []) }
        do {
            let problems = try await GitHubPRDetailEnricher(transport: connection.transport).fetchAndPublish(
                sessionReference: sessionReference, expectedUser: user, item: item) { [weak self] observation in
                    guard let self, self.connection.connectionID == connectionID, !Task.isCancelled,
                          store.isPanelOpen, store.selection.isCurrent(selection), details.isCurrent(request),
                          let version = details.observeHead(observation.headSHA, lifecycle: observation.lifecycle,
                            at: observation.observedAt, for: request),
                          let value = PRDetails(version: version, lifecycle: observation.lifecycle,
                            ci: observation.ci, review: observation.review) else { return false }
                    return details.publish(value, problem: observation.problems.first, for: request)
                }
            return RefreshOutcome(problems: problems)
        } catch GitHubAPIError.identityChanged {
            if connection.connectionID == connectionID, details.isCurrent(request) {
                connection.requireRequalification(); stop()
            }
            return RefreshOutcome(problems: [.authenticationRequired])
        } catch {
            let failure = error as? GitHubBatchFailure
            let problem = failure?.problem ?? GitHubPersonalPRProvider.problem(error)
            if problem == .authenticationRequired, connection.connectionID == connectionID, details.isCurrent(request) {
                connection.requireRequalification(); stop()
            } else { details.finish(with: problem, for: request) }
            return RefreshOutcome(problems: (failure?.observedProblems ?? []) + [problem])
        }
    }
}
