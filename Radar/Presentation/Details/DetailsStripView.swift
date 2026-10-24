import SwiftUI

struct DetailsStripView: View {
    let presentation: DetailsStripPresentation?
    let close: () -> Void
    let refresh: () -> Void
    let canRefresh: Bool
    let focused: FocusState<RadarFocusTarget?>.Binding
    let focus: RadarFocusCoordinator
    @State private var scrollPosition = ScrollPosition(y: 0)
    @State private var contentOffset: CGFloat = 0
    @State private var maximumOffset: CGFloat = 0
    var selectRelated: ((SelectionKey) -> Void)?
    let open: (SelectionKey) -> Void
    let copyLink: (SelectionKey) -> Void
    let canNavigate: (SelectionKey) -> Bool
    let navigationMessage: String?

    var body: some View {
        Group {
            if let presentation {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Conexões · \(presentation.title)")
                            .font(RadarTheme.Typography.body.weight(.semibold)).lineLimit(1)
                        Spacer(minLength: 4)
                        Button("Atualizar", systemImage: "arrow.clockwise", action: refresh)
                            .disabled(!canRefresh)
                            .focusable().focused(focused, equals: .refreshDetails).focusEffectDisabled()
                            .modifier(RadarFocusOutline(isFocused: focused.wrappedValue == .refreshDetails))
                        destinationActions(presentation.key, title: presentation.title)
                        Button(action: close) { Image(systemName: "xmark") }
                            .buttonStyle(.plain).accessibilityLabel("Fechar detalhes e voltar à linha")
                            .padding(6)
                            .focusable().focused(focused, equals: .closeDetails).focusEffectDisabled()
                            .modifier(RadarFocusOutline(isFocused: focused.wrappedValue == .closeDetails))
                    }
                    if let navigationMessage {
                        Text(navigationMessage).font(RadarTheme.Typography.caption).foregroundStyle(RadarTheme.secondaryText)
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
                    .scrollPosition($scrollPosition)
                    .onScrollGeometryChange(for: CGFloat.self) { $0.contentOffset.y } action: { _, value in
                        contentOffset = value
                    }
                    .onScrollGeometryChange(for: CGFloat.self) {
                        max(0, $0.contentSize.height - $0.containerSize.height)
                    } action: { _, value in maximumOffset = value }
                    .focusable().focused(focused, equals: .detailsContent).focusEffectDisabled()
                    .modifier(RadarFocusOutline(isFocused: focused.wrappedValue == .detailsContent))
                    .accessibilityLabel("Conteúdo dos detalhes; use as setas para rolar")
                    .onChange(of: focus.detailScrollGeneration) { _, _ in
                        scrollPosition.scrollTo(y: min(maximumOffset, max(0, contentOffset + focus.detailScrollDelta)))
                    }
                    .onChange(of: presentation.key) { _, _ in scrollPosition.scrollTo(y: 0) }
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

    private func destinationActions(_ key: SelectionKey, title: String) -> some View {
        HStack(spacing: 6) {
            Button { open(key) } label: { Image(systemName: "arrow.up.right.square") }
                .accessibilityLabel("Abrir \(title) no navegador").help("Abrir no navegador")
                .disabled(!canNavigate(key))
                .focusable().focused(focused, equals: .openDestination(key)).focusEffectDisabled()
                .modifier(RadarFocusOutline(isFocused: focused.wrappedValue == .openDestination(key)))
            Button { copyLink(key) } label: { Image(systemName: "doc.on.doc") }
                .accessibilityLabel("Copiar link de \(title)").help("Copiar link")
                .disabled(!canNavigate(key))
                .focusable().focused(focused, equals: .copyDestination(key)).focusEffectDisabled()
                .modifier(RadarFocusOutline(isFocused: focused.wrappedValue == .copyDestination(key)))
        }
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
        case let .observed(items, coverage, scope, isRefreshing, problem):
            if isRefreshing { Text("Atualizando conexões…") }
            if let problem {
                Text("Conexões anteriores · \(SourceStatusText.message(for: problem))")
                    .foregroundStyle(RadarTheme.attention)
            }
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
                    .focusable().focused(focused, equals: .related(item.id)).focusEffectDisabled()
                    .modifier(RadarFocusOutline(isFocused: focused.wrappedValue == .related(item.id)))
                    destinationActions(item.id, title: item.title)
                }
                Divider().overlay(RadarTheme.separator)
            }
        }
    }
}
