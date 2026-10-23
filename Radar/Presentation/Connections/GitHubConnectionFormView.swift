import SwiftUI
import UniformTypeIdentifiers

struct GitHubConnectionFormView: View {
    let status: SourceStatus
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
                Button("Escolher gh…") { showsPicker = true }
                if let selectionProblem { Text(selectionProblem).foregroundStyle(.secondary) }
                Button("Validar gh", action: qualify).disabled(operation != nil)
                if let qualification { Text("gh \(qualification.version) validado. A autenticação ainda não foi consultada.").font(.caption) }
            }
            Section("Escopo pessoal") {
                TextField("Repositórios", text: $repositories, prompt: Text("owner/repo, owner/outro"))
                    .autocorrectionDisabled()
                Text("A consulta inclui autoria, atribuição e revisão solicitada somente nos repositórios escolhidos.")
                    .font(.caption).foregroundStyle(.secondary)
                Button("Conectar GitHub") {}.disabled(true)
            }
            Text("A validação executa somente --version, sem consultar sua conta. O Radar não instala o gh. As permissões existentes do CLI podem ser mais amplas que as consultas do app.")
                .font(.caption).foregroundStyle(.secondary)
        }
        .formStyle(.grouped)
        .onChange(of: executablePath) { _, _ in cancel(); qualification = nil }
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

    private func cancel() { generation = UUID(); operation?.cancel(); operation = nil }

}
