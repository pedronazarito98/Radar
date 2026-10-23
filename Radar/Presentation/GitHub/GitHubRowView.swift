import SwiftUI

struct GitHubRowView: View {
    let item: PullRequestItem
    let key: SelectionKey
    let focused: FocusState<RadarFocusTarget?>.Binding
    let isSelected: Bool
    let details: PRDetails?
    let category: RepositoryCategory?
    let select: () -> Void

    var body: some View {
        Button(action: select) {
            VStack(alignment: .leading, spacing: 5) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("#\(item.id.number)").fontWeight(.semibold)
                    Text(item.title).lineLimit(2).frame(maxWidth: .infinity, alignment: .leading)
                    Image(systemName: "chevron.right").font(.caption)
                }
                HStack(spacing: 5) {
                    Image(systemName: "shippingbox").accessibilityHidden(true)
                    Text(item.repositoryName.fullName).lineLimit(1).truncationMode(.middle)
                    if let category { Text(category.rawValue).fontWeight(.medium) }
                    Spacer(minLength: 0)
                    Text(PRStatusText.lifecycle(details?.lifecycle ?? item.lifecycle))
                }
                .font(RadarTheme.Typography.caption)
                .foregroundStyle(RadarTheme.secondaryText)
                Text(PRStatusText.roles(item.personalRoles))
                    .font(RadarTheme.Typography.caption)
                    .foregroundStyle(RadarTheme.secondaryText)
                    .lineLimit(2)
                if let details {
                    Text("CI: \(PRStatusText.ci(details.ci.summary)) · Revisão: \(PRStatusText.review(details.review.summary))")
                        .font(RadarTheme.Typography.caption).lineLimit(2)
                }
            }
            .font(RadarTheme.Typography.body)
            .padding(10)
            .foregroundStyle(RadarTheme.primaryText)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? RadarTheme.selection : .clear, in: RoundedRectangle(cornerRadius: 9))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .focusable().focused(focused, equals: .row(key)).focusEffectDisabled()
        .modifier(RadarFocusOutline(isFocused: focused.wrappedValue == .row(key)))
        .accessibilityElement(children: .combine)
        .accessibilityValue(isSelected ? "Selecionado" : "")
        .accessibilityHint("Mostrar conexões, CI e decisões de revisão deste PR")
        .help("\(item.repositoryName.fullName) #\(item.id.number) — \(item.title)")
    }
}
