import AppKit

@MainActor
final class RadarAppDelegate: NSObject, NSApplicationDelegate {
    let composition = AppComposition()
    private var termination: Task<Void, Never>?

    func applicationDidFinishLaunching(_ notification: Notification) {
        composition.start()
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        guard termination == nil else { return .terminateLater }
        termination = Task {
            let drained = await composition.prepareForTermination()
            if !drained { await composition.resumeAfterDeferredTermination() }
            termination = nil
            sender.reply(toApplicationShouldTerminate: drained)
        }
        return .terminateLater
    }

    func applicationWillTerminate(_ notification: Notification) {
        composition.stop()
    }
}
