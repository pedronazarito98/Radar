import AppKit

@MainActor
final class PanelInteractionController: NSObject, NSWindowDelegate {
    private weak var panel: RadarPanel?
    private var previousApplication: NSRunningApplication?
    private var localMouseMonitor: Any?
    private var globalMouseMonitor: Any?
    var onDismiss: ((PanelDismissalReason) -> Void)?

    init(panel: RadarPanel) {
        self.panel = panel
        super.init()
        panel.delegate = self
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
                guard let self, event.window !== self.panel else { return }
                self.onDismiss?(.outsideClick)
            }
            return event
        }
        globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .otherMouseDown]) { [weak self] _ in
            MainActor.assumeIsolated {
                guard self?.globalMouseMonitor != nil else { return }
                self?.onDismiss?(.outsideClick)
            }
        }
    }

    func windowDidResignKey(_ notification: Notification) {
        guard localMouseMonitor != nil else { return }
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
