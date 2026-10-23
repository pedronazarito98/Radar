import SwiftUI

struct ConnectionRecoveryView: View {
    let source: WorkSource
    let status: SourceStatus
    let retry: () -> Void

    var body: some View {
        if let plan = ConnectionRecoveryController.plan(source: source, status: status) {
            Section("Recuperar esta origem") {
                Text(plan.message).font(.caption).foregroundStyle(.secondary)
                if plan.action == .retry, status.connection == .connected {
                    Button("Tentar novamente", action: retry).disabled(status.isRefreshing)
                }
            }
        }
    }
}
