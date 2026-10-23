import Observation
import SwiftUI

enum RadarFocusTarget: Hashable {
    case row(SelectionKey)
    case applyUpdates
    case collapse
    case closeDetails
    case refreshDetails
    case detailsContent
    case related(SelectionKey)
}

@MainActor
@Observable
final class RadarFocusCoordinator {
    let store: RadarStore
    var focusedTarget: RadarFocusTarget?
    private(set) var requestedTarget: RadarFocusTarget?
    private(set) var requestGeneration: UInt64 = 0

    private(set) var detailScrollGeneration: UInt64 = 0
    private(set) var detailScrollDelta: CGFloat = 0

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

    func selectRelated(_ key: SelectionKey) {
        guard store.selectRelated(key) != nil else { return }
        request(.closeDetails)
    }

    func reconcileAliases() {
        func canonical(_ target: RadarFocusTarget?) -> RadarFocusTarget? {
            switch target {
            case let .row(key): store.repositoryAliases.canonical(key).map(RadarFocusTarget.row)
            case let .related(key): store.repositoryAliases.canonical(key).map(RadarFocusTarget.related)
            default: target
            }
        }
        focusedTarget = canonical(focusedTarget)
        if let next = canonical(requestedTarget), next != requestedTarget { request(next) }
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
        if store.selection.selectedKey != nil {
            if store.jira.status.connection == .connected, store.github.status.connection == .connected,
               !store.relations.isRefreshing { targets.append(.refreshDetails) }
            targets += [.closeDetails, .detailsContent]
            if case let .observed(items, _, _, _, _) = DetailsStripPresentation.current(in: store)?.relations {
                targets += items.map { .related($0.id) }
            }
        }
        let current = focusedTarget ?? requestedTarget
        let index = current.flatMap { targets.firstIndex(of: $0) }
        let next = index.map { ($0 + (backwards ? targets.count - 1 : 1)) % targets.count }
            ?? (backwards ? targets.count - 1 : 0)
        request(targets[next])
    }

    func move(_ direction: MoveCommandDirection) {
        if focusedTarget == .detailsContent {
            guard direction == .up || direction == .down else { return }
            detailScrollDelta = direction == .up ? -64 : 64
            precondition(detailScrollGeneration < .max, "Scroll generation exhausted")
            detailScrollGeneration += 1
            return
        }
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

    func activate(close: () -> Void, refreshDetails: () -> Void) -> Bool {
        switch focusedTarget ?? requestedTarget {
        case .row(let key): select(key)
        case .applyUpdates: applyUpdates()
        case .collapse: close()
        case .closeDetails: closeDetails()
        case .refreshDetails:
            guard store.jira.status.connection == .connected, store.github.status.connection == .connected,
                  !store.relations.isRefreshing else { return false }
            refreshDetails()
        case let .related(key): selectRelated(key)
        case .detailsContent, nil: return false
        }
        return true
    }

    private var rows: [SelectionKey] {
        store.jira.items.map { SelectionKey(contextID: store.contextID, itemID: .jira($0.id)) }
            + store.github.items.map { SelectionKey(contextID: store.contextID, itemID: .pullRequest($0.id)) }
    }
}
