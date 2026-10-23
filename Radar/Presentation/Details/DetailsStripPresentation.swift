import Foundation

struct RelatedWorkPresentation: Identifiable {
    let id: SelectionKey
    let title: String
    let subtitle: String
    let provenance: String
}

enum RelationPresentation {
    case notQueried
    case loading
    case observed(items: [RelatedWorkPresentation], coverage: ObservationCoverage, scope: String)
    case failed(SourceProblem)
}

struct DetailsStripPresentation {
    let key: SelectionKey
    let title: String
    let isInPersonalSnapshot: Bool
    let relations: RelationPresentation
    let prDetails: PRDetails?
    let isRefreshingPR: Bool
    let prProblem: SourceProblem?

    /// Presentation adapter only; T31 supplies the real relation result.
    @MainActor static func current(in store: RadarStore) -> Self? {
        guard let key = store.selection.selectedKey else { return nil }
        let title: String
        switch key.itemID {
        case let .jira(identity):
            title = store.jira.items.first { $0.id == identity }?.key.rawValue ?? "Card relacionado"
        case let .pullRequest(identity):
            let item = store.github.items.first { $0.id == identity }
            title = item.map { "\($0.repositoryName.fullName) #\(identity.number)" } ?? "PR #\(identity.number)"
        }
        return Self(
            key: key, title: title, isInPersonalSnapshot: store.selection.isInPersonalSnapshot,
            relations: .notQueried, prDetails: store.selection.prDetails.details,
            isRefreshingPR: store.selection.prDetails.isRefreshing,
            prProblem: store.selection.prDetails.problem
        )
    }
}
