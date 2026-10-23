import AppKit

@MainActor
final class RadarAppDelegate: NSObject, NSApplicationDelegate {
    let store = RadarStore()
    let jiraConnection = JiraCloudConnection()
    let refreshScheduler = RefreshScheduler()
    lazy var githubWork = GitHubWorkController(connection: githubConnection, scheduler: refreshScheduler)
    lazy var githubConnection = GitHubConnectionController(store: store)
    lazy var jiraWork = JiraWorkController(store: store, connection: jiraConnection, scheduler: refreshScheduler)
    private(set) var panelController: NotchPanelController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard let geometry = ScreenGeometryResolver().resolve() else { return }
        panelController = NotchPanelController(geometry: geometry, store: store)
        panelController?.showCompact()
    }

    func applicationWillTerminate(_ notification: Notification) {
        githubWork.stop()
        jiraWork.stop()
        panelController?.invalidate()
        panelController = nil
    }
}
