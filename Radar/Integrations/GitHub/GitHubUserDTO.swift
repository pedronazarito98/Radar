import Foundation

struct GitHubUserDTO: Decodable, Sendable {
    let id: Int64
    let login: String

    static func decode(_ data: Data) throws -> GitHubAuthor {
        guard let dto = try? JSONDecoder().decode(Self.self, from: data), let id = GitHubUserID(dto.id), !dto.login.isEmpty,
              dto.login.utf8.allSatisfy({ (65...90).contains($0) || (97...122).contains($0) || (48...57).contains($0) || $0 == 45 }) else {
            throw GitHubCLIError.source(.invalidResponse)
        }
        return GitHubAuthor(id: id, login: dto.login)
    }
}
