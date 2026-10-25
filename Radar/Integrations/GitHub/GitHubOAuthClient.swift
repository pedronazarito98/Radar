import Foundation

/// Only this public challenge reaches presentation. Device code and bearer tokens never do.
struct GitHubDeviceChallenge: Sendable {
    let userCode: String
    let expiresAt: Date
}

struct GitHubTokenSet: Codable, Sendable {
    let clientID: String
    let accessToken: String
    let refreshToken: String
    let expiresAt: Date
    let refreshExpiresAt: Date

    var isStructurallyValid: Bool {
        !clientID.isEmpty && clientID.utf8.count <= 128
            && Self.validSecret(accessToken) && Self.validSecret(refreshToken)
            && expiresAt.timeIntervalSince1970.isFinite && refreshExpiresAt.timeIntervalSince1970.isFinite
            && refreshExpiresAt > expiresAt
    }

    private static func validSecret(_ value: String) -> Bool {
        !value.isEmpty && value.utf8.count <= 16_384 && !value.contains(where: { $0.isWhitespace || $0.isNewline })
            && value.utf8.allSatisfy { (33...126).contains($0) }
    }
}

actor GitHubOAuthClient {
    private var cooldown: (deadline: Date, problem: SourceProblem)?
    private struct DeviceResponse: Decodable {
        let device_code: String
        let user_code: String
        let verification_uri: String
        let expires_in: Int
        let interval: Int
    }
    private struct TokenResponse: Decodable {
        let access_token: String?
        let refresh_token: String?
        let expires_in: Int?
        let refresh_token_expires_in: Int?
        let token_type: String?
        let scope: String?
        let error: String?
        let interval: Int?

        func tokens(clientID: String) throws -> GitHubTokenSet {
            guard error == nil, let access_token, let refresh_token,
                  let expires_in, (60...86_400).contains(expires_in),
                  let refresh_token_expires_in, (expires_in...31_536_000).contains(refresh_token_expires_in),
                  token_type?.lowercased() == "bearer", scope == nil || scope == "" else {
                throw GitHubAuthorizationError.invalidResponse
            }
            let now = Date()
            let tokens = GitHubTokenSet(clientID: clientID, accessToken: access_token, refreshToken: refresh_token,
                expiresAt: now.addingTimeInterval(Double(expires_in)),
                refreshExpiresAt: now.addingTimeInterval(Double(refresh_token_expires_in)))
            guard tokens.isStructurallyValid else { throw GitHubAuthorizationError.invalidResponse }
            return tokens
        }
    }

    func authorize(configuration: GitHubAppConfiguration,
                   present: @escaping @MainActor @Sendable (GitHubDeviceChallenge) -> Void) async throws -> GitHubTokenSet {
        let data = try await post(path: "/login/device/code", values: ["client_id": configuration.clientID, "scope": "offline_access"])
        guard let device = try? JSONDecoder().decode(DeviceResponse.self, from: data),
              (1...900).contains(device.expires_in), (1...300).contains(device.interval),
              (1...256).contains(device.device_code.utf8.count),
              device.device_code.utf8.allSatisfy({ (33...126).contains($0) }),
              device.user_code.count == 9, device.user_code[device.user_code.index(device.user_code.startIndex, offsetBy: 4)] == "-",
              device.user_code.utf8.allSatisfy({ (65...90).contains($0) || (48...57).contains($0) || $0 == 45 }),
              device.verification_uri == GitHubAppConfiguration.verificationURL.absoluteString else {
            throw GitHubAuthorizationError.configurationRejected
        }
        let deadline = ContinuousClock.now.advanced(by: .seconds(device.expires_in))
        try Task.checkCancellation()
        await present(GitHubDeviceChallenge(userCode: device.user_code, expiresAt: Date().addingTimeInterval(Double(device.expires_in))))
        var interval = device.interval
        while ContinuousClock.now < deadline {
            try await Task.sleep(until: min(ContinuousClock.now.advanced(by: .seconds(interval)), deadline), clock: .continuous)
            try Task.checkCancellation()
            let remaining = ContinuousClock.now.duration(to: deadline).components
            let seconds = Double(remaining.seconds) + Double(remaining.attoseconds) / 1e18
            guard seconds > 0 else { throw GitHubAuthorizationError.expired }
            let body = try await post(path: "/login/oauth/access_token", values: ["client_id": configuration.clientID,
                "device_code": device.device_code, "grant_type": "urn:ietf:params:oauth:grant-type:device_code"], timeout: min(15, seconds))
            guard let response = try? JSONDecoder().decode(TokenResponse.self, from: body) else { throw GitHubAuthorizationError.invalidResponse }
            try Task.checkCancellation()
            guard ContinuousClock.now < deadline else { throw GitHubAuthorizationError.expired }
            switch response.error {
            case "authorization_pending": continue
            case "slow_down":
                interval = max(interval + 5, response.interval ?? 0)
                guard interval <= 300 else { throw GitHubAuthorizationError.unavailable }
            case "access_denied": throw GitHubAuthorizationError.denied
            case "expired_token", "token_expired": throw GitHubAuthorizationError.expired
            case nil: return try response.tokens(clientID: configuration.clientID)
            default: throw GitHubAuthorizationError.configurationRejected
            }
        }
        throw GitHubAuthorizationError.expired
    }

    func refresh(_ current: GitHubTokenSet, timeout: TimeInterval) async throws -> GitHubTokenSet {
        guard current.refreshExpiresAt > Date().addingTimeInterval(30) else { throw GitHubAPIError.source(.authenticationRequired) }
        let body = try await post(path: "/login/oauth/access_token", values: ["client_id": current.clientID,
            "grant_type": "refresh_token", "refresh_token": current.refreshToken], timeout: timeout)
        guard let response = try? JSONDecoder().decode(TokenResponse.self, from: body) else { throw GitHubAuthorizationError.invalidResponse }
        if response.error != nil { throw GitHubAPIError.source(.authenticationRequired) }
        return try response.tokens(clientID: current.clientID)
    }

    private func post(path: String, values: [String: String], timeout: TimeInterval = 15) async throws -> Data {
        try Task.checkCancellation()
        if let cooldown, cooldown.deadline > Date() { throw GitHubAPIError.source(cooldown.problem) }
        cooldown = nil
        var request = URLRequest(url: URL(string: "https://github.com\(path)")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        var form = URLComponents()
        form.queryItems = values.sorted(by: { $0.key < $1.key }).map { URLQueryItem(name: $0.key, value: $0.value) }
        request.httpBody = Data((form.percentEncodedQuery ?? "").replacingOccurrences(of: "+", with: "%2B").utf8)
        let response = try await GitHubNetworkTransport().send(request, timeout: timeout)
        let retry = GitHubHTTPResponse.retryDate(response.headers["retry-after"])
        if response.status == 429 || (response.status == 403 && response.headers["retry-after"] != nil) {
            let problem = SourceProblem.rateLimited(retryAfter: retry, resetAt: nil)
            recordBackoff(problem)
            throw GitHubAPIError.source(problem)
        }
        if response.status >= 500 {
            let problem = SourceProblem.serviceUnavailable(retryAfter: retry)
            recordBackoff(problem)
            throw GitHubAPIError.source(problem)
        }
        guard [200, 400, 403].contains(response.status) else { throw GitHubAuthorizationError.configurationRejected }
        guard response.headers["content-type"]?.lowercased().hasPrefix("application/json") == true else {
            throw GitHubAuthorizationError.invalidResponse
        }
        return response.body
    }

    private func recordBackoff(_ problem: SourceProblem) {
        guard let deadline = RefreshOutcome(problems: [problem]).retryDeadline(at: Date()) else { return }
        if deadline > (cooldown?.deadline ?? .distantPast) { cooldown = (deadline, problem) }
    }
}
