import Foundation

/// Explicit account intent and invalidation share one narrow cleanup path.
@MainActor
final class DataLifecycleController {
    private let store: RadarStore
    private let jira: JiraCloudConnection
    private let github: GitHubConnectionController
    private let jiraWork: JiraWorkController
    private let githubWork: GitHubWorkController
    private let details: GitHubDetailController
    private let relations: RelatedItemsCoordinator
    private let refresh: SourceRefreshCoordinator

    init(store: RadarStore, jira: JiraCloudConnection, github: GitHubConnectionController,
         jiraWork: JiraWorkController, githubWork: GitHubWorkController, details: GitHubDetailController,
         relations: RelatedItemsCoordinator, refresh: SourceRefreshCoordinator) {
        self.store = store; self.jira = jira; self.github = github
        self.jiraWork = jiraWork; self.githubWork = githubWork; self.details = details
        self.relations = relations; self.refresh = refresh
    }

    func start() {
        github.onInvalidated = { [weak self] in
            self?.githubWork.stop(); self?.details.stop(); self?.relations.stop()
        }
        refresh.start()
    }

    func disconnectGitHub() { github.disconnectAfterUserAction() }

    func removeJiraAfterUserAction() async throws {
        prepareJiraChange()
        await jira.invalidateActiveSession()
        try await jira.removeAfterUserAction()
    }

    func resumeJiraAfterUserAction(policyAllowed: Bool, attemptID: UUID) async throws -> JiraQualifiedConnection {
        prepareJiraChange()
        await jira.invalidateActiveSession()
        return try await jira.resumeAfterUserAction(policyAllowed: policyAllowed, attemptID: attemptID)
    }

    func stop() {
        github.onInvalidated = nil
        refresh.stop(); relations.stop(); details.stop(); jiraWork.stop(); githubWork.stop()
        github.shutdown()
        store.invalidate(.jira)
        Task { await jira.invalidateActiveSession() }
    }

    private func prepareJiraChange() {
        jiraWork.stop(); relations.stop()
        store.invalidate(.jira)
    }
}
