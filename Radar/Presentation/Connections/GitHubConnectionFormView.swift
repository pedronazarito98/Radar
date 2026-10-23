import SwiftUI
import UniformTypeIdentifiers

struct GitHubConnectionFormView: View {
    let status: SourceStatus
    let connection: GitHubConnectionController
    let work: GitHubWorkController
    @State private var executablePath = "/opt/homebrew/bin/gh"
    @State private var repositories = ""
    @State private var showsPicker = false
    @State private var qualification: QualifiedGitHubExecutable?
    @State private var operation: Task<Void, Never>?
    @State private var generation = UUID()
    @State private var selectionProblem: String?

    var body: some View {
        Form {
            Section {
                Text(SourceStatusText.summary(status))
                Text("Use o gh já instalado e autenticado. O Radar consulta GitHub.com e não altera sua autenticação.")
                    .foregroundStyle(.secondary)
            }
            Section("GitHub CLI") {
                TextField("Caminho absoluto", text: $executablePath).autocorrectionDisabled()
                    .disabled(operation != nil || status.connection == .connected)
                Button("Escolher gh…") { showsPicker = true }.disabled(operation != nil || status.connection == .connected)
                if let selectionProblem { Text(selectionProblem).foregroundStyle(.secondary) }
                Button("Validar gh", action: qualify).disabled(operation != nil || status.connection == .connected)
                if let qualification {
                    Text(status.connection == .connected
                         ? "gh \(qualification.version) · identidade qualificada"
                         : "gh \(qualification.version) validado. A autenticação ainda não foi consultada.").font(.caption)
                }
            }
            Section("Escopo pessoal") {
                TextField("Repositórios", text: $repositories, prompt: Text("owner/repo, owner/outro"))
                    .autocorrectionDisabled().disabled(operation != nil || status.connection == .connected)
                Text("A consulta inclui autoria, atribuição e revisão solicitada somente nos repositórios escolhidos.")
                    .font(.caption).foregroundStyle(.secondary)
                Text("Escolha de 1 a 10 repositórios; excesso será recusado.").font(.caption)
                Button("Conectar GitHub", action: connect).disabled(qualification == nil || operation != nil || status.connection == .connected)
                if status.connection == .connected {
                    Button("Consultar / atualizar PRs") { work.requestAfterUserAction() }.disabled(status.isRefreshing)
                    Button("Desconectar GitHub") { work.stop(); connection.disconnect() }
                }
            }
            Text("Validar gh executa somente --version. Conectar GitHub consulta sua identidade por GET /user. O Radar não instala o gh. As permissões existentes do CLI podem ser mais amplas que as consultas do app.")
                .font(.caption).foregroundStyle(.secondary)
        }
        .formStyle(.grouped)
        .onChange(of: executablePath) { _, _ in
            guard status.connection != .connected else { return }
            cancel(); qualification = nil
        }
        .task {
            if let executable = connection.executable {
                executablePath = executable.url.path
                qualification = executable
            }
            if case let .github(repos) = connection.store.github.scope?.resources {
                repositories = repos.map(\.fullName).sorted().joined(separator: ", ")
            }
        }
        .onDisappear(perform: cancel)
        .background(ConnectionWindowCloseObserver(onClose: cancel).frame(width: 0, height: 0))
        .fileImporter(isPresented: $showsPicker, allowedContentTypes: [.item]) { result in
            switch result {
            case .success(let url):
                executablePath = url.path
                selectionProblem = nil
            case .failure:
                selectionProblem = "Não foi possível selecionar o arquivo."
            }
        }
    }

    private func qualify() {
        let current = UUID(); generation = current
        let path = executablePath
        selectionProblem = nil
        qualification = nil
        operation = Task {
            do {
                let result = try await GitHubExecutableResolver().qualify(path: path)
                guard generation == current, !Task.isCancelled else { return }
                qualification = result
            } catch {
                guard generation == current, !Task.isCancelled else { return }
                if case let GitHubCLIError.source(problem) = error { selectionProblem = SourceStatusText.message(for: problem) }
                else { selectionProblem = "A validação foi interrompida." }
            }
            guard generation == current else { return }
            operation = nil
        }
    }

    private func connect() {
        guard let qualification else { return }
        let current = UUID(); generation = current
        selectionProblem = "Qualificando identidade…"
        operation = Task {
            do {
                try await connection.connect(executable: qualification, repositories: repositories)
                guard generation == current, !Task.isCancelled else { return }
                selectionProblem = "Identidade qualificada. A lista de PRs será atualizada."
            } catch {
                guard generation == current, !Task.isCancelled else { return }
                if case let GitHubCLIError.source(problem) = error { selectionProblem = SourceStatusText.message(for: problem) }
                else if case GitHubCLIError.identityChanged = error {
                    connection.requireRequalification()
                    selectionProblem = "A conta ativa mudou durante a consulta. Qualifique novamente."
                } else { selectionProblem = "A consulta foi interrompida." }
            }
            guard generation == current else { return }
            operation = nil
        }
    }

    private func cancel() { generation = UUID(); operation?.cancel(); operation = nil }

}
