import Foundation

/// Shared by serial requests in a bounded operation; time is monotonic.
actor RequestBudget {
    private var remainingCalls: Int
    private let deadline: ContinuousClock.Instant

    init(maximumCalls: Int, duration: Duration) {
        remainingCalls = max(0, maximumCalls)
        deadline = ContinuousClock.now.advanced(by: duration)
    }

    func consume(reserving reserve: Int = 0) -> Bool {
        guard reserve >= 0, remainingCalls > reserve, ContinuousClock.now < deadline else { return false }
        remainingCalls -= 1
        return true
    }

    var timeRemaining: Duration { max(.zero, ContinuousClock.now.duration(to: deadline)) }
}
