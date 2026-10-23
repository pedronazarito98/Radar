import SwiftUI

struct SourceSectionHeader: View {
    let brand: SourceBrandMark.Brand
    let count: Count
    let subtitle: String

    var body: some View {
        HStack(spacing: 10) {
            SourceBrandMark(brand: brand)
                .frame(width: RadarTheme.Layout.sourceSymbolSize, height: RadarTheme.Layout.sourceSymbolSize)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(brand == .jira ? "Jira" : "GitHub")
                        .font(RadarTheme.Typography.heading)
                    Text(count.displayText)
                        .font(RadarTheme.Typography.heading.monospacedDigit())
                        .foregroundStyle(RadarTheme.secondaryText)
                        .accessibilityLabel(count.accessibilityDescription)
                }
                Text(subtitle)
                    .font(RadarTheme.Typography.caption)
                    .foregroundStyle(RadarTheme.secondaryText)
            }
            Spacer(minLength: 0)
        }
        .foregroundStyle(RadarTheme.primaryText)
    }
}
