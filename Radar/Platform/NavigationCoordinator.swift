import AppKit
import Observation

/// User-triggered navigation only. No remote URL or pasteboard content is read.
@MainActor
@Observable
final class NavigationCoordinator {
    private let store: RadarStore
    private let jira: JiraCloudConnection
    private let github: GitHubConnectionController
    private var operation: Task<Void, Never>?
    private var generation = UUID()
    private(set) var message: String?
    var didOpenDestination: (() -> Void)?

    init(store: RadarStore, jira: JiraCloudConnection, github: GitHubConnectionController) {
        self.store = store; self.jira = jira; self.github = github
    }

    func canNavigate(_ key: SelectionKey) -> Bool {
        guard store.isPanelOpen, key.contextID == store.contextID, isPresented(key) else { return false }
        switch key.itemID {
        case let .jira(id):
            guard store.jira.status.connection == .connected, let scope = store.jira.scope,
                  let item = store.jiraItem(id) else { return false }
            return item.belongs(to: scope)
        case let .pullRequest(id):
            guard store.github.status.connection == .connected, let scope = store.github.scope,
                  let item = store.pullRequest(id), let connection = github.connectionID else { return false }
            return item.belongs(to: scope) && item.sourceConnections.contains(connection)
        }
    }

    func open(_ key: SelectionKey) { perform(key, copying: false) }
    func copyLink(_ key: SelectionKey) { perform(key, copying: true) }

    func cancel() {
        generation = UUID(); operation?.cancel(); operation = nil; message = nil
    }

    private func perform(_ key: SelectionKey, copying: Bool) {
        cancel()
        guard canNavigate(key), let selection = store.selection.token else {
            message = "Este destino não está disponível no contexto atual."; return
        }
        let attempt = generation
        operation = Task { [weak self] in
            guard let self else { return }
            let url = await destination(for: key)
            guard !Task.isCancelled, generation == attempt, store.selection.isCurrent(selection), canNavigate(key) else { return }
            guard let url else { message = "O endereço não corresponde ao destino autorizado."; operation = nil; return }
            if copying {
                NSPasteboard.general.clearContents()
                message = NSPasteboard.general.setString(url.absoluteString, forType: .string)
                    ? "Link copiado." : "Não foi possível copiar o link."
            } else if NSWorkspace.shared.open(url) {
                didOpenDestination?()
            } else {
                message = "Não foi possível abrir o endereço no navegador."
            }
            operation = nil
        }
    }

    private func destination(for key: SelectionKey) async -> URL? {
        switch key.itemID {
        case let .jira(id):
            guard let item = store.jiraItem(id), let connection = try? await jira.currentConnection(),
                  connection.scope == store.jira.scope, item.belongs(to: connection.scope),
                  item.sourceConnections.contains(connection.connectionID),
                  let host = connection.configuration.siteURL.host,
                  item.siteURL.host?.lowercased() == host.lowercased() else { return nil }
            return Self.validated(item.webURL, host: host)
        case let .pullRequest(id):
            guard let item = store.pullRequest(id), let url = item.webURL else { return nil }
            return Self.validated(url, host: GitHubHost.githubDotCom.rawValue)
        }
    }

    private func isPresented(_ key: SelectionKey) -> Bool {
        if store.selection.selectedKey == key { return true }
        guard case let .observed(items, _, _, _, _) = DetailsStripPresentation.current(in: store)?.relations else { return false }
        return items.contains { $0.id == key }
    }

    private static func validated(_ url: URL, host: String) -> URL? {
        guard let value = URLComponents(url: url, resolvingAgainstBaseURL: false),
              value.scheme?.lowercased() == "https", value.host?.lowercased() == host.lowercased(),
              value.user == nil, value.password == nil, value.port == nil || value.port == 443,
              value.query == nil, value.fragment == nil else { return nil }
        return value.url
    }
}
