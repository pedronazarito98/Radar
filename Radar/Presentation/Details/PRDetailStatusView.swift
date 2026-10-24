import SwiftUI

struct PRDetailStatusView: View {
    let details: PRDetails

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Fase: \(PRStatusText.lifecycle(details.lifecycle))")
            Text("CI: \(PRStatusText.ci(details.ci.summary))")
            ForEach(Array(details.ci.signals.enumerated()), id: \.offset) { _, signal in
                Text(CISignalText.label(signal))
                    .foregroundStyle(RadarTheme.secondaryText)
            }
            Text("Solicitações observadas: \(details.review.requests.users.count) pessoas · \(details.review.requests.teams.count) equipes")
            if let role = details.review.personalRequestRole {
                Text("\(PRStatusText.roles([role])) · solicitação observada")
            }
            Text("Cobertura de solicitações: \(coverage(details.review.requests.coverage))")
                .foregroundStyle(RadarTheme.secondaryText)
            Text("Revisão: \(PRStatusText.review(details.review.summary))")
            if details.ci.coverage != .complete || details.review.coverage != .complete
                || details.review.requests.coverage != .complete {
                Text("Cobertura parcial ou indisponível")
                    .foregroundStyle(RadarTheme.attention)
            }
            let decisions = details.review.decisions
            Text("Observadas: \(decisions.approvals) aprovações · \(decisions.changesRequested) solicitações de alteração")
            if decisions.previousCommitReviews > 0 {
                Text("Revisões em outro commit: \(decisions.previousCommitReviews)")
            }
            Text("Commit \(String(details.version.headSHA.rawValue.prefix(7))) · \(details.version.observedAt.formatted(date: .omitted, time: .shortened))")
                .foregroundStyle(RadarTheme.secondaryText)
            Text("Decisões registradas não certificam as regras de merge.")
                .foregroundStyle(RadarTheme.secondaryText)
        }
        .font(RadarTheme.Typography.caption)
        .accessibilityElement(children: .combine)
    }
    private func coverage(_ value: ObservationCoverage) -> String {
        switch value {
        case .complete: "completa"
        case .partial: "parcial"
        case .unavailable: "indisponível"
        }
    }
}
