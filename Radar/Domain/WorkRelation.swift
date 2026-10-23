import Foundation

struct OriginProblem: Equatable, Sendable {
    let source: WorkSource
    let problem: SourceProblem
}

struct WorkRelation: Hashable, Sendable {
    let jiraID: JiraIdentity
    let pullRequestID: PullRequestIdentity
    let provenance: Set<JiraReferenceProvenance>
}

enum RelationSubject: Sendable {
    case jira(JiraWorkItem)
    case pullRequest(PullRequestItem)
}

struct RelationObservation: Sendable {
    var jiraItems: [JiraWorkItem] = []
    var pullRequests: [PullRequestItem] = []
    var edges: [WorkRelation] = []
    var repositoryResolutions: [RepositoryIdentityResolution] = []
    var coverage: ObservationCoverage = .complete
    var problems: [OriginProblem] = []
}

struct RelationFailure: Error, Sendable {
    let problem: SourceProblem
    let observedProblems: [OriginProblem]
    let identityChanged: Bool
}
