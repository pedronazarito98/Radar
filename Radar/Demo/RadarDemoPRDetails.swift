import Foundation

@MainActor
enum RadarDemoPRDetails {
    static func publish(_ item: PullRequestItem, into store: PRDetailStore, limited: Bool) {
        guard let request = store.beginRefresh(),
              let sha = GitCommitSHA(String(repeating: String(item.id.number % 10), count: 40)),
              let user = GitHubUserID(1), let reviewer = GitHubUserID(2),
              let version = store.observeHead(sha, lifecycle: item.lifecycle, at: Date(), for: request) else { return }
        let coverage: ObservationCoverage = limited ? .unavailable(.permissionDenied) : .complete
        let states: [CISignalState]
        switch item.id.number {
        case 81, 24: states = [.success, .success]
        case 82: states = [.success, .inProgress]
        case 23: states = [.success, .failure]
        case 15: states = [.success, .skipped]
        default: states = []
        }
        let signals = limited ? [] : states.enumerated().map { index, state in
            CISignal(origin: .checkRun(id: Int64(index + 1), name: index == 0 ? "Build" : "Verificação de interface"),
                     headSHA: sha, state: state)
        }
        let reviews: [PullRequestReview]
        if !limited, [81, 23, 24].contains(item.id.number) {
            reviews = [PullRequestReview(id: 1, authorID: reviewer,
                state: item.id.number == 23 ? .changesRequested : .approved,
                commitSHA: sha, submittedAt: Date().addingTimeInterval(-600))]
        } else { reviews = [] }
        let requestedUsers: Set<GitHubUserID> = item.personalRoles.contains(.directlyRequestedReviewer) ? [user] : []
        let review = ReviewReport(headSHA: sha,
            requests: ReviewRequests(users: limited ? [] : requestedUsers, teams: [], coverage: coverage),
            reviews: reviews, coverage: coverage, authenticatedUserID: user)
        guard let ci = CIReport(headSHA: sha, signals: signals, coverage: coverage),
              let details = PRDetails(version: version, lifecycle: item.lifecycle, ci: ci, review: review) else { return }
        store.publish(details, problem: limited ? .permissionDenied : nil, for: request)
    }
}
