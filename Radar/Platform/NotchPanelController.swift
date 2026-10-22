import AppKit
import SwiftUI

@MainActor
final class NotchPanelController {
    let panel: RadarPanel
    private(set) var isExpanded = false
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
        hostingView = NSHostingView(rootView: NotchPanelRootView(
            isExpanded: false, cameraRect: .zero, toggle: {}
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
    }

    func toggle() {
        if isExpanded {
            showCompact()
        } else {
            showExpanded()
        }
    }

    func showCompact() {
        isExpanded = false
        guard let frame = geometry.compactFrame(wingWidth: 72, height: geometry.safeTopHeight) else {
            panel.orderOut(nil)
            return
        }
        present(frame: frame)
    }

    func showExpanded() {
        isExpanded = true
        present(frame: geometry.expandedFrame(preferredSize: NSSize(width: 760, height: 410)))
    }

    func invalidate() {
        panel.orderOut(nil)
        panel.contentView = nil
        panel.close()
    }

    private func present(frame: NSRect) {
        let camera = geometry.cameraFrame.map {
            NSRect(x: $0.minX - frame.minX, y: frame.maxY - $0.maxY, width: $0.width, height: $0.height)
        } ?? NSRect(x: frame.width / 2, y: 0, width: 0, height: 32)
        hostingView.rootView = NotchPanelRootView(
            isExpanded: isExpanded, cameraRect: camera, toggle: { [weak self] in self?.toggle() }
        )
        panel.setFrame(frame, display: true)
        panel.orderFrontRegardless()
    }
}
