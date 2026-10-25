import Foundation

enum GitHubEndpoint: Sendable {
    case user
    case installations(page: Int)
    case installationRepositories(id: Int64, page: Int)
    case repository(GitHubRepositoryName)
    case search(query: PersonalWorkQuery, login: String, repositories: Set<GitHubRepositoryName>, page: Int)
    case pullRequest(GitHubRepositoryName, number: Int)
    case pulls(GitHubRepositoryName, page: Int)
    case checkRuns(GitHubRepositoryName, sha: GitCommitSHA, page: Int)
    case checkSuites(GitHubRepositoryName, sha: GitCommitSHA)
    case statuses(GitHubRepositoryName, sha: GitCommitSHA, page: Int)
    case reviews(GitHubRepositoryName, number: Int, page: Int)
    case requestedReviewers(GitHubRepositoryName, number: Int, page: Int)

    func components() throws -> URLComponents {
        var result = URLComponents()
        var query: [URLQueryItem] = []
        func paginated(_ page: Int) throws -> [URLQueryItem] {
            guard (1...10).contains(page) else { throw GitHubAPIError.source(.resourceLimit) }
            return [URLQueryItem(name: "per_page", value: "100"), URLQueryItem(name: "page", value: String(page))]
        }
        func prPath(_ repo: GitHubRepositoryName, _ number: Int) throws -> String {
            guard number > 0 else { throw GitHubAPIError.source(.invalidResponse) }
            return "/repos/\(repo.fullName)/pulls/\(number)"
        }
        switch self {
        case .user: result.path = "/user"
        case let .installations(page): result.path = "/user/installations"; query = try paginated(page)
        case let .installationRepositories(id, page):
            guard id > 0 else { throw GitHubAPIError.source(.invalidResponse) }
            result.path = "/user/installations/\(id)/repositories"; query = try paginated(page)
        case .repository(let repo): result.path = "/repos/\(repo.fullName)"
        case let .search(role, login, repos, page):
            guard (1...10).contains(repos.count), !login.isEmpty,
                  login.utf8.allSatisfy({ (65...90).contains($0) || (97...122).contains($0) || (48...57).contains($0) || $0 == 45 }) else {
                throw GitHubAPIError.source(.invalidResponse)
            }
            let qualifier: String
            switch role {
            case .authoredPullRequests: qualifier = "author"
            case .assignedPullRequests: qualifier = "assignee"
            case .reviewRequestedPullRequests: qualifier = "review-requested"
            case .assignedJiraWork: throw GitHubAPIError.source(.capabilityUnavailable)
            }
            result.path = "/search/issues"
            query = try paginated(page)
            let scope = repos.map(\.fullName).sorted().map { "repo:\($0)" }.joined(separator: " ")
            query.append(URLQueryItem(name: "q", value: "is:pull-request is:open \(qualifier):\(login) \(scope)"))
            query.append(URLQueryItem(name: "sort", value: "updated"))
            query.append(URLQueryItem(name: "order", value: "desc"))
        case let .pullRequest(repo, number): result.path = try prPath(repo, number)
        case let .pulls(repo, page):
            result.path = "/repos/\(repo.fullName)/pulls"; query = try paginated(page)
            query.append(URLQueryItem(name: "state", value: "open"))
        case let .checkRuns(repo, sha, page):
            result.path = "/repos/\(repo.fullName)/commits/\(sha.rawValue)/check-runs"; query = try paginated(page)
            query.append(URLQueryItem(name: "filter", value: "latest"))
        case let .checkSuites(repo, sha):
            result.path = "/repos/\(repo.fullName)/commits/\(sha.rawValue)/check-suites"
            query = [URLQueryItem(name: "per_page", value: "1"), URLQueryItem(name: "page", value: "1")]
        case let .statuses(repo, sha, page):
            result.path = "/repos/\(repo.fullName)/commits/\(sha.rawValue)/statuses"; query = try paginated(page)
        case let .reviews(repo, number, page): result.path = try prPath(repo, number) + "/reviews"; query = try paginated(page)
        case let .requestedReviewers(repo, number, page): result.path = try prPath(repo, number) + "/requested_reviewers"; query = try paginated(page)
        }
        result.queryItems = query.isEmpty ? nil : query
        return result
    }

    func argument() throws -> String {
        let url = try components()
        return url.percentEncodedPath + (url.percentEncodedQuery.map { "?\($0)" } ?? "")
    }
}
