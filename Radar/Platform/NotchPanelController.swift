import AppKit
import SwiftUI

@MainActor
final class NotchPanelController {
    enum Phase {
        case compact, opening, expanded, closing
    }

    let panel: RadarPanel
    private(set) var phase: Phase = .compact
    var isExpanded: Bool { phase == .opening || phase == .expanded }
    private let interaction: PanelInteractionController
    private let animator = NotchFrameAnimator()
    private let geometry: ScreenGeometry
    private let store: RadarStore
    private let hostingView: NSHostingView<NotchPanelRootView>
    private var contentOpacity: CGFloat = 0

    init(geometry: ScreenGeometry, store: RadarStore) {
        self.geometry = geometry
        self.store = store
        panel = RadarPanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        interaction = PanelInteractionController(panel: panel)
        hostingView = NSHostingView(rootView: NotchPanelRootView(
            store: store,
            isExpanded: false, showsContent: false, contentOpacity: 0,
            cameraRect: .zero, toggle: {}, escape: {}
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
        store.setPanelOpen(false)
        animator.cancel()
        interaction.endInteraction(reason: .outsideClick)
        phase = .compact
        contentOpacity = 0
        guard let frame = compactFrame else {
            panel.orderOut(nil)
            return
        }
        present(frame: frame)
        panel.orderFrontRegardless()
    }

    func showExpanded() {
        guard !isExpanded else { return }
        store.setPanelOpen(true)
        transition(expanding: true)
        interaction.beginExplicitInteraction()
    }

    func dismiss(reason: PanelDismissalReason) {
        store.setPanelOpen(false)
        interaction.endInteraction(reason: reason)
        guard phase != .compact, phase != .closing else { return }
        transition(expanding: false)
    }

    func invalidate() {
        store.setPanelOpen(false)
        animator.cancel()
        interaction.endInteraction(reason: .termination)
        panel.onEscape = nil
        interaction.onDismiss = nil
        panel.orderOut(nil)
        panel.contentView = nil
        panel.close()
    }

    private var compactFrame: NSRect? {
        geometry.compactFrame(
            wingWidth: RadarTheme.Layout.compactWingWidth,
            height: geometry.safeTopHeight
        )
    }

    private func transition(expanding: Bool) {
        animator.cancel()
        guard let targetFrame = expanding
            ? geometry.expandedFrame(preferredSize: RadarTheme.Layout.expandedSize)
            : compactFrame else {
            showCompact()
            return
        }
        let motion = PresentationMotionPolicy.current
        if motion.reducesMotion, !expanding {
            showCompact()
            return
        }
        let startFrame = panel.isVisible && !motion.reducesMotion ? panel.frame : targetFrame
        let startOpacity = contentOpacity
        let targetOpacity: CGFloat = expanding ? 1 : 0
        phase = expanding ? .opening : .closing
        panel.orderFrontRegardless()
        animator.animate(duration: motion.duration) { [weak self] progress in
            guard let self else { return }
            self.contentOpacity = startOpacity + (targetOpacity - startOpacity) * progress
            self.present(frame: NSRect(
                x: startFrame.minX + (targetFrame.minX - startFrame.minX) * progress,
                y: startFrame.minY + (targetFrame.minY - startFrame.minY) * progress,
                width: startFrame.width + (targetFrame.width - startFrame.width) * progress,
                height: startFrame.height + (targetFrame.height - startFrame.height) * progress
            ))
        } completion: { [weak self] in
            guard let self else { return }
            self.phase = expanding ? .expanded : .compact
            self.contentOpacity = targetOpacity
            self.present(frame: targetFrame)
        }
    }

    private func present(frame: NSRect) {
        let camera = geometry.cameraFrame.map {
            NSRect(x: $0.minX - frame.minX, y: frame.maxY - $0.maxY, width: $0.width, height: $0.height)
        } ?? NSRect(x: frame.width / 2, y: 0, width: 0, height: 32)
        hostingView.rootView = NotchPanelRootView(
            store: store,
            isExpanded: isExpanded,
            showsContent: phase != .compact,
            contentOpacity: contentOpacity,
            cameraRect: camera,
            toggle: { [weak self] in self?.toggle() },
            escape: { [weak self] in self?.dismiss(reason: .escape) }
        )
        panel.setFrame(frame, display: true)
    }
}
