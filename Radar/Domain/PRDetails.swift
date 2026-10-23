import Foundation

enum ObservationUnavailableReason: Equatable, Sendable {
    case permissionDenied
    case capabilityUnavailable
    case invalidResponse
    case requestFailed
}

enum ObservationCoverage: Equatable, Sendable {
    case complete
    case partial
    case unavailable(ObservationUnavailableReason)
}

struct PRDetailVersion: Hashable, Sendable {
    let contextID: WorkContextID
    let pullRequestID: PullRequestIdentity
    let selectionGeneration: UInt64
    let detailGeneration: UInt64
    let headSHA: GitCommitSHA
    let observedAt: Date
}

struct PRDetails: Equatable, Sendable {
    let version: PRDetailVersion
    let lifecycle: PullRequestLifecycle
    let ci: CIReport
    let review: ReviewReport

    init?(version: PRDetailVersion, lifecycle: PullRequestLifecycle, ci: CIReport, review: ReviewReport) {
        guard ci.headSHA == version.headSHA, review.headSHA == version.headSHA else { return nil }
        self.version = version
        self.lifecycle = lifecycle
        self.ci = ci
        self.review = review
    }
}
