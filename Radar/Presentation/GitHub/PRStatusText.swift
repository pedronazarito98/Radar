import Foundation

enum PRStatusText {
    static func lifecycle(_ value: PullRequestLifecycle) -> String {
        switch value {
        case .draft: "Rascunho"
        case .open: "Aberto"
        case .merged: "Mesclado"
        case .closed: "Fechado"
        }
    }

    static func roles(_ values: Set<PersonalPRRole>) -> String {
        var labels: [String] = []
        if values.contains(.author) { labels.append("Autoria") }
        if values.contains(.assignee) { labels.append("Atribuído a você") }
        if values.contains(.directlyRequestedReviewer) { labels.append("Sua revisão direta") }
        if values.contains(.confirmedTeamReviewer) { labels.append("Revisão da sua equipe") }
        if values.contains(.reviewRequestedUnclassified),
           !values.contains(.directlyRequestedReviewer), !values.contains(.confirmedTeamReviewer) {
            labels.append("Revisão solicitada")
        }
        return labels.isEmpty ? "Contexto relacionado" : labels.joined(separator: " · ")
    }

    static func ci(_ value: CISummary) -> String {
        switch value {
        case .failureObserved: "Falha observada"
        case .actionRequired: "Requer ação"
        case .inProgress: "Em andamento"
        case .cancelled: "Cancelado"
        case .unavailable: "Indisponível ou parcial"
        case .passed: "Passou"
        case .noChecks: "Sem checks"
        case .mixedNeutralResults: "Resultados mistos, com conclusões neutras/ignoradas"
        case .neutralOrSkipped: "Conclusões neutras ou ignoradas"
        }
    }

    static func review(_ value: ReviewSummary) -> String {
        switch value {
        case .changesRequested(let count): "Alterações solicitadas (\(count))"
        case .approvalsRecorded(let count): "Aprovações registradas (\(count))"
        case .awaitingReview: "Aguardando revisão"
        case .noCurrentDecision: "Sem decisão no commit atual"
        case .unavailable: "Indisponível ou parcial"
        }
    }
}
