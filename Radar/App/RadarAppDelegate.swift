import AppKit

@MainActor
final class RadarAppDelegate: NSObject, NSApplicationDelegate {
    let store = RadarStore()
    let jiraConnection = JiraCloudConnection()
    private(set) var panelController: NotchPanelController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard let geometry = ScreenGeometryResolver().resolve() else { return }
        panelController = NotchPanelController(geometry: geometry, store: store)
        panelController?.showCompact()
    }

    func applicationWillTerminate(_ notification: Notification) {
        panelController?.invalidate()
        panelController = nil
    }
}
