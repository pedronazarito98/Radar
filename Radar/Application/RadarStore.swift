import Foundation
import Observation

@MainActor
@Observable
final class RadarStore {
    private(set) var contextID: WorkContextID
    private(set) var jira = SourcePresentationState<JiraWorkItem>()
    private(set) var github = SourcePresentationState<PullRequestItem>()
    private(set) var isPanelOpen = false
    private var requestGeneration: UInt64 = 0

    init(contextID: WorkContextID = WorkContextID()) {
        self.contextID = contextID
    }

    /// Synchronous intent after qualification; asynchronous results use refresh tokens.
    func configureSource(_ scope: SourceScope, connection: SourceConnectionState) {
        switch scope.source {
        case .jira: jira = SourcePresentationState(scope: scope, connection: connection)
        case .github: github = SourcePresentationState(scope: scope, connection: connection)
        }
    }

    func activateContext(_ contextID: WorkContextID) {
        guard contextID != self.contextID else { return }
        self.contextID = contextID
        jira = SourcePresentationState()
        github = SourcePresentationState()
        // requestGeneration intentionally survives A → B → A context changes.
    }

    func invalidate(_ source: WorkSource, connection: SourceConnectionState = .disconnected) {
        switch source {
        case .jira: jira = SourcePresentationState(connection: connection)
        case .github: github = SourcePresentationState(connection: connection)
        }
    }

    func setPanelOpen(_ isOpen: Bool) {
        isPanelOpen = isOpen
        if !isOpen { applyPendingUpdates() }
    }

    func applyPendingUpdates() {
        jira.applyPendingSnapshot()
        github.applyPendingSnapshot()
    }

    func beginRefresh(for source: WorkSource) -> SourceRefreshToken? {
        let scope: SourceScope?
        switch source {
        case .jira: scope = jira.scope
        case .github: scope = github.scope
        }
        guard let scope else { return nil }
        precondition(requestGeneration < .max, "Refresh generation exhausted")
        requestGeneration += 1
        let token = SourceRefreshToken(contextID: contextID, source: source, scope: scope, generation: requestGeneration)
        let accepted: Bool
        switch source {
        case .jira: accepted = jira.beginRefresh(token)
        case .github: accepted = github.beginRefresh(token)
        }
        return accepted ? token : nil
    }

    func isCurrent(_ token: SourceRefreshToken) -> Bool {
        guard token.contextID == contextID else { return false }
        switch token.source {
        case .jira: return jira.accepts(token)
        case .github: return github.accepts(token)
        }
    }

    @discardableResult
    func publish(_ snapshot: SourceSnapshot<JiraWorkItem>, for token: SourceRefreshToken) -> Bool {
        guard isCurrent(token) else { return false }
        return jira.publish(snapshot, for: token, holdPresentation: isPanelOpen)
    }

    @discardableResult
    func publish(_ snapshot: SourceSnapshot<PullRequestItem>, for token: SourceRefreshToken) -> Bool {
        guard isCurrent(token) else { return false }
        return github.publish(snapshot, for: token, holdPresentation: isPanelOpen)
    }

    @discardableResult
    func finishRefresh(with problem: SourceProblem, for token: SourceRefreshToken) -> Bool {
        guard isCurrent(token) else { return false }
        switch token.source {
        case .jira: return jira.finish(with: problem, for: token)
        case .github: return github.finish(with: problem, for: token)
        }
    }
}
