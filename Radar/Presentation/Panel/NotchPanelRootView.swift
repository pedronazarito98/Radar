import SwiftUI

struct NotchPanelRootView: View {
    let store: RadarStore
    let focus: RadarFocusCoordinator
    let related: RelatedItemsCoordinator
    let isExpanded: Bool
    let showsContent: Bool
    let contentOpacity: CGFloat
    let cameraRect: CGRect
    let toggle: () -> Void
    let escape: () -> Void

    var body: some View {
        let surface = NotchSurfaceShape(
            cameraRect: cameraRect,
            cornerRadius: RadarTheme.Layout.compactRadius
                + (RadarTheme.Layout.expandedRadius - RadarTheme.Layout.compactRadius) * contentOpacity
        )
        ZStack(alignment: .topLeading) {
            surface
                .fill(RadarTheme.surface, style: FillStyle(eoFill: true))
                .allowsHitTesting(false)

            CompactNotchView(
                brand: .jira, count: store.jira.count, status: store.jira.status,
                height: cameraRect.height, isExpanded: isExpanded, toggle: toggle
            )
                .position(x: cameraRect.minX - RadarTheme.Layout.compactWingWidth / 2, y: cameraRect.height / 2)
            CompactNotchView(
                brand: .github, count: store.github.count, status: store.github.status,
                height: cameraRect.height, isExpanded: isExpanded, toggle: toggle
            )
                .position(x: cameraRect.maxX + RadarTheme.Layout.compactWingWidth / 2, y: cameraRect.height / 2)

            if showsContent {
                RadarContentView(store: store, focus: focus, related: related, close: toggle)
                    .padding(.top, cameraRect.height + RadarTheme.Layout.headerSpacing)
                    .opacity(contentOpacity)
                    .allowsHitTesting(isExpanded)
                    .accessibilityHidden(!isExpanded)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .clipShape(surface, style: FillStyle(eoFill: true))
        .preferredColorScheme(.dark)
        .onExitCommand(perform: escape)
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
