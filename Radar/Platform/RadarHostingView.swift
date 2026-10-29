import AppKit
import SwiftUI

/// The drawn surface and the native input region stay in sync while the panel animates.
final class RadarHostingView: NSHostingView<NotchPanelRootView> {
    var surface = NotchSurfaceShape(cornerRadius: 0)

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
    override func shouldDelayWindowOrdering(for event: NSEvent) -> Bool { false }
    override var mouseDownCanMoveWindow: Bool { false }

    override func hitTest(_ point: NSPoint) -> NSView? {
        let localPoint = convert(point, from: superview)
        guard !isHidden, surface.path(in: bounds).contains(localPoint, eoFill: true) else { return nil }
        return super.hitTest(point) ?? self
    }

    func contains(screenPoint: NSPoint) -> Bool {
        guard let window, window.isVisible else { return false }
        let localPoint = convert(window.convertPoint(fromScreen: screenPoint), from: nil)
        return surface.path(in: bounds).contains(localPoint, eoFill: true)
    }
}
