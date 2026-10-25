import Foundation

struct RelationResolver: Sendable {
    let jira: JiraCloudConnection
    let github: GitHubAPITransport

    func fetchAndPublish(
        subject: RelationSubject, jiraConnection: JiraQualifiedConnection,
        githubConnectionID: ConnectionID, githubScope: SourceScope,
        sessionReference: GitHubSessionReference, expectedUser: GitHubAuthor,
        knownPRs: [PullRequestItem],
        isCurrent: @escaping @MainActor @Sendable () -> Bool,
        publish: @escaping @MainActor @Sendable (RelationObservation) -> Bool
    ) async throws -> [OriginProblem] {
        guard case let .github(repositories) = githubScope.resources, (1...10).contains(repositories.count) else {
            throw RelationFailure(problem: .invalidResponse, observedProblems: [], identityChanged: false)
        }
        let budget = RequestBudget(maximumCalls: 20, duration: .seconds(30))
        return try await github.withBatch(sessionReference: sessionReference, budget: budget) { session in
            var result = RelationObservation()
            var observed = false
            do {
                try await ensureCurrent(jiraConnection, isCurrent)
                let initial = try GitHubUserDTO.decode(try await session.get(.user).body)
                guard initial.id == expectedUser.id else { throw GitHubAPIError.identityChanged }
                try await ensureCurrent(jiraConnection, isCurrent)
                switch subject {
                case let .jira(card):
                    guard case let .jira(site, projects) = jiraConnection.scope.resources,
                          card.id.site == site, projects.contains(card.key.projectKey) else {
                        throw GitHubAPIError.source(.invalidResponse)
                    }
                    result.jiraItems = [card]
                    var fresh: [PullRequestItem] = []
                    for repository in repositories.sorted(by: { $0.fullName < $1.fullName }) {
                        var complete = false
                        for page in 1...10 {
                            do {
                                try await ensureCurrent(jiraConnection, isCurrent)
                                let response = try await session.get(.pulls(repository, page: page))
                                try await ensureCurrent(jiraConnection, isCurrent)
                                let dtos = try JSONDecoder().decode([GitHubRelatedPRDTO].self, from: response.body)
                                guard dtos.count <= 100 else { throw GitHubAPIError.source(.invalidResponse) }
                                let items = try dtos.map { try $0.item(repository: repository, connectionID: githubConnectionID, requireOpen: true) }
                                var validated = result
                                for item in items { try register(item, in: &validated) }
                                result.repositoryResolutions = validated.repositoryResolutions
                                observed = true
                                for item in items {
                                    if fresh.contains(where: { $0.id == item.id }) { result.coverage = .partial }
                                    fresh.removeAll { $0.id == item.id }
                                    fresh.append(item)
                                }
                                if !response.hasNextPage { complete = true; break }
                                if items.isEmpty { break }
                            } catch {
                                result.problems.append(OriginProblem(source: .github, problem: GitHubPersonalPRProvider.problem(error)))
                                if Task.isCancelled { throw error }
                                break
                            }
                        }
                        if !complete { result.coverage = .partial }
                    }
                    // Previously observed titles can supplement a partial scan; never claim them as a complete new scan.
                    var candidates = fresh
                    if result.coverage != .complete {
                        let observed = Set(fresh.map { "\($0.repositoryName.fullName)#\($0.id.number)" })
                        candidates += knownPRs.filter { repositories.contains($0.repositoryName)
                            && $0.sourceConnections.contains(githubConnectionID)
                            && !observed.contains("\($0.repositoryName.fullName)#\($0.id.number)") }
                    }
                    for pr in candidates {
                        let references = JiraKeyReferenceExtractor().references(title: pr.title, branch: pr.headRef, scope: jiraConnection.scope)
                        if let reference = references.first(where: { $0.key == card.key && $0.site == card.id.site }) {
                            merge(card: card, pr: pr, provenance: reference.provenance, into: &result)
                        }
                    }
                case let .pullRequest(selected):
                    guard repositories.contains(selected.repositoryName) else { throw GitHubAPIError.source(.permissionDenied) }
                    let response = try await session.get(.pullRequest(selected.repositoryName, number: selected.id.number))
                    try await ensureCurrent(jiraConnection, isCurrent)
                    let dto = try JSONDecoder().decode(GitHubRelatedPRDTO.self, from: response.body)
                    let pr = try dto.item(repository: selected.repositoryName, connectionID: githubConnectionID, requireOpen: false)
                    guard pr.id.number == selected.id.number else { throw GitHubAPIError.source(.invalidResponse) }
                    if case .stable = selected.id.repository, pr.id != selected.id { throw GitHubAPIError.source(.invalidResponse) }
                    try register(pr, in: &result)
                    result.pullRequests = [pr]
                    observed = true
                    for reference in JiraKeyReferenceExtractor().references(title: pr.title, branch: pr.headRef, scope: jiraConnection.scope) {
                        do {
                            try await ensureCurrent(jiraConnection, isCurrent)
                            let data = try await jira.readIssue(reference.key, expectedConnectionID: jiraConnection.connectionID, budget: budget)
                            try await ensureCurrent(jiraConnection, isCurrent)
                            let dto = try JSONDecoder().decode(JiraIssueDTO.self, from: data)
                            guard let card = dto.contextualItem(connection: jiraConnection), card.key == reference.key,
                                  card.id.site == reference.site else { throw JiraConnectionError.source(.invalidResponse) }
                            merge(card: card, pr: pr, provenance: reference.provenance, into: &result)
                        } catch {
                            let problem = jiraProblem(error)
                            result.problems.append(OriginProblem(source: .jira, problem: problem))
                            if Task.isCancelled { throw error }
                            result.coverage = .partial
                            if problem == .resourceLimit || problem == .timeout { break }
                            if case .rateLimited = problem { break }
                            if case .serviceUnavailable = problem { break }
                        }
                    }
                }
                try await ensureCurrent(jiraConnection, isCurrent)
                let finalResponse = try await session.get(.user, finalIdentity: true)
                let final = try GitHubUserDTO.decode(finalResponse.body)
                guard final.id == expectedUser.id else { throw GitHubAPIError.identityChanged }
                if finalResponse.remainingRequests == 0 {
                    result.problems.append(OriginProblem(source: .github,
                        problem: .rateLimited(retryAfter: nil, resetAt: finalResponse.resetAt)))
                }
                try await ensureCurrent(jiraConnection, isCurrent)
                if !result.problems.isEmpty { result.coverage = .partial }
                guard await budget.timeRemaining > .zero else { throw GitHubAPIError.source(.timeout) }
                guard observed || !result.edges.isEmpty else { throw GitHubAPIError.source(result.problems.first?.problem ?? .invalidResponse) }
                guard await publish(result) else { throw GitHubAPIError.source(.cancelled) }
                return result.problems
            } catch {
                if let failure = error as? RelationFailure { throw failure }
                let changed: Bool
                if case GitHubAPIError.identityChanged = error { changed = true } else { changed = false }
                let problem = error is JiraConnectionError ? jiraProblem(error) : GitHubPersonalPRProvider.problem(error)
                let source: WorkSource = error is JiraConnectionError ? .jira : .github
                throw RelationFailure(problem: problem, observedProblems: result.problems + [OriginProblem(source: source, problem: problem)], identityChanged: changed)
            }
        }
    }

    private func ensureCurrent(_ expected: JiraQualifiedConnection, _ check: @MainActor @Sendable () -> Bool) async throws {
        try Task.checkCancellation()
        guard try await jira.currentConnection().connectionID == expected.connectionID, await check() else {
            throw JiraConnectionError.source(.cancelled)
        }
    }

    private func merge(card: JiraWorkItem, pr: PullRequestItem, provenance: Set<JiraReferenceProvenance>, into result: inout RelationObservation) {
        if let previous = result.jiraItems.first(where: { $0.id == card.id }) {
            if previous != card { result.coverage = .partial }
        } else { result.jiraItems.append(card) }
        if !result.pullRequests.contains(where: { $0.id == pr.id }) { result.pullRequests.append(pr) }
        if let index = result.edges.firstIndex(where: { $0.jiraID == card.id && $0.pullRequestID == pr.id }) {
            let previous = result.edges[index]
            result.edges[index] = WorkRelation(jiraID: card.id, pullRequestID: pr.id,
                provenance: previous.provenance.union(provenance))
        } else { result.edges.append(WorkRelation(jiraID: card.id, pullRequestID: pr.id, provenance: provenance)) }
    }

    private func register(_ item: PullRequestItem, in result: inout RelationObservation) throws {
        guard case let .stable(id) = item.id.repository else { return }
        if let previous = result.repositoryResolutions.first(where: { $0.name == item.repositoryName }) {
            guard previous.id == id else { throw GitHubAPIError.source(.invalidResponse) }
        } else { result.repositoryResolutions.append(RepositoryIdentityResolution(name: item.repositoryName, id: id)) }
    }

    private func jiraProblem(_ error: Error) -> SourceProblem {
        if case let JiraConnectionError.source(problem) = error { return problem }
        if error is CancellationError { return .cancelled }
        return .invalidResponse
    }
}
