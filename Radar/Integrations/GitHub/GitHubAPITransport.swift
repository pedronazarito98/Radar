import Foundation

/// A lease covers the entire operation, including identity checks and guarded publication.
/// Actor reentrancy alone is deliberately not used as serialization.
actor GitHubAPITransport {
    private let authorization: GitHubAuthorizationStore

    init(authorization: GitHubAuthorizationStore) { self.authorization = authorization }

    private var leaseID: UUID?
    private var cooldown: (deadline: Date, problem: SourceProblem)?
    private struct Waiter {
        let id: UUID
        let continuation: CheckedContinuation<Void, Error>
        let expiration: Task<Void, Never>
    }
    private var waiters: [Waiter] = []

    func withBatch<Result: Sendable>(sessionReference: GitHubSessionReference, maximumCalls: Int, duration: Duration,
                                    operation: @Sendable (GitHubReadSession) async throws -> Result) async throws -> Result {
        let budget = RequestBudget(maximumCalls: maximumCalls, duration: duration)
        return try await withBatch(sessionReference: sessionReference, budget: budget, operation: operation)
    }

    /// The same budget can cover Jira reads while this GitHub lease remains occupied.
    func withBatch<Result: Sendable>(sessionReference: GitHubSessionReference, budget: RequestBudget,
                                    operation: @Sendable (GitHubReadSession) async throws -> Result) async throws -> Result {
        let id = UUID()
        try await acquire(id, budget: budget)
        defer { release(id) }
        try Task.checkCancellation()
        guard await budget.timeRemaining > .zero else { throw GitHubAPIError.source(.timeout) }
        if let cooldown, cooldown.deadline > Date() { throw GitHubAPIError.source(cooldown.problem) }
        cooldown = nil
        do { try await authorization.prepare(sessionReference, budget: budget) }
        catch let GitHubAPIError.source(problem) { recordBackoff(problem); throw GitHubAPIError.source(problem) }
        let session = GitHubReadSession(transport: self, leaseID: id, sessionReference: sessionReference, budget: budget)
        return try await operation(session)
    }

    private func acquire(_ id: UUID, budget: RequestBudget) async throws {
        try Task.checkCancellation()
        let deadline = budget.deadline
        guard ContinuousClock.now < deadline else { throw GitHubAPIError.source(.timeout) }
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
        waiter.continuation.resume(throwing: GitHubAPIError.source(problem))
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

    fileprivate func request(_ endpoint: GitHubEndpoint, lease: UUID, sessionReference: GitHubSessionReference,
                             timeout: TimeInterval) async throws -> GitHubHTTPResponse {
        guard leaseID == lease else { throw GitHubAPIError.source(.cancelled) }
        try Task.checkCancellation()
        let result = try await authorization.get(endpoint, reference: sessionReference, timeout: timeout)
        // Parse control errors even when cancellation arrived after exit: cooldown must survive.
        let response: GitHubHTTPResponse
        do { response = try GitHubHTTPResponse.parse(result, endpoint: endpoint) }
        catch let GitHubAPIError.source(problem) { recordBackoff(problem); throw GitHubAPIError.source(problem) }
        if response.remainingRequests == 0 { recordBackoff(.rateLimited(retryAfter: nil, resetAt: response.resetAt)) }
        try Task.checkCancellation()
        guard leaseID == lease, await authorization.isCurrent(sessionReference) else { throw GitHubAPIError.source(.cancelled) }
        return response
    }

    private func recordBackoff(_ problem: SourceProblem) {
        let now = Date()
        guard let deadline = RefreshOutcome(problems: [problem]).retryDeadline(at: now) else { return }
        if deadline > (cooldown?.deadline ?? .distantPast) { cooldown = (deadline, problem) }
    }

}

actor GitHubReadSession {
    private let transport: GitHubAPITransport
    private let leaseID: UUID
    private let sessionReference: GitHubSessionReference
    private let budget: RequestBudget
    private var blocked: SourceProblem?
    private var requestInFlight = false

    fileprivate init(transport: GitHubAPITransport, leaseID: UUID, sessionReference: GitHubSessionReference, budget: RequestBudget) {
        self.transport = transport; self.leaseID = leaseID; self.sessionReference = sessionReference; self.budget = budget
    }

    func get(_ endpoint: GitHubEndpoint, finalIdentity: Bool = false) async throws -> GitHubHTTPResponse {
        if let blocked { throw GitHubAPIError.source(blocked) }
        guard !requestInFlight else { throw GitHubAPIError.source(.transportUnavailable) }
        if finalIdentity, case .user = endpoint {} else if finalIdentity { throw GitHubAPIError.source(.invalidResponse) }
        requestInFlight = true
        defer { requestInFlight = false }
        guard await budget.consume(reserving: finalIdentity ? 0 : 1) else { throw GitHubAPIError.source(.resourceLimit) }
        let duration = await budget.timeRemaining
        let parts = duration.components
        let seconds = Double(parts.seconds) + Double(parts.attoseconds) / 1e18
        guard seconds > 0 else { throw GitHubAPIError.source(.resourceLimit) }
        do {
            let response = try await transport.request(endpoint, lease: leaseID, sessionReference: sessionReference, timeout: min(15, seconds))
            if response.remainingRequests == 0 {
                blocked = .rateLimited(retryAfter: nil, resetAt: response.resetAt)
            }
            return response
        } catch let GitHubAPIError.source(problem) {
            switch problem {
            case .rateLimited, .serviceUnavailable: blocked = problem
            default: break
            }
            throw GitHubAPIError.source(problem)
        }
    }
}
