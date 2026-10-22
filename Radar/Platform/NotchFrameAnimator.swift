import Foundation

@MainActor
final class NotchFrameAnimator {
    private var timer: Timer?
    private var generation: UUID?

    func animate(
        duration: TimeInterval,
        update: @escaping @MainActor (CGFloat) -> Void,
        completion: @escaping @MainActor () -> Void
    ) {
        cancel()
        let generation = UUID()
        self.generation = generation
        let startedAt = ProcessInfo.processInfo.systemUptime
        update(0)
        let timer = Timer(timeInterval: 1.0 / 60.0, repeats: true) { [weak self] timer in
            guard let self else {
                timer.invalidate()
                return
            }
            MainActor.assumeIsolated {
                guard self.generation == generation else { return }
                let elapsed = ProcessInfo.processInfo.systemUptime - startedAt
                let progress = min(max(elapsed / duration, 0), 1)
                let eased = progress * progress * (3 - 2 * progress)
                update(CGFloat(eased))
                if progress == 1 {
                    self.cancel()
                    completion()
                }
            }
        }
        timer.tolerance = 1.0 / 240.0
        self.timer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    func cancel() {
        timer?.invalidate()
        timer = nil
        generation = nil
    }
}
