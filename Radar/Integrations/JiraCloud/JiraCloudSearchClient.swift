import Foundation

struct JiraSearchFailure: Error, Sendable {
    let problem: SourceProblem
    let observedProblems: [SourceProblem]
}

struct JiraCloudSearchClient: Sendable {
    let connection: JiraCloudConnection

    func fetch(contextID: WorkContextID, scope: SourceScope) async throws -> SourceSnapshot<JiraWorkItem> {
        let qualified = try await connection.currentConnection()
        guard qualified.scope == scope else { throw JiraConnectionError.source(.cancelled) }
        let projects = qualified.configuration.projectKeys.sorted().map { "\"\($0)\"" }.joined(separator: ",")
        let jql = "assignee = currentUser() AND statusCategory != Done AND project IN (\(projects)) ORDER BY updated DESC, key ASC"
        var items: [JiraWorkItem] = []
        var seenIDs: Set<JiraIdentity> = []
        var seenTokens: Set<String> = []
        var nextToken: String?
        var reasons: Set<QueryPartialReason> = []
        var problems: [SourceProblem] = []
        var completed = false
        for pageNumber in 1...10 {
            try Task.checkCancellation()
            var query = [URLQueryItem(name: "jql", value: jql),
                URLQueryItem(name: "fields", value: "summary,status,project,assignee,updated"),
                URLQueryItem(name: "maxResults", value: "100")]
            if let nextToken { query.append(URLQueryItem(name: "nextPageToken", value: nextToken)) }
            do {
                let data = try await connection.read(expectedConnectionID: qualified.connectionID, path: "search/jql", query: query)
                try Task.checkCancellation()
                guard let page = try? JSONDecoder().decode(JiraSearchPageDTO.self, from: data) else {
                    throw JiraConnectionError.source(.invalidResponse)
                }
                var pageItems: [JiraWorkItem] = []
                for dto in page.issues {
                    guard let item = dto.item(connection: qualified) else { throw JiraConnectionError.source(.invalidResponse) }
                    pageItems.append(item)
                }
                for item in pageItems {
                    if seenIDs.insert(item.id).inserted { items.append(item) }
                    else { reasons.insert(.inconsistentPagination) }
                }
                if page.hasWarnings { reasons.insert(.incompleteResults) }
                guard let token = page.nextPageToken else {
                    if page.isLast == false { reasons.insert(.inconsistentPagination) }
                    else { completed = true }
                    break
                }
                if page.isLast == true {
                    reasons.insert(.inconsistentPagination)
                    break
                }
                guard !token.isEmpty, seenTokens.insert(token).inserted else {
                    reasons.insert(.inconsistentPagination)
                    break
                }
                nextToken = token
                if pageNumber == 10 { reasons.insert(.pageLimit) }
            } catch {
                let problem: SourceProblem
                if case let JiraConnectionError.source(value) = error { problem = value }
                else if error is CancellationError { problem = .cancelled }
                else { problem = .invalidResponse }
                guard problem != .cancelled, !Task.isCancelled, !items.isEmpty else {
                    throw JiraConnectionError.source(problem)
                }
                reasons.insert(.interrupted)
                problems.append(problem)
                break
            }
        }
        do {
            try Task.checkCancellation()
            let current = try await connection.currentConnection()
            guard current.connectionID == qualified.connectionID else { throw JiraConnectionError.source(.cancelled) }
        } catch {
            let problem: SourceProblem
            if case let JiraConnectionError.source(value) = error { problem = value }
            else { problem = .cancelled }
            throw JiraSearchFailure(problem: problem, observedProblems: problems)
        }
        if !completed, reasons.isEmpty { reasons.insert(.inconsistentPagination) }
        let coverage: QueryCoverage = reasons.isEmpty ? .complete : .partial(reasons)
        guard let snapshot = SourceSnapshot(contextID: contextID, scope: scope, items: items,
            queryCoverage: [.assignedJiraWork: coverage], lastSuccessfulAt: Date(), observedProblems: problems) else {
            throw JiraConnectionError.source(.invalidResponse)
        }
        return snapshot
    }
}
