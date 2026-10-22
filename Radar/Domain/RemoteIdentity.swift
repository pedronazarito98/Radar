import Foundation

struct WorkContextID: Hashable, Sendable {
    let rawValue: UUID

    init(rawValue: UUID = UUID()) {
        self.rawValue = rawValue
    }
}

/// Provenance and permissions belong to a connection, never to remote equality.
struct ConnectionID: Hashable, Sendable {
    let rawValue: UUID

    init(rawValue: UUID = UUID()) {
        self.rawValue = rawValue
    }
}

/// Choose one qualified tenant authority per context and keep it for every issue.
/// A site fallback and a cloud ID are not silently assumed to be the same tenant.
struct JiraSiteIdentity: Hashable, Sendable {
    enum Authority: Hashable, Sendable {
        case cloudID(String)
        case site(URL)
    }

    let authority: Authority

    init?(cloudID: String) {
        guard !cloudID.isEmpty, !cloudID.contains(where: \.isWhitespace) else { return nil }
        authority = .cloudID(cloudID)
    }

    init?(siteURL: URL) {
        guard var components = URLComponents(url: siteURL, resolvingAgainstBaseURL: false),
              components.scheme?.lowercased() == "https",
              let host = components.host, !host.isEmpty,
              components.user == nil, components.password == nil,
              components.query == nil, components.fragment == nil,
              components.port == nil || components.port == 443,
              components.path.isEmpty || components.path == "/" else { return nil }
        components.scheme = "https"
        components.host = host.lowercased()
        components.port = nil
        components.path = ""
        guard let normalizedURL = components.url else { return nil }
        authority = .site(normalizedURL)
    }
}

struct JiraIdentity: Hashable, Sendable {
    let site: JiraSiteIdentity
    let issueID: String

    init?(site: JiraSiteIdentity, issueID: String) {
        guard !issueID.isEmpty, !issueID.contains(where: \.isWhitespace) else { return nil }
        self.site = site
        self.issueID = issueID
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.site == rhs.site && lhs.issueID == rhs.issueID
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(site)
        hasher.combine(issueID)
    }
}

enum GitHubHost: String, Hashable, Sendable {
    case githubDotCom = "github.com"
}

struct GitHubRepositoryID: Hashable, Sendable {
    let rawValue: Int64

    init?(_ rawValue: Int64) {
        guard rawValue > 0 else { return nil }
        self.rawValue = rawValue
    }
}

struct GitHubRepositoryName: Hashable, Sendable {
    let owner: String
    let name: String

    init?(owner: String, name: String) {
        let permitted = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-_.")
        guard [owner, name].allSatisfy({ value in
            !value.isEmpty && value != "." && value != ".."
                && value.unicodeScalars.allSatisfy(permitted.contains)
        }) else { return nil }
        self.owner = owner.lowercased()
        self.name = name.lowercased()
    }

    var fullName: String { "\(owner)/\(name)" }
}

enum GitHubRepositoryIdentity: Hashable, Sendable {
    case stable(GitHubRepositoryID)
    case fallback(GitHubRepositoryName)
}

/// Search issue IDs are deliberately absent: they are not PR identities.
struct PullRequestIdentity: Hashable, Sendable {
    let host: GitHubHost
    let repository: GitHubRepositoryIdentity
    let number: Int

    init?(host: GitHubHost = .githubDotCom, repository: GitHubRepositoryIdentity, number: Int) {
        guard number > 0 else { return nil }
        self.host = host
        self.repository = repository
        self.number = number
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.host == rhs.host && lhs.repository == rhs.repository && lhs.number == rhs.number
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(host)
        hasher.combine(repository)
        hasher.combine(number)
    }
}

enum RemoteWorkItemID: Hashable, Sendable {
    case jira(JiraIdentity)
    case pullRequest(PullRequestIdentity)
}

struct SelectionKey: Hashable, Sendable {
    let contextID: WorkContextID
    let itemID: RemoteWorkItemID
}
