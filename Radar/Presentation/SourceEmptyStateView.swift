import SwiftUI

struct SourceEmptyStateView: View {
    let source: WorkSource
    let count: Count
    let status: SourceStatus

    private var message: String {
        if status.connection == .disconnected {
            return source == .jira
                ? "Conecte o Jira Cloud em Configurações para ver seus cards."
                : "Qualifique o gh existente em Configurações para ver seus PRs."
        }
        if let problem = status.problem { return SourceStatusText.message(for: problem) }
        if status.isRefreshing { return "Consultando seu trabalho…" }
        switch count.value {
        case .exact(0): return "Nenhum item pessoal encontrado no escopo consultado."
        case .partial: return "Consulta parcial. Ainda não é possível confirmar um total."
        default: return "Ainda não há uma consulta concluída."
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(message)
            if let recovery = ConnectionRecoveryController.plan(source: source, status: status) {
                Text(recovery.message + " Acesse Configurações pelo menu Radar.")
                    .font(RadarTheme.Typography.caption)
            }
        }
            .font(RadarTheme.Typography.body)
            .foregroundStyle(RadarTheme.secondaryText)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(.top, 12)
    }
}
