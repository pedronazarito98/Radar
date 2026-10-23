import Foundation

struct RepositoryIdentityResolution: Equatable, Sendable {
    let name: GitHubRepositoryName
    let id: GitHubRepositoryID
}

/// A value owned by one work context. Register only provider-confirmed repo pairs.
/// Reconciliation returns new values; an ID already stored in a Set never changes hash.
struct RepositoryIdentityAliases: Sendable {
    enum Registration: Equatable, Sendable {
        case registered
        case unchanged
        case conflict
    }

    let contextID: WorkContextID
    private var repositoryIDs: [GitHubRepositoryName: GitHubRepositoryID] = [:]

    init(contextID: WorkContextID) {
        self.contextID = contextID
    }

    mutating func register(name: GitHubRepositoryName, id: GitHubRepositoryID) -> Registration {
        if let existing = repositoryIDs[name] {
            return existing == id ? .unchanged : .conflict
        }
        repositoryIDs[name] = id
        return .registered
    }

    func canonical(_ identity: PullRequestIdentity) -> PullRequestIdentity {
        guard case let .fallback(name) = identity.repository,
              let repositoryID = repositoryIDs[name],
              let resolved = PullRequestIdentity(
                host: identity.host, repository: .stable(repositoryID), number: identity.number
              ) else { return identity }
        return resolved
    }

    func canonical(_ selection: SelectionKey) -> SelectionKey? {
        guard selection.contextID == contextID else { return nil }
        guard case let .pullRequest(identity) = selection.itemID else { return selection }
        return SelectionKey(contextID: contextID, itemID: .pullRequest(canonical(identity)))
    }

    func isCanonical(_ item: PullRequestItem) -> Bool {
        guard let byName = PullRequestIdentity(
            host: item.id.host, repository: .fallback(item.repositoryName), number: item.id.number
        ) else { return false }
        let resolvedName = canonical(byName)
        if case .stable = resolvedName.repository { return resolvedName == item.id }
        return canonical(item.id) == item.id
    }
}
