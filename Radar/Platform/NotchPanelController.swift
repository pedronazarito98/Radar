import AppKit
import SwiftUI

@MainActor
final class NotchPanelController {
    let panel: RadarPanel
    private(set) var isExpanded = false
    private let interaction: PanelInteractionController
    private let geometry: ScreenGeometry
    private let hostingView: NSHostingView<NotchPanelRootView>

    init(geometry: ScreenGeometry) {
        self.geometry = geometry
        panel = RadarPanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        interaction = PanelInteractionController(panel: panel)
        hostingView = NSHostingView(rootView: NotchPanelRootView(
            isExpanded: false, cameraRect: .zero, toggle: {}, escape: {}
        ))
        panel.title = "Radar — Meu trabalho"
        panel.isReleasedWhenClosed = false
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.hidesOnDeactivate = false
        panel.isMovable = false
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        hostingView.sizingOptions = []
        hostingView.autoresizingMask = [.width, .height]
        panel.contentView = hostingView
        panel.onEscape = { [weak self] in self?.dismiss(reason: .escape) }
        interaction.onDismiss = { [weak self] reason in self?.dismiss(reason: reason) }
    }

    func toggle() {
        if isExpanded {
            dismiss(reason: .explicitToggle)
        } else {
            showExpanded()
        }
    }

    func showCompact() {
        isExpanded = false
        guard let frame = geometry.compactFrame(wingWidth: RadarTheme.Layout.compactWingWidth, height: geometry.safeTopHeight) else {
            panel.orderOut(nil)
            return
        }
        present(frame: frame)
    }

    func showExpanded() {
        isExpanded = true
        present(frame: geometry.expandedFrame(preferredSize: RadarTheme.Layout.expandedSize))
        interaction.beginExplicitInteraction()
    }

    func dismiss(reason: PanelDismissalReason) {
        interaction.endInteraction(reason: reason)
        showCompact()
    }

    func invalidate() {
        interaction.endInteraction(reason: .termination)
        panel.onEscape = nil
        interaction.onDismiss = nil
        panel.orderOut(nil)
        panel.contentView = nil
        panel.close()
    }

    private func present(frame: NSRect) {
        let camera = geometry.cameraFrame.map {
            NSRect(x: $0.minX - frame.minX, y: frame.maxY - $0.maxY, width: $0.width, height: $0.height)
        } ?? NSRect(x: frame.width / 2, y: 0, width: 0, height: 32)
        hostingView.rootView = NotchPanelRootView(
            isExpanded: isExpanded,
            cameraRect: camera,
            toggle: { [weak self] in self?.toggle() },
            escape: { [weak self] in self?.dismiss(reason: .escape) }
        )
        panel.setFrame(frame, display: true)
        panel.orderFrontRegardless()
    }
}
