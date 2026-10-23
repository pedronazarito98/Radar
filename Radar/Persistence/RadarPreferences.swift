import Foundation

enum RepositoryCategory: String, CaseIterable, Codable, Sendable {
    case web = "WEB", api = "API", infrastructure = "Infra", other = "Outro"
}

struct JiraSavedConfiguration: Codable, Sendable {
    let site: String
    let email: String
    let projects: [String]
    let tokenKind: String
    var reference: JiraCredentialReference?

    init(configuration: JiraConnectionConfiguration, reference: JiraCredentialReference?) {
        site = configuration.siteURL.absoluteString; email = configuration.email
        projects = configuration.projectKeys.sorted(); tokenKind = configuration.tokenKind.rawValue
        self.reference = reference
    }

    func configuration(policyAllowed: Bool) -> JiraConnectionConfiguration? {
        guard let kind = JiraTokenKind(rawValue: tokenKind) else { return nil }
        return JiraConnectionConfiguration(site: site, email: email, projects: projects.joined(separator: ","),
            tokenKind: kind, policyAllowed: policyAllowed)
    }
}

struct RadarPreferences: Codable, Sendable {
    var version = 1
    var jira: JiraSavedConfiguration?
    var ghPath: String?
    var repositories: [String] = []
    var preferredDisplayID: UInt32?
    var categories: [String: RepositoryCategory] = [:]

    var isValid: Bool {
        guard version == 1, repositories.count <= 10, categories.count <= 10,
              jira == nil || jira?.configuration(policyAllowed: true) != nil,
              ghPath == nil || (ghPath?.hasPrefix("/") == true && ghPath?.contains("\0") == false
                && ghPath.map { URL(fileURLWithPath: $0).lastPathComponent == "gh" && $0.utf8.count <= 4_096 } == true),
              preferredDisplayID == nil || preferredDisplayID != 0 else { return false }
        let names = repositories.compactMap(Self.repository)
        return names.count == repositories.count && Set(names).count == names.count
            && categories.keys.allSatisfy { Self.repository($0) != nil && repositories.contains($0) }
    }

    static func repository(_ value: String) -> GitHubRepositoryName? {
        let parts = value.split(separator: "/", omittingEmptySubsequences: false)
        guard parts.count == 2 else { return nil }
        return GitHubRepositoryName(owner: String(parts[0]), name: String(parts[1]))
    }
}

enum PreferencesError: Error, Sendable {
    case unavailable, invalidStoredData, invalidValue, conflictingReference

    var message: String {
        switch self {
        case .invalidStoredData: "As preferências locais não puderam ser validadas. Foram preservadas; nenhuma referência de token será substituída."
        case .conflictingReference: "Há uma referência de token pendente. Remova-a pelo fluxo do Radar antes de criar outra."
        case .invalidValue: "Confira os valores das preferências."
        case .unavailable: "Não foi possível confirmar a gravação das preferências locais. Nenhum novo token será salvo."
        }
    }
}
