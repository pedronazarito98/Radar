import Foundation

enum JiraTokenKind: String, Sendable { case scoped, legacy }

struct JiraConnectionConfiguration: Sendable {
    let siteURL: URL
    let email: String
    let projectKeys: Set<String>
    let tokenKind: JiraTokenKind

    init?(site: String, email: String, projects: String, tokenKind: JiraTokenKind, policyAllowed: Bool) {
        guard policyAllowed, var url = URLComponents(string: site.trimmingCharacters(in: .whitespacesAndNewlines)),
              url.scheme == "https", let host = url.host?.lowercased(),
              host.hasSuffix(".atlassian.net"), host.split(separator: ".", omittingEmptySubsequences: false).count == 3,
              let tenant = host.split(separator: ".", omittingEmptySubsequences: false).first, !tenant.isEmpty,
              tenant.first != "-", tenant.last != "-",
              tenant.utf8.allSatisfy({ (97...122).contains($0) || (48...57).contains($0) || $0 == 45 }),
              url.user == nil, url.password == nil, url.port == nil || url.port == 443,
              url.query == nil, url.fragment == nil, url.path.isEmpty || url.path == "/" else { return nil }
        url.host = host; url.port = nil; url.path = ""
        let email = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !email.isEmpty, email.contains("@"), !email.contains(":"),
              !email.contains(where: { $0.isWhitespace || $0.isNewline }), email.utf8.count <= 320,
              let siteURL = url.url, let identity = JiraSiteIdentity(siteURL: siteURL) else { return nil }
        let keys = Set(projects.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) })
        guard let scope = SourceScope(jiraSite: identity, projectKeys: keys),
              case let .jira(_, normalizedKeys) = scope.resources else { return nil }
        self.siteURL = siteURL; self.email = email; projectKeys = normalizedKeys; self.tokenKind = tokenKind
    }
}

struct JiraQualifiedConnection: Sendable {
    let configuration: JiraConnectionConfiguration
    let cloudID: UUID
    let accountID: String
    let connectionID: ConnectionID
    let scope: SourceScope
}

enum JiraConnectionError: Error, Sendable {
    case source(SourceProblem)
    case vault(CredentialVaultError)
    case removalPending
}
