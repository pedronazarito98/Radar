import Foundation

private final class GitHubSessionDelegate: NSObject, URLSessionTaskDelegate, Sendable {
    func urlSession(_ session: URLSession, task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest,
                    completionHandler: @escaping @Sendable (URLRequest?) -> Void) {
        completionHandler(nil)
    }
}

struct GitHubNetworkResponse: Sendable {
    let status: Int
    let headers: [String: String]
    let body: Data
}

/// Only official OAuth POSTs and API GETs. No shared cache, cookie jar or credential storage.
struct GitHubNetworkTransport: Sendable {
    func send(_ request: URLRequest, timeout: TimeInterval = 15) async throws -> GitHubNetworkResponse {
        guard timeout.isFinite, timeout > 0, timeout <= 15,
              let url = request.url, let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              components.scheme == "https", components.port == nil, components.user == nil,
              components.password == nil, components.fragment == nil else { throw GitHubAPIError.source(.invalidResponse) }
        let oauth = components.host == "github.com" && request.httpMethod == "POST"
            && ["/login/device/code", "/login/oauth/access_token"].contains(components.path) && components.query == nil
        let api = components.host == "api.github.com" && request.httpMethod == "GET"
        guard oauth || api else { throw GitHubAPIError.source(.permissionDenied) }
        var request = request
        request.setValue("Radar/0.1.0", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = timeout
        let configuration = URLSessionConfiguration.ephemeral
        configuration.urlCache = nil; configuration.httpCookieStorage = nil; configuration.urlCredentialStorage = nil
        configuration.httpShouldSetCookies = false
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.timeoutIntervalForRequest = timeout; configuration.timeoutIntervalForResource = timeout
        let session = URLSession(configuration: configuration, delegate: GitHubSessionDelegate(), delegateQueue: nil)
        defer { session.invalidateAndCancel() }
        do {
            let (bytes, response) = try await session.bytes(for: request)
            guard let http = response as? HTTPURLResponse else { throw GitHubAPIError.source(.invalidResponse) }
            let permitted = ["content-type", "link", "retry-after", "x-ratelimit-remaining", "x-ratelimit-reset", "x-github-sso"]
            var headers: [String: String] = [:]
            for name in permitted { if let value = http.value(forHTTPHeaderField: name) { headers[name] = value } }
            // Retain control responses without reading error bodies or cancelling away their cooldown.
            if !(200...299).contains(http.statusCode) && !(oauth && [400, 403].contains(http.statusCode)) {
                return GitHubNetworkResponse(status: http.statusCode, headers: headers, body: Data())
            }
            try Task.checkCancellation()
            let cap = oauth ? 65_536 : 5 * 1_024 * 1_024
            guard response.expectedContentLength <= cap else { throw GitHubAPIError.source(.resourceLimit) }
            var data = Data()
            for try await byte in bytes {
                try Task.checkCancellation()
                guard data.count < cap else { throw GitHubAPIError.source(.resourceLimit) }
                data.append(byte)
            }
            return GitHubNetworkResponse(status: http.statusCode, headers: headers, body: data)
        } catch let error as GitHubAPIError { throw error }
        catch is CancellationError { throw GitHubAPIError.source(.cancelled) }
        catch let error as URLError {
            throw GitHubAPIError.source(error.code == .timedOut ? .timeout : error.code == .cancelled ? .cancelled : .networkFailure)
        } catch { throw GitHubAPIError.source(.transportUnavailable) }
    }
}
