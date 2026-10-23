import Foundation

struct GitHubHTTPResponse: Sendable {
    let body: Data
    let hasNextPage: Bool
    let remainingRequests: Int?
    let resetAt: Date?

    static func parse(_ result: GitHubProcessResult, endpoint: GitHubEndpoint) throws -> Self {
        if result.exitCode == 4 { throw GitHubCLIError.source(.authenticationRequired) }
        let separators = [Data("\r\n\r\n".utf8), Data("\n\n".utf8)]
        guard let boundary = separators.compactMap({ result.output.range(of: $0) }).min(by: { $0.lowerBound < $1.lowerBound }),
              boundary.lowerBound <= 65_536,
              let header = String(data: result.output[..<boundary.lowerBound], encoding: .utf8) else {
            throw GitHubCLIError.source(result.exitCode == 0 ? .invalidResponse : .transportUnavailable)
        }
        let lines = header.components(separatedBy: .newlines).filter { !$0.isEmpty }
        guard let first = lines.first, first.hasPrefix("HTTP/"),
              let status = first.split(separator: " ").dropFirst().first.flatMap({ Int($0) }) else {
            throw GitHubCLIError.source(.invalidResponse)
        }
        let allowed: Set<String> = ["content-type", "link", "retry-after", "x-ratelimit-remaining", "x-ratelimit-reset", "x-ratelimit-resource", "x-github-sso"]
        var headers: [String: String] = [:]
        for line in lines.dropFirst() {
            guard let colon = line.firstIndex(of: ":") else { continue }
            let name = line[..<colon].lowercased()
            guard allowed.contains(name) else { continue }
            let value = line[line.index(after: colon)...].trimmingCharacters(in: .whitespaces)
            if name == "link", let previous = headers[name] { headers[name] = previous + "," + value }
            else if let previous = headers[name], previous != value { throw GitHubCLIError.source(.invalidResponse) }
            else { headers[name] = value }
        }
        let retry = retryDate(headers["retry-after"])
        let reset = headers["x-ratelimit-reset"].flatMap(Double.init).flatMap { $0.isFinite && $0 >= 0 ? Date(timeIntervalSince1970: $0) : nil }
        let remaining = headers["x-ratelimit-remaining"].flatMap(Int.init)
        if status == 401 { throw GitHubCLIError.source(.authenticationRequired) }
        if status == 429 || (status == 403 && (remaining == 0 || headers["retry-after"] != nil)) {
            throw GitHubCLIError.source(.rateLimited(retryAfter: retry, resetAt: reset))
        }
        if status == 403 {
            let sso = headers["x-github-sso"]?.lowercased().hasPrefix("required") == true
            throw GitHubCLIError.source(sso ? .singleSignOnRequired : .permissionDenied)
        }
        if status == 503 || ((500...599).contains(status) && headers["retry-after"] != nil) {
            throw GitHubCLIError.source(.serviceUnavailable(retryAfter: retry))
        }
        guard (200...299).contains(status), result.exitCode == 0 else { throw GitHubCLIError.source(.remoteFailure(statusCode: status)) }
        guard let contentType = headers["content-type"]?.lowercased().split(separator: ";").first?.trimmingCharacters(in: .whitespaces),
              ["application/json", "application/vnd.github+json"].contains(contentType) else {
            throw GitHubCLIError.source(.invalidResponse)
        }
        let next = try hasNext(headers["link"], endpoint: endpoint)
        return Self(body: Data(result.output[boundary.upperBound...]), hasNextPage: next, remainingRequests: remaining, resetAt: reset)
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
                throw GitHubCLIError.source(.invalidResponse)
            }
            var normalized = url
            // Link query uses form encoding: raw '+' is a space; encoded %2B stays literal.
            normalized.percentEncodedQuery = url.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%20")
            let items = normalized.queryItems ?? []
            guard Set(items.map(\.name)).count == items.count else { throw GitHubCLIError.source(.invalidResponse) }
            var query = Dictionary(uniqueKeysWithValues: items.map { ($0.name, $0.value ?? "") })
            let page = query.removeValue(forKey: "page").flatMap(Int.init)
            var expected = originalQuery; let current = expected.removeValue(forKey: "page").flatMap(Int.init)
            guard query == expected, let page, page > 0, let current else { throw GitHubCLIError.source(.invalidResponse) }
            if pieces.dropFirst().contains(where: { $0.trimmingCharacters(in: .whitespaces) == "rel=\"next\"" }) {
                guard page == current + 1, !next else { throw GitHubCLIError.source(.invalidResponse) }
                next = true
            }
        }
        return next
    }

    private static func retryDate(_ value: String?) -> Date? {
        guard let value else { return nil }
        if let number = Double(value), number.isFinite, number >= 0 { return Date().addingTimeInterval(number) }
        let parser = DateFormatter()
        parser.locale = Locale(identifier: "en_US_POSIX"); parser.timeZone = TimeZone(secondsFromGMT: 0)
        parser.dateFormat = "EEE, dd MMM yyyy HH:mm:ss z"
        return parser.date(from: value)
    }
}
