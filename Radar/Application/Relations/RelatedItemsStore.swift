import Foundation
import Observation

@MainActor
@Observable
final class RelatedItemsStore {
    private(set) var invalidation = UUID()
    private(set) var selection: SelectionToken?
    private(set) var queryID: UUID?
    private(set) var observation: RelationObservation?
    private(set) var isRefreshing = false
    private(set) var problem: SourceProblem?
    private(set) var jiraItems: [JiraIdentity: JiraWorkItem] = [:]
    private(set) var pullRequests: [PullRequestIdentity: PullRequestItem] = [:]

    func clear() {
        invalidation = UUID(); selection = nil; queryID = nil; observation = nil
        isRefreshing = false; problem = nil; jiraItems = [:]; pullRequests = [:]
    }

    func begin(selection: SelectionToken, queryID: UUID) {
        if self.selection != selection { observation = nil; problem = nil }
        self.selection = selection; self.queryID = queryID; isRefreshing = true
    }

    func cancel() { queryID = nil; isRefreshing = false }

    func fail(_ problem: SourceProblem, queryID: UUID) {
        guard self.queryID == queryID else { return }
        self.problem = problem; self.queryID = nil; isRefreshing = false
    }

    func publish(_ result: RelationObservation, selection: SelectionToken, queryID: UUID) -> Bool {
        guard self.queryID == queryID else { return false }
        self.selection = selection; observation = result
        // Keep only the current observation (which includes its subject), not a browsing cache.
        jiraItems = Dictionary(uniqueKeysWithValues: result.jiraItems.map { ($0.id, $0) })
        pullRequests = Dictionary(uniqueKeysWithValues: result.pullRequests.map { ($0.id, $0) })
        self.queryID = nil; isRefreshing = false; problem = result.problems.first?.problem
        return true
    }

    func canReconcile(using aliases: RepositoryIdentityAliases) -> Bool { reconciledItems(using: aliases) != nil }

    func reconcile(using aliases: RepositoryIdentityAliases) -> Bool {
        guard let next = reconciledItems(using: aliases) else { return false }
        pullRequests = next
        if let selected = selection, let key = aliases.canonical(selected.key), key != selected.key {
            selection = nil; observation = nil; queryID = nil; isRefreshing = false
        }
        if var value = observation {
            value.pullRequests = value.pullRequests.compactMap { $0.reconciling(using: aliases) }
            value.edges = value.edges.map { WorkRelation(jiraID: $0.jiraID,
                pullRequestID: aliases.canonical($0.pullRequestID), provenance: $0.provenance) }
            observation = value
        }
        return true
    }

    private func reconciledItems(using aliases: RepositoryIdentityAliases) -> [PullRequestIdentity: PullRequestItem]? {
        var next: [PullRequestIdentity: PullRequestItem] = [:]
        for value in pullRequests.values {
            guard let item = value.reconciling(using: aliases), next[item.id] == nil else { return nil }
            next[item.id] = item
        }
        return next
    }
}
