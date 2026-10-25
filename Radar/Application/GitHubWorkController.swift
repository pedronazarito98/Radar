import Foundation

@MainActor
final class GitHubWorkController {
    private let connection: GitHubConnectionController
    private let scheduler: RefreshScheduler
    private var configuredKey: RefreshScheduleKey?

    init(connection: GitHubConnectionController, scheduler: RefreshScheduler) {
        self.connection = connection; self.scheduler = scheduler
    }

    func requestAfterUserAction() {
        let store = connection.store
        guard let scope = store.github.scope, store.github.status.connection == .connected else { return }
        let key = RefreshScheduleKey(contextID: store.contextID, scope: scope, kind: .personalList)
        if configuredKey != key {
            stop(); configuredKey = key
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
        let store = connection.store
        guard let sessionReference = connection.sessionReference, let user = connection.identity, let id = connection.connectionID,
              let token = store.beginRefresh(for: .github) else { return RefreshOutcome(problems: []) }
        do {
            let problems = try await GitHubPersonalPRProvider(transport: connection.transport).fetchAndPublish(
                sessionReference: sessionReference, expectedUser: user, connectionID: id, contextID: token.contextID,
                scope: token.scope, aliases: store.repositoryAliases) { [weak self] snapshot, resolutions in
                    guard let self, self.connection.connectionID == id, !Task.isCancelled, store.isCurrent(token) else { return false }
                    return store.publish(snapshot, for: token, repositoryResolutions: resolutions)
                }
            return RefreshOutcome(problems: problems)
        } catch GitHubAPIError.identityChanged {
            if connection.connectionID == id, store.isCurrent(token) {
                connection.requireRequalification(); stop()
            }
            return RefreshOutcome(problems: [.authenticationRequired])
        } catch {
            let failure = error as? GitHubBatchFailure
            let problem = failure?.problem ?? GitHubPersonalPRProvider.problem(error)
            if problem == .authenticationRequired, connection.connectionID == id, store.isCurrent(token) {
                connection.requireRequalification(); stop()
            } else { store.finishRefresh(with: problem, for: token) }
            return RefreshOutcome(problems: (failure?.observedProblems ?? []) + [problem])
        }
    }
}
