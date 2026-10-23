import SwiftUI

struct PRDetailStatusView: View {
    let details: PRDetails

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text("Fase: \(PRStatusText.lifecycle(details.lifecycle))")
            Text("CI: \(PRStatusText.ci(details.ci.summary))")
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
}
