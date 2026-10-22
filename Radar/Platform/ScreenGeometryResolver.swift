import AppKit

struct ScreenGeometry {
    let displayID: CGDirectDisplayID
    let screenFrame: NSRect
    let visibleFrame: NSRect
    let backingScale: CGFloat
    let cameraFrame: NSRect?

    var hasNotch: Bool { cameraFrame != nil }
    var safeTopHeight: CGFloat { cameraFrame?.height ?? 0 }

    func compactFrame(wingWidth: CGFloat, height: CGFloat) -> NSRect? {
        guard let cameraFrame else { return nil }
        let width = min(cameraFrame.width + wingWidth * 2, screenFrame.width)
        let boundedHeight = min(max(height, cameraFrame.height), screenFrame.height)
        return boundedTopFrame(width: width, height: boundedHeight, centerX: cameraFrame.midX)
    }

    func expandedFrame(preferredSize: NSSize) -> NSRect {
        let bounds = hasNotch ? screenFrame : visibleFrame
        let width = min(preferredSize.width, bounds.width)
        let height = min(preferredSize.height, bounds.height)
        let center = cameraFrame?.midX ?? bounds.midX
        let x = min(max(center - width / 2, bounds.minX), bounds.maxX - width)
        return NSRect(x: x, y: bounds.maxY - height, width: width, height: height)
    }

    private func boundedTopFrame(width: CGFloat, height: CGFloat, centerX: CGFloat) -> NSRect {
        let x = min(max(centerX - width / 2, screenFrame.minX), screenFrame.maxX - width)
        return NSRect(x: x, y: screenFrame.maxY - height, width: width, height: height)
    }
}

@MainActor
struct ScreenGeometryResolver {
    func resolve() -> ScreenGeometry? {
        let candidates = NSScreen.screens
        let screen = candidates.first(where: { cameraFrame(on: $0) != nil })
            ?? NSScreen.main
            ?? candidates.first
        guard let screen else { return nil }
        let number = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber
        return ScreenGeometry(
            displayID: number?.uint32Value ?? CGMainDisplayID(),
            screenFrame: screen.frame,
            visibleFrame: screen.visibleFrame,
            backingScale: screen.backingScaleFactor,
            cameraFrame: cameraFrame(on: screen)
        )
    }

    private func cameraFrame(on screen: NSScreen) -> NSRect? {
        let height = screen.safeAreaInsets.top
        guard height > 0,
              let left = screen.auxiliaryTopLeftArea,
              let right = screen.auxiliaryTopRightArea else { return nil }
        let cameraMinX = max(screen.frame.minX, left.maxX)
        let cameraMaxX = min(screen.frame.maxX, right.minX)
        guard cameraMaxX > cameraMinX else { return nil }
        return NSRect(
            x: cameraMinX,
            y: screen.frame.maxY - min(height, screen.frame.height),
            width: cameraMaxX - cameraMinX,
            height: min(height, screen.frame.height)
        )
    }
}
