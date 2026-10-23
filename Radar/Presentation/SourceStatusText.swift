import Foundation

enum SourceStatusText {
    static func summary(_ status: SourceStatus) -> String {
        switch status.connection {
        case .disconnected: return "Conta não conectada"
        case .connecting: return "Qualificando conexão"
        case .requalificationRequired: return "Qualifique a conexão novamente"
        case .unavailable: return "Origem indisponível"
        case .connected: break
        }
        var parts: [String] = []
        if status.isRefreshing { parts.append("Atualizando") }
        if let problem = status.problem { parts.append(message(for: problem)) }
        switch status.freshness {
        case .neverLoaded: parts.append("Ainda sem consulta concluída")
        case .stale: parts.append("Dados desatualizados")
        case .current: if parts.isEmpty { parts.append("Consulta recebida") }
        }
        return parts.joined(separator: ". ")
    }

    static func message(for problem: SourceProblem) -> String {
        switch problem {
        case .authenticationRequired: "Autenticação necessária"
        case .permissionDenied: "Acesso não permitido"
        case .singleSignOnRequired: "Autorização SSO necessária"
        case .rateLimited: "Limite de consultas; aguardando nova tentativa"
        case .serviceUnavailable: "Serviço temporariamente indisponível"
        case .timeout: "Tempo de consulta esgotado"
        case .cancelled: "Consulta interrompida"
        case .invalidResponse: "Resposta não pôde ser validada"
        case .capabilityUnavailable: "Capacidade indisponível"
        case .executableMissing: "gh não encontrado"
        case .executableIncompatible: "gh incompatível"
        case .transportUnavailable: "Consulta indisponível"
        case .networkFailure: "Falha de conexão"
        case .resourceLimit: "Limite local da consulta atingido"
        case .remoteFailure: "O serviço não concluiu a consulta"
        }
    }
}
