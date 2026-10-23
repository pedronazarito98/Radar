import Foundation

struct QualifiedGitHubExecutable: Equatable, Sendable {
    let url: URL
    let version: String
}

struct GitHubExecutableResolver: Sendable {
    func qualify(path: String) async throws -> QualifiedGitHubExecutable {
        guard path.hasPrefix("/"), !path.contains("\0"), URL(fileURLWithPath: path).lastPathComponent == "gh" else {
            throw GitHubCLIError.source(.executableIncompatible)
        }
        let url = URL(fileURLWithPath: path).resolvingSymlinksInPath().standardizedFileURL
        let attributes = try? FileManager.default.attributesOfItem(atPath: url.path)
        guard attributes != nil else { throw GitHubCLIError.source(.executableMissing) }
        guard attributes?[.type] as? FileAttributeType == .typeRegular,
              FileManager.default.isExecutableFile(atPath: url.path),
              url.lastPathComponent == "gh", Self.hasNativeMachOHeader(url) else {
            throw GitHubCLIError.source(.executableIncompatible)
        }
        let result = try await BoundedGitHubProcess(limit: 4_096).run(executable: url, arguments: ["--version"])
        try Task.checkCancellation()
        guard result.exitCode == 0, let text = String(data: result.output, encoding: .utf8),
              let firstLine = text.split(separator: "\n").first else { throw GitHubCLIError.source(.executableIncompatible) }
        let parts = firstLine.split(separator: " ")
        guard parts.count >= 3, parts[0] == "gh", parts[1] == "version" else { throw GitHubCLIError.source(.executableIncompatible) }
        let segments = parts[2].split(separator: ".", omittingEmptySubsequences: false)
        guard segments.count == 3, segments.allSatisfy({ !$0.isEmpty && $0.utf8.allSatisfy { (48...57).contains($0) } }) else {
            throw GitHubCLIError.source(.executableIncompatible)
        }
        let components = segments.compactMap { Int($0) }
        guard components.count == 3, components[0] == 2, components[1] >= 96 else {
            throw GitHubCLIError.source(.executableIncompatible)
        }
        return QualifiedGitHubExecutable(url: url, version: String(parts[2]))
    }

    private static func hasNativeMachOHeader(_ url: URL) -> Bool {
        guard let handle = try? FileHandle(forReadingFrom: url) else { return false }
        defer { try? handle.close() }
        guard let data = try? handle.read(upToCount: 4_096), data.count >= 8 else { return false }
        let bytes = [UInt8](data)
        #if arch(arm64)
        let cpu: UInt32 = 0x0100000c
        #else
        let cpu: UInt32 = 0x01000007
        #endif
        func word(_ offset: Int, bigEndian: Bool) -> UInt32 {
            let slice = Array(bytes[offset..<(offset + 4)])
            let ordered = bigEndian ? slice : Array(slice.reversed())
            return ordered.reduce(0) { ($0 << 8) | UInt32($1) }
        }
        let magic = word(0, bigEndian: true)
        if magic == 0xcffaedfe { return word(4, bigEndian: false) == cpu }
        guard magic == 0xcafebabe || magic == 0xcafebabf else { return false }
        let count = Int(word(4, bigEndian: true))
        let stride = magic == 0xcafebabf ? 32 : 20
        guard count > 0, count <= 64, bytes.count >= 8 + count * stride else { return false }
        return (0..<count).contains { word(8 + $0 * stride, bigEndian: true) == cpu }
    }

}
