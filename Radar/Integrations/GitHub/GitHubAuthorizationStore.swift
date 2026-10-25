import Foundation

/// Owns bearer material privately. UI and providers receive only an opaque session reference.
actor GitHubAuthorizationStore {
    private struct ActiveSession {
        let reference: GitHubSessionReference
        let credential: GitHubCredentialReference
        var tokens: GitHubTokenSet
    }
    private let preferences: PreferencesStore
    private let vault = GitHubCredentialVault()
    private let oauth = GitHubOAuthClient()
    private var active: ActiveSession?
    private var authorizationID = UUID()
    private var credentialGeneration = UUID()
    private var isRotating = false
    private var isShuttingDown = false
    private var persistenceOperations = 0
    private struct DrainWaiter {
        let id: UUID
        let continuation: CheckedContinuation<Bool, Never>
        let deadline: Task<Void, Never>
    }
    private var drainWaiters: [DrainWaiter] = []

    init(preferences: PreferencesStore) { self.preferences = preferences }

    func authorize(configuration: GitHubAppConfiguration,
                   present: @escaping @MainActor @Sendable (GitHubDeviceChallenge) -> Void) async throws -> GitHubSessionReference {
        guard !isShuttingDown else { throw GitHubAPIError.source(.cancelled) }
        guard !isRotating else { throw GitHubAuthorizationError.rotationInProgress }
        let attempt = UUID(); authorizationID = attempt
        guard try await preferences.snapshot().githubCredential == nil else { throw PreferencesError.conflictingReference }
        try Task.checkCancellation()
        guard !isShuttingDown, authorizationID == attempt else { throw GitHubAPIError.source(.cancelled) }
        let tokens = try await oauth.authorize(configuration: configuration, present: present)
        try Task.checkCancellation()
        guard authorizationID == attempt else { throw GitHubAPIError.source(.cancelled) }
        let credential = GitHubCredentialReference()
        // Durable non-secret reference precedes the only new Keychain item.
        persistenceOperations += 1
        defer { persistenceOperations -= 1; finishDrainIfIdle() }
        try await preferences.reserveGitHubReference(credential)
        try Task.checkCancellation()
        guard authorizationID == attempt else { throw GitHubAPIError.source(.cancelled) }
        try await vault.save(tokens, reference: credential)
        try Task.checkCancellation()
        guard authorizationID == attempt else { throw GitHubAPIError.source(.cancelled) }
        credentialGeneration = UUID()
        let reference = GitHubSessionReference()
        active = ActiveSession(reference: reference, credential: credential, tokens: tokens)
        return reference
    }

    func resumeAfterUserAction(configuration: GitHubAppConfiguration) async throws -> GitHubSessionReference {
        guard !isShuttingDown else { throw GitHubAPIError.source(.cancelled) }
        guard !isRotating else { throw GitHubAuthorizationError.rotationInProgress }
        let attempt = UUID(); authorizationID = attempt
        guard let credential = try await preferences.snapshot().githubCredential else { throw GitHubAuthorizationError.savedSessionMissing }
        try Task.checkCancellation()
        guard !isShuttingDown, authorizationID == attempt else { throw GitHubAPIError.source(.cancelled) }
        let tokens = try await vault.readAfterUserAction(credential)
        try Task.checkCancellation()
        guard authorizationID == attempt else { throw GitHubAPIError.source(.cancelled) }
        guard tokens.clientID == configuration.clientID else { throw GitHubAuthorizationError.differentApplication }
        guard tokens.refreshExpiresAt > Date() else { throw GitHubAuthorizationError.expired }
        credentialGeneration = UUID()
        let reference = GitHubSessionReference()
        active = ActiveSession(reference: reference, credential: credential, tokens: tokens)
        return reference
    }

    /// Called under the transport lease before a batch. Refresh is accounted in the same budget.
    func prepare(_ reference: GitHubSessionReference, budget: RequestBudget) async throws {
        guard !isShuttingDown else { throw GitHubAPIError.source(.cancelled) }
        guard let current = active, current.reference == reference else { throw GitHubAPIError.source(.authenticationRequired) }
        let generation = credentialGeneration
        let remaining = await budget.timeRemaining.components
        let seconds = max(0, Double(remaining.seconds) + Double(remaining.attoseconds) / 1e18)
        try Task.checkCancellation()
        guard !isShuttingDown, active?.reference == reference, credentialGeneration == generation else {
            throw GitHubAPIError.source(.cancelled)
        }
        guard current.tokens.expiresAt <= Date().addingTimeInterval(seconds + 30) else { return }
        guard await budget.consume(reserving: 2), seconds > 0 else { throw GitHubAPIError.source(.resourceLimit) }
        try Task.checkCancellation()
        guard !isShuttingDown, active?.reference == reference, credentialGeneration == generation else {
            throw GitHubAPIError.source(.cancelled)
        }
        guard !isRotating else { throw GitHubAuthorizationError.rotationInProgress }
        isRotating = true
        defer { isRotating = false; finishDrainIfIdle() }
        // Token rotation is bounded but finishes persistence even if its caller is cancelled.
        // Disconnect invalidates this generation; shutdown only discards active memory.
        let rotation = Task { try await oauth.refresh(current.tokens, timeout: min(15, seconds)) }
        let tokens: GitHubTokenSet
        do { tokens = try await rotation.value }
        catch {
            switch error {
            case GitHubAPIError.source(.rateLimited), GitHubAPIError.source(.serviceUnavailable): break
            default: if active?.reference == reference { active = nil }
            }
            throw error
        }
        let savedReference = try await preferences.snapshot().githubCredential
        guard credentialGeneration == generation, savedReference == current.credential else {
            throw GitHubAPIError.source(.cancelled)
        }
        do { try await vault.save(tokens, reference: current.credential) }
        catch {
            if active?.reference == reference { active = nil }
            throw GitHubAPIError.source(.authenticationRequired)
        }
        guard credentialGeneration == generation else { throw GitHubAPIError.source(.cancelled) }
        if active?.reference == reference { active?.tokens = tokens }
        try Task.checkCancellation()
        guard active?.reference == reference else { throw GitHubAPIError.source(.cancelled) }
    }

    func get(_ endpoint: GitHubEndpoint, reference: GitHubSessionReference, timeout: TimeInterval) async throws -> GitHubNetworkResponse {
        guard let current = active, current.reference == reference,
              current.tokens.expiresAt > Date() else { throw GitHubAPIError.source(.authenticationRequired) }
        var components = try endpoint.components()
        components.scheme = "https"; components.host = "api.github.com"
        guard let url = components.url else { throw GitHubAPIError.source(.invalidResponse) }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(current.tokens.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2026-03-10", forHTTPHeaderField: "X-GitHub-Api-Version")
        let response = try await GitHubNetworkTransport().send(request, timeout: timeout)
        // Return rate-control headers even if invalidated; transport records them before cancellation checks.
        return response
    }

    func isCurrent(_ reference: GitHubSessionReference) -> Bool { !isShuttingDown && active?.reference == reference }

    /// Quit never starts credential work. It waits only for work already in progress.
    func discardMemoryAndDrain() async -> Bool {
        isShuttingDown = true
        discardMemory()
        guard isRotating || persistenceOperations > 0 else { return true }
        return await withCheckedContinuation { continuation in
            let id = UUID()
            let deadline = Task { [weak self] in
                do { try await Task.sleep(for: .seconds(30)) } catch { return }
                await self?.expireDrain(id)
            }
            drainWaiters.append(DrainWaiter(id: id, continuation: continuation, deadline: deadline))
        }
    }

    func cancelShutdown() { isShuttingDown = false }

    private func finishDrainIfIdle() {
        guard !isRotating, persistenceOperations == 0 else { return }
        let completed = drainWaiters; drainWaiters = []
        for waiter in completed { waiter.deadline.cancel(); waiter.continuation.resume(returning: true) }
    }

    private func expireDrain(_ id: UUID) {
        guard let index = drainWaiters.firstIndex(where: { $0.id == id }) else { return }
        let waiter = drainWaiters.remove(at: index)
        waiter.continuation.resume(returning: false)
    }

    func discardMemory(ifMatching reference: GitHubSessionReference?) {
        guard active?.reference == reference else { return }
        discardMemory()
    }

    func discardMemory() {
        authorizationID = UUID()
        active = nil
    }

    func removeAfterUserAction() async throws {
        guard !isShuttingDown else { throw GitHubAPIError.source(.cancelled) }
        persistenceOperations += 1
        defer { persistenceOperations -= 1; finishDrainIfIdle() }
        authorizationID = UUID(); credentialGeneration = UUID(); active = nil
        guard let reference = try await preferences.snapshot().githubCredential else { return }
        try await vault.removeAfterUserAction(reference)
        try await preferences.clearGitHubReference(reference)
    }
}
