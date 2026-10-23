import SwiftUI

struct ConnectionsSettingsView: View {
    let store: RadarStore
    let jiraConnection: JiraCloudConnection
    let jiraWork: JiraWorkController
    let githubConnection: GitHubConnectionController
    let githubWork: GitHubWorkController

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Conexões do Radar").font(.title2.weight(.semibold))
                .padding(.horizontal, 20).padding(.top, 16)
            TabView {
                JiraConnectionFormView(store: store, connection: jiraConnection, work: jiraWork)
                    .tabItem { Label("Jira Cloud", systemImage: "square.stack") }
                GitHubConnectionFormView(status: store.github.status, connection: githubConnection, work: githubWork)
                    .tabItem { Label("GitHub.com", systemImage: "chevron.left.forwardslash.chevron.right") }
            }
        }
        .frame(width: 600, height: 570)
    }
}
