import SwiftUI

struct NotchSurfaceShape: Shape {
    let cornerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        Path(roundedRect: rect, cornerRadius: cornerRadius)
    }
}
