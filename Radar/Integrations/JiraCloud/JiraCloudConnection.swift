import Foundation

/// Owns the secret for one active session. Metadata consumers never receive it.
actor JiraCloudConnection {
    private let vault = CredentialVault()
    private let transport = JiraHTTPTransport()
    private var token: String?
    private var qualified: JiraQualifiedConnection?
    private var reference: JiraCredentialReference?
    private var operationID = UUID()
    private var busy = false

    func connectAfterUserAction(configuration: JiraConnectionConfiguration, token: String, attemptID: UUID) async throws -> JiraQualifiedConnection {
        guard !busy, qualified == nil, reference == nil else { throw JiraConnectionError.removalPending }
        guard !token.isEmpty, token.utf8.count <= 16_384 else { throw JiraConnectionError.vault(.invalidSecret) }
        busy = true
        let operation = attemptID; operationID = operation
        defer { busy = false }
        do {
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
            let reference = JiraCredentialReference()
            // Retain reference before the awaited write: cancellation must never orphan a saved item.
            self.reference = reference
            do { try await vault.saveJiraToken(token, for: reference) }
            catch let error as CredentialVaultError { throw JiraConnectionError.vault(error) }
            try ensureCurrent(operation)
            let result = JiraQualifiedConnection(configuration: configuration, cloudID: cloudID,
                accountID: myself.accountId, connectionID: ConnectionID(), scope: scope)
            self.token = token
            qualified = result
            return result
        } catch {
            self.token = nil; qualified = nil
            throw error
        }
    }

    /// Cancellation only invalidates memory. It never silently invokes Keychain removal.
    func cancelConnection(attemptID: UUID) {
        guard operationID == attemptID else { return }
        operationID = UUID()
        token = nil; qualified = nil
    }

    func removeAfterUserAction() async throws {
        guard !busy else { throw JiraConnectionError.source(.cancelled) }
        operationID = UUID(); token = nil; qualified = nil
        guard let reference else { return }
        busy = true
        defer { busy = false }
        do { try await vault.removeJiraTokenAfterUserAction(for: reference) }
        catch let error as CredentialVaultError { throw JiraConnectionError.vault(error) }
        self.reference = nil
    }

    func hasSavedReference() -> Bool { reference != nil }

    func read(path: String, query: [URLQueryItem] = []) async throws -> Data {
        guard let token, let qualified else { throw JiraConnectionError.source(.authenticationRequired) }
        let operation = operationID
        let request = try authenticatedRequest(configuration: qualified.configuration, cloudID: qualified.cloudID,
            token: token, path: path, query: query)
        let data = try await transport.get(request)
        try ensureCurrent(operation)
        return data
    }

    private func ensureCurrent(_ operation: UUID) throws {
        guard operationID == operation, !Task.isCancelled else { throw JiraConnectionError.source(.cancelled) }
    }

    private func authenticatedRequest(configuration: JiraConnectionConfiguration, cloudID: UUID,
                                      token: String, path: String, query: [URLQueryItem] = []) throws -> URLRequest {
        guard ["myself", "search/jql"].contains(path) else { throw JiraConnectionError.source(.capabilityUnavailable) }
        let allowedNames: Set<String> = ["jql", "fields", "maxResults", "nextPageToken"]
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
