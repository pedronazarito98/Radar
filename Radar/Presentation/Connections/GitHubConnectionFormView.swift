import AppKit
import SwiftUI

struct GitHubConnectionFormView: View {
    let status: SourceStatus
    let connection: GitHubConnectionController
    let work: GitHubWorkController
    let preferences: PreferencesController
    let lifecycle: DataLifecycleController
    @State private var browserProblem: String?
    @State private var copied = false

    var body: some View {
        Form {
            Section {
                Label("Seus pull requests, perto do trabalho", systemImage: "arrow.triangle.pull")
                    .font(.headline)
                Text("Entre com sua conta no navegador e escolha os repositórios que deseja acompanhar.")
                    .foregroundStyle(.secondary)
                if connection.configuration == nil {
                    Text("A conexão com o GitHub ainda precisa ser habilitada nesta versão do Radar. Depois disso, você poderá entrar por aqui, sem instalar ferramentas.")
                        .foregroundStyle(.secondary)
                    Button("Conectar ao GitHub") {}.disabled(true)
                } else if let user = connection.identity {
                    Label("Conectado como @\(user.login)", systemImage: "person.crop.circle.badge.checkmark")
                    if connection.isConnected { Text(SourceStatusText.summary(status)).font(.caption).foregroundStyle(.secondary) }
                } else if connection.challenge == nil {
                    if connection.hasSavedSession {
                        Button("Retomar conexão", action: connection.resumeAfterUserAction)
                            .buttonStyle(.borderedProminent).disabled(connection.isBusy)
                        Text("O macOS pode pedir sua permissão para usar a sessão salva neste Radar.")
                            .font(.caption).foregroundStyle(.secondary)
                    } else {
                        Button("Conectar ao GitHub", action: connection.connectAfterUserAction)
                            .buttonStyle(.borderedProminent).disabled(connection.isBusy)
                    }
                }
            }

            if let challenge = connection.challenge {
                Section("Autorize no GitHub") {
                    Text("No navegador, confirme sua conta e informe este código:")
                    Text(challenge.userCode).font(.system(.title2, design: .monospaced).weight(.semibold))
                        .textSelection(.enabled).accessibilityLabel("Código de autorização: \(challenge.userCode)")
                    HStack {
                        Button(copied ? "Abrir GitHub novamente" : "Copiar código e abrir GitHub") { openAuthorization(challenge) }
                            .buttonStyle(.borderedProminent)
                        Button("Cancelar", action: connection.cancelOnboarding)
                    }
                    Text("Válido até \(challenge.expiresAt.formatted(date: .omitted, time: .shortened)). Volte ao Radar depois de autorizar.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }

            if connection.isBusy {
                HStack { ProgressView().controlSize(.small); Text(connection.activity).font(.callout) }
                if connection.challenge == nil && connection.canCancel { Button("Cancelar", action: connection.cancelOnboarding) }
            }
            if let message = connection.message { Text(message).font(.callout).foregroundStyle(.secondary) }
            if let browserProblem { Text(browserProblem).font(.callout).foregroundStyle(.secondary) }

            if connection.identity != nil {
                GitHubRepositoryPicker(connection: connection)
                Section {
                    HStack {
                        Button(connection.isConnected ? "Salvar seleção" : "Começar a acompanhar",
                               action: connection.applySelectionAfterUserAction)
                            .buttonStyle(.borderedProminent).disabled(!connection.canApply)
                        if connection.isConnected {
                            Button("Atualizar PRs", action: work.requestAfterUserAction)
                                .disabled(connection.isBusy || status.isRefreshing)
                        }
                    }
                    if let configuration = connection.configuration {
                        Button("Liberar acesso a outros repositórios no GitHub…") { open(configuration.installationURL) }
                            .disabled(connection.isBusy)
                        Text("Se um repositório não aparecer, libere o acesso no GitHub e atualize a lista. Organizações podem exigir aprovação de um administrador.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                ConnectionRecoveryView(source: .github, status: status, retry: work.requestAfterUserAction)
            }

            if connection.hasSavedSession || connection.identity != nil {
                Section {
                    Button(connection.identity == nil ? "Remover sessão salva deste Radar" : "Desconectar GitHub",
                           role: .destructive, action: lifecycle.disconnectGitHub)
                        .disabled(connection.isBusy)
                    Text("Remove apenas a sessão salva neste Radar. A autorização da aplicação pode ser gerenciada nas configurações do GitHub.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            Text("O Radar consulta repositórios, pull requests e seus estados. Não altera código, revisões ou tarefas.")
                .font(.caption).foregroundStyle(.secondary)
        }
        .disabled(connection.isTerminating)
        .formStyle(.grouped)
        .scrollContentBackground(.hidden)
        .contentMargins(.top, 8, for: .scrollContent)
        .task { await connection.loadSavedState() }
        .onDisappear(perform: connection.cancelOnboarding)
        .onChange(of: connection.challenge?.userCode) { _, _ in copied = false; browserProblem = nil }
        .onChange(of: connection.isConnected) { _, connected in
            if connected { work.requestAfterUserAction(); Task { await preferences.load() } }
        }
        .background(ConnectionWindowCloseObserver(onClose: connection.cancelOnboarding).frame(width: 0, height: 0))
    }

    private func openAuthorization(_ challenge: GitHubDeviceChallenge) {
        guard challenge.expiresAt > Date() else { return }
        NSPasteboard.general.clearContents()
        copied = NSPasteboard.general.setString(challenge.userCode, forType: .string)
        open(GitHubAppConfiguration.verificationURL)
    }

    private func open(_ url: URL) {
        browserProblem = NSWorkspace.shared.open(url) ? nil : "Não foi possível abrir o navegador. Tente novamente."
    }
}
