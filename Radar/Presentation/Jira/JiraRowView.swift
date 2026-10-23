import SwiftUI

struct JiraRowView: View {
    let item: JiraWorkItem
    let key: SelectionKey
    let focused: FocusState<RadarFocusTarget?>.Binding
    let isSelected: Bool
    let select: () -> Void

    var body: some View {
        Button(action: select) {
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.key.rawValue).font(RadarTheme.Typography.body.weight(.semibold))
                    Text(item.summary).font(RadarTheme.Typography.body).lineLimit(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Text(item.status.name)
                    .font(RadarTheme.Typography.caption)
                    .lineLimit(2)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(RadarTheme.separator.opacity(0.6), in: Capsule())
                    .frame(maxWidth: 112)
                Image(systemName: "chevron.right")
                    .font(.caption).foregroundStyle(RadarTheme.secondaryText)
            }
            .padding(10)
            .foregroundStyle(RadarTheme.primaryText)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? RadarTheme.selection : .clear, in: RoundedRectangle(cornerRadius: 9))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .focusable().focused(focused, equals: .row(key)).focusEffectDisabled()
        .modifier(RadarFocusOutline(isFocused: focused.wrappedValue == .row(key)))
        .accessibilityLabel("\(item.key.rawValue). \(item.summary). Status: \(item.status.name)")
        .accessibilityValue(isSelected ? "Selecionado" : "")
        .accessibilityHint("Mostrar conexões deste card")
        .help(item.summary)
    }
}
