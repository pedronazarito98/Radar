import Foundation

struct ReviewRequests: Equatable, Sendable {
    let users: Set<GitHubUserID>
    let teams: Set<GitHubTeamID>
    let coverage: ObservationCoverage

    var hasKnownRequests: Bool { !users.isEmpty || !teams.isEmpty }
}

enum PullRequestReviewState: Equatable, Sendable {
    case approved, changesRequested, commented, pending, dismissed, unknown

    var isFormalDecision: Bool {
        self == .approved || self == .changesRequested || self == .dismissed
    }
}

struct PullRequestReview: Equatable, Sendable {
    let id: Int64
    let authorID: GitHubUserID?
    let state: PullRequestReviewState
    let commitSHA: GitCommitSHA?
    let submittedAt: Date?
}

enum ReviewSummary: Equatable, Sendable {
    case changesRequested(Int)
    case approvalsRecorded(Int)
    case awaitingReview
    case noCurrentDecision
    case unavailable
}

struct ReviewDecisionCounts: Equatable, Sendable {
    let approvals: Int
    let changesRequested: Int
    let previousCommitReviews: Int
    let hasAmbiguity: Bool
}

/// These are recorded decisions, never a branch-protection or merge-readiness result.
struct ReviewReport: Equatable, Sendable {
    let headSHA: GitCommitSHA
    let requests: ReviewRequests
    let reviews: [PullRequestReview]
    let coverage: ObservationCoverage
    let decisions: ReviewDecisionCounts

    init(headSHA: GitCommitSHA, requests: ReviewRequests, reviews: [PullRequestReview], coverage: ObservationCoverage) {
        self.headSHA = headSHA
        self.requests = requests
        self.reviews = reviews
        self.coverage = coverage
        decisions = Self.evaluate(reviews, headSHA: headSHA)
    }

    var summary: ReviewSummary {
        guard coverage == .complete, requests.coverage == .complete,
              !decisions.hasAmbiguity else { return .unavailable }
        if decisions.changesRequested > 0 { return .changesRequested(decisions.changesRequested) }
        if decisions.approvals > 0 { return .approvalsRecorded(decisions.approvals) }
        if requests.hasKnownRequests { return .awaitingReview }
        return .noCurrentDecision
    }

    private static func evaluate(_ reviews: [PullRequestReview], headSHA: GitCommitSHA) -> ReviewDecisionCounts {
        var unique: [Int64: PullRequestReview] = [:]
        var ambiguous = false
        for review in reviews {
            guard review.id > 0 else {
                ambiguous = true
                continue
            }
            if let previous = unique[review.id], previous != review { ambiguous = true }
            unique[review.id] = review
            if review.state == .unknown { ambiguous = true }
        }
        let formal = unique.values.filter { $0.state.isFormalDecision }
        if formal.contains(where: { $0.commitSHA == nil }) { ambiguous = true }
        let current = formal.filter { $0.commitSHA == headSHA }
        let previousCount = unique.values.filter {
            $0.submittedAt != nil && $0.commitSHA != nil && $0.commitSHA != headSHA
        }.count
        var approvals = 0
        var changes = 0

        for (author, records) in Dictionary(grouping: current, by: \.authorID) {
            guard author != nil, records.allSatisfy({ $0.submittedAt != nil }),
                  let latestDate = records.compactMap(\.submittedAt).max() else {
                ambiguous = true
                continue
            }
            let latest = records.filter { $0.submittedAt == latestDate }
            guard latest.count == 1, let decision = latest.first else {
                ambiguous = true
                continue
            }
            // A dismissed latest record suppresses earlier decisions on this observed SHA.
            guard decision.state != .dismissed else { continue }
            if decision.state == .approved { approvals += 1 }
            if decision.state == .changesRequested { changes += 1 }
        }
        return ReviewDecisionCounts(
            approvals: approvals, changesRequested: changes,
            previousCommitReviews: previousCount, hasAmbiguity: ambiguous
        )
    }
}
