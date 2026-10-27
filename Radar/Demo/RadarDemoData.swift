import Foundation

/// Entirely fictional, deterministic identities. Nothing is fetched or persisted.
struct RadarDemoData {
    let jiraScope: SourceScope
    let githubScope: SourceScope
    let siteURL: URL
    let site: JiraSiteIdentity
    let repositories: [GitHubRepositoryName]
    let connection = ConnectionID()
    let createdAt = Date()

    init() {
        guard let url = URL(string: "https://radar-demo.invalid"),
              let site = JiraSiteIdentity(siteURL: url),
              let web = GitHubRepositoryName(owner: "radar-demo", name: "web"),
              let api = GitHubRepositoryName(owner: "radar-demo", name: "api"),
              let design = GitHubRepositoryName(owner: "radar-demo", name: "design-system"),
              let jiraScope = SourceScope(jiraSite: site, projectKeys: ["RAD"]),
              let githubScope = SourceScope(githubRepositories: [web, api, design]) else {
            preconditionFailure("Invalid built-in Radar demo scope")
        }
        self.siteURL = url; self.site = site
        repositories = [web, api, design]
        self.jiraScope = jiraScope; self.githubScope = githubScope
    }

    var cards: [JiraWorkItem] {
        [card(241, "Refinar a experiência de login", status: "Em andamento"),
         card(242, "Preservar filtros ao voltar para a lista", status: "Em revisão"),
         card(243, "Melhorar contraste e foco dos componentes", status: "Em andamento"),
         card(244, "Investigar lentidão no carregamento do painel", status: "Bloqueado"),
         card(245, "Documentar o fluxo de recuperação de acesso", status: "A fazer")]
    }

    var personalPRs: [PullRequestItem] {
        [pullRequest(81, repository: 0, title: "RAD-241 Ajusta validação e mensagens do login", branch: "feat/RAD-241-login", roles: [.author]),
         pullRequest(82, repository: 0, title: "RAD-242 Mantém filtros entre navegações", branch: "fix/RAD-242-filters", roles: [.directlyRequestedReviewer]),
         pullRequest(23, repository: 1, title: "RAD-241 RAD-244 Reduz latência da sessão", branch: "perf/RAD-244-session", roles: [.author, .assignee]),
         pullRequest(14, repository: 2, title: "RAD-243 Revisa contraste de campos e botões", branch: "feat/RAD-243-contrast", roles: [.assignee], lifecycle: .draft),
         pullRequest(15, repository: 2, title: "Atualiza documentação dos componentes", branch: "docs/components", roles: [.reviewRequestedUnclassified])]
    }

    var contextualPR: PullRequestItem {
        pullRequest(24, repository: 1, title: "RAD-241 Padroniza respostas de autenticação",
                    branch: "feat/RAD-241-errors", roles: [])
    }

    func card(_ number: Int, _ title: String, status: String = "A fazer") -> JiraWorkItem {
        guard let id = JiraIdentity(site: site, issueID: String(number)), let key = JiraIssueKey("RAD-\(number)"),
              let item = JiraWorkItem(id: id, key: key, summary: title,
                status: JiraWorkStatus(id: status, name: status, category: JiraStatusCategory(
                    key: status == "A fazer" ? "new" : "indeterminate", name: status)),
                project: JiraProject(id: "demo", key: "RAD", name: "Radar · demonstração"),
                assignee: JiraAssignee(accountID: "demo-person", displayName: "Pessoa de exemplo"),
                updatedAt: createdAt.addingTimeInterval(-Double(number)), siteURL: siteURL,
                sourceConnections: [connection]) else { preconditionFailure("Invalid built-in demo card") }
        return item
    }

    func pullRequest(_ number: Int, repository: Int, title: String, branch: String,
                     roles: Set<PersonalPRRole>, lifecycle: PullRequestLifecycle = .open) -> PullRequestItem {
        let name = repositories[repository]
        guard let id = PullRequestIdentity(repository: .fallback(name), number: number),
              let authorID = GitHubUserID(roles.contains(.author) ? 1 : 2),
              let item = PullRequestItem(id: id, repositoryName: name, title: title,
                author: GitHubAuthor(id: authorID, login: roles.contains(.author) ? "pessoa-demo" : "colega-demo"),
                lifecycle: lifecycle, personalRoles: roles, headSHA: nil, headRef: branch,
                updatedAt: createdAt.addingTimeInterval(-Double(number)), sourceConnections: [connection]) else {
            preconditionFailure("Invalid built-in demo pull request")
        }
        return item
    }

    var manyCards: [JiraWorkItem] {
        cards + (1...105).map { card(1000 + $0,
            "Revisar acessibilidade e comportamento de navegação do componente de exemplo \($0)",
            status: $0.isMultiple(of: 2) ? "Em andamento" : "A fazer") }
    }

    var manyPRs: [PullRequestItem] {
        personalPRs + (1...100).map { pullRequest(1000 + $0, repository: $0 % repositories.count,
            title: "Ajusta estados vazios e mensagens para o fluxo de demonstração \($0)",
            branch: "demo/iteration-\($0)", roles: [.author]) }
    }

    func relations(for key: SelectionKey, cards: [JiraWorkItem], pullRequests: [PullRequestItem]) -> RelationObservation {
        let allPRs = pullRequests + [contextualPR]
        let edges = allPRs.flatMap { pr in
            JiraKeyReferenceExtractor().references(title: pr.title, branch: pr.headRef, scope: jiraScope).compactMap { reference in
                cards.first(where: { $0.key == reference.key }).map {
                    WorkRelation(jiraID: $0.id, pullRequestID: pr.id, provenance: reference.provenance)
                }
            }
        }.filter { edge in
            switch key.itemID {
            case let .jira(id): edge.jiraID == id
            case let .pullRequest(id): edge.pullRequestID == id
            }
        }
        let cardIDs = Set(edges.map(\.jiraID))
        let prIDs = Set(edges.map(\.pullRequestID))
        return RelationObservation(
            jiraItems: cards.filter { cardIDs.contains($0.id) || key.itemID == .jira($0.id) },
            pullRequests: allPRs.filter { prIDs.contains($0.id) || key.itemID == .pullRequest($0.id) }, edges: edges)
    }
}
