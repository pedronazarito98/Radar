enum RadarDemoScenario: String, CaseIterable, Identifiable {
    case daily, empty, loading, offline, partial, reconnect, busy

    var id: String { rawValue }

    var title: String {
        switch self {
        case .daily: "Dia de trabalho"
        case .empty: "Tudo em dia"
        case .loading: "Carregando"
        case .offline: "Falha de rede"
        case .partial: "Acesso parcial"
        case .reconnect: "Reconectar GitHub"
        case .busy: "Muitos itens · 99+"
        }
    }

    var description: String {
        switch self {
        case .daily: "5 cards, 5 PRs pessoais e um PR contextual. Selecione RAD-241 para explorar os vínculos."
        case .empty: "Consultas concluídas sem itens: contadores em zero e mensagens de estado vazio."
        case .loading: "Consultas pendentes, sem total confirmado. O estado permanece até trocar de cenário."
        case .offline: "Listas preservadas com falha de conexão e dados desatualizados; detalhes indisponíveis."
        case .partial: "Totais parciais, relações incompletas e CI/revisão sem permissão."
        case .reconnect: "Jira disponível enquanto o GitHub pede uma nova conexão."
        case .busy: "110 cards e 105 PRs para explorar rolagem, títulos longos e contadores acima de 99."
        }
    }
}
