import SwiftUI

struct DisconnectedPanelView: View {
    let close: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Meu trabalho").font(.title2.weight(.semibold))
                Spacer()
                Button(action: close) {
                    Image(systemName: "chevron.up")
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Recolher Radar")
            }

            HStack(alignment: .top, spacing: 24) {
                disconnectedSource(
                    title: "Jira", symbol: "diamond.fill", color: .blue,
                    subtitle: "Conta não conectada", message: "Conecte o Jira Cloud para ver seus cards."
                )
                Divider()
                disconnectedSource(
                    title: "GitHub", symbol: "chevron.left.forwardslash.chevron.right", color: .purple,
                    subtitle: "Conta não qualificada", message: "Use o gh existente para consultar PRs e revisões."
                )
            }
            .frame(maxHeight: .infinity)

            Divider()
            HStack(spacing: 8) {
                Image(systemName: "link")
                Text("Conecte as origens para consultar card e PR no mesmo contexto.")
            }
            .font(.callout)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
        .foregroundStyle(.white)
    }

    private func disconnectedSource(
        title: String, symbol: String, color: Color, subtitle: String, message: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 12) {
                Image(systemName: symbol).font(.title2).foregroundStyle(color)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(.headline)
                    Text(subtitle).font(.caption).foregroundStyle(.secondary)
                }
            }
            Text(message)
                .font(.callout)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("Use Configurações no menu Radar.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }
}
