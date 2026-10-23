import Foundation

enum JiraConnectionErrorText {
    static func message(_ error: Error) -> String {
        guard let error = error as? JiraConnectionError else { return "Não foi possível concluir a conexão." }
        switch error {
        case .source(let problem):
            return SourceStatusText.message(for: problem) + ". " + ConnectionRecoveryController.guidance(source: .jira, problem: problem)
        case .preferences(let problem): return problem.message
        case .removalPending: return "Remova a conexão anterior antes de conectar novamente."
        case .vault(let problem):
            switch problem {
            case .cancelled: return "A operação do Keychain foi cancelada."
            case .denied: return "O acesso ao Keychain foi negado."
            case .missing: return "O token salvo não foi encontrado."
            case .invalidSecret: return "O token está vazio ou excede o limite permitido."
            case .interactionRequired: return "O Keychain precisa de uma nova ação sua."
            case .unavailable: return "O Keychain não concluiu a operação."
            }
        }
    }
}
