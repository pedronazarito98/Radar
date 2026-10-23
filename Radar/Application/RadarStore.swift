import Foundation
import Observation

@MainActor
@Observable
final class RadarStore {
    private(set) var contextID: WorkContextID
    private(set) var jira = SourcePresentationState<JiraWorkItem>()
    private(set) var github = SourcePresentationState<PullRequestItem>()
    private(set) var isPanelOpen = false
    let selection: SelectionStore
    private(set) var repositoryAliases: RepositoryIdentityAliases
    private var pendingRepositoryAliases: RepositoryIdentityAliases?
    private var requestGeneration: UInt64 = 0

    init(contextID: WorkContextID = WorkContextID()) {
        self.contextID = contextID
        selection = SelectionStore(contextID: contextID)
        repositoryAliases = RepositoryIdentityAliases(contextID: contextID)
    }

    /// Synchronous intent after qualification; asynchronous results use refresh tokens.
    func configureSource(_ scope: SourceScope, connection: SourceConnectionState) {
        invalidate(scope.source, connection: connection)
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
        selection.activateContext(contextID)
        repositoryAliases = RepositoryIdentityAliases(contextID: contextID)
        pendingRepositoryAliases = nil
        // requestGeneration intentionally survives A → B → A context changes.
    }

    func invalidate(_ source: WorkSource, connection: SourceConnectionState = .disconnected) {
        selection.invalidate(source)
        switch source {
        case .jira: jira = SourcePresentationState(connection: connection)
        case .github:
            github = SourcePresentationState(connection: connection)
            repositoryAliases = RepositoryIdentityAliases(contextID: contextID)
            pendingRepositoryAliases = nil
        }
    }

    func setPanelOpen(_ isOpen: Bool) {
        isPanelOpen = isOpen
        if !isOpen {
            applyPendingUpdates()
            selection.clear()
        }
    }

    func applyPendingUpdates() {
        jira.applyPendingSnapshot()
        if github.applyPendingSnapshot(), let pendingRepositoryAliases {
            repositoryAliases = pendingRepositoryAliases
            self.pendingRepositoryAliases = nil
            selection.reconcile(using: repositoryAliases)
        }
        updateSelectionMembership()
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
        guard token.source == .jira, isCurrent(token) else { return false }
        let published = jira.publish(snapshot, for: token, holdPresentation: isPanelOpen)
        if published { updateSelectionMembership() }
        return published
    }

    @discardableResult
    func publish(
        _ snapshot: SourceSnapshot<PullRequestItem>, for token: SourceRefreshToken,
        repositoryResolutions: [RepositoryIdentityResolution] = []
    ) -> Bool {
        guard token.source == .github, isCurrent(token), snapshot.contextID == contextID,
              snapshot.scope == token.scope,
              case let .github(repositories) = token.scope.resources else { return false }
        guard repositoryResolutions.allSatisfy({ repositories.contains($0.name) }) else {
            finishRefresh(with: .invalidResponse, for: token)
            return false
        }
        var aliases = pendingRepositoryAliases ?? repositoryAliases
        for resolution in repositoryResolutions {
            guard aliases.register(name: resolution.name, id: resolution.id) != .conflict else {
                finishRefresh(with: .invalidResponse, for: token)
                return false
            }
        }
        guard snapshot.items.allSatisfy(aliases.isCanonical) else {
            finishRefresh(with: .invalidResponse, for: token)
            return false
        }
        guard github.publish(snapshot, for: token, holdPresentation: isPanelOpen) else { return false }
        if github.hasPendingUpdate {
            pendingRepositoryAliases = aliases
        } else {
            repositoryAliases = aliases
            pendingRepositoryAliases = nil
            selection.reconcile(using: aliases)
        }
        updateSelectionMembership()
        return true
    }

    @discardableResult
    func finishRefresh(with problem: SourceProblem, for token: SourceRefreshToken) -> Bool {
        guard isCurrent(token) else { return false }
        switch token.source {
        case .jira: return jira.finish(with: problem, for: token)
        case .github: return github.finish(with: problem, for: token)
        }
    }

    @discardableResult
    func select(_ key: SelectionKey, origin: SelectionKey? = nil) -> SelectionToken? {
        guard let key = repositoryAliases.canonical(key) else { return nil }
        let canonicalOrigin = origin.flatMap { repositoryAliases.canonical($0) }
        guard origin == nil || canonicalOrigin != nil else { return nil }
        let token = selection.select(key, origin: canonicalOrigin)
        updateSelectionMembership()
        return token
    }

    func consumeFocusReturnKey() -> SelectionKey? {
        guard let key = selection.consumeFocusReturnKey(), containsPresentedItem(key) else { return nil }
        return key
    }

    private func updateSelectionMembership() {
        selection.setPersonalSnapshotMembership(selection.selectedKey.map(containsPresentedItem) ?? false)
    }

    private func containsPresentedItem(_ key: SelectionKey) -> Bool {
        guard key.contextID == contextID else { return false }
        switch key.itemID {
        case .jira(let identity): return jira.items.contains { $0.id == identity }
        case .pullRequest(let identity): return github.items.contains { $0.id == identity }
        }
    }
}
