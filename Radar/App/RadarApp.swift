import SwiftUI

@main
struct RadarApp: App {
    @NSApplicationDelegateAdaptor(RadarAppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("Radar", systemImage: "dot.radiowaves.left.and.right") {
            Button("Abrir ou recolher Radar") {
                appDelegate.panelController?.toggle()
            }
            Divider()
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
            ConnectionsSettingsView(store: appDelegate.store, jiraConnection: appDelegate.jiraConnection, jiraWork: appDelegate.jiraWork)
        }
    }
}
