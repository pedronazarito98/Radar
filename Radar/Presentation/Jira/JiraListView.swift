import SwiftUI

struct JiraListView: View {
    let store: RadarStore
    let focus: RadarFocusCoordinator
    let focused: FocusState<RadarFocusTarget?>.Binding

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SourceSectionHeader(brand: .jira, count: store.jira.count, subtitle: "Atribuídos a mim")
            if store.jira.items.isEmpty {
                SourceEmptyStateView(source: .jira, count: store.jira.count, status: store.jira.status)
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 4) {
                            ForEach(store.jira.items) { item in
                                let key = SelectionKey(contextID: store.contextID, itemID: .jira(item.id))
                                JiraRowView(item: item, key: key, focused: focused, isSelected: store.selection.selectedKey == key) {
                                    focus.select(key)
                                }
                                .id(key)
                            }
                        }
                    }
                    .onChange(of: focus.requestedTarget) { _, target in
                        if case let .row(key) = target, key.itemID.source == .jira { proxy.scrollTo(key) }
                    }
                }
                .accessibilityLabel("Cards pessoais do Jira")
            }
            Text(SourceStatusText.summary(store.jira.status))
                .font(RadarTheme.Typography.caption)
                .foregroundStyle(RadarTheme.secondaryText)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
