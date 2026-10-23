import Foundation

/// A lease covers the entire operation, including identity checks and guarded publication.
/// Actor reentrancy alone is deliberately not used as serialization.
actor GitHubCLITransport {
    private var leaseID: UUID?
    private var cooldown: (deadline: Date, problem: SourceProblem)?
    private struct Waiter {
        let id: UUID
        let continuation: CheckedContinuation<Void, Error>
        let expiration: Task<Void, Never>
    }
    private var waiters: [Waiter] = []

    func withBatch<Result: Sendable>(executable: QualifiedGitHubExecutable, maximumCalls: Int, duration: Duration,
                                    operation: @Sendable (GitHubReadSession) async throws -> Result) async throws -> Result {
        let budget = RequestBudget(maximumCalls: maximumCalls, duration: duration)
        return try await withBatch(executable: executable, budget: budget, operation: operation)
    }

    /// The same budget can cover Jira reads while this GitHub lease remains occupied.
    func withBatch<Result: Sendable>(executable: QualifiedGitHubExecutable, budget: RequestBudget,
                                    operation: @Sendable (GitHubReadSession) async throws -> Result) async throws -> Result {
        let id = UUID()
        try await acquire(id, budget: budget)
        defer { release(id) }
        try Task.checkCancellation()
        guard await budget.timeRemaining > .zero else { throw GitHubCLIError.source(.timeout) }
        guard !GitHubProcessSafety.isUnavailable else { throw GitHubCLIError.source(.transportUnavailable) }
        if let cooldown, cooldown.deadline > Date() { throw GitHubCLIError.source(cooldown.problem) }
        cooldown = nil
        let session = GitHubReadSession(transport: self, leaseID: id, executable: executable, budget: budget)
        return try await operation(session)
    }

    private func acquire(_ id: UUID, budget: RequestBudget) async throws {
        try Task.checkCancellation()
        let deadline = budget.deadline
        guard ContinuousClock.now < deadline else { throw GitHubCLIError.source(.timeout) }
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                if Task.isCancelled { continuation.resume(throwing: CancellationError()); return }
                if leaseID == nil { leaseID = id; continuation.resume() }
                else {
                    let expiration = Task { [weak self] in
                        do { try await Task.sleep(until: deadline, clock: .continuous) } catch { return }
                        await self?.removeWaiter(id, problem: .timeout)
                    }
                    waiters.append(Waiter(id: id, continuation: continuation, expiration: expiration))
                }
            }
        } onCancel: { Task { await self.removeWaiter(id, problem: .cancelled) } }
    }

    private func removeWaiter(_ id: UUID, problem: SourceProblem) {
        guard let index = waiters.firstIndex(where: { $0.id == id }) else { return }
        let waiter = waiters.remove(at: index)
        waiter.expiration.cancel()
        waiter.continuation.resume(throwing: GitHubCLIError.source(problem))
    }

    private func release(_ id: UUID) {
        guard leaseID == id else { return }
        if waiters.isEmpty { leaseID = nil }
        else {
            let next = waiters.removeFirst()
            next.expiration.cancel()
            leaseID = next.id
            next.continuation.resume()
        }
    }

    fileprivate func request(_ endpoint: GitHubEndpoint, lease: UUID, executable: QualifiedGitHubExecutable,
                             timeout: TimeInterval) async throws -> GitHubHTTPResponse {
        guard leaseID == lease else { throw GitHubCLIError.source(.cancelled) }
        try Task.checkCancellation()
        let arguments = ["api", try endpoint.argument(), "--hostname", "github.com", "--method", "GET", "--include",
            "--header", "Accept: application/vnd.github+json", "--header", "X-GitHub-Api-Version: 2026-03-10"]
        let result = try await BoundedGitHubProcess().run(executable: executable.url, arguments: arguments, timeoutSeconds: timeout)
        // Parse control errors even when cancellation arrived after exit: cooldown must survive.
        let response: GitHubHTTPResponse
        do { response = try GitHubHTTPResponse.parse(result, endpoint: endpoint) }
        catch let GitHubCLIError.source(problem) { recordBackoff(problem); throw GitHubCLIError.source(problem) }
        if response.remainingRequests == 0 { recordBackoff(.rateLimited(retryAfter: nil, resetAt: response.resetAt)) }
        try Task.checkCancellation()
        guard leaseID == lease else { throw GitHubCLIError.source(.cancelled) }
        return response
    }

    private func recordBackoff(_ problem: SourceProblem) {
        let now = Date()
        guard let deadline = RefreshOutcome(problems: [problem]).retryDeadline(at: now) else { return }
        if deadline > (cooldown?.deadline ?? .distantPast) { cooldown = (deadline, problem) }
    }

}

actor GitHubReadSession {
    private let transport: GitHubCLITransport
    private let leaseID: UUID
    private let executable: QualifiedGitHubExecutable
    private let budget: RequestBudget
    private var blocked: SourceProblem?
    private var requestInFlight = false

    fileprivate init(transport: GitHubCLITransport, leaseID: UUID, executable: QualifiedGitHubExecutable, budget: RequestBudget) {
        self.transport = transport; self.leaseID = leaseID; self.executable = executable; self.budget = budget
    }

    func get(_ endpoint: GitHubEndpoint, finalIdentity: Bool = false) async throws -> GitHubHTTPResponse {
        if let blocked { throw GitHubCLIError.source(blocked) }
        guard !requestInFlight else { throw GitHubCLIError.source(.transportUnavailable) }
        if finalIdentity, case .user = endpoint {} else if finalIdentity { throw GitHubCLIError.source(.invalidResponse) }
        requestInFlight = true
        defer { requestInFlight = false }
        guard await budget.consume(reserving: finalIdentity ? 0 : 1) else { throw GitHubCLIError.source(.resourceLimit) }
        let duration = await budget.timeRemaining
        let parts = duration.components
        let seconds = Double(parts.seconds) + Double(parts.attoseconds) / 1e18
        guard seconds > 0 else { throw GitHubCLIError.source(.resourceLimit) }
        do {
            let response = try await transport.request(endpoint, lease: leaseID, executable: executable, timeout: min(15, seconds))
            if response.remainingRequests == 0 {
                blocked = .rateLimited(retryAfter: nil, resetAt: response.resetAt)
            }
            return response
        } catch let GitHubCLIError.source(problem) {
            switch problem {
            case .rateLimited, .serviceUnavailable: blocked = problem
            default: break
            }
            throw GitHubCLIError.source(problem)
        }
    }
}
