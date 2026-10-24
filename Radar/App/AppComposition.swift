import AppKit

/// Owns the production graph; account actions remain inside their explicit UI flows.
@MainActor
final class AppComposition {
    let store = RadarStore()
    let preferencesStore = PreferencesStore()
    lazy var preferences = PreferencesController(storage: preferencesStore, store: store)
    lazy var jiraConnection = JiraCloudConnection(preferences: preferencesStore)
    let refreshScheduler = RefreshScheduler()
    lazy var githubDetails = GitHubDetailController(connection: githubConnection, scheduler: refreshScheduler)
    lazy var githubWork = GitHubWorkController(connection: githubConnection, scheduler: refreshScheduler)
    lazy var githubConnection = GitHubConnectionController(store: store, preferences: preferencesStore)
    lazy var jiraWork = JiraWorkController(store: store, connection: jiraConnection, scheduler: refreshScheduler)
    lazy var relatedItems = RelatedItemsCoordinator(store: store, jira: jiraConnection,
        github: githubConnection, details: githubDetails, scheduler: refreshScheduler)
    lazy var sourceRefresh = SourceRefreshCoordinator(store: store, scheduler: refreshScheduler,
        jira: jiraWork, github: githubWork)
    lazy var lifecycle = DataLifecycleController(store: store, jira: jiraConnection, github: githubConnection,
        jiraWork: jiraWork, githubWork: githubWork, details: githubDetails, relations: relatedItems, refresh: sourceRefresh)
    lazy var navigation = NavigationCoordinator(store: store, jira: jiraConnection, github: githubConnection)
    private(set) var panelController: NotchPanelController?

    private var started = false
    private var preferencesLoad: Task<Void, Never>?

    func start() {
        guard !started else { return }
        started = true
        preferencesLoad = Task { await preferences.load() }
        lifecycle.start()
        guard let geometry = ScreenGeometryResolver().resolve() else { return }
        panelController = NotchPanelController(geometry: geometry, store: store, related: relatedItems, navigation: navigation)
        panelController?.showCompact()
    }

    func stop() {
        guard started else { return }
        started = false
        preferencesLoad?.cancel()
        preferencesLoad = nil
        lifecycle.stop()
        panelController?.invalidate()
        panelController = nil
    }
}
