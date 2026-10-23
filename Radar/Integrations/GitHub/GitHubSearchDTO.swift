import Foundation

struct GitHubSearchPageDTO: Decodable {
    let total_count: Int
    let incomplete_results: Bool
    let items: [GitHubSearchItemDTO]
}

struct GitHubRepositoryDTO: Decodable {
    let id: Int64
    let full_name: String
}

struct GitHubSearchItemDTO: Decodable {
    let number: Int
    let title: String
    let state: String
    let draft: Bool?
    let user: GitHubUserDTO?
    let assignees: [GitHubUserDTO]
    let repository_url: String
    let updated_at: String
    let pull_request: PullRequestMarker?
    struct PullRequestMarker: Decodable { let url: String }

    func item(role: PersonalWorkQuery, userID: GitHubUserID, scope: SourceScope,
              repositories: [GitHubRepositoryName: GitHubRepositoryIdentity], connectionID: ConnectionID) -> PullRequestItem? {
        guard state == "open", pull_request != nil,
              let url = URLComponents(string: repository_url), url.scheme == "https", url.host == "api.github.com",
              url.user == nil, url.password == nil, url.port == nil, url.query == nil, url.fragment == nil else { return nil }
        let path = url.path.split(separator: "/", omittingEmptySubsequences: false)
        guard path.count == 4, path[0].isEmpty, path[1] == "repos",
              let name = GitHubRepositoryName(owner: String(path[2]), name: String(path[3])),
              case let .github(allowed) = scope.resources, allowed.contains(name), let repository = repositories[name],
              let identity = PullRequestIdentity(repository: repository, number: number) else { return nil }
        var roles: Set<PersonalPRRole> = []
        if user?.id == userID.rawValue { roles.insert(.author) }
        if assignees.contains(where: { $0.id == userID.rawValue }) { roles.insert(.assignee) }
        switch role {
        case .authoredPullRequests: guard roles.contains(.author) else { return nil }
        case .assignedPullRequests: guard roles.contains(.assignee) else { return nil }
        case .reviewRequestedPullRequests: roles.insert(.reviewRequestedUnclassified)
        case .assignedJiraWork: return nil
        }
        let author = user.flatMap { dto in GitHubUserID(dto.id).map { GitHubAuthor(id: $0, login: dto.login) } }
        return PullRequestItem(id: identity, repositoryName: name, title: title, author: author,
            lifecycle: draft == true ? .draft : .open, personalRoles: roles, headSHA: nil, headRef: nil,
            updatedAt: ISO8601DateFormatter().date(from: updated_at), sourceConnections: [connectionID])
    }
}

struct GitHubBatchFailure: Error, Sendable {
    let problem: SourceProblem
    let observedProblems: [SourceProblem]
}
