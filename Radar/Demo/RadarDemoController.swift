import Foundation
import Observation

@MainActor
@Observable
final class RadarDemoController: RelatedItemsCoordinating {
    private(set) var scenario: RadarDemoScenario = .daily
    private let store: RadarStore
    private let data = RadarDemoData()
    private var detailTask: Task<Void, Never>?
    private var requestID = UUID()

    init(store: RadarStore) { self.store = store }

    func load(_ scenario: RadarDemoScenario) {
        stop()
        self.scenario = scenario
        store.selection.clear()
        store.configureSource(data.jiraScope, connection: .connected)
        store.configureSource(data.githubScope, connection: .connected)
        store.repositoryCategories = [data.repositories[0]: .web, data.repositories[1]: .api]

        switch scenario {
        case .loading:
            _ = store.beginRefresh(for: .jira)
            _ = store.beginRefresh(for: .github)
        case .empty:
            publish(cards: [], pullRequests: [])
        case .busy:
            publish(cards: data.manyCards, pullRequests: data.manyPRs)
        case .daily, .offline, .partial, .reconnect:
            publish(cards: data.cards, pullRequests: data.personalPRs, partial: scenario == .partial)
            if scenario == .offline {
                for source in [WorkSource.jira, .github] {
                    if let token = store.beginRefresh(for: source) { store.finishRefresh(with: .networkFailure, for: token) }
                }
            } else if scenario == .reconnect {
                store.invalidate(.github, connection: .requalificationRequired)
            }
        }
    }

    func simulateUpdate() {
        let cards = [data.card(246, "Revisar mensagens do novo onboarding", status: "Em revisão")] + data.cards
        publish(cards: cards, pullRequests: Array(data.personalPRs.reversed()))
    }

    func selectionChanged() {
        stop()
        guard store.isPanelOpen, let selection = store.selection.token else { return }
        let request = UUID(); requestID = request
        store.relations.begin(selection: selection, queryID: request)
        // A short cancellable delay exposes the actual loading and rapid-selection UX.
        detailTask = Task { [weak self] in
            do { try await Task.sleep(for: .milliseconds(450)) } catch { return }
            guard let self, requestID == request, store.isPanelOpen, store.selection.isCurrent(selection) else { return }
            if scenario == .offline || scenario == .reconnect {
                let problem: SourceProblem = scenario == .offline ? .networkFailure : .authenticationRequired
                store.relations.fail(problem, queryID: request)
                if let detailRequest = store.selection.prDetails.beginRefresh() {
                    store.selection.prDetails.finish(with: problem, for: detailRequest)
                }
                return
            }
            var observation = data.relations(for: selection.key, cards: store.jira.items, pullRequests: store.github.items)
            if scenario == .partial {
                observation.coverage = .partial
                observation.problems = [OriginProblem(source: .github, problem: .permissionDenied)]
            }
            _ = store.publishRelations(observation, queryID: request, selection: selection)
            if case let .pullRequest(id) = selection.key.itemID, let item = store.pullRequest(id) {
                RadarDemoPRDetails.publish(item, into: store.selection.prDetails, limited: scenario == .partial)
            }
        }
    }

    func refresh() { selectionChanged() }

    func stop() {
        requestID = UUID()
        detailTask?.cancel(); detailTask = nil
        store.relations.cancel()
    }

    private func publish(cards: [JiraWorkItem], pullRequests: [PullRequestItem], partial: Bool = false) {
        let coverage: QueryCoverage = partial ? .partial([.pageLimit]) : .complete
        if let token = store.beginRefresh(for: .jira),
           let snapshot = SourceSnapshot(contextID: store.contextID, scope: data.jiraScope, items: cards,
               queryCoverage: [.assignedJiraWork: coverage], lastSuccessfulAt: Date()) {
            store.publish(snapshot, for: token)
        }
        if let token = store.beginRefresh(for: .github),
           let snapshot = SourceSnapshot(contextID: store.contextID, scope: data.githubScope, items: pullRequests,
               queryCoverage: [.authoredPullRequests: coverage, .assignedPullRequests: coverage,
                               .reviewRequestedPullRequests: coverage], lastSuccessfulAt: Date()) {
            store.publish(snapshot, for: token)
        }
    }
}
