import SwiftUI

struct NotchPanelRootView: View {
    let isExpanded: Bool
    let cameraRect: CGRect
    let toggle: () -> Void
    let escape: () -> Void

    var body: some View {
        ZStack(alignment: .topLeading) {
            NotchSurfaceShape(cameraRect: cameraRect, cornerRadius: isExpanded ? RadarTheme.Layout.expandedRadius : RadarTheme.Layout.compactRadius)
                .fill(RadarTheme.surface, style: FillStyle(eoFill: true))
                .allowsHitTesting(false)

            indicator(.jira, label: "Jira, conta não conectada")
                .position(x: cameraRect.minX - RadarTheme.Layout.compactWingWidth / 2, y: cameraRect.height / 2)
            indicator(.github, label: "GitHub, conta não qualificada")
                .position(x: cameraRect.maxX + RadarTheme.Layout.compactWingWidth / 2, y: cameraRect.height / 2)

            if isExpanded {
                DisconnectedPanelView(close: toggle)
                    .padding(.top, cameraRect.height + RadarTheme.Layout.headerSpacing)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .preferredColorScheme(.dark)
        .onExitCommand(perform: escape)
    }

    private func indicator(_ brand: SourceBrandMark.Brand, label: String) -> some View {
        Button(action: toggle) {
            HStack(spacing: 8) {
                SourceBrandMark(brand: brand)
                    .frame(width: RadarTheme.Layout.compactSymbolSize, height: RadarTheme.Layout.compactSymbolSize)
                    .accessibilityHidden(true)
                Text("—").foregroundStyle(brand == .github ? RadarTheme.githubAccent : RadarTheme.primaryText)
            }
            .font(RadarTheme.Typography.indicator)
            .frame(width: RadarTheme.Layout.compactWingWidth, height: cameraRect.height)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityHint(isExpanded ? "Recolher Radar" : "Abrir Radar")
    }
}

private struct NotchSurfaceShape: Shape {
    let cameraRect: CGRect
    let cornerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path(roundedRect: rect, cornerRadius: cornerRadius)
        if cameraRect.width > 0 {
            path.addRect(cameraRect)
        }
        return path
    }
}
