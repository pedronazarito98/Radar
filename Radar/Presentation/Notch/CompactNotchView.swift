import SwiftUI

struct CompactNotchView: View {
    let brand: SourceBrandMark.Brand
    let count: Count
    let status: SourceStatus
    let height: CGFloat
    let open: () -> Void

    private var sourceName: String { brand == .jira ? "Jira" : "GitHub" }

    var body: some View {
        Button(action: open) {
            HStack(spacing: 8) {
                SourceBrandMark(brand: brand)
                    .frame(width: RadarTheme.Layout.compactSymbolSize, height: RadarTheme.Layout.compactSymbolSize)
                    .accessibilityHidden(true)
                Text(count.displayText)
                    .monospacedDigit()
                    .foregroundStyle(brand == .github ? RadarTheme.githubAccent : RadarTheme.primaryText)
            }
            .font(RadarTheme.Typography.indicator)
            .frame(width: RadarTheme.Layout.compactWingWidth, height: height)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(sourceName). \(count.accessibilityDescription). \(SourceStatusText.summary(status))")
        .accessibilityHint("Abrir Radar")
    }
}
