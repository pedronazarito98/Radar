import AppKit

struct PresentationMotionPolicy {
    let reducesMotion: Bool

    var duration: TimeInterval { reducesMotion ? 0.12 : 0.25 }

    @MainActor
    static var current: Self {
        Self(reducesMotion: NSWorkspace.shared.accessibilityDisplayShouldReduceMotion)
    }
}
