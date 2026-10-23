import Foundation

extension PullRequestItem {
    func reconciling(using aliases: RepositoryIdentityAliases) -> PullRequestItem? {
        guard aliases.isCanonicalName(repositoryName, for: id) else { return nil }
        return PullRequestItem(id: aliases.canonical(id), repositoryName: repositoryName, title: title,
            author: author, lifecycle: lifecycle, personalRoles: personalRoles, headSHA: headSHA,
            headRef: headRef, updatedAt: updatedAt, sourceConnections: sourceConnections)
    }
}

extension RepositoryIdentityAliases {
    func isCanonicalName(_ name: GitHubRepositoryName, for id: PullRequestIdentity) -> Bool {
        guard let fallback = PullRequestIdentity(repository: .fallback(name), number: id.number) else { return false }
        let resolved = canonical(fallback)
        if case .stable = resolved.repository { return resolved == canonical(id) }
        return true
    }
}
