import Foundation

struct SelectionToken: Hashable, Sendable {
    let key: SelectionKey
    let generation: UInt64
}

struct PRDetailRequestToken: Hashable, Sendable {
    let selection: SelectionToken
    let pullRequestID: PullRequestIdentity
    let detailGeneration: UInt64
}

struct PRHeadObservation: Equatable, Sendable {
    let version: PRDetailVersion
    let lifecycle: PullRequestLifecycle
}
