import SwiftUI

@main
struct RadarApp: App {
    @NSApplicationDelegateAdaptor(RadarAppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra(appDelegate.composition.store.isDemo ? "Radar Demo" : "Radar", systemImage: "dot.radiowaves.left.and.right") {
            Button("Abrir ou recolher Radar") {
                appDelegate.composition.togglePanel()
            }
            Divider()
            if let demo = appDelegate.composition.demo {
                RadarDemoMenu(demo: demo, select: appDelegate.composition.showDemoScenario,
                              simulateUpdate: appDelegate.composition.simulateDemoUpdate)
                Divider()
            }
            SettingsLink {
                Text("Configurações…")
            }
            Divider()
            Button("Encerrar Radar", role: .destructive) {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }

        Settings {
            if let demo = appDelegate.composition.demo {
                RadarDemoSettingsView(demo: demo, select: appDelegate.composition.showDemoScenario)
            } else {
                ConnectionsSettingsView(store: appDelegate.composition.store, jiraConnection: appDelegate.composition.jiraConnection, jiraWork: appDelegate.composition.jiraWork, githubConnection: appDelegate.composition.githubConnection, githubWork: appDelegate.composition.githubWork, preferences: appDelegate.composition.preferences, lifecycle: appDelegate.composition.lifecycle, displays: appDelegate.composition.displays)
            }
        }
    }
}
