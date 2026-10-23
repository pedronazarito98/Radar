import Foundation

/// Owns scheduling only. Providers perform nonblocking I/O and guard publication separately.
@MainActor
final class RefreshScheduler {
    typealias Operation = @MainActor () async -> RefreshOutcome

    private struct Entry {
        var operation: Operation
        var eligible: Bool
        var nextRun: Date
        var generation = UUID()
        var runningID: UUID?
        var running: Task<Void, Never>?
        var wakeup: Task<Void, Never>?
        var removalRequested = false
    }

    private var entries: [RefreshScheduleKey: Entry] = [:]
    private var sleeping = false
    private var cooldowns: [WorkSource: Date] = [:]

    func configure(_ key: RefreshScheduleKey, eligible: Bool, operation: @escaping Operation) {
        if case let .detail(selection) = key.kind, selection.contextID != key.contextID { return }
        if var entry = entries[key] {
            entry.operation = operation
            entry.eligible = eligible
            entry.removalRequested = false
            entries[key] = entry
        } else {
            entries[key] = Entry(operation: operation, eligible: eligible, nextRun: Date())
        }
        if !eligible { entries[key]?.running?.cancel() }
        schedule(key)
    }

    /// Repeated requests coalesce into the operation already in flight.
    func request(_ key: RefreshScheduleKey) {
        guard var entry = entries[key], entry.eligible, !entry.removalRequested,
              entry.runningID == nil else { return }
        entry.nextRun = Date()
        entries[key] = entry
        schedule(key)
    }

    func remove(_ key: RefreshScheduleKey) {
        guard var entry = entries[key] else { return }
        entry.eligible = false
        entry.removalRequested = true
        entry.wakeup?.cancel()
        entry.wakeup = nil
        entry.running?.cancel()
        // Keep the occupied slot until cancellation actually completes.
        entries[key] = entry.runningID == nil ? nil : entry
    }

    func removeAll() {
        for key in Array(entries.keys) { remove(key) }
    }

    func suspendForSleep() {
        sleeping = true
        for key in Array(entries.keys) {
            entries[key]?.wakeup?.cancel()
            entries[key]?.wakeup = nil
            entries[key]?.running?.cancel()
        }
    }

    func resumeAfterWake() {
        guard sleeping else { return }
        sleeping = false
        for key in Array(entries.keys) {
            entries[key]?.nextRun = Date()
            schedule(key)
        }
    }

    private func schedule(_ key: RefreshScheduleKey) {
        guard var entry = entries[key] else { return }
        entry.wakeup?.cancel()
        entry.wakeup = nil
        entries[key] = entry
        guard !sleeping, entry.eligible, !entry.removalRequested, entry.runningID == nil else { return }
        purgeExpiredCooldowns()
        let deadline = max(entry.nextRun, cooldowns[key.scope.source] ?? .distantPast)
        let delay = deadline.timeIntervalSinceNow
        if delay <= 0 {
            start(key)
            return
        }
        let generation = entry.generation
        entries[key]?.wakeup = Task { [weak self] in
            do { try await Task.sleep(for: .seconds(min(delay, 3_600))) }
            catch { return }
            guard let self, !Task.isCancelled, self.entries[key]?.generation == generation else { return }
            self.schedule(key)
        }
    }

    private func start(_ key: RefreshScheduleKey) {
        guard let entry = entries[key], entry.runningID == nil, entry.eligible,
              !entry.removalRequested, !sleeping else { return }
        purgeExpiredCooldowns()
        if let deadline = cooldowns[key.scope.source], deadline > Date() {
            schedule(key)
            return
        }
        let runID = UUID()
        entries[key]?.runningID = runID
        entries[key]?.running = Task { [weak self, operation = entry.operation] in
            guard !Task.isCancelled else {
                self?.finish(key, runID: runID, outcome: RefreshOutcome(problems: [.cancelled]))
                return
            }
            let outcome = await operation()
            self?.finish(key, runID: runID, outcome: outcome)
        }
    }

    private func finish(_ key: RefreshScheduleKey, runID: UUID, outcome: RefreshOutcome) {
        guard var entry = entries[key], entry.runningID == runID else { return }
        let now = Date()
        purgeExpiredCooldowns()
        if let deadline = outcome.retryDeadline(at: now) {
            cooldowns[key.scope.source] = max(cooldowns[key.scope.source] ?? .distantPast, deadline)
        }
        entry.runningID = nil
        entry.running = nil
        guard !entry.removalRequested else {
            entries[key] = nil
            reschedule(source: key.scope.source)
            return
        }
        entry.nextRun = now.addingTimeInterval(key.interval)
        entries[key] = entry
        reschedule(source: key.scope.source)
    }

    private func purgeExpiredCooldowns() {
        let now = Date()
        cooldowns = cooldowns.filter { $0.value > now }
    }

    private func reschedule(source: WorkSource) {
        for key in Array(entries.keys) where key.scope.source == source { schedule(key) }
    }
}
