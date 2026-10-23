import Foundation

/// Rows and count are always read from the same immutable presented snapshot.
struct SourcePresentationState<Item: SourceSnapshotItem> {
    let scope: SourceScope?
    private(set) var presentedSnapshot: SourceSnapshot<Item>?
    private(set) var pendingSnapshot: SourceSnapshot<Item>?
    private(set) var status: SourceStatus
    private(set) var activeRefresh: SourceRefreshToken?

    init(scope: SourceScope? = nil, connection: SourceConnectionState = .disconnected) {
        self.scope = scope
        status = SourceStatus(connection: connection)
    }

    var items: [Item] { presentedSnapshot?.items ?? [] }
    var count: Count { presentedSnapshot?.count ?? .unknown }
    var hasPendingUpdate: Bool { pendingSnapshot != nil }

    mutating func beginRefresh(_ token: SourceRefreshToken) -> Bool {
        guard token.scope == scope, token.source == Item.source,
              status.connection == .connected else { return false }
        activeRefresh = token
        status.isRefreshing = true
        // An existing problem remains visible while recovery is in flight.
        return true
    }

    func accepts(_ token: SourceRefreshToken) -> Bool {
        activeRefresh == token && token.scope == scope && token.source == Item.source
    }

    @discardableResult
    mutating func publish(
        _ snapshot: SourceSnapshot<Item>, for token: SourceRefreshToken, holdPresentation: Bool
    ) -> Bool {
        guard accepts(token), snapshot.contextID == token.contextID, snapshot.scope == scope else { return false }
        let hasObservation = snapshot.queryCoverage.values.contains { coverage in
            switch coverage {
            case .complete, .partial: true
            case .failed: false
            }
        }
        guard hasObservation else {
            finish(with: snapshot.firstProblem ?? .invalidResponse, for: token)
            return false
        }
        if holdPresentation, presentedSnapshot != nil {
            pendingSnapshot = snapshot
        } else {
            presentedSnapshot = snapshot
            pendingSnapshot = nil
        }
        activeRefresh = nil
        status.isRefreshing = false
        status.problem = snapshot.firstProblem
        status.freshness = pendingSnapshot == nil && status.problem == nil ? .current : .stale
        return true
    }

    @discardableResult
    mutating func finish(with problem: SourceProblem, for token: SourceRefreshToken) -> Bool {
        guard accepts(token) else { return false }
        activeRefresh = nil
        status.isRefreshing = false
        status.problem = problem
        status.freshness = presentedSnapshot == nil ? .neverLoaded : .stale
        return true
    }

    @discardableResult
    mutating func applyPendingSnapshot() -> Bool {
        guard let pendingSnapshot else { return false }
        presentedSnapshot = pendingSnapshot
        self.pendingSnapshot = nil
        status.freshness = status.problem == nil ? .current : .stale
        return true
    }
}
