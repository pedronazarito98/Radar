import AppKit

@MainActor
final class PanelInteractionController {
    private weak var panel: RadarPanel?
    private var previousApplication: NSRunningApplication?
    private var localMouseMonitor: Any?
    private var globalMouseMonitor: Any?
    var onDismiss: ((PanelDismissalReason) -> Void)?

    init(panel: RadarPanel) {
        self.panel = panel
    }

    func beginExplicitInteraction() {
        guard let panel, localMouseMonitor == nil else { return }
        let frontmost = NSWorkspace.shared.frontmostApplication
        previousApplication = frontmost?.processIdentifier == ProcessInfo.processInfo.processIdentifier
            ? nil : frontmost
        panel.acceptsKeyboard = true
        panel.makeKey()
        panel.makeFirstResponder(panel.contentView)

        localMouseMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]) { [weak self] event in
            MainActor.assumeIsolated {
                self?.dismissIfOutside(event)
            }
            return event
        }
        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]) { [weak self] event in
            MainActor.assumeIsolated {
                guard self?.globalMouseMonitor != nil else { return }
                self?.dismissIfOutside(event)
            }
        }
    }

    private func dismissIfOutside(_ event: NSEvent) {
        guard let panel, localMouseMonitor != nil else { return }
        var eventWindow = event.window
        while let window = eventWindow {
            if window === panel { return }
            eventWindow = window.parent ?? window.sheetParent
        }
        let screenPoint = event.window?.convertPoint(toScreen: event.locationInWindow) ?? event.locationInWindow
        guard panel.containsSurfacePoint?(screenPoint) != true else { return }
        onDismiss?(.outsideClick)
    }

    func endInteraction(reason: PanelDismissalReason) {
        if let localMouseMonitor { NSEvent.removeMonitor(localMouseMonitor) }
        if let globalMouseMonitor { NSEvent.removeMonitor(globalMouseMonitor) }
        localMouseMonitor = nil
        globalMouseMonitor = nil
        panel?.acceptsKeyboard = false
        let wasKey = panel?.isKeyWindow == true
        if wasKey { panel?.resignKey() }
        if reason.restoresPreviousApplication, wasKey {
            previousApplication?.activate(options: [])
        }
        previousApplication = nil
    }
}
