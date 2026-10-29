import SwiftUI

struct NotchPanelRootView: View {
    let store: RadarStore
    let focus: RadarFocusCoordinator
    let related: any RelatedItemsCoordinating
    let navigation: NavigationCoordinator
    let demo: RadarDemoController?
    let isExpanded: Bool
    let showsContent: Bool
    let contentOpacity: CGFloat
    let cameraRect: CGRect
    let open: () -> Void
    let toggle: () -> Void
    let escape: () -> Void

    var body: some View {
        let surface = NotchSurfaceShape(
            cornerRadius: RadarTheme.Layout.compactRadius
                + (RadarTheme.Layout.expandedRadius - RadarTheme.Layout.compactRadius) * contentOpacity
        )
        ZStack(alignment: .topLeading) {
            surface
                .fill(RadarTheme.surface, style: FillStyle(eoFill: true))

            // Keep the physical camera area black while the whole notch receives input.
            if cameraRect.width > 0 {
                Color.black
                    .frame(width: cameraRect.width, height: cameraRect.height)
                    .position(x: cameraRect.midX, y: cameraRect.midY)
                    .accessibilityHidden(true)
            }

            CompactNotchView(
                brand: .jira, count: store.jira.count, status: store.jira.status,
                height: cameraRect.height, open: open
            )
                .position(x: cameraRect.minX - RadarTheme.Layout.compactWingWidth / 2, y: cameraRect.height / 2)
            CompactNotchView(
                brand: .github, count: store.github.count, status: store.github.status,
                height: cameraRect.height, open: open
            )
                .position(x: cameraRect.maxX + RadarTheme.Layout.compactWingWidth / 2, y: cameraRect.height / 2)

            if showsContent {
                RadarContentView(store: store, focus: focus, related: related, navigation: navigation, demo: demo, close: toggle)
                    .padding(.top, cameraRect.height + RadarTheme.Layout.headerSpacing)
                    .opacity(contentOpacity)
                    .allowsHitTesting(isExpanded)
                    .accessibilityHidden(!isExpanded)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .contentShape(.interaction, surface, eoFill: true)
        .onTapGesture(perform: open)
        .clipShape(surface, style: FillStyle(eoFill: true))
        .preferredColorScheme(.dark)
        .onExitCommand(perform: escape)
    }

}
