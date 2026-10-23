import Foundation
import Observation

@MainActor
@Observable
final class SelectionStore {
    private(set) var contextID: WorkContextID
    private(set) var selectedKey: SelectionKey?
    private(set) var generation: UInt64 = 0
    private(set) var isInPersonalSnapshot = false
    private(set) var focusReturnKey: SelectionKey?
    let prDetails = PRDetailStore()
    private var originKey: SelectionKey?

    init(contextID: WorkContextID) { self.contextID = contextID }

    var token: SelectionToken? {
        selectedKey.map { SelectionToken(key: $0, generation: generation) }
    }

    func isCurrent(_ token: SelectionToken) -> Bool {
        token.key.contextID == contextID && self.token == token
    }

    @discardableResult
    func select(_ key: SelectionKey, origin: SelectionKey? = nil) -> SelectionToken? {
        guard key.contextID == contextID, origin == nil || origin?.contextID == contextID else { return nil }
        guard selectedKey != key else { return token }
        advanceGeneration()
        selectedKey = key
        originKey = origin ?? key
        focusReturnKey = nil
        isInPersonalSnapshot = false
        prDetails.reset(for: token)
        return token
    }

    func selectRelated(_ key: SelectionKey) -> SelectionToken? {
        select(key, origin: originKey ?? selectedKey)
    }

    func dismissDetails() {
        let returnKey = originKey
        clear()
        focusReturnKey = returnKey
    }

    func clear() {
        advanceGeneration()
        selectedKey = nil
        originKey = nil
        focusReturnKey = nil
        isInPersonalSnapshot = false
        prDetails.reset(for: nil)
    }

    func activateContext(_ contextID: WorkContextID) {
        clear()
        self.contextID = contextID
    }

    func invalidate(_ source: WorkSource) {
        if selectedKey?.itemID.source == source {
            clear()
            return
        }
        if originKey?.itemID.source == source { originKey = nil }
        if focusReturnKey?.itemID.source == source { focusReturnKey = nil }
    }

    func setPersonalSnapshotMembership(_ isIncluded: Bool) {
        isInPersonalSnapshot = selectedKey != nil && isIncluded
    }

    func reconcile(using aliases: RepositoryIdentityAliases) {
        guard aliases.contextID == contextID else { return }
        let canonicalSelection = selectedKey.flatMap { aliases.canonical($0) }
        originKey = originKey.flatMap { aliases.canonical($0) }
        focusReturnKey = focusReturnKey.flatMap { aliases.canonical($0) }
        guard selectedKey != canonicalSelection else { return }
        advanceGeneration()
        selectedKey = canonicalSelection
        prDetails.reset(for: token)
    }

    func consumeFocusReturnKey() -> SelectionKey? {
        defer { focusReturnKey = nil }
        return focusReturnKey
    }

    private func advanceGeneration() {
        precondition(generation < .max, "Selection generation exhausted")
        generation += 1
    }
}

extension RemoteWorkItemID {
    var source: WorkSource {
        switch self {
        case .jira: .jira
        case .pullRequest: .github
        }
    }
}
