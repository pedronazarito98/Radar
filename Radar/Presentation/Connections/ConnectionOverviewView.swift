import SwiftUI

struct ConnectionOverviewView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Radar")
                .font(.largeTitle.weight(.semibold))
            Text("Card e PR no mesmo contexto")
                .foregroundStyle(.secondary)

            GroupBox("Jira Cloud") {
                Text("Conta não conectada. A conexão pessoal será feita com token informado diretamente no app.")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            }
            GroupBox("GitHub.com") {
                Text("Conta não qualificada. O Radar usará o gh existente, com autenticação administrada pelo próprio CLI.")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 8)
            }
            Text("As conexões ainda não estão disponíveis nesta etapa local.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(28)
        .frame(width: 460)
    }
}
