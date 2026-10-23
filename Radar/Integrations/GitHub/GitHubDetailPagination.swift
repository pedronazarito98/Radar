import Foundation

struct GitHubDetailPage<Element: Sendable>: Sendable {
    let items: [Element]
    let total: Int?
}

struct GitHubDetailCollection<Element: Sendable>: Sendable {
    var items: [Element] = []
    var coverage: ObservationCoverage = .complete
    var problems: [SourceProblem] = []
}

enum GitHubDetailPagination {
    static func read<Element: Sendable>(
        session: GitHubReadSession, endpoint: @Sendable (Int) -> GitHubEndpoint,
        decode: @Sendable (Data) throws -> GitHubDetailPage<Element>
    ) async -> GitHubDetailCollection<Element> {
        var result = GitHubDetailCollection<Element>()
        var observed = false
        var total: Int?
        for page in 1...10 {
            do {
                let response = try await session.get(endpoint(page))
                let decoded = try decode(response.body)
                guard decoded.items.count <= 100, decoded.total.map({ $0 >= 0 }) ?? true else {
                    throw GitHubCLIError.source(.invalidResponse)
                }
                observed = true
                if let previous = total, previous != decoded.total { result.coverage = .partial }
                total = decoded.total
                result.items.append(contentsOf: decoded.items)
                if !response.hasNextPage {
                    if let total, total != result.items.count { result.coverage = .partial }
                    return result
                }
                if decoded.items.isEmpty || page == 10 { result.coverage = .partial; return result }
            } catch {
                let problem = GitHubPersonalPRProvider.problem(error)
                result.problems.append(problem)
                result.coverage = observed ? .partial : .unavailable(reason(problem))
                return result
            }
        }
        return result
    }

    static func reason(_ problem: SourceProblem) -> ObservationUnavailableReason {
        switch problem {
        case .permissionDenied, .singleSignOnRequired: .permissionDenied
        case .capabilityUnavailable: .capabilityUnavailable
        case .invalidResponse: .invalidResponse
        default: .requestFailed
        }
    }
}
