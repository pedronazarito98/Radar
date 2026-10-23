import AppKit
import SwiftUI

struct PreferencesFormView: View {
    let preferences: PreferencesController

    var body: some View {
        Form {
            Section("Apresentação") {
                Picker("Tela preferida", selection: Binding(
                    get: { preferences.snapshot.preferredDisplayID },
                    set: { value in Task { await preferences.selectDisplay(value) } }
                )) {
                    Text("Automática — priorizar notch").tag(UInt32?.none)
                    ForEach(NSScreen.screens, id: \.self) { screen in
                        if let id = (screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value {
                            Text(screen.localizedName).tag(Optional(id))
                        }
                    }
                }
                Text("Se a tela escolhida estiver indisponível, o Radar usa o fallback disponível.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section("Categorias dos repositórios") {
                if preferences.snapshot.repositories.isEmpty {
                    Text("Escolha os repositórios na conexão GitHub para definir categorias opcionais.")
                }
                ForEach(preferences.snapshot.repositories, id: \.self) { repository in
                    Picker(repository, selection: Binding(
                        get: { preferences.snapshot.categories[repository] },
                        set: { category in Task { await preferences.selectCategory(category, repository: repository) } }
                    )) {
                        Text("Sem categoria").tag(RepositoryCategory?.none)
                        ForEach(RepositoryCategory.allCases, id: \.self) { category in
                            Text(category.rawValue).tag(Optional(category))
                        }
                    }
                }
                Text("Categorias são escolhas suas; nenhum repositório é classificado pelo nome.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            if let message = preferences.message { Text(message).foregroundStyle(.secondary) }
            Text("Somente preferências e a referência própria do token são salvas. Cards, PRs e respostas dos serviços ficam em memória.")
                .font(.caption).foregroundStyle(.secondary)
        }
        .formStyle(.grouped)
        .task { await preferences.load() }
    }
}
