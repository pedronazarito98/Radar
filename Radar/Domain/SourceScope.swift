import Foundation

enum WorkSource: Hashable, Sendable {
    case jira
    case github
}

enum PersonalWorkQuery: Hashable, CaseIterable, Sendable {
    case assignedJiraWork
    case authoredPullRequests
    case assignedPullRequests
    case reviewRequestedPullRequests
}

/// Authorized resources only; account/context identity is carried separately.
struct SourceScope: Hashable, Sendable {
    enum Resources: Hashable, Sendable {
        case jira(site: JiraSiteIdentity, projectKeys: Set<String>)
        case github(repositories: Set<GitHubRepositoryName>)
    }

    let resources: Resources

    init?(jiraSite: JiraSiteIdentity, projectKeys: Set<String>) {
        let letters = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZ")
        let permitted = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_")
        let normalized = Set(projectKeys.map { $0.uppercased() })
        guard !normalized.isEmpty, projectKeys.allSatisfy({ $0.utf8.allSatisfy { $0 < 128 } }),
              normalized.allSatisfy({ key in
                  guard let first = key.unicodeScalars.first else { return false }
                  return letters.contains(first) && key.unicodeScalars.allSatisfy(permitted.contains)
              }) else { return nil }
        resources = .jira(site: jiraSite, projectKeys: normalized)
    }

    init?(githubRepositories: Set<GitHubRepositoryName>) {
        guard !githubRepositories.isEmpty else { return nil }
        resources = .github(repositories: githubRepositories)
    }

    var source: WorkSource {
        switch resources {
        case .jira: .jira
        case .github: .github
        }
    }

    var requiredQueries: Set<PersonalWorkQuery> {
        switch resources {
        case .jira: [.assignedJiraWork]
        case .github: [.authoredPullRequests, .assignedPullRequests, .reviewRequestedPullRequests]
        }
    }
}

protocol SourceSnapshotItem: Identifiable, Equatable, Sendable where ID: Hashable, ID: Sendable {
    static var source: WorkSource { get }
    func belongs(to scope: SourceScope) -> Bool
}

extension JiraWorkItem: SourceSnapshotItem {
    static var source: WorkSource { .jira }

    func belongs(to scope: SourceScope) -> Bool {
        guard case let .jira(site, projects) = scope.resources else { return false }
        return id.site == site && projects.contains(key.projectKey)
    }
}

extension PullRequestItem: SourceSnapshotItem {
    static var source: WorkSource { .github }

    func belongs(to scope: SourceScope) -> Bool {
        guard case let .github(repositories) = scope.resources else { return false }
        return repositories.contains(repositoryName)
    }
}
