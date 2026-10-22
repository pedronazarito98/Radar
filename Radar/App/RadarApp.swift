import SwiftUI

@main
struct RadarApp: App {
    var body: some Scene {
        MenuBarExtra("Radar", systemImage: "dot.radiowaves.left.and.right") {
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
            ConnectionOverviewView()
        }
    }
}
