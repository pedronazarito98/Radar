import Foundation

/// No provider payload, arbitrary message or credential is retained in a problem.
enum SourceProblem: Equatable, Sendable {
    case authenticationRequired
    case permissionDenied
    case singleSignOnRequired
    case rateLimited(retryAfter: Date?, resetAt: Date?)
    case serviceUnavailable(retryAfter: Date?)
    case timeout
    case cancelled
    case invalidResponse
    case capabilityUnavailable
    case transportUnavailable
    case networkFailure
    case resourceLimit
    case remoteFailure(statusCode: Int?)
}

enum SourceConnectionState: Equatable, Sendable {
    case disconnected
    case connecting
    case connected
    case requalificationRequired
    case unavailable
}

enum SourceFreshness: Equatable, Sendable {
    case neverLoaded
    case current
    case stale
}

struct SourceStatus: Equatable, Sendable {
    var connection: SourceConnectionState = .disconnected
    var isRefreshing = false
    var problem: SourceProblem?
    var freshness: SourceFreshness = .neverLoaded
}
