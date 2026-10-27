import SwiftUI

struct RadarDemoSettingsView: View {
    let demo: RadarDemoController
    let select: @MainActor @Sendable (RadarDemoScenario) -> Void

    var body: some View {
        Form {
            Section("Demonstração do Radar") {
                Text("Explore a interface com dados fictícios, sem conectar contas.")
                Picker("Cenário", selection: Binding(get: { demo.scenario }, set: select)) {
                    ForEach(RadarDemoScenario.allCases) { scenario in
                        Text(scenario.title).tag(scenario)
                    }
                }
                Text(demo.scenario.description).foregroundStyle(.secondary)
                Button("Abrir cenário") { select(demo.scenario) }
            }
            Section("O que experimentar") {
                Text("Selecione um card, abra um PR relacionado e volte pelo Esc. Os totais pessoais permanecem iguais.")
                Text("Troque rapidamente a seleção para conferir o carregamento e use Tab e setas para navegar.")
                Text("Abrir e copiar links ficam desativados: todos os destinos são fictícios. Para conectar suas contas, use o app Radar normal.")
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .frame(width: 540, height: 400)
    }
}
