import Foundation
import Observation

@MainActor
@Observable
final class PRDetailStore {
    private(set) var observedHead: PRHeadObservation?
    private(set) var details: PRDetails?
    private(set) var isRefreshing = false
    private(set) var problem: SourceProblem?
    private(set) var activeRequest: PRDetailRequestToken?
    private var selection: SelectionToken?
    private var detailGeneration: UInt64 = 0

    func reset(for selection: SelectionToken?) {
        self.selection = selection
        observedHead = nil
        details = nil
        isRefreshing = false
        problem = nil
        activeRequest = nil
    }

    func beginRefresh() -> PRDetailRequestToken? {
        guard let selection, case let .pullRequest(identity) = selection.key.itemID else { return nil }
        precondition(detailGeneration < .max, "Detail generation exhausted")
        detailGeneration += 1
        let request = PRDetailRequestToken(
            selection: selection, pullRequestID: identity, detailGeneration: detailGeneration
        )
        activeRequest = request
        isRefreshing = true
        return request
    }

    func isCurrent(_ request: PRDetailRequestToken) -> Bool {
        activeRequest == request && selection == request.selection
    }

    /// Bind one observed head per request; another head observation starts a new refresh.
    func observeHead(
        _ headSHA: GitCommitSHA, lifecycle: PullRequestLifecycle, at observedAt: Date,
        for request: PRDetailRequestToken
    ) -> PRDetailVersion? {
        guard isCurrent(request), observedHead?.version.detailGeneration != request.detailGeneration else { return nil }
        let version = PRDetailVersion(
            contextID: request.selection.key.contextID, pullRequestID: request.pullRequestID,
            selectionGeneration: request.selection.generation, detailGeneration: request.detailGeneration,
            headSHA: headSHA, observedAt: observedAt
        )
        observedHead = PRHeadObservation(version: version, lifecycle: lifecycle)
        if details?.version.headSHA != headSHA { details = nil }
        return version
    }

    @discardableResult
    func publish(_ details: PRDetails, for request: PRDetailRequestToken) -> Bool {
        guard isCurrent(request), observedHead?.version == details.version,
              observedHead?.lifecycle == details.lifecycle else { return false }
        self.details = details
        activeRequest = nil
        isRefreshing = false
        problem = nil
        return true
    }

    @discardableResult
    func finish(with problem: SourceProblem, for request: PRDetailRequestToken) -> Bool {
        guard isCurrent(request) else { return false }
        activeRequest = nil
        isRefreshing = false
        self.problem = problem
        return true
    }
}
