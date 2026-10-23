import AppKit
import SwiftUI

struct JiraConnectionFormView: View {
    let status: SourceStatus
    @State private var site = ""
    @State private var email = ""
    @State private var projects = ""
    @State private var usesScopedToken = true
    @State private var policyAllowsToken = false
    @State private var token = ""

    var body: some View {
        Form {
            Section {
                Text(SourceStatusText.summary(status))
                Text("Conecte sua conta pessoal do Jira Cloud. O token será guardado somente no Keychain do Radar.")
                    .foregroundStyle(.secondary)
            }
            Section("Conta e escopo") {
                TextField("Site HTTPS", text: $site, prompt: Text("https://sua-equipe.atlassian.net"))
                    .autocorrectionDisabled()
                TextField("E-mail da conta", text: $email).autocorrectionDisabled()
                TextField("Chaves dos projetos", text: $projects, prompt: Text("Separe por vírgulas"))
                    .autocorrectionDisabled()
                Picker("Tipo de token", selection: $usesScopedToken) {
                    Text("Com escopos").tag(true)
                    Text("Sem escopos (legado)").tag(false)
                }
            }
            Section("Token pessoal") {
                Toggle("A política da minha organização permite esse método", isOn: $policyAllowsToken)
                SecureField("Token", text: $token)
                    .textContentType(.password)
                    .disabled(true)
                Text("A conexão ainda não está disponível neste build. Não informe o token agora.")
                    .font(.caption).foregroundStyle(.secondary)
                Button("Conectar Jira") {}.disabled(true)
            }
        }
        .formStyle(.grouped)
        .onDisappear { token = "" }
        .onReceive(NotificationCenter.default.publisher(for: NSWindow.willCloseNotification)) { _ in token = "" }
    }
}
