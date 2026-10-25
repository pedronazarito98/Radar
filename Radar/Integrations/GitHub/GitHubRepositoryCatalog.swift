import Foundation

struct GitHubRepositoryOption: Identifiable, Hashable, Sendable {
    let id: GitHubRepositoryID
    let name: GitHubRepositoryName
    let isPrivate: Bool
}

struct GitHubCatalogCursor: Sendable {
    var installations: [Int64] = []
    var nextInstallationPage: Int? = 1
    var installationIndex = 0
    var repositoryPage = 1
    var observedRepositoryIDs: Set<Int64> = []
    var expectedRepositoryTotal: Int?
    var isPartial = false
    var reachedLimit = false
    var hasMore: Bool { !reachedLimit && (installationIndex < installations.count || nextInstallationPage != nil) }
}

struct GitHubCatalogPage: Sendable {
    let repositories: [GitHubRepositoryOption]
    let cursor: GitHubCatalogCursor
}

struct GitHubRepositoryCatalog: Sendable {
    let transport: GitHubAPITransport

    private struct InstallationPage: Decodable {
        struct Installation: Decodable { let id: Int64 }
        let total_count: Int
        let installations: [Installation]
    }
    private struct RepositoryPage: Decodable {
        let total_count: Int
        let repositories: [RepositoryDTO]
    }
    struct RepositoryDTO: Decodable {
        let id: Int64
        let full_name: String
        let `private`: Bool

        func option() throws -> GitHubRepositoryOption {
            guard let id = GitHubRepositoryID(id), let name = RadarPreferences.repository(full_name) else {
                throw GitHubAPIError.source(.invalidResponse)
            }
            return GitHubRepositoryOption(id: id, name: name, isPrivate: self.private)
        }
    }

    /// One repository page per explicit action, with stable identity on both sides.
    func page(after previous: GitHubCatalogCursor, sessionReference: GitHubSessionReference,
              expectedUser: GitHubAuthor) async throws -> GitHubCatalogPage {
        try await transport.withBatch(sessionReference: sessionReference, maximumCalls: 5, duration: .seconds(60)) { session in
            let initial = try GitHubUserDTO.decode(try await session.get(.user).body)
            guard initial.id == expectedUser.id else { throw GitHubAPIError.identityChanged }
            var cursor = previous
            var repositories: [GitHubRepositoryOption] = []
            guard cursor.hasMore else { throw GitHubAPIError.source(.resourceLimit) }
            if cursor.installationIndex >= cursor.installations.count, let page = cursor.nextInstallationPage {
                let response = try await session.get(.installations(page: page))
                let dto = try JSONDecoder().decode(InstallationPage.self, from: response.body)
                guard (0...100).contains(dto.installations.count), dto.total_count >= dto.installations.count,
                      dto.installations.allSatisfy({ $0.id > 0 }),
                      !response.hasNextPage || !dto.installations.isEmpty else { throw GitHubAPIError.source(.invalidResponse) }
                for installation in dto.installations {
                    if cursor.installations.contains(installation.id) { cursor.isPartial = true }
                    else { cursor.installations.append(installation.id) }
                }
                cursor.nextInstallationPage = response.hasNextPage && page < 10 ? page + 1 : nil
                if response.hasNextPage && page == 10 { cursor.isPartial = true }
                if !response.hasNextPage && dto.total_count > cursor.installations.count { cursor.isPartial = true }
            }
            if cursor.installationIndex < cursor.installations.count {
                let id = cursor.installations[cursor.installationIndex]
                let response = try await session.get(.installationRepositories(id: id, page: cursor.repositoryPage))
                let dto = try JSONDecoder().decode(RepositoryPage.self, from: response.body)
                guard dto.repositories.count <= 100, dto.total_count >= dto.repositories.count,
                      !response.hasNextPage || !dto.repositories.isEmpty else { throw GitHubAPIError.source(.invalidResponse) }
                repositories = try dto.repositories.map { try $0.option() }
                if let expected = cursor.expectedRepositoryTotal, expected != dto.total_count { cursor.isPartial = true }
                cursor.expectedRepositoryTotal = dto.total_count
                for repository in repositories {
                    if !cursor.observedRepositoryIDs.insert(repository.id.rawValue).inserted { cursor.isPartial = true }
                }
                if cursor.observedRepositoryIDs.count > dto.total_count { cursor.isPartial = true }
                if response.hasNextPage && cursor.repositoryPage < 10 { cursor.repositoryPage += 1 }
                else {
                    if response.hasNextPage || dto.total_count != cursor.observedRepositoryIDs.count { cursor.isPartial = true }
                    cursor.installationIndex += 1; cursor.repositoryPage = 1
                    cursor.observedRepositoryIDs = []; cursor.expectedRepositoryTotal = nil
                }
            }
            let final = try GitHubUserDTO.decode(try await session.get(.user, finalIdentity: true).body)
            guard final.id == initial.id, final.id == expectedUser.id else { throw GitHubAPIError.identityChanged }
            try Task.checkCancellation()
            return GitHubCatalogPage(repositories: repositories, cursor: cursor)
        }
    }

    func validateSelection(_ repositories: [GitHubRepositoryOption], sessionReference: GitHubSessionReference,
                           expectedUser: GitHubAuthor) async throws {
        guard (1...10).contains(repositories.count), Set(repositories.map(\.id)).count == repositories.count else {
            throw GitHubAPIError.source(.resourceLimit)
        }
        try await transport.withBatch(sessionReference: sessionReference, maximumCalls: 13, duration: .seconds(180)) { session in
            let initial = try GitHubUserDTO.decode(try await session.get(.user).body)
            guard initial.id == expectedUser.id else { throw GitHubAPIError.identityChanged }
            for repository in repositories {
                let response = try await session.get(.repository(repository.name))
                let option = try JSONDecoder().decode(RepositoryDTO.self, from: response.body).option()
                guard option.id == repository.id, option.name == repository.name else { throw GitHubAPIError.source(.invalidResponse) }
            }
            let final = try GitHubUserDTO.decode(try await session.get(.user, finalIdentity: true).body)
            guard final.id == expectedUser.id, final.id == initial.id else { throw GitHubAPIError.identityChanged }
            try Task.checkCancellation()
        }
    }
}
