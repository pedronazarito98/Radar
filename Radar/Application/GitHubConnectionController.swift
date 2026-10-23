import Foundation
import Observation

@MainActor
@Observable
final class GitHubConnectionController {
    let transport = GitHubCLITransport()
    let store: RadarStore
    private let preferences: PreferencesStore
    private(set) var executable: QualifiedGitHubExecutable?
    private(set) var identity: GitHubAuthor?
    private(set) var connectionID: ConnectionID?
    private var generation = UUID()

    init(store: RadarStore, preferences: PreferencesStore) { self.store = store; self.preferences = preferences }

    func connect(executable: QualifiedGitHubExecutable, repositories: String) async throws {
        let names = repositories.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        guard (1...10).contains(names.count) else { throw GitHubCLIError.source(.resourceLimit) }
        var repos: Set<GitHubRepositoryName> = []
        for name in names {
            let parts = name.split(separator: "/", omittingEmptySubsequences: false)
            guard parts.count == 2, let repo = GitHubRepositoryName(owner: String(parts[0]), name: String(parts[1])) else {
                throw GitHubCLIError.source(.invalidResponse)
            }
            repos.insert(repo)
        }
        guard let scope = SourceScope(githubRepositories: repos) else { throw GitHubCLIError.source(.invalidResponse) }
        let attempt = UUID(); generation = attempt
        try await preferences.saveGitHub(executable: executable, repositories: repos)
        guard generation == attempt, !Task.isCancelled else { throw GitHubCLIError.source(.cancelled) }
        try await transport.withBatch(executable: executable, maximumCalls: 2, duration: .seconds(30)) { session in
            let initial = try GitHubUserDTO.decode(try await session.get(.user).body)
            let final = try GitHubUserDTO.decode(try await session.get(.user, finalIdentity: true).body)
            guard initial.id == final.id else { throw GitHubCLIError.identityChanged }
            try Task.checkCancellation()
            try await self.accept(initial, executable: executable, scope: scope, attempt: attempt)
        }
    }

    private func accept(_ identity: GitHubAuthor, executable: QualifiedGitHubExecutable, scope: SourceScope, attempt: UUID) throws {
        guard generation == attempt, !Task.isCancelled else { throw GitHubCLIError.source(.cancelled) }
        self.identity = identity; self.executable = executable; connectionID = ConnectionID()
        store.configureSource(scope, connection: .connected)
    }

    func disconnect() {
        generation = UUID(); identity = nil; executable = nil; connectionID = nil
        store.invalidate(.github)
    }

    func requireRequalification() {
        disconnect()
        store.invalidate(.github, connection: .requalificationRequired)
    }
}
