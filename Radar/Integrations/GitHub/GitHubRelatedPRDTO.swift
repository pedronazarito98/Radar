import Foundation

/// The list endpoint supplies branch context, never authority for CI/review head.
struct GitHubRelatedPRDTO: Decodable {
    let number: Int
    let title: String
    let state: String
    let draft: Bool
    let merged: Bool?
    let user: GitHubUserDTO?
    let head: Head
    let base: Base
    struct Head: Decodable { let ref: String }
    struct Base: Decodable { let repo: GitHubRepositoryDTO }

    func item(repository: GitHubRepositoryName, connectionID: ConnectionID, requireOpen: Bool) throws -> PullRequestItem {
        guard base.repo.full_name.lowercased() == repository.fullName,
              let repositoryID = GitHubRepositoryID(base.repo.id),
              let id = PullRequestIdentity(repository: .stable(repositoryID), number: number),
              state == "open" || state == "closed", !requireOpen || state == "open",
              !(merged == true && state == "open"), !head.ref.isEmpty else {
            throw GitHubCLIError.source(.invalidResponse)
        }
        let author = try user.map { user -> GitHubAuthor in
            guard let id = GitHubUserID(user.id), !user.login.isEmpty else {
                throw GitHubCLIError.source(.invalidResponse)
            }
            return GitHubAuthor(id: id, login: user.login)
        }
        guard let item = PullRequestItem(id: id, repositoryName: repository, title: title, author: author,
            lifecycle: merged == true ? .merged : state == "closed" ? .closed : draft ? .draft : .open,
            personalRoles: [], headSHA: nil, headRef: head.ref, updatedAt: nil, sourceConnections: [connectionID]) else {
            throw GitHubCLIError.source(.invalidResponse)
        }
        return item
    }
}
