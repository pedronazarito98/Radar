import AppKit
import SwiftUI

/// Observes only the window hosting this form; no global keyboard/window behavior.
struct ConnectionWindowCloseObserver: NSViewRepresentable {
    let onClose: @MainActor () -> Void

    func makeNSView(context: Context) -> ObserverView {
        let view = ObserverView()
        view.onClose = onClose
        return view
    }

    func updateNSView(_ nsView: ObserverView, context: Context) { nsView.onClose = onClose }

    static func dismantleNSView(_ nsView: ObserverView, coordinator: ()) {
        NotificationCenter.default.removeObserver(nsView)
        nsView.onClose = nil
    }

    final class ObserverView: NSView {
        var onClose: (@MainActor () -> Void)?

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            NotificationCenter.default.removeObserver(self)
            guard let window else { return }
            NotificationCenter.default.addObserver(self, selector: #selector(willClose),
                name: NSWindow.willCloseNotification, object: window)
        }

        @objc private func willClose(_ notification: Notification) { onClose?() }
    }
}
