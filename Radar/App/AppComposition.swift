import AppKit

/// Selects the live or offline demonstration graph once, before loading any state.
@MainActor
final class AppComposition {
    let store: RadarStore
    let preferencesStore: PreferencesStore
    let demo: RadarDemoController?
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
    lazy var displays = DisplayPolicyController(preferences: preferences)
    lazy var navigation = store.isDemo
        ? NavigationCoordinator(demoStore: store)
        : NavigationCoordinator(store: store, jira: jiraConnection, github: githubConnection)
    private(set) var panelController: NotchPanelController?

    private var started = false
    private var preferencesLoad: Task<Void, Never>?

    init() {
        let isDemo = ProcessInfo.processInfo.arguments.contains("--demo")
            || Bundle.main.bundleIdentifier == "dev.pedronazarito.Radar.demo"
        store = RadarStore(isDemo: isDemo)
        preferencesStore = PreferencesStore(persists: !isDemo)
        demo = isDemo ? RadarDemoController(store: store) : nil
    }

    func start() {
        guard !started else { return }
        started = true
        if let demo {
            demo.load(.daily)
        } else {
            preferencesLoad = Task { await preferences.load() }
            lifecycle.start()
        }
        displays.geometryChanged = { [weak self] geometry in self?.applyGeometry(geometry) }
        displays.start()
    }

    func togglePanel() {
        displays.refresh()
        panelController?.toggle()
    }

    func showDemoScenario(_ scenario: RadarDemoScenario) {
        guard let demo else { return }
        panelController?.showCompact()
        demo.load(scenario)
        displays.refresh()
        panelController?.showExpanded()
    }

    func simulateDemoUpdate() {
        guard let demo else { return }
        if demo.scenario != .daily {
            showDemoScenario(.daily)
        } else {
            displays.refresh()
            panelController?.showExpanded()
        }
        demo.simulateUpdate()
    }

    private func applyGeometry(_ geometry: ScreenGeometry?) {
        if let panelController {
            panelController.updateGeometry(geometry)
        } else if let geometry {
            let coordinator: any RelatedItemsCoordinating
            if let demo { coordinator = demo } else { coordinator = relatedItems }
            let controller = NotchPanelController(geometry: geometry, store: store, related: coordinator,
                                                 navigation: navigation, demo: demo)
            panelController = controller
            controller.showCompact()
        }
    }

    func prepareForTermination() async -> Bool {
        stop()
        if demo != nil { return true }
        return await githubConnection.finishPendingCredentialWrite()
    }

    func resumeAfterDeferredTermination() async {
        await githubConnection.resumeAfterDeferredTermination()
        start()
    }

    func stop() {
        guard started else { return }
        started = false
        preferencesLoad?.cancel()
        preferencesLoad = nil
        displays.stop()
        if let demo { demo.stop() } else { lifecycle.stop() }
        panelController?.invalidate()
        panelController = nil
    }
}
