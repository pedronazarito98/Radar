import AppKit

final class RadarPanel: NSPanel {
    var acceptsKeyboard = false
    var onEscape: (() -> Void)?

    override var canBecomeKey: Bool { acceptsKeyboard }

    override func cancelOperation(_ sender: Any?) {
        guard acceptsKeyboard else { return }
        onEscape?()
    }

    override var canBecomeMain: Bool { false }
}
