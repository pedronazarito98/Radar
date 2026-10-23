import Foundation

struct RefreshScheduleKey: Hashable, Sendable {
    enum Kind: Hashable, Sendable {
        case personalList
        case detail(SelectionKey)
    }

    let contextID: WorkContextID
    let scope: SourceScope
    let kind: Kind

    var interval: TimeInterval {
        switch kind {
        case .personalList: 60
        case .detail: 15
        }
    }
}

struct RefreshOutcome: Sendable {
    let problems: [SourceProblem]

    /// Every query contributes; the problem chosen for UI is not a retry policy.
    func retryDeadline(at now: Date) -> Date? {
        problems.compactMap { problem -> Date? in
            guard case let .rateLimited(retryAfter, resetAt) = problem else { return nil }
            return [retryAfter, resetAt].compactMap { $0 }.max()
                .map { max($0, now.addingTimeInterval(1)) }
                ?? now.addingTimeInterval(60)
        }.max()
    }
}
