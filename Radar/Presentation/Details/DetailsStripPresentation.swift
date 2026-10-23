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
    case observed(items: [RelatedWorkPresentation], coverage: ObservationCoverage, scope: String, isRefreshing: Bool = false, problem: SourceProblem? = nil)
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

    /// Contextual items stay outside the personal snapshot and its count.
    @MainActor static func current(in store: RadarStore) -> Self? {
        guard let key = store.selection.selectedKey else { return nil }
        let title: String
        switch key.itemID {
        case let .jira(identity):
            title = store.jiraItem(identity)?.key.rawValue ?? "Card relacionado"
        case let .pullRequest(identity):
            let item = store.pullRequest(identity)
            title = item.map { "\($0.repositoryName.fullName) #\(identity.number)" } ?? "PR #\(identity.number)"
        }
        return Self(
            key: key, title: title, isInPersonalSnapshot: store.selection.isInPersonalSnapshot,
            relations: relationPresentation(in: store), prDetails: store.selection.prDetails.details,
            isRefreshingPR: store.selection.prDetails.isRefreshing,
            prProblem: store.selection.prDetails.problem
        )
    }

    @MainActor private static func relationPresentation(in store: RadarStore) -> RelationPresentation {
        let relations = store.relations
        guard relations.selection == store.selection.token else { return .notQueried }
        guard let observation = relations.observation else {
            if relations.isRefreshing { return .loading }
            return relations.problem.map(RelationPresentation.failed) ?? .notQueried
        }
        let context = store.contextID
        var items: [RelatedWorkPresentation] = []
        for edge in observation.edges {
            let provenance = "Referência textual no " + edge.provenance.map { $0 == .title ? "título" : "branch" }.sorted().joined(separator: " e ")
            switch store.selection.selectedKey?.itemID {
            case let .jira(id) where id == edge.jiraID:
                if let pr = store.pullRequest(edge.pullRequestID) {
                    items.append(RelatedWorkPresentation(id: SelectionKey(contextID: context, itemID: .pullRequest(pr.id)),
                        title: "\(pr.repositoryName.fullName) #\(pr.id.number)", subtitle: pr.title, provenance: provenance))
                }
            case let .pullRequest(id) where id == edge.pullRequestID:
                if let card = store.jiraItem(edge.jiraID) {
                    items.append(RelatedWorkPresentation(id: SelectionKey(contextID: context, itemID: .jira(card.id)),
                        title: card.key.rawValue, subtitle: card.summary, provenance: provenance))
                }
            default: break
            }
        }
        let scope: String
        if case .jira = store.selection.selectedKey?.itemID {
            scope = "PRs abertos nos repositórios selecionados"
        } else { scope = "Cards referenciados pelo PR selecionado nos projetos autorizados" }
        return .observed(items: items, coverage: observation.coverage,
            scope: scope + " · chaves textuais fora de URLs reconhecidas · site Jira configurado",
            isRefreshing: relations.isRefreshing, problem: relations.problem)
    }

}
