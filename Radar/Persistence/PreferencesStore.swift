import Foundation

/// Only this app's allowlisted, non-secret schema is read/written. No business cache.
actor PreferencesStore {
    private let url: URL?
    private var value = RadarPreferences()
    private var failure: PreferencesError?

    init() {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("Radar", isDirectory: true)
        url = directory?.appendingPathComponent("preferences.json")
        guard let url else { failure = .unavailable; return }
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            guard attributes[.type] as? FileAttributeType == .typeRegular,
                  let size = attributes[.size] as? NSNumber, size.intValue <= 65_536 else {
                failure = .invalidStoredData; return
            }
            let data = try Data(contentsOf: url)
            let decoded = try JSONDecoder().decode(RadarPreferences.self, from: data)
            guard decoded.isValid else { failure = .invalidStoredData; return }
            value = decoded
        } catch let error as CocoaError where error.code == .fileReadNoSuchFile || error.code == .fileNoSuchFile {
            // Absence is the only load failure that permits starting with defaults.
        } catch { failure = .invalidStoredData }
    }

    func snapshot() throws -> RadarPreferences {
        if let failure { throw failure }
        return value
    }

    func saveJira(configuration: JiraConnectionConfiguration, reference: JiraCredentialReference) throws {
        if let previous = value.jira?.reference, previous != reference { throw PreferencesError.conflictingReference }
        var next = try snapshot()
        next.jira = JiraSavedConfiguration(configuration: configuration, reference: reference)
        try write(next)
    }

    func clearJiraReference(expected: JiraCredentialReference) throws {
        var next = try snapshot()
        guard next.jira?.reference == nil || next.jira?.reference == expected else { throw PreferencesError.conflictingReference }
        next.jira?.reference = nil
        try write(next)
    }

    func saveGitHub(executable: QualifiedGitHubExecutable, repositories: Set<GitHubRepositoryName>? = nil) throws {
        var next = try snapshot()
        next.ghPath = executable.url.path
        if let repositories {
            next.repositories = repositories.map(\.fullName).sorted()
            next.categories = next.categories.filter { next.repositories.contains($0.key) }
        }
        try write(next)
    }

    func saveDisplay(_ id: UInt32?) throws {
        var next = try snapshot(); next.preferredDisplayID = id; try write(next)
    }

    func saveCategory(_ category: RepositoryCategory?, repository: String) throws {
        var next = try snapshot()
        guard next.repositories.contains(repository) else { throw PreferencesError.invalidValue }
        next.categories[repository] = category; try write(next)
    }

    private func write(_ next: RadarPreferences) throws {
        guard let url else { throw PreferencesError.unavailable }
        guard next.isValid else { throw PreferencesError.invalidValue }
        do {
            let data = try JSONEncoder().encode(next)
            guard data.count <= 65_536 else { throw PreferencesError.invalidValue }
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true,
                attributes: [.posixPermissions: 0o700])
            try data.write(to: url, options: .atomic)
            let handle = try FileHandle(forWritingTo: url)
            defer { try? handle.close() }
            try handle.synchronize()
            value = next
        } catch let error as PreferencesError { throw error }
        catch { throw PreferencesError.unavailable }
    }
}
