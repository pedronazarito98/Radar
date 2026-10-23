import SwiftUI

struct GitHubListView: View {
    let store: RadarStore

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            SourceSectionHeader(brand: .github, count: store.github.count, subtitle: "Meus PRs e revisões")
            if store.github.items.isEmpty {
                SourceEmptyStateView(source: .github, count: store.github.count, status: store.github.status)
            } else {
                ScrollView {
                    LazyVStack(spacing: 4) {
                        ForEach(store.github.items) { item in
                            let key = SelectionKey(contextID: store.contextID, itemID: .pullRequest(item.id))
                            let details = store.selection.prDetails.details
                            GitHubRowView(
                                item: item, isSelected: store.selection.selectedKey == key,
                                details: details?.version.pullRequestID == item.id ? details : nil
                            ) { store.select(key) }
                                .id(key)
                        }
                    }
                }
                .accessibilityLabel("Pull requests pessoais do GitHub")
            }
            Text(SourceStatusText.summary(store.github.status))
                .font(RadarTheme.Typography.caption)
                .foregroundStyle(RadarTheme.secondaryText)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
