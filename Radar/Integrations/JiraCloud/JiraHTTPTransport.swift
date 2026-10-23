import Foundation

/// Per-request ephemeral sessions hold no shared cookies, cache or credential storage.
/// Authentication redirects are refused, including redirects to the same host.
private final class JiraSessionDelegate: NSObject, URLSessionTaskDelegate, Sendable {
    func urlSession(_ session: URLSession, task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest,
                    completionHandler: @escaping @Sendable (URLRequest?) -> Void) {
        completionHandler(nil)
    }

}

struct JiraHTTPTransport: Sendable {
    func get(_ request: URLRequest) async throws -> Data {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.urlCache = nil
        configuration.httpCookieStorage = nil
        configuration.urlCredentialStorage = nil
        configuration.httpShouldSetCookies = false
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.timeoutIntervalForRequest = 15
        configuration.timeoutIntervalForResource = 15
        let session = URLSession(configuration: configuration, delegate: JiraSessionDelegate(), delegateQueue: nil)
        defer { session.invalidateAndCancel() }
        do {
            let (bytes, response) = try await session.bytes(for: request)
            try Task.checkCancellation()
            guard let http = response as? HTTPURLResponse else { throw JiraConnectionError.source(.invalidResponse) }
            switch http.statusCode {
            case 200: break
            case 401: throw JiraConnectionError.source(.authenticationRequired)
            case 403: throw JiraConnectionError.source(.permissionDenied)
            case 429:
                throw JiraConnectionError.source(.rateLimited(
                    retryAfter: retryDate(http.value(forHTTPHeaderField: "Retry-After")),
                    resetAt: http.value(forHTTPHeaderField: "X-RateLimit-Reset").flatMap { ISO8601DateFormatter().date(from: $0) }))
            default: throw JiraConnectionError.source(.remoteFailure(statusCode: http.statusCode))
            }
            let cap = 5 * 1_024 * 1_024
            guard response.expectedContentLength <= cap else { throw JiraConnectionError.source(.resourceLimit) }
            var data = Data()
            for try await byte in bytes {
                try Task.checkCancellation()
                guard data.count < cap else { throw JiraConnectionError.source(.resourceLimit) }
                data.append(byte)
            }
            return data
        } catch let error as JiraConnectionError { throw error }
        catch is CancellationError { throw JiraConnectionError.source(.cancelled) }
        catch let error as URLError {
            throw JiraConnectionError.source(error.code == .timedOut ? .timeout : error.code == .cancelled ? .cancelled : .networkFailure)
        } catch { throw JiraConnectionError.source(.transportUnavailable) }
    }

    private func retryDate(_ value: String?) -> Date? {
        guard let value else { return nil }
        if let delay = Double(value), delay.isFinite, delay >= 0 {
            return Date().addingTimeInterval(delay)
        }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss z"
        return formatter.date(from: value)
    }
}
