import AppKit
import Observation

struct RadarDisplay: Identifiable, Equatable {
    let id: UInt32
    let name: String
}

/// Presentation-only observation. It never changes system settings or network work.
@MainActor
@Observable
final class DisplayPolicyController {
    private let preferences: PreferencesController
    private(set) var availableDisplays: [RadarDisplay] = []
    var geometryChanged: ((ScreenGeometry?) -> Void)?
    private var screenObserver: NSObjectProtocol?
    private var spaceObserver: NSObjectProtocol?
    private var observationGeneration = UUID()
    private var active = false

    init(preferences: PreferencesController) { self.preferences = preferences }

    func start() {
        guard !active else { return }
        active = true
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
        spaceObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.activeSpaceDidChangeNotification, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.refresh() }
        }
        refresh(); observePreference()
    }

    func refresh() {
        guard active else { return }
        availableDisplays = NSScreen.screens.compactMap { screen in
            guard let id = ScreenGeometryResolver.displayID(of: screen) else { return nil }
            return RadarDisplay(id: id, name: screen.localizedName)
        }
        geometryChanged?(ScreenGeometryResolver().resolve(preferredDisplayID: preferences.snapshot.preferredDisplayID))
    }

    func stop() {
        active = false; observationGeneration = UUID()
        if let screenObserver { NotificationCenter.default.removeObserver(screenObserver) }
        if let spaceObserver { NSWorkspace.shared.notificationCenter.removeObserver(spaceObserver) }
        screenObserver = nil; spaceObserver = nil; geometryChanged = nil
    }

    private func observePreference() {
        guard active else { return }
        let generation = UUID(); observationGeneration = generation
        withObservationTracking {
            _ = preferences.snapshot.preferredDisplayID
        } onChange: { [weak self] in
            Task { @MainActor in
                guard let self, self.active, self.observationGeneration == generation else { return }
                self.refresh(); self.observePreference()
            }
        }
    }
}
