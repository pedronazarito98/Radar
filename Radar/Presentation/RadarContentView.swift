import SwiftUI

struct RadarContentView: View {
    let store: RadarStore
    let close: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: RadarTheme.Layout.sectionSpacing) {
            HStack {
                Text("Meu trabalho").font(RadarTheme.Typography.title)
                Spacer()
                if store.jira.hasPendingUpdate || store.github.hasPendingUpdate {
                    Button("Aplicar atualização", action: store.applyPendingUpdates)
                        .font(RadarTheme.Typography.caption)
                        .help("Aplicar a nova revisão das listas e dos totais")
                }
                Button(action: close) {
                    Image(systemName: "chevron.up")
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Recolher Radar")
            }

            HStack(alignment: .top, spacing: RadarTheme.Layout.contentPadding) {
                JiraListView(store: store)
                Rectangle().fill(RadarTheme.separator).frame(width: 1)
                GitHubListView(store: store)
            }
            .frame(maxHeight: .infinity)

            Rectangle().fill(RadarTheme.separator).frame(height: 1)
            DetailsStripView(presentation: .current(in: store), close: store.selection.dismissDetails)
        }
        .padding(.horizontal, RadarTheme.Layout.contentPadding)
        .padding(.bottom, RadarTheme.Layout.contentPadding)
        .foregroundStyle(RadarTheme.primaryText)
    }

}
