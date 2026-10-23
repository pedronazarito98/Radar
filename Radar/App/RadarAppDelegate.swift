import AppKit

@MainActor
final class RadarAppDelegate: NSObject, NSApplicationDelegate {
    let store = RadarStore()
    let jiraConnection = JiraCloudConnection()
    let refreshScheduler = RefreshScheduler()
    lazy var githubDetails = GitHubDetailController(connection: githubConnection, scheduler: refreshScheduler)
    lazy var githubWork = GitHubWorkController(connection: githubConnection, scheduler: refreshScheduler)
    lazy var githubConnection = GitHubConnectionController(store: store)
    lazy var jiraWork = JiraWorkController(store: store, connection: jiraConnection, scheduler: refreshScheduler)
    lazy var relatedItems = RelatedItemsCoordinator(store: store, jira: jiraConnection,
        github: githubConnection, details: githubDetails, scheduler: refreshScheduler)
    lazy var sourceRefresh = SourceRefreshCoordinator(store: store, scheduler: refreshScheduler,
        jira: jiraWork, github: githubWork)
    private(set) var panelController: NotchPanelController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        sourceRefresh.start()
        guard let geometry = ScreenGeometryResolver().resolve() else { return }
        panelController = NotchPanelController(geometry: geometry, store: store, related: relatedItems)
        panelController?.showCompact()
    }

    func applicationWillTerminate(_ notification: Notification) {
        sourceRefresh.stop()
        relatedItems.stop()
        githubDetails.stop()
        githubWork.stop()
        jiraWork.stop()
        panelController?.invalidate()
        panelController = nil
    }
}
