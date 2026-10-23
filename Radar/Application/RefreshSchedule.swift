import Foundation

struct RefreshScheduleKey: Hashable, Sendable {
    enum Kind: Hashable, Sendable {
        case personalList
        case detail(SelectionKey)
        case relations(SelectionKey)
    }

    let contextID: WorkContextID
    let scope: SourceScope
    let kind: Kind

    var interval: TimeInterval? {
        switch kind {
        case .personalList: 60
        case .detail: 15
        case .relations: nil
        }
    }
}

struct RefreshOutcome: Sendable {
    let problems: [SourceProblem]
    let originProblems: [OriginProblem]

    init(problems: [SourceProblem] = [], originProblems: [OriginProblem] = []) {
        self.problems = problems; self.originProblems = originProblems
    }

    func byOrigin(default source: WorkSource) -> [OriginProblem] {
        problems.map { OriginProblem(source: source, problem: $0) } + originProblems
    }

    /// Every query contributes; the problem chosen for UI is not a retry policy.
    func retryDeadline(at now: Date) -> Date? {
        problems.compactMap { problem -> Date? in
            let deadlines: [Date?]
            switch problem {
            case let .rateLimited(retryAfter, resetAt): deadlines = [retryAfter, resetAt]
            case let .serviceUnavailable(retryAfter): deadlines = [retryAfter]
            default: return nil
            }
            return deadlines.compactMap { $0 }.max()
                .map { max($0, now.addingTimeInterval(1)) }
                ?? now.addingTimeInterval(60)
        }.max()
    }
}
