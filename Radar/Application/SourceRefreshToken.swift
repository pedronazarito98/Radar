import Foundation

struct SourceRefreshToken: Hashable, Sendable {
    let contextID: WorkContextID
    let source: WorkSource
    let scope: SourceScope
    let generation: UInt64
}
