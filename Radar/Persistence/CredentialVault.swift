import Foundation
import Security

/// An app-generated reference, never an arbitrary Keychain account or service.
struct JiraCredentialReference: Hashable, Codable, Sendable {
    let id: UUID

    init(id: UUID = UUID()) { self.id = id }
}

enum CredentialVaultError: Error, Equatable, Sendable {
    case missing
    case invalidSecret
    case denied
    case cancelled
    case interactionRequired
    case unavailable
}

/// Called only by explicit connection/reconnection/removal actions in the app.
/// No initialization, UI appearance or background refresh reads the Keychain.
actor CredentialVault {
    private let service = "dev.pedronazarito.Radar"

    func saveJiraToken(_ token: String, for reference: JiraCredentialReference) throws {
        guard !token.isEmpty, token.utf8.count <= 16_384 else { throw CredentialVaultError.invalidSecret }
        let data = Data(token.utf8)
        var attributes = query(for: reference)
        attributes[kSecValueData as String] = data
        attributes[kSecAttrLabel as String] = "Radar · Jira Cloud"
        let result = SecItemAdd(attributes as CFDictionary, nil)
        if result == errSecDuplicateItem {
            try check(SecItemUpdate(query(for: reference) as CFDictionary,
                                    [kSecValueData as String: data] as CFDictionary))
        } else {
            try check(result)
        }
    }

    func readJiraTokenAfterUserAction(for reference: JiraCredentialReference) throws -> String {
        var attributes = query(for: reference)
        attributes[kSecMatchLimit as String] = kSecMatchLimitOne
        attributes[kSecReturnData as String] = true
        var result: CFTypeRef?
        try check(SecItemCopyMatching(attributes as CFDictionary, &result))
        guard let data = result as? Data, data.count <= 16_384,
              let token = String(data: data, encoding: .utf8), !token.isEmpty else {
            throw CredentialVaultError.invalidSecret
        }
        return token
    }

    func removeJiraTokenAfterUserAction(for reference: JiraCredentialReference) throws {
        let result = SecItemDelete(query(for: reference) as CFDictionary)
        if result != errSecItemNotFound { try check(result) }
    }

    private func query(for reference: JiraCredentialReference) -> [String: Any] {
        // Classic Keychain for the qualified local ad-hoc bundle. No broad
        // matching, access group, synchronization or unqualified protection claim.
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: service,
         kSecAttrAccount as String: "jira.\(reference.id.uuidString)",
         kSecAttrSynchronizable as String: false]
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
