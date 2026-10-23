import Foundation

struct ConnectionRecoveryPlan: Equatable {
    enum Action: Equatable { case retry, wait, configure, reconnect, restart }
    let action: Action
    let message: String
}

enum ConnectionRecoveryController {
    static func guidance(source: WorkSource, problem: SourceProblem) -> String {
        var status = SourceStatus(connection: .connected)
        status.problem = problem
        return plan(source: source, status: status)?.message ?? ""
    }

    static func plan(source: WorkSource, status: SourceStatus) -> ConnectionRecoveryPlan? {
        if status.connection == .requalificationRequired {
            return reconnect(source)
        }
        guard let problem = status.problem else { return nil }
        switch problem {
        case .authenticationRequired: return reconnect(source)
        case .permissionDenied:
            return ConnectionRecoveryPlan(action: .configure,
                message: "Confira o acesso aos projetos ou repositórios escolhidos. Permissão negada não significa sessão expirada.")
        case .singleSignOnRequired:
            return ConnectionRecoveryPlan(action: .configure,
                message: "Autorize o SSO pelo fluxo da sua organização e qualifique a conexão novamente. O Radar não amplia permissões.")
        case .rateLimited:
            return ConnectionRecoveryPlan(action: .wait,
                message: "Aguarde a liberação indicada pelo serviço. Atualizar ou trocar seleção não reduz essa espera.")
        case .serviceUnavailable:
            return ConnectionRecoveryPlan(action: .wait,
                message: "O serviço pediu uma pausa. A próxima consulta respeitará esse prazo.")
        case .executableMissing, .executableIncompatible:
            return ConnectionRecoveryPlan(action: .configure,
                message: "Escolha e valide uma instalação compatível do gh. O Radar não instala ferramentas.")
        case .transportUnavailable:
            return ConnectionRecoveryPlan(action: .restart,
                message: "Encerre e abra o Radar novamente para requalificar o transporte. Nenhuma autenticação será alterada.")
        case .capabilityUnavailable:
            return ConnectionRecoveryPlan(action: .configure,
                message: "Confira se a conta permite esta leitura no escopo escolhido. Nenhum escopo será ampliado automaticamente.")
        case .resourceLimit:
            return ConnectionRecoveryPlan(action: .configure,
                message: "O escopo excedeu o limite desta consulta. Restrinja os projetos ou repositórios e reconecte; conteúdo parcial não é vazio.")
        case .timeout, .cancelled, .invalidResponse, .networkFailure, .remoteFailure:
            return ConnectionRecoveryPlan(action: .retry,
                message: "Você pode repetir a consulta. Conteúdo anterior e limites de espera serão preservados.")
        }
    }

    private static func reconnect(_ source: WorkSource) -> ConnectionRecoveryPlan {
        ConnectionRecoveryPlan(action: .reconnect, message: source == .jira
            ? "Se houver token salvo, use Retomar / requalificar após confirmar a política da organização. Sem token salvo, informe-o somente neste formulário; para substituí-lo, remova antes a conexão."
            : "Confira a autenticação do gh fora do Radar; se esta origem estiver conectada, desconecte-a e conecte novamente aqui. O Radar não executa comandos de autenticação.")
    }
}
