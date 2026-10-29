import SwiftUI

struct RadarDemoMenu: View {
    let demo: RadarDemoController
    let select: (RadarDemoScenario) -> Void
    let simulateUpdate: () -> Void

    var body: some View {
        Menu("Cenários de demonstração") {
            ForEach(RadarDemoScenario.allCases) { scenario in
                Button { select(scenario) } label: {
                    if demo.scenario == scenario {
                        Label(scenario.title, systemImage: "checkmark")
                    } else {
                        Text(scenario.title)
                    }
                }
            }
        }
        Button("Simular atualização", action: simulateUpdate)
        Text("Dados fictícios · sem conexão")
    }
}
