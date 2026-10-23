import Synchronization

/// If termination cannot be confirmed, no later gh subprocess is allowed this launch.
enum GitHubProcessSafety {
    private static let unavailable = Mutex(false)
    static var isUnavailable: Bool { unavailable.withLock { $0 } }
    static func markUnavailable() { unavailable.withLock { $0 = true } }
}
