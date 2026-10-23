import SwiftUI

struct RadarContentView: View {
    let store: RadarStore
    let focus: RadarFocusCoordinator
    let related: RelatedItemsCoordinator
    let close: () -> Void
    @FocusState private var focused: RadarFocusTarget?

    var body: some View {
        VStack(alignment: .leading, spacing: RadarTheme.Layout.sectionSpacing) {
            HStack {
                Text("Meu trabalho").font(RadarTheme.Typography.title)
                Spacer()
                if store.jira.hasPendingUpdate || store.github.hasPendingUpdate {
                    Button("Aplicar atualização", action: focus.applyUpdates)
                        .font(RadarTheme.Typography.caption)
                        .help("Aplicar a nova revisão das listas e dos totais")
                        .focusable().focused($focused, equals: .applyUpdates).focusEffectDisabled()
                        .modifier(RadarFocusOutline(isFocused: focused == .applyUpdates))
                }
                Button(action: close) {
                    Image(systemName: "chevron.up")
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Recolher Radar")
                .padding(6)
                .focusable().focused($focused, equals: .collapse).focusEffectDisabled()
                .modifier(RadarFocusOutline(isFocused: focused == .collapse))
            }

            HStack(alignment: .top, spacing: RadarTheme.Layout.contentPadding) {
                JiraListView(store: store, focus: focus, focused: $focused)
                Rectangle().fill(RadarTheme.separator).frame(width: 1)
                GitHubListView(store: store, focus: focus, focused: $focused)
            }
            .frame(maxHeight: .infinity)

            Rectangle().fill(RadarTheme.separator).frame(height: 1)
            DetailsStripView(presentation: .current(in: store), close: focus.closeDetails, refresh: related.refresh,
                             canRefresh: store.jira.status.connection == .connected && store.github.status.connection == .connected
                                && !store.relations.isRefreshing, focused: $focused,
                             focus: focus, selectRelated: focus.selectRelated)
        }
        .padding(.horizontal, RadarTheme.Layout.contentPadding)
        .padding(.bottom, RadarTheme.Layout.contentPadding)
        .foregroundStyle(RadarTheme.primaryText)
        .onAppear { focused = focus.requestedTarget }
        .task(id: RelatedItemsTrigger(selection: store.selection.token, invalidation: store.relations.invalidation,
                                     jiraScope: store.jira.scope, githubScope: store.github.scope)) {
            focus.reconcileAliases()
            related.selectionChanged()
        }
        .onChange(of: store.github.items.map(\.id)) { _, _ in focus.reconcileAliases() }
        .onDisappear { related.stop() }
        .onChange(of: focused) { _, value in focus.focusedTarget = value }
        .onChange(of: focus.requestGeneration) { _, generation in
            Task { @MainActor in
                await Task.yield()
                guard focus.requestGeneration == generation else { return }
                focused = store.isPanelOpen ? focus.requestedTarget : nil
            }
        }
        .onMoveCommand(perform: focus.move)
        .onKeyPress(keys: [.tab], phases: .down) { press in
            guard press.modifiers.intersection([.command, .control, .option]).isEmpty else { return .ignored }
            focus.advance(backwards: press.modifiers.contains(.shift))
            return .handled
        }
        .onKeyPress(keys: [.return, .space], phases: .down) { press in
            guard press.modifiers.intersection([.command, .control, .option]).isEmpty else { return .ignored }
            return focus.activate(close: close, refreshDetails: related.refresh) ? .handled : .ignored
        }
    }

}
