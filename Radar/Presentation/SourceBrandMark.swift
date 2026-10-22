import SwiftUI

struct SourceBrandMark: View {
    enum Brand {
        case jira
        case github
    }

    let brand: Brand

    var body: some View {
        switch brand {
        case .jira:
            JiraSourceShape()
                .fill(RadarTheme.jiraAccent, style: FillStyle(eoFill: true))
        case .github:
            Image("GitHubInvertocat")
                .renderingMode(.original)
                .resizable()
                .scaledToFit()
        }
    }
}

private struct JiraSourceShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        for inset in [CGFloat.zero, min(rect.width, rect.height) * 0.32] {
            let bounds = rect.insetBy(dx: inset, dy: inset)
            path.move(to: CGPoint(x: bounds.midX, y: bounds.minY))
            path.addLine(to: CGPoint(x: bounds.maxX, y: bounds.midY))
            path.addLine(to: CGPoint(x: bounds.midX, y: bounds.maxY))
            path.addLine(to: CGPoint(x: bounds.minX, y: bounds.midY))
            path.closeSubpath()
        }
        return path
    }
}
