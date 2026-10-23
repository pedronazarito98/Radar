import SwiftUI

struct DetailsStripView: View {
    let presentation: DetailsStripPresentation?
    let close: () -> Void
    var selectRelated: ((SelectionKey) -> Void)?
    var open: ((SelectionKey) -> Void)?

    var body: some View {
        Group {
            if let presentation {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Conexões · \(presentation.title)")
                            .font(RadarTheme.Typography.body.weight(.semibold)).lineLimit(1)
                        Spacer(minLength: 4)
                        Button("Abrir", systemImage: "arrow.up.right.square") { open?(presentation.key) }
                            .disabled(open == nil)
                        Button(action: close) { Image(systemName: "xmark") }
                            .buttonStyle(.plain).accessibilityLabel("Fechar detalhes e voltar à linha")
                    }
                    ScrollView {
                        VStack(alignment: .leading, spacing: 8) {
                            if !presentation.isInPersonalSnapshot {
                                Text("Item fora da lista pessoal apresentada. Os totais permanecem pessoais.")
                                    .foregroundStyle(RadarTheme.secondaryText)
                            }
                            if let details = presentation.prDetails { PRDetailStatusView(details: details) }
                            if presentation.isRefreshingPR { Text("Atualizando CI e revisão…") }
                            if let problem = presentation.prProblem { Text(SourceStatusText.message(for: problem)) }
                            relations(presentation.relations)
                        }
                        .font(RadarTheme.Typography.caption)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .frame(height: 128)
            } else {
                Label("Selecione um card ou PR para consultar conexões.", systemImage: "link")
                    .font(RadarTheme.Typography.body)
                    .foregroundStyle(RadarTheme.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(height: 32)
            }
        }
        .foregroundStyle(RadarTheme.primaryText)
    }

    @ViewBuilder
    private func relations(_ state: RelationPresentation) -> some View {
        switch state {
        case .notQueried:
            Text("Conexões ainda não consultadas.").foregroundStyle(RadarTheme.secondaryText)
        case .loading:
            Text("Consultando conexões…")
        case .failed(let problem):
            Text(SourceStatusText.message(for: problem))
        case let .observed(items, coverage, scope):
            Text(scope).foregroundStyle(RadarTheme.secondaryText)
            if coverage != .complete {
                Text("Resultado parcial ou indisponível; podem existir outros vínculos.")
                    .foregroundStyle(RadarTheme.attention)
            } else if items.isEmpty {
                Text("Nenhum vínculo encontrado no escopo consultado.")
            }
            ForEach(items) { item in
                HStack(alignment: .top, spacing: 8) {
                    Button { selectRelated?(item.id) } label: {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(item.title).fontWeight(.semibold)
                            Text(item.subtitle).foregroundStyle(RadarTheme.secondaryText)
                            Text(item.provenance).foregroundStyle(RadarTheme.secondaryText)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain).disabled(selectRelated == nil)
                    Button("Abrir", systemImage: "arrow.up.right.square") { open?(item.id) }
                        .disabled(open == nil)
                }
                Divider().overlay(RadarTheme.separator)
            }
        }
    }
}
