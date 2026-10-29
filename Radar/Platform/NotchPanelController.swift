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
    private var geometry: ScreenGeometry
    private var hasAvailableDisplay = true
    private let navigation: NavigationCoordinator
    private let related: any RelatedItemsCoordinating
    private let demo: RadarDemoController?
    private let store: RadarStore
    private let focus: RadarFocusCoordinator
    private let hostingView: RadarHostingView
    private var contentOpacity: CGFloat = 0

    init(geometry: ScreenGeometry, store: RadarStore, related: any RelatedItemsCoordinating,
         navigation: NavigationCoordinator, demo: RadarDemoController? = nil) {
        self.geometry = geometry
        self.store = store
        self.related = related
        self.navigation = navigation
        self.demo = demo
        focus = RadarFocusCoordinator(store: store, navigation: navigation, demo: demo)
        panel = RadarPanel(
            contentRect: .zero,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        interaction = PanelInteractionController(panel: panel)
        hostingView = RadarHostingView(rootView: NotchPanelRootView(
            store: store, focus: focus, related: related, navigation: navigation, demo: demo,
            isExpanded: false, showsContent: false, contentOpacity: 0,
            cameraRect: .zero, open: {}, toggle: {}, escape: {}
        ))
        panel.title = store.isDemo ? "Radar Demo — dados fictícios" : "Radar — Meu trabalho"
        panel.isReleasedWhenClosed = false
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.hidesOnDeactivate = false
        panel.isMovable = false
        panel.ignoresMouseEvents = false
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        hostingView.sizingOptions = []
        hostingView.autoresizingMask = [.width, .height]
        panel.contentView = hostingView
        panel.containsSurfacePoint = { [weak hostingView] point in hostingView?.contains(screenPoint: point) == true }
        panel.onEscape = { [weak self] in self?.handleEscape() }
        interaction.onDismiss = { [weak self] reason in self?.dismiss(reason: reason) }
        navigation.didOpenDestination = { [weak self] in self?.dismiss(reason: .externalDestination) }
    }

    func toggle() {
        if isExpanded {
            dismiss(reason: .explicitToggle)
        } else {
            showExpanded()
        }
    }

    func showCompact() {
        focus.clear()
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
        guard hasAvailableDisplay, !isExpanded else { return }
        store.setPanelOpen(true)
        transition(expanding: true)
        interaction.beginExplicitInteraction()
        focus.open()
    }

    func dismiss(reason: PanelDismissalReason) {
        focus.clear()
        store.setPanelOpen(false)
        interaction.endInteraction(reason: reason)
        guard phase != .compact, phase != .closing else { return }
        transition(expanding: false)
    }

    func updateGeometry(_ value: ScreenGeometry?) {
        guard let value else {
            hasAvailableDisplay = false
            animator.cancel(); navigation.cancel(); related.stop()
            focus.clear(); store.setPanelOpen(false)
            interaction.endInteraction(reason: .outsideClick)
            phase = .compact; contentOpacity = 0
            panel.orderOut(nil)
            return
        }
        guard value != geometry || !hasAvailableDisplay else { return }
        let expanded = isExpanded
        animator.cancel()
        geometry = value; hasAvailableDisplay = true
        phase = expanded ? .expanded : .compact
        contentOpacity = expanded ? 1 : 0
        guard let frame = expanded
            ? geometry.expandedFrame(preferredSize: RadarTheme.Layout.expandedSize)
            : compactFrame else {
            panel.orderOut(nil)
            return
        }
        present(frame: frame)
        if !panel.isVisible { panel.orderFrontRegardless() }
    }

    func invalidate() {
        navigation.cancel()
        navigation.didOpenDestination = nil
        focus.clear()
        store.setPanelOpen(false)
        animator.cancel()
        interaction.endInteraction(reason: .termination)
        panel.onEscape = nil
        panel.containsSurfacePoint = nil
        interaction.onDismiss = nil
        panel.orderOut(nil)
        panel.contentView = nil
        panel.close()
    }

    private var compactFrame: NSRect? {
        guard hasAvailableDisplay else { return nil }
        return geometry.compactFrame(
            wingWidth: RadarTheme.Layout.compactWingWidth,
            height: geometry.safeTopHeight
        )
    }

    private func handleEscape() {
        guard isExpanded else { return }
        if store.selection.selectedKey != nil {
            focus.closeDetails()
        } else {
            dismiss(reason: .escape)
        }
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
        hostingView.surface = NotchSurfaceShape(
            cornerRadius: RadarTheme.Layout.compactRadius
                + (RadarTheme.Layout.expandedRadius - RadarTheme.Layout.compactRadius) * contentOpacity
        )
        hostingView.rootView = NotchPanelRootView(
            store: store, focus: focus, related: related, navigation: navigation, demo: demo,
            isExpanded: isExpanded,
            showsContent: phase != .compact,
            contentOpacity: contentOpacity,
            cameraRect: camera,
            open: { [weak self] in self?.showExpanded() },
            toggle: { [weak self] in self?.toggle() },
            escape: { [weak self] in self?.handleEscape() }
        )
        panel.setFrame(frame, display: true)
    }
}
