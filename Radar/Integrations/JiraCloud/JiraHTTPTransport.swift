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
    func get(_ request: URLRequest, timeout: TimeInterval = 15) async throws -> Data {
        guard timeout.isFinite, timeout > 0, timeout <= 15 else { throw JiraConnectionError.source(.timeout) }
        var request = request
        request.timeoutInterval = timeout
        let configuration = URLSessionConfiguration.ephemeral
        configuration.urlCache = nil
        configuration.httpCookieStorage = nil
        configuration.urlCredentialStorage = nil
        configuration.httpShouldSetCookies = false
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.timeoutIntervalForRequest = timeout
        configuration.timeoutIntervalForResource = timeout
        let session = URLSession(configuration: configuration, delegate: JiraSessionDelegate(), delegateQueue: nil)
        defer { session.invalidateAndCancel() }
        do {
            let (bytes, response) = try await session.bytes(for: request)
            guard let http = response as? HTTPURLResponse else { throw JiraConnectionError.source(.invalidResponse) }
            switch http.statusCode {
            case 200: break
            case 401: throw JiraConnectionError.source(.authenticationRequired)
            case 403: throw JiraConnectionError.source(.permissionDenied)
            case 429:
                throw JiraConnectionError.source(.rateLimited(
                    retryAfter: retryDate(http.value(forHTTPHeaderField: "Retry-After")),
                    resetAt: resetDate(http.value(forHTTPHeaderField: "X-RateLimit-Reset"))))
            case 503: throw JiraConnectionError.source(.serviceUnavailable(retryAfter: retryDate(http.value(forHTTPHeaderField: "Retry-After"))))
            case 500...599 where http.value(forHTTPHeaderField: "Retry-After") != nil:
                throw JiraConnectionError.source(.serviceUnavailable(retryAfter: retryDate(http.value(forHTTPHeaderField: "Retry-After"))))
            default: throw JiraConnectionError.source(.remoteFailure(statusCode: http.statusCode))
            }
            // Preserve received rate/availability control errors even if cancellation arrived with headers.
            try Task.checkCancellation()
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

    private func resetDate(_ value: String?) -> Date? {
        guard let value else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: value) { return date }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: value)
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
