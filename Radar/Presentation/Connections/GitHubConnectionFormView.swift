import SwiftUI
import UniformTypeIdentifiers

struct GitHubConnectionFormView: View {
    let status: SourceStatus
    @State private var executablePath = "/opt/homebrew/bin/gh"
    @State private var repositories = ""
    @State private var showsPicker = false
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
                Button("Validar gh") {}.disabled(true)
            }
            Section("Escopo pessoal") {
                TextField("Repositórios", text: $repositories, prompt: Text("owner/repo, owner/outro"))
                    .autocorrectionDisabled()
                Text("A consulta inclui autoria, atribuição e revisão solicitada somente nos repositórios escolhidos.")
                    .font(.caption).foregroundStyle(.secondary)
                Button("Conectar GitHub") {}.disabled(true)
            }
            Text("A validação ainda não está disponível neste build. O Radar não instala o gh. As permissões existentes do CLI podem ser mais amplas que as consultas do app.")
                .font(.caption).foregroundStyle(.secondary)
        }
        .formStyle(.grouped)
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
}
