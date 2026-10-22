import SwiftUI

struct NotchPanelRootView: View {
    let isExpanded: Bool
    let cameraRect: CGRect
    let toggle: () -> Void

    var body: some View {
        ZStack(alignment: .topLeading) {
            NotchSurfaceShape(cameraRect: cameraRect, cornerRadius: isExpanded ? 24 : 12)
                .fill(Color(red: 0.055, green: 0.075, blue: 0.09), style: FillStyle(eoFill: true))
                .allowsHitTesting(false)

            indicator("diamond.fill", color: .blue, label: "Jira, conta não conectada")
                .position(x: cameraRect.minX - 36, y: cameraRect.height / 2)
            indicator("chevron.left.forwardslash.chevron.right", color: .purple, label: "GitHub, conta não qualificada")
                .position(x: cameraRect.maxX + 36, y: cameraRect.height / 2)

            if isExpanded {
                DisconnectedPanelView(close: toggle)
                    .padding(.top, cameraRect.height + 16)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .preferredColorScheme(.dark)
    }

    private func indicator(_ symbol: String, color: Color, label: String) -> some View {
        Button(action: toggle) {
            HStack(spacing: 8) {
                Image(systemName: symbol).foregroundStyle(color)
                Text("—").foregroundStyle(.white)
            }
            .font(.system(size: 14, weight: .semibold))
            .frame(width: 72, height: cameraRect.height)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityHint(isExpanded ? "Recolher Radar" : "Abrir Radar")
    }
}

private struct NotchSurfaceShape: Shape {
    let cameraRect: CGRect
    let cornerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path(roundedRect: rect, cornerRadius: cornerRadius)
        if cameraRect.width > 0 {
            path.addRect(cameraRect)
        }
        return path
    }
}
