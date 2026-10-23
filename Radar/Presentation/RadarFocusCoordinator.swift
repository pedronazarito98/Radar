import Observation
import SwiftUI

enum RadarFocusTarget: Hashable {
    case row(SelectionKey)
    case applyUpdates
    case collapse
    case closeDetails
}

@MainActor
@Observable
final class RadarFocusCoordinator {
    let store: RadarStore
    var focusedTarget: RadarFocusTarget?
    private(set) var requestedTarget: RadarFocusTarget?
    private(set) var requestGeneration: UInt64 = 0

    init(store: RadarStore) { self.store = store }

    func request(_ target: RadarFocusTarget?) {
        precondition(requestGeneration < .max, "Focus generation exhausted")
        requestedTarget = target
        requestGeneration += 1
    }

    func open() { request(rows.first.map(RadarFocusTarget.row) ?? .collapse) }

    func clear() {
        focusedTarget = nil
        request(nil)
    }

    func select(_ key: SelectionKey) {
        guard rows.contains(key), store.select(key) != nil else { return }
        request(.closeDetails)
    }

    func closeDetails() {
        store.selection.dismissDetails()
        request(store.consumeFocusReturnKey().map(RadarFocusTarget.row) ?? .collapse)
    }

    func applyUpdates() {
        store.applyPendingUpdates()
        if case let .row(key) = focusedTarget,
           let canonical = store.repositoryAliases.canonical(key), rows.contains(canonical) {
            request(.row(canonical))
        } else {
            request(.collapse)
        }
    }

    func advance(backwards: Bool) {
        var targets: [RadarFocusTarget] = []
        if store.jira.hasPendingUpdate || store.github.hasPendingUpdate { targets.append(.applyUpdates) }
        targets.append(.collapse)
        targets += rows.map(RadarFocusTarget.row)
        if store.selection.selectedKey != nil { targets.append(.closeDetails) }
        let current = focusedTarget ?? requestedTarget
        let index = current.flatMap { targets.firstIndex(of: $0) }
        let next = index.map { ($0 + (backwards ? targets.count - 1 : 1)) % targets.count }
            ?? (backwards ? targets.count - 1 : 0)
        request(targets[next])
    }

    func move(_ direction: MoveCommandDirection) {
        guard !rows.isEmpty else { return }
        guard case let .row(key) = focusedTarget ?? requestedTarget else {
            request(.row(rows[0]))
            return
        }
        let current = rows.filter { $0.itemID.source == key.itemID.source }
        guard let index = current.firstIndex(of: key) else { return }
        switch direction {
        case .up: request(.row(current[max(0, index - 1)]))
        case .down: request(.row(current[min(current.count - 1, index + 1)]))
        case .left, .right:
            let destination: WorkSource = direction == .left ? .jira : .github
            let other = rows.filter { $0.itemID.source == destination }
            if !other.isEmpty { request(.row(other[min(index, other.count - 1)])) }
        @unknown default: break
        }
    }

    func activate(close: () -> Void) -> Bool {
        switch focusedTarget ?? requestedTarget {
        case .row(let key): select(key)
        case .applyUpdates: applyUpdates()
        case .collapse: close()
        case .closeDetails: closeDetails()
        case nil: return false
        }
        return true
    }

    private var rows: [SelectionKey] {
        store.jira.items.map { SelectionKey(contextID: store.contextID, itemID: .jira($0.id)) }
            + store.github.items.map { SelectionKey(contextID: store.contextID, itemID: .pullRequest($0.id)) }
    }
}
