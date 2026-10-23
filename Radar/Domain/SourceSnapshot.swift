import Foundation

enum QueryPartialReason: Hashable, Sendable {
    case pageLimit
    case requestBudget
    case outputLimit
    case incompleteResults
    case interrupted
    case unresolvedIdentity
    case inconsistentPagination
}

enum QueryCoverage: Equatable, Sendable {
    case complete
    case partial(Set<QueryPartialReason>)
    case failed(SourceProblem)
}

struct SnapshotRevision: Hashable, Sendable {
    let rawValue: UUID

    init() { rawValue = UUID() }
}

/// The producer unions provenance/roles and canonicalizes aliases before construction.
/// Duplicate IDs are rejected instead of silently discarding one version of an item.
struct SourceSnapshot<Item: SourceSnapshotItem>: Equatable, Sendable {
    let contextID: WorkContextID
    let revision: SnapshotRevision
    let scope: SourceScope
    let items: [Item]
    let queryCoverage: [PersonalWorkQuery: QueryCoverage]
    let lastSuccessfulAt: Date

    init?(
        contextID: WorkContextID,
        scope: SourceScope,
        items: [Item],
        queryCoverage: [PersonalWorkQuery: QueryCoverage],
        lastSuccessfulAt: Date
    ) {
        guard scope.source == Item.source,
              Set(items.map(\.id)).count == items.count,
              items.allSatisfy({ $0.belongs(to: scope) }),
              Set(queryCoverage.keys).isSubset(of: scope.requiredQueries) else { return nil }
        self.contextID = contextID
        revision = SnapshotRevision()
        self.scope = scope
        self.items = items
        self.queryCoverage = queryCoverage
        self.lastSuccessfulAt = lastSuccessfulAt
    }

    var isComplete: Bool {
        scope.requiredQueries.allSatisfy { queryCoverage[$0] == .complete }
    }

    var missingQueries: Set<PersonalWorkQuery> {
        scope.requiredQueries.subtracting(queryCoverage.keys)
    }

    var count: Count { Count(snapshot: self) }

    /// Stable query order prevents dictionary iteration from choosing the displayed problem.
    var firstProblem: SourceProblem? {
        for query in PersonalWorkQuery.allCases {
            if case let .failed(problem) = queryCoverage[query] { return problem }
        }
        return nil
    }
}
