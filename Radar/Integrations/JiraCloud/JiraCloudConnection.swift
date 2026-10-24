import Foundation

/// Owns the secret for one active session. Metadata consumers never receive it.
actor JiraCloudConnection {
    private let vault = CredentialVault()
    private let transport = JiraHTTPTransport()
    private let preferences: PreferencesStore
    private var token: String?
    private var qualified: JiraQualifiedConnection?
    private var reference: JiraCredentialReference?
    private var savedConfiguration: JiraConnectionConfiguration?
    private var metadataLoaded = false
    private var operationID = UUID()
    private var busy = false

    init(preferences: PreferencesStore) { self.preferences = preferences }

    func savedMetadata() async throws -> JiraSavedConfiguration? {
        try await restoreMetadata()
        guard let savedConfiguration else { return nil }
        return JiraSavedConfiguration(configuration: savedConfiguration, reference: reference)
    }

    private func restoreMetadata() async throws {
        guard !metadataLoaded else { return }
        let saved: JiraSavedConfiguration?
        do { saved = try await preferences.snapshot().jira }
        catch let error as PreferencesError { throw JiraConnectionError.preferences(error) }
        guard !metadataLoaded else { return }
        reference = saved?.reference
        savedConfiguration = saved?.configuration(policyAllowed: true)
        metadataLoaded = true
    }

    func connectAfterUserAction(configuration: JiraConnectionConfiguration, token: String, attemptID: UUID) async throws -> JiraQualifiedConnection {
        try await restoreMetadata()
        guard !busy, qualified == nil, reference == nil else { throw JiraConnectionError.removalPending }
        guard !token.isEmpty, token.utf8.count <= 16_384 else { throw JiraConnectionError.vault(.invalidSecret) }
        busy = true; operationID = attemptID
        defer { busy = false }
        do {
            let result = try await qualify(configuration: configuration, token: token, operation: attemptID)
            let reference = JiraCredentialReference()
            // Keep the pending reference in memory even if the atomic preference write fails.
            self.reference = reference; savedConfiguration = configuration
            do { try await preferences.saveJira(configuration: configuration, reference: reference) }
            catch let error as PreferencesError { throw JiraConnectionError.preferences(error) }
            try ensureCurrent(attemptID)
            do { try await vault.saveJiraToken(token, for: reference) }
            catch let error as CredentialVaultError { throw JiraConnectionError.vault(error) }
            try ensureCurrent(attemptID)
            self.token = token; qualified = result
            return result
        } catch { self.token = nil; qualified = nil; throw error }
    }

    func resumeAfterUserAction(policyAllowed: Bool, attemptID: UUID) async throws -> JiraQualifiedConnection {
        guard policyAllowed else { throw JiraConnectionError.source(.permissionDenied) }
        try await restoreMetadata()
        guard !busy else { throw JiraConnectionError.source(.cancelled) }
        guard let reference, let configuration = savedConfiguration else { throw JiraConnectionError.vault(.missing) }
        busy = true; operationID = attemptID; token = nil; qualified = nil
        defer { busy = false }
        do {
            try ensureCurrent(attemptID)
            let secret: String
            do { secret = try await vault.readJiraTokenAfterUserAction(for: reference) }
            catch let error as CredentialVaultError { throw JiraConnectionError.vault(error) }
            try ensureCurrent(attemptID)
            let result = try await qualify(configuration: configuration, token: secret, operation: attemptID)
            token = secret; qualified = result
            return result
        } catch { token = nil; qualified = nil; throw error }
    }

    private func qualify(configuration: JiraConnectionConfiguration, token: String, operation: UUID) async throws -> JiraQualifiedConnection {
        try ensureCurrent(operation)
        var tenantRequest = URLRequest(url: configuration.siteURL.appendingPathComponent("_edge/tenant_info"))
        tenantRequest.httpMethod = "GET"
        tenantRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        let tenantData = try await transport.get(tenantRequest)
        try ensureCurrent(operation)
        struct Tenant: Decodable { let cloudId: String }
        guard let tenant = try? JSONDecoder().decode(Tenant.self, from: tenantData),
              let cloudID = UUID(uuidString: tenant.cloudId),
              let identity = JiraSiteIdentity(cloudID: cloudID.uuidString.lowercased()),
              let scope = SourceScope(jiraSite: identity, projectKeys: configuration.projectKeys) else {
            throw JiraConnectionError.source(.invalidResponse)
        }
        let request = try authenticatedRequest(configuration: configuration, cloudID: cloudID, token: token, path: "myself")
        let data = try await transport.get(request)
        try ensureCurrent(operation)
        struct Myself: Decodable { let accountId: String; let active: Bool }
        guard let myself = try? JSONDecoder().decode(Myself.self, from: data),
              !myself.accountId.isEmpty, myself.active else { throw JiraConnectionError.source(.invalidResponse) }
        return JiraQualifiedConnection(configuration: configuration, cloudID: cloudID,
            accountID: myself.accountId, connectionID: ConnectionID(), scope: scope)
    }

    /// Cancellation only invalidates memory. It never silently invokes Keychain removal.
    func cancelConnection(attemptID: UUID) {
        guard operationID == attemptID else { return }
        operationID = UUID(); token = nil; qualified = nil
    }

    func removeAfterUserAction() async throws {
        try await restoreMetadata()
        guard !busy else { throw JiraConnectionError.source(.cancelled) }
        operationID = UUID(); token = nil; qualified = nil
        guard let reference else { return }
        busy = true
        defer { busy = false }
        guard !Task.isCancelled else { throw JiraConnectionError.source(.cancelled) }
        do { try await vault.removeJiraTokenAfterUserAction(for: reference) }
        catch let error as CredentialVaultError { throw JiraConnectionError.vault(error) }
        do { try await preferences.clearJiraReference(expected: reference) }
        catch let error as PreferencesError { throw JiraConnectionError.preferences(error) }
        self.reference = nil
    }

    func hasSavedReference() async -> Bool {
        // Metadata only. The form separately displays a sanitized load error.
        try? await restoreMetadata()
        return reference != nil
    }

    /// Memory-only lifecycle invalidation; pending metadata and the own vault item are untouched.
    func invalidateActiveSession() {
        operationID = UUID(); token = nil; qualified = nil
    }

    func currentConnection() throws -> JiraQualifiedConnection {
        guard let qualified, token != nil else { throw JiraConnectionError.source(.authenticationRequired) }
        return qualified
    }

    func read(expectedConnectionID: ConnectionID, path: String, query: [URLQueryItem] = []) async throws -> Data {
        guard let token, let qualified, qualified.connectionID == expectedConnectionID else { throw JiraConnectionError.source(.authenticationRequired) }
        let operation = operationID
        let request = try authenticatedRequest(configuration: qualified.configuration, cloudID: qualified.cloudID,
            token: token, path: path, query: query)
        let data = try await transport.get(request)
        try ensureCurrent(operation)
        return data
    }

    func readIssue(_ key: JiraIssueKey, expectedConnectionID: ConnectionID, budget: RequestBudget) async throws -> Data {
        guard let token, let qualified, qualified.connectionID == expectedConnectionID,
              qualified.configuration.projectKeys.contains(key.projectKey) else {
            throw JiraConnectionError.source(.authenticationRequired)
        }
        let operation = operationID
        guard await budget.consume(reserving: 1) else { throw JiraConnectionError.source(.resourceLimit) }
        let remaining = await budget.timeRemaining.components
        let timeout = min(15, Double(remaining.seconds) + Double(remaining.attoseconds) / 1e18)
        let query = [URLQueryItem(name: "fields", value: "summary,status,project,assignee,updated"),
                     URLQueryItem(name: "updateHistory", value: "false")]
        let request = try authenticatedRequest(configuration: qualified.configuration, cloudID: qualified.cloudID,
            token: token, path: "issue/" + key.rawValue, query: query)
        try ensureCurrent(operation)
        let data = try await transport.get(request, timeout: timeout)
        try ensureCurrent(operation)
        return data
    }

    private func ensureCurrent(_ operation: UUID) throws {
        guard operationID == operation, !Task.isCancelled else { throw JiraConnectionError.source(.cancelled) }
    }

    private func authenticatedRequest(configuration: JiraConnectionConfiguration, cloudID: UUID,
                                      token: String, path: String, query: [URLQueryItem] = []) throws -> URLRequest {
        let issueKey = path.hasPrefix("issue/") ? JiraIssueKey(String(path.dropFirst(6))) : nil
        guard ["myself", "search/jql"].contains(path) || issueKey.map({ configuration.projectKeys.contains($0.projectKey) }) == true else {
            throw JiraConnectionError.source(.capabilityUnavailable)
        }
        let allowedNames: Set<String> = issueKey == nil
            ? ["jql", "fields", "maxResults", "nextPageToken"] : ["fields", "updateHistory"]
        if issueKey != nil, query.first(where: { $0.name == "updateHistory" })?.value != "false" {
            throw JiraConnectionError.source(.invalidResponse)
        }
        guard query.allSatisfy({ allowedNames.contains($0.name) }), Set(query.map(\.name)).count == query.count else {
            throw JiraConnectionError.source(.invalidResponse)
        }
        let base: URL
        switch configuration.tokenKind {
        case .scoped:
            guard let gateway = URL(string: "https://api.atlassian.com/ex/jira/\(cloudID.uuidString.lowercased())") else {
                throw JiraConnectionError.source(.invalidResponse)
            }
            base = gateway
        case .legacy: base = configuration.siteURL
        }
        guard var url = URLComponents(url: base.appendingPathComponent("rest/api/3/\(path)"), resolvingAgainstBaseURL: false) else {
            throw JiraConnectionError.source(.invalidResponse)
        }
        url.queryItems = query.isEmpty ? nil : query
        guard let destination = url.url else { throw JiraConnectionError.source(.invalidResponse) }
        var request = URLRequest(url: destination)
        request.httpMethod = "GET"
        request.timeoutInterval = 15
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Basic " + Data("\(configuration.email):\(token)".utf8).base64EncodedString(), forHTTPHeaderField: "Authorization")
        return request
    }
}
