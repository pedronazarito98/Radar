import Foundation

enum GitHubCLIEnvironment {
    static var values: [String: String] {
        ["HOME": FileManager.default.homeDirectoryForCurrentUser.path,
         "PATH": "/usr/bin:/bin:/usr/sbin:/sbin",
         "GH_PROMPT_DISABLED": "1", "GH_NO_UPDATE_NOTIFIER": "1",
         "GH_NO_EXTENSION_UPDATE_NOTIFIER": "1", "GH_TELEMETRY": "false",
         "GH_PAGER": "cat", "NO_COLOR": "1"]
    }
}

enum GitHubCLIError: Error, Sendable {
    case source(SourceProblem)
    case identityChanged
}

struct GitHubProcessResult: Sendable {
    let output: Data
    let exitCode: Int32
}
