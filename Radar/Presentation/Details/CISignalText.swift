enum CISignalText {
    static func label(_ signal: CISignal) -> String {
        let origin: String
        switch signal.origin {
        case let .checkRun(_, name): origin = "Check · \(name)"
        case let .commitStatus(context): origin = "Status · \(context)"
        }
        return "\(origin): \(state(signal.state))"
    }

    private static func state(_ value: CISignalState) -> String {
        switch value {
        case .success: "sucesso"
        case .failure: "falha"
        case .error: "erro"
        case .timedOut: "tempo esgotado"
        case .actionRequired: "requer ação"
        case .queued: "na fila"
        case .pending: "pendente"
        case .inProgress: "em execução"
        case .waiting: "aguardando"
        case .cancelled: "cancelado"
        case .neutral: "neutro"
        case .skipped: "ignorado"
        case .unknown: "desconhecido"
        }
    }
}
