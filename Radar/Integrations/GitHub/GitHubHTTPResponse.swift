import Foundation

struct GitHubHTTPResponse: Sendable {
    let body: Data
    let hasNextPage: Bool
    let remainingRequests: Int?
    let resetAt: Date?

    static func parse(_ response: GitHubNetworkResponse, endpoint: GitHubEndpoint) throws -> Self {
        let status = response.status
        let headers = response.headers
        let retry = retryDate(headers["retry-after"])
        let reset = headers["x-ratelimit-reset"].flatMap(Double.init).flatMap { $0.isFinite && $0 >= 0 ? Date(timeIntervalSince1970: $0) : nil }
        let remaining = headers["x-ratelimit-remaining"].flatMap(Int.init)
        if status == 401 { throw GitHubAPIError.source(.authenticationRequired) }
        if status == 429 || (status == 403 && (remaining == 0 || headers["retry-after"] != nil)) {
            throw GitHubAPIError.source(.rateLimited(retryAfter: retry, resetAt: reset))
        }
        if status == 403 {
            let sso = headers["x-github-sso"]?.lowercased().hasPrefix("required") == true
            throw GitHubAPIError.source(sso ? .singleSignOnRequired : .permissionDenied)
        }
        if (200...299).contains(status), let sso = headers["x-github-sso"], !sso.isEmpty {
            let classification = sso.lowercased().split(separator: ";").first?.trimmingCharacters(in: .whitespaces)
            if classification == "partial-results" || classification == "required" {
                throw GitHubAPIError.source(.singleSignOnRequired)
            }
            throw GitHubAPIError.source(.invalidResponse)
        }
        if status == 503 || ((500...599).contains(status) && headers["retry-after"] != nil) {
            throw GitHubAPIError.source(.serviceUnavailable(retryAfter: retry))
        }
        guard (200...299).contains(status) else { throw GitHubAPIError.source(.remoteFailure(statusCode: status)) }
        guard let contentType = headers["content-type"]?.lowercased().split(separator: ";").first?.trimmingCharacters(in: .whitespaces),
              ["application/json", "application/vnd.github+json"].contains(contentType) else {
            throw GitHubAPIError.source(.invalidResponse)
        }
        let next = try hasNext(headers["link"], endpoint: endpoint)
        return Self(body: response.body, hasNextPage: next, remainingRequests: remaining, resetAt: reset)
    }

    private static func hasNext(_ value: String?, endpoint: GitHubEndpoint) throws -> Bool {
        guard let value else { return false }
        let original = try endpoint.components()
        let originalQuery = Dictionary(uniqueKeysWithValues: (original.queryItems ?? []).map { ($0.name, $0.value ?? "") })
        var next = false
        for part in value.components(separatedBy: ",") {
            let pieces = part.components(separatedBy: ";")
            guard let target = pieces.first?.trimmingCharacters(in: .whitespaces), target.hasPrefix("<"), target.hasSuffix(">"),
                  let url = URLComponents(string: String(target.dropFirst().dropLast())), url.scheme == "https", url.host == "api.github.com",
                  url.port == nil, url.user == nil, url.password == nil, url.fragment == nil, url.path == original.path else {
                throw GitHubAPIError.source(.invalidResponse)
            }
            var normalized = url
            // Link query uses form encoding: raw '+' is a space; encoded %2B stays literal.
            normalized.percentEncodedQuery = url.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%20")
            let items = normalized.queryItems ?? []
            guard Set(items.map(\.name)).count == items.count else { throw GitHubAPIError.source(.invalidResponse) }
            var query = Dictionary(uniqueKeysWithValues: items.map { ($0.name, $0.value ?? "") })
            let page = query.removeValue(forKey: "page").flatMap(Int.init)
            var expected = originalQuery; let current = expected.removeValue(forKey: "page").flatMap(Int.init)
            guard query == expected, let page, page > 0, let current else { throw GitHubAPIError.source(.invalidResponse) }
            if pieces.dropFirst().contains(where: { $0.trimmingCharacters(in: .whitespaces) == "rel=\"next\"" }) {
                guard page == current + 1, !next else { throw GitHubAPIError.source(.invalidResponse) }
                next = true
            }
        }
        return next
    }

    static func retryDate(_ value: String?) -> Date? {
        guard let value else { return nil }
        if let number = Double(value), number.isFinite, number >= 0 { return Date().addingTimeInterval(number) }
        let parser = DateFormatter()
        parser.locale = Locale(identifier: "en_US_POSIX"); parser.timeZone = TimeZone(secondsFromGMT: 0)
        parser.dateFormat = "EEE, dd MMM yyyy HH:mm:ss z"
        return parser.date(from: value)
    }
}
