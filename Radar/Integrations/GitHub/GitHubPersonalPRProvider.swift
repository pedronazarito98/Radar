import Foundation

struct GitHubPersonalPRProvider: Sendable {
    let transport: GitHubCLITransport

    func fetchAndPublish(executable: QualifiedGitHubExecutable, expectedUser: GitHubAuthor, connectionID: ConnectionID,
                         contextID: WorkContextID, scope: SourceScope, aliases: RepositoryIdentityAliases,
                         publish: @escaping @MainActor @Sendable (SourceSnapshot<PullRequestItem>, [RepositoryIdentityResolution]) -> Bool) async throws -> [SourceProblem] {
        try await transport.withBatch(executable: executable, maximumCalls: 42, duration: .seconds(180)) { session in
            var problems: [SourceProblem] = []
            do {
                let initial = try GitHubUserDTO.decode(try await session.get(.user).body)
                guard initial.id == expectedUser.id else { throw GitHubCLIError.identityChanged }
                guard case let .github(repos) = scope.resources else { throw GitHubCLIError.source(.invalidResponse) }
                var identities: [GitHubRepositoryName: GitHubRepositoryIdentity] = [:]
                var resolutions: [RepositoryIdentityResolution] = []
                var identityPartial = false
                for repo in repos.sorted(by: { $0.fullName < $1.fullName }) {
                    guard let fallback = PullRequestIdentity(repository: .fallback(repo), number: 1) else { throw GitHubCLIError.source(.invalidResponse) }
                    identities[repo] = aliases.canonical(fallback).repository
                    do {
                        let response = try await session.get(.repository(repo))
                        guard let dto = try? JSONDecoder().decode(GitHubRepositoryDTO.self, from: response.body),
                              dto.full_name.lowercased() == repo.fullName, let id = GitHubRepositoryID(dto.id) else {
                            throw GitHubCLIError.source(.invalidResponse)
                        }
                        if case let .stable(previous) = identities[repo], previous != id { throw GitHubCLIError.source(.invalidResponse) }
                        identities[repo] = .stable(id)
                        resolutions.append(RepositoryIdentityResolution(name: repo, id: id))
                    } catch {
                        if error is CancellationError { throw error }
                        // A previously canonical repo cannot be relabelled from an unqualified read.
                        if case .stable = identities[repo] { throw error }
                        let problem = Self.problem(error)
                        problems.append(problem); identityPartial = true
                        if Self.stopsWork(problem) { throw error }
                    }
                }
                var union: [PullRequestIdentity: PullRequestItem] = [:]
                var coverage: [PersonalWorkQuery: QueryCoverage] = [:]
                for query in [PersonalWorkQuery.authoredPullRequests, .assignedPullRequests, .reviewRequestedPullRequests] {
                    var reasons: Set<QueryPartialReason> = identityPartial ? [.unresolvedIdentity] : []
                    var count = 0
                    var total: Int?
                    var observedPage = false
                    var queryIDs: Set<PullRequestIdentity> = []
                    for page in 1...10 {
                        do {
                            let response = try await session.get(.search(query: query, login: initial.login, repositories: repos, page: page))
                            guard let dto = try? JSONDecoder().decode(GitHubSearchPageDTO.self, from: response.body), dto.total_count >= 0 else {
                                throw GitHubCLIError.source(.invalidResponse)
                            }
                            let items = dto.items.compactMap { $0.item(role: query, userID: initial.id, scope: scope, repositories: identities, connectionID: connectionID) }
                            guard items.count == dto.items.count else { throw GitHubCLIError.source(.invalidResponse) }
                            observedPage = true
                            if let total, total != dto.total_count { reasons.insert(.inconsistentPagination) }
                            total = dto.total_count
                            if dto.incomplete_results || dto.total_count >= 1_000 { reasons.insert(.incompleteResults) }
                            count += items.count
                            for item in items {
                                if !queryIDs.insert(item.id).inserted { reasons.insert(.inconsistentPagination) }
                                union[item.id] = Self.merge(union[item.id], item)
                            }
                            if !response.hasNextPage {
                                if count != min(dto.total_count, 1_000) { reasons.insert(.inconsistentPagination) }
                                break
                            }
                            if page == 10 { reasons.insert(.pageLimit) }
                        } catch {
                            if error is CancellationError { throw error }
                            let problem = Self.problem(error)
                            problems.append(problem)
                            if Self.stopsWork(problem) { throw error }
                            if observedPage { reasons.insert(.interrupted) }
                            else { coverage[query] = .failed(problem) }
                            break
                        }
                    }
                    if coverage[query] == nil { coverage[query] = reasons.isEmpty ? .complete : .partial(reasons) }
                }
                let final = try GitHubUserDTO.decode(try await session.get(.user, finalIdentity: true).body)
                guard final.id == initial.id, final.id == expectedUser.id else { throw GitHubCLIError.identityChanged }
                try Task.checkCancellation()
                let items = union.values.sorted {
                    if $0.updatedAt != $1.updatedAt { return ($0.updatedAt ?? .distantPast) > ($1.updatedAt ?? .distantPast) }
                    if $0.repositoryName != $1.repositoryName { return $0.repositoryName.fullName < $1.repositoryName.fullName }
                    return $0.id.number < $1.id.number
                }
                let hasObservation = coverage.values.contains { value in
                    switch value { case .complete, .partial: true; case .failed: false }
                }
                guard hasObservation else { throw GitHubCLIError.source(problems.first ?? .invalidResponse) }
                guard let snapshot = SourceSnapshot(contextID: contextID, scope: scope, items: items, queryCoverage: coverage,
                    lastSuccessfulAt: Date(), observedProblems: problems) else { throw GitHubCLIError.source(.invalidResponse) }
                guard await publish(snapshot, resolutions) else { throw GitHubCLIError.source(.cancelled) }
                return snapshot.allProblems
            } catch GitHubCLIError.identityChanged { throw GitHubCLIError.identityChanged }
            catch { throw GitHubBatchFailure(problem: Self.problem(error), observedProblems: problems) }
        }
    }

    static func problem(_ error: Error) -> SourceProblem {
        if case let GitHubCLIError.source(problem) = error { return problem }
        if error is CancellationError { return .cancelled }
        return .invalidResponse
    }

    private static func stopsWork(_ problem: SourceProblem) -> Bool {
        switch problem {
        case .rateLimited, .serviceUnavailable, .cancelled, .resourceLimit, .transportUnavailable, .authenticationRequired: true
        default: false
        }
    }

    private static func merge(_ previous: PullRequestItem?, _ item: PullRequestItem) -> PullRequestItem {
        guard let previous else { return item }
        let latest = (item.updatedAt ?? .distantPast) >= (previous.updatedAt ?? .distantPast) ? item : previous
        return PullRequestItem(id: latest.id, repositoryName: latest.repositoryName, title: latest.title, author: latest.author,
            lifecycle: latest.lifecycle, personalRoles: previous.personalRoles.union(item.personalRoles), headSHA: nil, headRef: nil,
            updatedAt: latest.updatedAt, sourceConnections: previous.sourceConnections.union(item.sourceConnections)) ?? previous
    }
}
