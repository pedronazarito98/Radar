import AppKit
import SwiftUI

struct JiraConnectionFormView: View {
    let store: RadarStore
    let connection: JiraCloudConnection
    @State private var operation: Task<Void, Never>?
    @State private var generation = UUID()
    @State private var message: String?
    @State private var hasSavedReference = false
    @State private var site = ""
    @State private var email = ""
    @State private var projects = ""
    @State private var usesScopedToken = true
    @State private var policyAllowsToken = false
    @State private var token = ""

    var body: some View {
        Form {
            Section {
                Text(SourceStatusText.summary(store.jira.status))
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
                    .disabled(!policyAllowsToken || operation != nil || hasSavedReference || store.jira.status.connection == .connected)
                Text("Informe o token somente aqui. A identidade será validada antes de salvar; consulta de cards exige uma ação separada.")
                    .font(.caption).foregroundStyle(.secondary)
                Button("Conectar Jira", action: connect)
                    .disabled(!policyAllowsToken || token.isEmpty || operation != nil || hasSavedReference || store.jira.status.connection == .connected)
                if hasSavedReference || store.jira.status.connection == .connected {
                    Button("Desconectar e remover token", action: disconnect).disabled(operation != nil)
                }
                if let message { Text(message).font(.caption).foregroundStyle(.secondary) }
            }
        }
        .formStyle(.grouped)
        .onDisappear(perform: cancelPending)
        .background(ConnectionWindowCloseObserver(onClose: cancelPending).frame(width: 0, height: 0))
        .task {
            let current = generation
            let saved = await connection.hasSavedReference()
            guard generation == current, !Task.isCancelled else { return }
            hasSavedReference = saved
        }
    }

    private func connect() {
        guard let configuration = JiraConnectionConfiguration(site: site, email: email, projects: projects,
            tokenKind: usesScopedToken ? .scoped : .legacy, policyAllowed: policyAllowsToken) else {
            message = "Confira site HTTPS atlassian.net, e-mail, projetos e a política da conta."
            return
        }
        let secret = token
        token = ""
        let current = UUID(); generation = current
        message = "Qualificando identidade…"
        operation = Task {
            do {
                let qualified = try await connection.connectAfterUserAction(configuration: configuration, token: secret, attemptID: current)
                guard generation == current, !Task.isCancelled else { return }
                store.configureSource(qualified.scope, connection: .connected)
                hasSavedReference = true
                message = "Identidade validada e token salvo. Os cards ainda não foram consultados."
            } catch {
                let saved = await connection.hasSavedReference()
                guard generation == current, !Task.isCancelled else { return }
                hasSavedReference = saved
                message = JiraConnectionErrorText.message(error)
            }
            guard generation == current else { return }
            operation = nil
        }
    }

    private func disconnect() {
        let current = UUID(); generation = current
        store.invalidate(.jira)
        token = ""
        operation = Task {
            do {
                try await connection.removeAfterUserAction()
                guard generation == current, !Task.isCancelled else { return }
                hasSavedReference = false
                message = "Conexão removida."
            } catch {
                guard generation == current, !Task.isCancelled else { return }
                hasSavedReference = true
                message = "Uso em memória interrompido. Remoção pendente: " + JiraConnectionErrorText.message(error)
            }
            guard generation == current else { return }
            operation = nil
        }
    }

    private func cancelPending() {
        token = ""
        guard operation != nil else { return }
        let cancelledAttempt = generation
        let cancelledOperation = operation
        generation = UUID()
        let cancellationGeneration = generation
        operation?.cancel(); operation = nil
        Task {
            await connection.cancelConnection(attemptID: cancelledAttempt)
            await cancelledOperation?.value
            let saved = await connection.hasSavedReference()
            guard generation == cancellationGeneration else { return }
            hasSavedReference = saved
        }
    }
}
