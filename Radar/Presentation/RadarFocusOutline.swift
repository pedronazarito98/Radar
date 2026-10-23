import SwiftUI

struct RadarFocusOutline: ViewModifier {
    let isFocused: Bool

    func body(content: Content) -> some View {
        content.overlay {
            RoundedRectangle(cornerRadius: 9)
                .strokeBorder(isFocused ? RadarTheme.primaryText : .clear, lineWidth: 2)
                .allowsHitTesting(false)
        }
    }
}
