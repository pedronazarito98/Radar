import SwiftUI

struct DisconnectedPanelView: View {
    let close: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: RadarTheme.Layout.sectionSpacing) {
            HStack {
                Text("Meu trabalho").font(RadarTheme.Typography.title)
                Spacer()
                Button(action: close) {
                    Image(systemName: "chevron.up")
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Recolher Radar")
            }

            HStack(alignment: .top, spacing: RadarTheme.Layout.contentPadding) {
                disconnectedSource(
                    title: "Jira", brand: .jira, color: RadarTheme.jiraAccent,
                    subtitle: "Conta não conectada", message: "Conecte o Jira Cloud para ver seus cards."
                )
                Rectangle().fill(RadarTheme.separator).frame(width: 1)
                disconnectedSource(
                    title: "GitHub", brand: .github, color: RadarTheme.githubAccent,
                    subtitle: "Conta não qualificada", message: "Use o gh existente para consultar PRs e revisões."
                )
            }
            .frame(maxHeight: .infinity)

            Rectangle().fill(RadarTheme.separator).frame(height: 1)
            HStack(spacing: 8) {
                Image(systemName: "link")
                Text("Conecte as origens para consultar card e PR no mesmo contexto.")
            }
            .font(RadarTheme.Typography.body)
            .foregroundStyle(RadarTheme.secondaryText)
        }
        .padding(.horizontal, RadarTheme.Layout.contentPadding)
        .padding(.bottom, RadarTheme.Layout.contentPadding)
        .foregroundStyle(RadarTheme.primaryText)
    }

    private func disconnectedSource(
        title: String, brand: SourceBrandMark.Brand, color: Color, subtitle: String, message: String
    ) -> some View {
        VStack(alignment: .leading, spacing: RadarTheme.Layout.sectionSpacing) {
            HStack(spacing: 12) {
                SourceBrandMark(brand: brand)
                    .frame(width: RadarTheme.Layout.sourceSymbolSize, height: RadarTheme.Layout.sourceSymbolSize)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(RadarTheme.Typography.heading).foregroundStyle(color)
                    Text(subtitle).font(RadarTheme.Typography.caption).foregroundStyle(RadarTheme.secondaryText)
                }
            }
            Text(message)
                .font(RadarTheme.Typography.body)
                .foregroundStyle(RadarTheme.secondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text("Use Configurações no menu Radar.")
                .font(RadarTheme.Typography.caption)
                .foregroundStyle(RadarTheme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }
}
