import Foundation

enum CISignalOrigin: Hashable, Sendable {
    case checkRun(id: Int64, name: String)
    case commitStatus(context: String)
}

enum CISignalState: Equatable, Sendable {
    case success, failure, error, timedOut, actionRequired
    case queued, pending, inProgress, waiting
    case cancelled, neutral, skipped, unknown
}

struct CISignal: Equatable, Sendable {
    let origin: CISignalOrigin
    let headSHA: GitCommitSHA
    let state: CISignalState
}

enum CISummary: Equatable, Sendable {
    case failureObserved
    case actionRequired
    case inProgress
    case cancelled
    case unavailable
    case passed
    case noChecks
    case mixedNeutralResults
    case neutralOrSkipped
}

/// The provider must supply the latest runs/status per context, never mixed rerun history.
/// Ambiguous ordering/pagination is partial coverage, not a fabricated winner.
struct CIReport: Equatable, Sendable {
    let headSHA: GitCommitSHA
    let signals: [CISignal]
    let coverage: ObservationCoverage

    init?(headSHA: GitCommitSHA, signals: [CISignal], coverage: ObservationCoverage) {
        guard signals.allSatisfy({ $0.headSHA == headSHA }) else { return nil }
        self.headSHA = headSHA
        self.signals = signals
        self.coverage = coverage
    }

    var summary: CISummary {
        let states = signals.map(\.state)
        if states.contains(where: { [.failure, .error, .timedOut].contains($0) }) {
            return .failureObserved
        }
        if states.contains(.actionRequired) { return .actionRequired }
        if states.contains(where: { [.queued, .pending, .inProgress, .waiting].contains($0) }) {
            return .inProgress
        }
        if states.contains(.cancelled) { return .cancelled }
        guard coverage == .complete, !states.contains(.unknown) else { return .unavailable }
        guard !states.isEmpty else { return .noChecks }
        if states.allSatisfy({ $0 == .success }) { return .passed }
        if states.allSatisfy({ $0 == .neutral || $0 == .skipped }) { return .neutralOrSkipped }
        return .mixedNeutralResults
    }
}
