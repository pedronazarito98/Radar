import Foundation

struct GitHubPRDetailObservation: Sendable {
    let headSHA: GitCommitSHA
    let lifecycle: PullRequestLifecycle
    let observedAt: Date
    let ci: CIReport
    let review: ReviewReport
    let problems: [SourceProblem]
}

struct GitHubPRDetailEnricher: Sendable {
    let transport: GitHubCLITransport

    func fetchAndPublish(executable: QualifiedGitHubExecutable, expectedUser: GitHubAuthor, item: PullRequestItem,
                         publish: @escaping @MainActor @Sendable (GitHubPRDetailObservation) -> Bool) async throws -> [SourceProblem] {
        try await transport.withBatch(executable: executable, maximumCalls: 20, duration: .seconds(30)) { session in
            var problems: [SourceProblem] = []
            do {
                let initial = try GitHubUserDTO.decode(try await session.get(.user).body)
                guard initial.id == expectedUser.id else { throw GitHubCLIError.identityChanged }
                let response = try await session.get(.pullRequest(item.repositoryName, number: item.id.number))
                let pr = try JSONDecoder().decode(GitHubPRDetailDTO.self, from: response.body)
                let (sha, lifecycle) = try pr.observation(for: item)
                let observedAt = Date()
                let repo = item.repositoryName
                var checks = await GitHubDetailPagination.read(session: session,
                    endpoint: { .checkRuns(repo, sha: sha, page: $0) }) { body in
                        let dto = try JSONDecoder().decode(GitHubCheckPageDTO.self, from: body)
                        return GitHubDetailPage(items: try dto.check_runs.map { try $0.signal(sha: sha) }, total: dto.total_count)
                    }
                problems += checks.problems
                let runIDs = checks.items.compactMap { signal -> Int64? in
                    if case let .checkRun(id, _) = signal.origin { return id }
                    return nil
                }
                if Set(runIDs).count != checks.items.count { checks.coverage = .partial }
                do {
                    let probe = try await session.get(.checkSuites(repo, sha: sha))
                    let dto = try JSONDecoder().decode(GitHubSuiteProbeDTO.self, from: probe.body)
                    guard (0...1_000).contains(dto.total_count), dto.check_suites.count == min(1, dto.total_count),
                          dto.check_suites.allSatisfy({ GitCommitSHA($0.head_sha) == sha }),
                          dto.total_count > 0 || checks.items.isEmpty else { throw GitHubCLIError.source(.invalidResponse) }
                } catch {
                    checks.coverage = .partial
                    problems.append(GitHubPersonalPRProvider.problem(error))
                }
                let statuses = await GitHubDetailPagination.read(session: session,
                    endpoint: { .statuses(repo, sha: sha, page: $0) }) { body in
                        let dto = try JSONDecoder().decode([GitHubStatusDTO].self, from: body)
                        return GitHubDetailPage(items: try dto.map { try $0.signal(sha: sha) }, total: nil)
                    }
                problems += statuses.problems
                // The server orders statuses newest first. Context is case-insensitive; never sort by ID.
                var contexts: Set<String> = []
                let latest = statuses.items.filter { signal in
                    guard case let .commitStatus(context) = signal.origin else { return false }
                    return contexts.insert(context.lowercased()).inserted
                }
                var reviews = await GitHubDetailPagination.read(session: session,
                    endpoint: { .reviews(repo, number: item.id.number, page: $0) }) { body in
                        let dto = try JSONDecoder().decode([GitHubReviewDTO].self, from: body)
                        return GitHubDetailPage(items: try dto.map { try $0.review() }, total: nil)
                    }
                problems += reviews.problems
                if Set(reviews.items.map(\.id)).count != reviews.items.count { reviews.coverage = .partial }
                var requests = await GitHubDetailPagination.read(session: session,
                    endpoint: { .requestedReviewers(repo, number: item.id.number, page: $0) }) { body in
                        let dto = try JSONDecoder().decode(GitHubReviewRequestsDTO.self, from: body)
                        let users = dto.users.compactMap { GitHubUserID($0.id) }
                        let teams = dto.teams.compactMap { GitHubTeamID($0.id) }
                        guard users.count == dto.users.count, teams.count == dto.teams.count,
                              Set(users).count == users.count, Set(teams).count == teams.count,
                              dto.users.count <= 100, dto.teams.count <= 100 else { throw GitHubCLIError.source(.invalidResponse) }
                        return GitHubDetailPage(items: [ReviewRequests(users: Set(users), teams: Set(teams), coverage: .complete)], total: nil)
                    }
                problems += requests.problems
                let final = try GitHubUserDTO.decode(try await session.get(.user, finalIdentity: true).body)
                guard final.id == initial.id, final.id == expectedUser.id else { throw GitHubCLIError.identityChanged }
                try Task.checkCancellation()
                guard let ci = CIReport(headSHA: sha, signals: checks.items + latest,
                    coverage: checks.coverage == .complete && statuses.coverage == .complete ? .complete : .partial) else {
                    throw GitHubCLIError.source(.invalidResponse)
                }
                let users = requests.items.reduce(into: Set<GitHubUserID>()) { $0.formUnion($1.users) }
                let teams = requests.items.reduce(into: Set<GitHubTeamID>()) { $0.formUnion($1.teams) }
                if users.count != requests.items.reduce(0, { $0 + $1.users.count }) ||
                    teams.count != requests.items.reduce(0, { $0 + $1.teams.count }) { requests.coverage = .partial }
                let requestSummary = ReviewRequests(users: users, teams: teams, coverage: requests.coverage)
                let review = ReviewReport(headSHA: sha, requests: requestSummary, reviews: reviews.items, coverage: reviews.coverage)
                let observation = GitHubPRDetailObservation(headSHA: sha, lifecycle: lifecycle, observedAt: observedAt,
                    ci: ci, review: review, problems: problems)
                guard await publish(observation) else { throw GitHubCLIError.source(.cancelled) }
                return problems
            } catch GitHubCLIError.identityChanged { throw GitHubCLIError.identityChanged }
            catch { throw GitHubBatchFailure(problem: GitHubPersonalPRProvider.problem(error), observedProblems: problems) }
        }
    }
}
