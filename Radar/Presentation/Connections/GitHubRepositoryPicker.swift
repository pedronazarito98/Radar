import SwiftUI

struct GitHubRepositoryPicker: View {
    let connection: GitHubConnectionController
    @State private var search = ""

    private var filtered: [GitHubRepositoryOption] {
        let term = search.trimmingCharacters(in: .whitespacesAndNewlines)
        return term.isEmpty ? connection.repositories : connection.repositories.filter {
            $0.name.fullName.localizedCaseInsensitiveContains(term)
        }
    }

    var body: some View {
        Section("Escolha seus repositórios") {
            TextField("Buscar nos repositórios carregados", text: $search)
                .textFieldStyle(.roundedBorder).autocorrectionDisabled()
            Text("\(connection.selectedIDs.count) de 10 selecionados · \(connection.repositories.count) carregados")
                .font(.caption).foregroundStyle(.secondary)
            if !connection.repositories.isEmpty {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        ForEach(filtered) { repository in
                            Toggle(isOn: Binding(
                                get: { connection.selectedIDs.contains(repository.id) },
                                set: { connection.select(repository.id, enabled: $0) })) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(repository.name.fullName).lineLimit(2)
                                        Label(repository.isPrivate ? "Privado" : "Público",
                                              systemImage: repository.isPrivate ? "lock" : "globe")
                                            .font(.caption).foregroundStyle(.secondary)
                                    }
                                }
                                .toggleStyle(.checkbox)
                                .disabled(connection.isBusy || (!connection.selectedIDs.contains(repository.id) && connection.selectedIDs.count >= 10))
                                .accessibilityLabel("\(repository.name.fullName), \(repository.isPrivate ? "privado" : "público")")
                        }
                        if filtered.isEmpty { Text("Nenhum resultado entre os repositórios carregados.").foregroundStyle(.secondary) }
                    }.frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 4)
                }
                .frame(maxHeight: 190)
            } else if connection.catalogLoaded && !connection.catalogCursor.hasMore && !connection.catalogCursor.isPartial {
                Text("Nenhum repositório liberado para o Radar nesta conta.").foregroundStyle(.secondary)
            } else if !connection.isBusy {
                Text("Carregue os repositórios disponíveis para escolher o que acompanhar.").foregroundStyle(.secondary)
            }
            if connection.catalogCursor.isPartial {
                Text("A lista está parcial: uma resposta mudou ou atingiu o limite de consulta. Os repositórios carregados continuam disponíveis para seleção.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            if connection.catalogProblem != nil {
                Text("A consulta não foi concluída. Os resultados já carregados foram preservados; tente carregar novamente.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            HStack {
                if connection.catalogCursor.hasMore {
                    Button(connection.catalogProblem == nil ? "Carregar mais" : "Tentar carregar novamente",
                           action: connection.loadMoreAfterUserAction).disabled(connection.isBusy)
                }
                Button("Atualizar lista", action: connection.reloadCatalogAfterUserAction).disabled(connection.isBusy)
            }
            Text("A busca filtra somente o que já foi carregado. Carregue mais para encontrar outros repositórios.")
                .font(.caption).foregroundStyle(.secondary)
        }
    }
}
