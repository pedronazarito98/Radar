import Foundation
import Security

struct GitHubCredentialReference: Hashable, Codable, Sendable {
    let id: UUID
    init(id: UUID = UUID()) { self.id = id }
}

/// Only Radar's GitHub item; never queries any external credential or CLI storage.
actor GitHubCredentialVault {
    func save(_ tokens: GitHubTokenSet, reference: GitHubCredentialReference) throws {
        guard tokens.isStructurallyValid else { throw CredentialVaultError.invalidSecret }
        let data = try JSONEncoder().encode(tokens)
        guard data.count <= 65_536 else { throw CredentialVaultError.invalidSecret }
        var attributes = query(reference)
        attributes[kSecValueData as String] = data
        attributes[kSecAttrLabel as String] = "Radar · GitHub"
        let result = SecItemAdd(attributes as CFDictionary, nil)
        if result == errSecDuplicateItem {
            try check(SecItemUpdate(query(reference) as CFDictionary, [kSecValueData as String: data] as CFDictionary))
        } else { try check(result) }
    }

    func readAfterUserAction(_ reference: GitHubCredentialReference) throws -> GitHubTokenSet {
        try Task.checkCancellation()
        var attributes = query(reference)
        attributes[kSecMatchLimit as String] = kSecMatchLimitOne
        attributes[kSecReturnData as String] = true
        var result: CFTypeRef?
        try check(SecItemCopyMatching(attributes as CFDictionary, &result))
        guard let data = result as? Data, data.count <= 65_536,
              let tokens = try? JSONDecoder().decode(GitHubTokenSet.self, from: data), tokens.isStructurallyValid else {
            throw CredentialVaultError.invalidSecret
        }
        return tokens
    }

    func removeAfterUserAction(_ reference: GitHubCredentialReference) throws {
        let status = SecItemDelete(query(reference) as CFDictionary)
        if status != errSecItemNotFound { try check(status) }
    }

    private func query(_ reference: GitHubCredentialReference) -> [String: Any] {
        [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: "dev.pedronazarito.Radar",
         kSecAttrAccount as String: "github.\(reference.id.uuidString)", kSecAttrSynchronizable as String: false]
    }

    private func check(_ status: OSStatus) throws {
        switch status {
        case errSecSuccess: return
        case errSecItemNotFound: throw CredentialVaultError.missing
        case errSecUserCanceled: throw CredentialVaultError.cancelled
        case errSecAuthFailed: throw CredentialVaultError.denied
        case errSecInteractionNotAllowed: throw CredentialVaultError.interactionRequired
        default: throw CredentialVaultError.unavailable
        }
    }
}
