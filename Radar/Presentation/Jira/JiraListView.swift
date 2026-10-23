import SwiftUI

struct JiraListView: View {
    let store: RadarStore

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SourceSectionHeader(brand: .jira, count: store.jira.count, subtitle: "Atribuídos a mim")
            if store.jira.items.isEmpty {
                SourceEmptyStateView(source: .jira, count: store.jira.count, status: store.jira.status)
            } else {
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(store.jira.items) { item in
                            let key = SelectionKey(contextID: store.contextID, itemID: .jira(item.id))
                            JiraRowView(item: item, isSelected: store.selection.selectedKey == key) {
                                store.select(key)
                            }
                            .id(key)
                        }
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
