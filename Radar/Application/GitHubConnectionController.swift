import Foundation
import Observation

@MainActor
@Observable
final class GitHubConnectionController {
    let transport: GitHubAPITransport
    let store: RadarStore
    let configuration = GitHubAppConfiguration.bundled
    private let preferences: PreferencesStore
    private let authorization: GitHubAuthorizationStore
    private(set) var sessionReference: GitHubSessionReference?
    private(set) var identity: GitHubAuthor?
    private(set) var connectionID: ConnectionID?
    private(set) var challenge: GitHubDeviceChallenge?
    private(set) var repositories: [GitHubRepositoryOption] = []
    private(set) var selectedIDs: Set<GitHubRepositoryID> = []
    private(set) var catalogCursor = GitHubCatalogCursor()
    private(set) var catalogLoaded = false
    private(set) var catalogProblem: String?
    private(set) var message: String?
    private(set) var hasSavedSession = false
    private(set) var isBusy = false
    private(set) var isTerminating = false
    private(set) var activity = ""
    private var generation = UUID()
    private var removing = false
    private var pendingSavedSelection: Set<GitHubRepositoryName> = []
    @ObservationIgnored private var operation: Task<Void, Never>?
    var onInvalidated: (() -> Void)?

    init(store: RadarStore, preferences: PreferencesStore) {
        self.store = store; self.preferences = preferences
        let authorization = GitHubAuthorizationStore(preferences: preferences)
        self.authorization = authorization
        transport = GitHubAPITransport(authorization: authorization)
    }

    var isConnected: Bool { store.github.status.connection == .connected }
    var canCancel: Bool { isBusy && !removing }
    var canApply: Bool { !isBusy && (1...10).contains(selectedIDs.count) && identity != nil }

    func loadSavedState() async {
        do { hasSavedSession = try await preferences.snapshot().githubCredential != nil }
        catch { message = PreferencesController.message(error) }
    }

    func connectAfterUserAction() {
        guard !isTerminating, let configuration, !isBusy, !hasSavedSession, identity == nil else { return }
        resetCatalog()
        start("Aguardando autorização no GitHub…") { [self] attempt in
            let reference = try await self.authorization.authorize(configuration: configuration) { [weak self] challenge in
                guard let self, self.generation == attempt, !Task.isCancelled else { return }
                self.challenge = challenge
            }
            try self.ensureCurrent(attempt)
            self.sessionReference = reference
            self.challenge = nil
            self.activity = "Confirmando sua conta…"
            try await self.qualifyIdentity(reference, attempt: attempt)
            self.activity = "Buscando seus repositórios…"
            try await self.loadPage(attempt: attempt)
        }
    }

    func resumeAfterUserAction() {
        guard !isTerminating, let configuration, !isBusy, hasSavedSession, identity == nil else { return }
        resetCatalog()
        start("Retomando sua conexão…") { attempt in
            let reference = try await self.authorization.resumeAfterUserAction(configuration: configuration)
            try self.ensureCurrent(attempt)
            self.sessionReference = reference
            try await self.qualifyIdentity(reference, attempt: attempt)
            self.activity = "Buscando seus repositórios…"
            try await self.loadPage(attempt: attempt)
        }
    }

    func loadMoreAfterUserAction() {
        guard !isTerminating, !isBusy, identity != nil, catalogCursor.hasMore else { return }
        start("Carregando mais repositórios…") { attempt in try await self.loadPage(attempt: attempt) }
    }

    func reloadCatalogAfterUserAction() {
        guard !isTerminating, !isBusy, identity != nil else { return }
        resetCatalog()
        start("Atualizando repositórios…") { attempt in try await self.loadPage(attempt: attempt) }
    }

    func select(_ id: GitHubRepositoryID, enabled: Bool) {
        guard !isTerminating, !isBusy, repositories.contains(where: { $0.id == id }) else { return }
        if enabled {
            guard selectedIDs.count < 10 else { return }
            selectedIDs.insert(id)
        } else { selectedIDs.remove(id) }
    }

    func applySelectionAfterUserAction() {
        guard !isTerminating, canApply, let reference = sessionReference, let user = identity else { return }
        let selected = repositories.filter { selectedIDs.contains($0.id) }
        guard selected.count == selectedIDs.count else { return }
        // Changing the scope invalidates all prior work before the new qualification begins.
        invalidateWork(connection: .disconnected)
        start("Confirmando os repositórios escolhidos…") { attempt in
            try await GitHubRepositoryCatalog(transport: self.transport).validateSelection(
                selected, sessionReference: reference, expectedUser: user)
            try self.ensureCurrent(attempt)
            guard self.sessionReference == reference, self.identity?.id == user.id,
                  let scope = SourceScope(githubRepositories: Set(selected.map(\.name))) else {
                throw GitHubAPIError.source(.cancelled)
            }
            try await self.preferences.saveGitHubSelection(Set(selected.map(\.name)), userID: user.id)
            try self.ensureCurrent(attempt)
            self.connectionID = ConnectionID()
            self.store.configureSource(scope, connection: .connected)
            self.message = "Conectado. Seus PRs serão atualizados nos repositórios escolhidos."
        }
    }

    func disconnectAfterUserAction() {
        guard !isTerminating, !removing else { return }
        cancelOnboarding()
        invalidateWork(connection: .disconnected)
        sessionReference = nil; identity = nil; resetCatalog()
        removing = true
        start("Removendo a sessão salva…") { _ in
            try await self.authorization.removeAfterUserAction()
            self.message = "GitHub desconectado deste Radar."
        }
    }

    func requireRequalification() {
        let previous = sessionReference
        cancelOnboarding()
        invalidateWork(connection: .requalificationRequired)
        sessionReference = nil; identity = nil; resetCatalog()
        Task { await authorization.discardMemory(ifMatching: previous) }
    }

    /// Closing settings cancels onboarding/catalog work, never the active personal feed.
    func cancelOnboarding() {
        guard !removing else { return }
        generation = UUID(); operation?.cancel(); operation = nil
        isBusy = false; challenge = nil; activity = ""
        Task { await loadSavedState() }
    }

    func shutdown() {
        isTerminating = true
        cancelOnboarding()
        invalidateWork(connection: .disconnected)
        sessionReference = nil; identity = nil; resetCatalog()
        Task { await authorization.discardMemory() }
    }

    func finishPendingCredentialWrite() async -> Bool {
        await authorization.discardMemoryAndDrain()
    }

    func resumeAfterDeferredTermination() async {
        await authorization.cancelShutdown()
        isTerminating = false
        message = "O encerramento foi adiado porque o macOS ainda está salvando sua sessão. Conclua a solicitação do sistema e tente encerrar novamente."
    }

    private func start(_ activity: String, operation work: @escaping @MainActor (UUID) async throws -> Void) {
        guard operation == nil else { return }
        let attempt = UUID(); generation = attempt
        self.activity = activity; isBusy = true; message = nil; catalogProblem = nil
        operation = Task { [weak self] in
            guard let self else { return }
            do { try await work(attempt) }
            catch {
                if self.generation == attempt {
                    self.message = Self.message(error)
                    if self.identity != nil { self.catalogProblem = self.message }
                    if case GitHubAPIError.identityChanged = error { self.requireRequalification() }
                    else if case GitHubAPIError.source(.authenticationRequired) = error { self.requireRequalification() }
                }
            }
            guard self.generation == attempt else { return }
            self.challenge = nil; self.isBusy = false; self.activity = ""; self.removing = false; self.operation = nil
            await self.loadSavedState()
        }
    }

    private func qualifyIdentity(_ reference: GitHubSessionReference, attempt: UUID) async throws {
        let user = try await transport.withBatch(sessionReference: reference, maximumCalls: 3, duration: .seconds(30)) { session in
            let initial = try GitHubUserDTO.decode(try await session.get(.user).body)
            let final = try GitHubUserDTO.decode(try await session.get(.user, finalIdentity: true).body)
            guard initial.id == final.id else { throw GitHubAPIError.identityChanged }
            return initial
        }
        try ensureCurrent(attempt)
        let saved = try await preferences.snapshot()
        try ensureCurrent(attempt)
        pendingSavedSelection = saved.githubUserID == user.id.rawValue
            ? Set(saved.repositories.compactMap(RadarPreferences.repository)) : []
        identity = user
    }

    private func loadPage(attempt: UUID) async throws {
        guard let reference = sessionReference, let user = identity else { throw GitHubAPIError.source(.authenticationRequired) }
        let page = try await GitHubRepositoryCatalog(transport: transport).page(after: catalogCursor,
            sessionReference: reference, expectedUser: user)
        try ensureCurrent(attempt)
        guard reference == sessionReference, user.id == identity?.id else { throw GitHubAPIError.source(.cancelled) }
        var merged = repositories
        for item in page.repositories {
            guard !merged.contains(where: { $0.name == item.name && $0.id != item.id }) else { throw GitHubAPIError.source(.invalidResponse) }
            if let index = merged.firstIndex(where: { $0.id == item.id }) { merged[index] = item }
            else { merged.append(item) }
        }
        catalogCursor = page.cursor
        if merged.count > 5_000 {
            merged = Array(merged.prefix(5_000)); catalogCursor.isPartial = true; catalogCursor.reachedLimit = true
        }
        for repository in merged where pendingSavedSelection.contains(repository.name) {
            // Consume each restored choice once; a later page must never undo a user's deselection.
            pendingSavedSelection.remove(repository.name)
            if selectedIDs.count < 10 { selectedIDs.insert(repository.id) }
        }
        repositories = merged.sorted { $0.name.fullName.localizedStandardCompare($1.name.fullName) == .orderedAscending }
        catalogLoaded = true
    }

    private func resetCatalog() {
        repositories = []; selectedIDs = []; pendingSavedSelection = []; catalogCursor = GitHubCatalogCursor(); catalogLoaded = false; catalogProblem = nil
    }

    private func invalidateWork(connection: SourceConnectionState) {
        connectionID = nil
        store.invalidate(.github, connection: connection)
        onInvalidated?()
    }

    private func ensureCurrent(_ attempt: UUID) throws {
        guard generation == attempt, !Task.isCancelled else { throw GitHubAPIError.source(.cancelled) }
    }

    private static func message(_ error: Error) -> String {
        if let error = error as? GitHubAuthorizationError { return error.message }
        if let error = error as? PreferencesError { return error.message }
        if error is CredentialVaultError { return "O macOS não liberou a sessão salva. Tente novamente; se não puder retomá-la, remova a sessão por este formulário." }
        if case let GitHubAPIError.source(problem) = error {
            return SourceStatusText.message(for: problem) + ". " + ConnectionRecoveryController.guidance(source: .github, problem: problem)
        }
        if case GitHubAPIError.identityChanged = error { return "A identidade da conta não corresponde à conexão. Retome a sessão para conferir." }
        if error is CancellationError { return "Conexão cancelada." }
        return "Não foi possível concluir esta etapa. Tente novamente."
    }
}
