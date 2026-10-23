import Foundation

/// Schedules whole operations and reserves all their scopes until their real completion.
@MainActor
final class RefreshScheduler {
    typealias Operation = @MainActor () async -> RefreshOutcome

    private struct Entry {
        var operation: Operation
        var scopes: Set<SourceScope>
        var eligible: Bool
        var nextRun: Date?
        var configurationID = UUID()
        var runningConfigurationID: UUID?
        var runningScopes: Set<SourceScope> = []
        var runningID: UUID?
        var running: Task<Void, Never>?
        var wakeup: Task<Void, Never>?
        var removalRequested = false
        var resumeAfterSleep = false
    }

    private var entries: [RefreshScheduleKey: Entry] = [:]
    private var occupiedScopes: [SourceScope: UUID] = [:]
    private var sleeping = false
    private var cooldowns: [WorkSource: Date] = [:]

    func configure(_ key: RefreshScheduleKey, eligible: Bool, scopes: Set<SourceScope>? = nil,
                   operation: @escaping Operation) {
        switch key.kind {
        case let .detail(selection), let .relations(selection):
            guard selection.contextID == key.contextID else { return }
        case .personalList: break
        }
        let dependencies = scopes ?? [key.scope]
        guard !dependencies.isEmpty, dependencies.contains(key.scope) else { return }
        if var entry = entries[key] {
            entry.operation = operation; entry.scopes = dependencies
            entry.eligible = eligible; entry.removalRequested = false
            entry.configurationID = UUID(); entry.nextRun = Date()
            entries[key] = entry
        } else {
            entries[key] = Entry(operation: operation, scopes: dependencies, eligible: eligible, nextRun: Date())
        }
        if !eligible { entries[key]?.running?.cancel() }
        schedule(key)
    }

    /// Repeated intent coalesces into the operation already running or waiting for its scopes.
    func request(_ key: RefreshScheduleKey) {
        guard var entry = entries[key], entry.eligible, !entry.removalRequested,
              entry.runningID == nil else { return }
        entry.nextRun = Date(); entries[key] = entry
        schedule(key)
    }

    func remove(_ key: RefreshScheduleKey) {
        guard var entry = entries[key] else { return }
        entry.eligible = false; entry.removalRequested = true
        entry.wakeup?.cancel(); entry.wakeup = nil
        entry.running?.cancel()
        entries[key] = entry.runningID == nil ? nil : entry
    }

    func removeAll() { for key in Array(entries.keys) { remove(key) } }

    func suspendForSleep() {
        sleeping = true
        for key in Array(entries.keys) {
            if entries[key]?.eligible == true, entries[key]?.removalRequested == false,
               entries[key]?.runningID != nil || entries[key]?.nextRun != nil {
                entries[key]?.resumeAfterSleep = true
            }
            entries[key]?.wakeup?.cancel(); entries[key]?.wakeup = nil
            entries[key]?.running?.cancel()
        }
    }

    func resumeAfterWake() {
        guard sleeping else { return }
        sleeping = false
        for key in Array(entries.keys) {
            guard key.interval != nil || entries[key]?.resumeAfterSleep == true else { continue }
            entries[key]?.resumeAfterSleep = false
            entries[key]?.nextRun = Date(); entries[key]?.configurationID = UUID()
        }
        scheduleAll()
    }

    private func schedule(_ key: RefreshScheduleKey) {
        guard var entry = entries[key] else { return }
        entry.wakeup?.cancel(); entry.wakeup = nil; entries[key] = entry
        guard !sleeping, entry.eligible, !entry.removalRequested, entry.runningID == nil,
              let next = entry.nextRun else { return }
        purgeExpiredCooldowns()
        let deadline = max(next, cooldown(for: entry.scopes))
        let delay = deadline.timeIntervalSinceNow
        if delay <= 0 { start(key); return }
        let generation = entry.configurationID
        entries[key]?.wakeup = Task { [weak self] in
            do { try await Task.sleep(for: .seconds(min(delay, 3_600))) } catch { return }
            guard let self, !Task.isCancelled, self.entries[key]?.configurationID == generation else { return }
            self.schedule(key)
        }
    }

    private func start(_ key: RefreshScheduleKey) {
        guard let entry = entries[key], entry.runningID == nil, entry.eligible,
              !entry.removalRequested, !sleeping else { return }
        purgeExpiredCooldowns()
        if cooldown(for: entry.scopes) > Date() { schedule(key); return }
        // No immediate timer when occupied: completion will reschedule waiters.
        guard entry.scopes.allSatisfy({ occupiedScopes[$0] == nil }) else { return }
        let runID = UUID()
        for scope in entry.scopes { occupiedScopes[scope] = runID }
        entries[key]?.runningID = runID
        entries[key]?.runningScopes = entry.scopes
        entries[key]?.runningConfigurationID = entry.configurationID
        entries[key]?.running = Task { [weak self, operation = entry.operation] in
            guard !Task.isCancelled else {
                self?.finish(key, runID: runID, outcome: RefreshOutcome(problems: [.cancelled])); return
            }
            self?.finish(key, runID: runID, outcome: await operation())
        }
    }

    private func finish(_ key: RefreshScheduleKey, runID: UUID, outcome: RefreshOutcome) {
        guard var entry = entries[key], entry.runningID == runID else { return }
        let now = Date()
        purgeExpiredCooldowns()
        for value in outcome.byOrigin(default: key.scope.source) {
            if let deadline = RefreshOutcome(problems: [value.problem]).retryDeadline(at: now) {
                cooldowns[value.source] = max(cooldowns[value.source] ?? .distantPast, deadline)
            }
        }
        for scope in entry.runningScopes where occupiedScopes[scope] == runID { occupiedScopes[scope] = nil }
        let sameConfiguration = entry.runningConfigurationID == entry.configurationID
        entry.runningID = nil; entry.running = nil; entry.runningScopes = []; entry.runningConfigurationID = nil
        if entry.removalRequested { entries[key] = nil }
        else {
            if sameConfiguration { entry.nextRun = key.interval.map { now.addingTimeInterval($0) } }
            entries[key] = entry
        }
        scheduleAll()
    }

    private func cooldown(for scopes: Set<SourceScope>) -> Date {
        scopes.compactMap { cooldowns[$0.source] }.max() ?? .distantPast
    }

    private func purgeExpiredCooldowns() {
        let now = Date(); cooldowns = cooldowns.filter { $0.value > now }
    }

    private func scheduleAll() { for key in Array(entries.keys) { schedule(key) } }
}
