import Foundation

struct GitHubUserID: Hashable, Sendable {
    let rawValue: Int64

    init?(_ rawValue: Int64) {
        guard rawValue > 0 else { return nil }
        self.rawValue = rawValue
    }
}

struct GitHubTeamID: Hashable, Sendable {
    let rawValue: Int64

    init?(_ rawValue: Int64) {
        guard rawValue > 0 else { return nil }
        self.rawValue = rawValue
    }
}

struct GitHubAuthor: Equatable, Sendable {
    let id: GitHubUserID
    let login: String
}

enum PersonalPRRole: Hashable, Sendable {
    case author
    case assignee
    case directlyRequestedReviewer
    /// The provider may add this only when team membership was actually qualified.
    case confirmedTeamReviewer
}

enum PullRequestLifecycle: Equatable, Sendable {
    case draft
    case open
    case merged
    case closed
}

struct GitCommitSHA: Hashable, Sendable {
    let rawValue: String

    init?(_ value: String) {
        let hex = CharacterSet(charactersIn: "0123456789abcdefABCDEF")
        guard (value.count == 40 || value.count == 64),
              value.unicodeScalars.allSatisfy(hex.contains) else { return nil }
        rawValue = value.lowercased()
    }
}

struct PullRequestItem: Identifiable, Equatable, Sendable {
    let id: PullRequestIdentity
    let repositoryName: GitHubRepositoryName
    let title: String
    let author: GitHubAuthor?
    let lifecycle: PullRequestLifecycle
    let personalRoles: Set<PersonalPRRole>
    let headSHA: GitCommitSHA?
    let headRef: String?
    let updatedAt: Date?
    let sourceConnections: Set<ConnectionID>

    init?(
        id: PullRequestIdentity, repositoryName: GitHubRepositoryName, title: String,
        author: GitHubAuthor?, lifecycle: PullRequestLifecycle, personalRoles: Set<PersonalPRRole>,
        headSHA: GitCommitSHA?, headRef: String?, updatedAt: Date?,
        sourceConnections: Set<ConnectionID>
    ) {
        if case let .fallback(name) = id.repository, name != repositoryName { return nil }
        self.id = id
        self.repositoryName = repositoryName
        self.title = title
        self.author = author
        self.lifecycle = lifecycle
        self.personalRoles = personalRoles
        self.headSHA = headSHA
        self.headRef = headRef
        self.updatedAt = updatedAt
        self.sourceConnections = sourceConnections
    }

    var webURL: URL? {
        URL(string: "https://\(id.host.rawValue)")?
            .appendingPathComponent(repositoryName.owner)
            .appendingPathComponent(repositoryName.name)
            .appendingPathComponent("pull")
            .appendingPathComponent(String(id.number))
    }
}
