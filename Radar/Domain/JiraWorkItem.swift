import Foundation

struct JiraIssueKey: Hashable, Sendable {
    let rawValue: String
    let projectKey: String

    init?(_ value: String) {
        guard value.utf8.allSatisfy({ $0 < 128 }) else { return nil }
        let normalized = value.uppercased()
        let parts = normalized.split(separator: "-", omittingEmptySubsequences: false)
        let letters = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZ")
        let projectCharacters = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_")
        guard parts.count == 2,
              let first = parts[0].unicodeScalars.first, letters.contains(first),
              parts[0].unicodeScalars.allSatisfy(projectCharacters.contains),
              !parts[1].isEmpty,
              parts[1].utf8.allSatisfy({ (48...57).contains($0) }),
              parts[1].contains(where: { $0 != "0" }) else { return nil }
        rawValue = normalized
        projectKey = String(parts[0])
    }
}

/// The API's names and category keys are preserved, including custom statuses.
struct JiraWorkStatus: Equatable, Sendable {
    let id: String
    let name: String
    let category: JiraStatusCategory?
}

struct JiraStatusCategory: Equatable, Sendable {
    let key: String
    let name: String
}

struct JiraProject: Equatable, Sendable {
    let id: String
    let key: String
    let name: String?
}

struct JiraAssignee: Equatable, Sendable {
    let accountID: String
    let displayName: String?
}

struct JiraWorkItem: Identifiable, Equatable, Sendable {
    let id: JiraIdentity
    let key: JiraIssueKey
    let summary: String
    let status: JiraWorkStatus
    let project: JiraProject
    let assignee: JiraAssignee?
    let updatedAt: Date?
    let siteURL: URL
    let sourceConnections: Set<ConnectionID>

    init?(
        id: JiraIdentity,
        key: JiraIssueKey,
        summary: String,
        status: JiraWorkStatus,
        project: JiraProject,
        assignee: JiraAssignee?,
        updatedAt: Date?,
        siteURL: URL,
        sourceConnections: Set<ConnectionID>
    ) {
        guard let site = JiraSiteIdentity(siteURL: siteURL),
              case let .site(normalizedURL) = site.authority else { return nil }
        if case .site = id.site.authority, id.site != site { return nil }
        self.id = id
        self.key = key
        self.summary = summary
        self.status = status
        self.project = project
        self.assignee = assignee
        self.updatedAt = updatedAt
        self.siteURL = normalizedURL
        self.sourceConnections = sourceConnections
    }

    /// Presentation destination only; NavigationCoordinator validates the active allowlist.
    var webURL: URL {
        siteURL.appendingPathComponent("browse").appendingPathComponent(key.rawValue)
    }
}
