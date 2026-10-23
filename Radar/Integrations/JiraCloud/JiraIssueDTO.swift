import Foundation

struct JiraSearchPageDTO: Decodable {
    let issues: [JiraIssueDTO]
    let isLast: Bool?
    let nextPageToken: String?
    let hasWarnings: Bool

    private enum CodingKeys: String, CodingKey { case issues, isLast, nextPageToken, warnings, warningMessages }
    private struct WarningPresence: Decodable { init(from decoder: Decoder) throws {} }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        issues = try values.decode([JiraIssueDTO].self, forKey: .issues)
        isLast = try values.decodeIfPresent(Bool.self, forKey: .isLast)
        nextPageToken = try values.decodeIfPresent(String.self, forKey: .nextPageToken)
        hasWarnings = [CodingKeys.warnings, CodingKeys.warningMessages].contains { key in
            guard values.contains(key), (try? values.decodeNil(forKey: key)) != true else { return false }
            // Warning text/shape is never retained. Unknown future shapes are conservative.
            guard let markers = try? values.decode([WarningPresence].self, forKey: key) else { return true }
            return !markers.isEmpty
        }
    }
}

struct JiraIssueDTO: Decodable {
    let id: String
    let key: String
    let fields: Fields

    struct Fields: Decodable {
        let summary: String
        let status: Status
        let project: Project
        let assignee: Assignee?
        let updated: String
    }
    struct Status: Decodable {
        let id: String
        let name: String
        let statusCategory: Category
    }
    struct Category: Decodable { let key: String; let name: String }
    struct Project: Decodable { let id: String; let key: String; let name: String? }
    struct Assignee: Decodable { let accountId: String; let displayName: String? }

    func item(connection: JiraQualifiedConnection) -> JiraWorkItem? {
        guard fields.assignee?.accountId == connection.accountID, fields.status.statusCategory.key != "done" else { return nil }
        return contextualItem(connection: connection)
    }

    func contextualItem(connection: JiraQualifiedConnection) -> JiraWorkItem? {
        guard let site = JiraSiteIdentity(cloudID: connection.cloudID.uuidString.lowercased()),
              let identity = JiraIdentity(site: site, issueID: id), let key = JiraIssueKey(key),
              fields.project.key == key.projectKey, connection.configuration.projectKeys.contains(key.projectKey),
              !fields.status.id.isEmpty, !fields.status.name.isEmpty, !fields.project.id.isEmpty else { return nil }
        return JiraWorkItem(id: identity, key: key, summary: fields.summary,
            status: JiraWorkStatus(id: fields.status.id, name: fields.status.name,
                category: JiraStatusCategory(key: fields.status.statusCategory.key, name: fields.status.statusCategory.name)),
            project: JiraProject(id: fields.project.id, key: fields.project.key, name: fields.project.name),
            assignee: fields.assignee.map { JiraAssignee(accountID: $0.accountId, displayName: $0.displayName) },
            updatedAt: Self.date(fields.updated), siteURL: connection.configuration.siteURL,
            sourceConnections: [connection.connectionID])
    }

    private static func date(_ value: String) -> Date? {
        let parser = ISO8601DateFormatter()
        parser.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = parser.date(from: value) { return date }
        parser.formatOptions = [.withInternetDateTime]
        return parser.date(from: value)
    }
}
