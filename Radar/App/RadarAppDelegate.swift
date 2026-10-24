import AppKit

@MainActor
final class RadarAppDelegate: NSObject, NSApplicationDelegate {
    let composition = AppComposition()

    func applicationDidFinishLaunching(_ notification: Notification) {
        composition.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        composition.stop()
    }
}
