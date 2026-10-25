import Foundation

struct GitHubAppConfiguration: Sendable {
    let clientID: String
    let slug: String

    static var bundled: Self? {
        guard let clientID = Bundle.main.object(forInfoDictionaryKey: "RadarGitHubClientID") as? String,
              let slug = Bundle.main.object(forInfoDictionaryKey: "RadarGitHubAppSlug") as? String,
              (1...128).contains(clientID.utf8.count), (1...100).contains(slug.utf8.count),
              clientID.utf8.allSatisfy({ Self.asciiAlphanumeric($0) || $0 == 95 || $0 == 46 }),
              slug.utf8.allSatisfy({ Self.asciiAlphanumeric($0) || $0 == 45 }),
              !slug.hasPrefix("-"), !slug.hasSuffix("-") else { return nil }
        return Self(clientID: clientID, slug: slug)
    }

    var installationURL: URL { URL(string: "https://github.com/apps/\(slug)/installations/new")! }
    static let verificationURL = URL(string: "https://github.com/login/device")!

    private static func asciiAlphanumeric(_ byte: UInt8) -> Bool {
        (65...90).contains(byte) || (97...122).contains(byte) || (48...57).contains(byte)
    }
}

struct GitHubSessionReference: Hashable, Sendable {
    let id: UUID
    init() { id = UUID() }
}

enum GitHubAPIError: Error, Sendable {
    case source(SourceProblem)
    case identityChanged
}

enum GitHubAuthorizationError: Error, Sendable {
    case notConfigured, denied, expired, invalidResponse, unavailable, configurationRejected, savedSessionMissing
    case credentialStorage, differentApplication, rotationInProgress

    var message: String {
        switch self {
        case .notConfigured: "A conexão com o GitHub ainda precisa ser habilitada nesta versão do Radar."
        case .denied: "A autorização foi cancelada no GitHub. Você pode conectar novamente quando quiser."
        case .expired: "O código ou a sessão expirou. Conecte novamente para continuar."
        case .invalidResponse: "Não foi possível confirmar a resposta do GitHub. Tente novamente."
        case .unavailable: "Não foi possível autorizar agora. Confira sua conexão e tente novamente."
        case .configurationRejected: "O GitHub não aceitou a configuração desta versão do Radar. O cadastro da aplicação precisa ser conferido."
        case .savedSessionMissing: "Não há uma sessão salva disponível. Remova a referência local e conecte novamente."
        case .credentialStorage: "Não foi possível guardar a sessão com segurança. Retome a conexão ou remova a sessão salva para tentar novamente."
        case .differentApplication: "A sessão salva pertence a outra configuração do Radar. Remova-a antes de conectar novamente."
        case .rotationInProgress: "A sessão está terminando uma atualização segura. Aguarde alguns segundos e tente retomar."
        }
    }
}
