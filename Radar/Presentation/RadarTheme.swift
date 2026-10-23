import SwiftUI

enum RadarTheme {
    static let surface = Color(red: 0.055, green: 0.075, blue: 0.09)
    static let selection = Color(red: 0.14, green: 0.17, blue: 0.20)
    static let separator = Color(red: 0.18, green: 0.22, blue: 0.26)
    static let primaryText = Color(red: 0.96, green: 0.97, blue: 0.99)
    static let secondaryText = Color(red: 0.68, green: 0.74, blue: 0.82)
    static let jiraAccent = Color(red: 0.04, green: 0.48, blue: 1)
    static let githubAccent = Color(red: 0.72, green: 0.43, blue: 0.98)
    static let positive = Color(red: 0.45, green: 0.85, blue: 0.50)
    static let attention = Color(red: 1, green: 0.72, blue: 0.25)
    static let negative = Color(red: 1, green: 0.34, blue: 0.40)

    enum Typography {
        static let title = Font.system(size: 20, weight: .semibold)
        static let heading = Font.system(size: 16, weight: .semibold)
        static let body = Font.system(size: 13)
        static let caption = Font.system(size: 12)
        static let indicator = Font.system(size: 14, weight: .semibold)
    }

    enum Layout {
        static let compactWingWidth: CGFloat = 72
        static let expandedSize = CGSize(width: 760, height: 520)
        static let compactRadius: CGFloat = 12
        static let expandedRadius: CGFloat = 24
        static let contentPadding: CGFloat = 24
        static let sectionSpacing: CGFloat = 20
        static let headerSpacing: CGFloat = 16
        static let compactSymbolSize: CGFloat = 19
        static let sourceSymbolSize: CGFloat = 26
    }
}
