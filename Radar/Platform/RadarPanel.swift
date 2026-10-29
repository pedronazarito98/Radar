import AppKit

final class RadarPanel: NSPanel {
    var acceptsKeyboard = false
    var onEscape: (() -> Void)?
    var containsSurfacePoint: ((NSPoint) -> Bool)?

    override var canBecomeKey: Bool { acceptsKeyboard }

    override func cancelOperation(_ sender: Any?) {
        guard acceptsKeyboard else { return }
        onEscape?()
    }

    override var canBecomeMain: Bool { false }

    // Controls get first refusal through the normal responder chain. Events left
    // over on the panel's background end here, including scroll at a list boundary.
    override func scrollWheel(with event: NSEvent) {}
    override func mouseDown(with event: NSEvent) {}
    override func rightMouseDown(with event: NSEvent) {}
    override func otherMouseDown(with event: NSEvent) {}
    override func magnify(with event: NSEvent) {}
    override func rotate(with event: NSEvent) {}
    override func swipe(with event: NSEvent) {}
}
