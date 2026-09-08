import SwiftUI

public enum FontSize {
    public static let xs: CGFloat = 12
    public static let sm: CGFloat = 14
    public static let base: CGFloat = 16
    public static let md: CGFloat = 17
    public static let xl: CGFloat = 20
    public static let xxl: CGFloat = 24
    public static let xxxl: CGFloat = 28
}

public extension Font {
    static func typo(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom(openRundeName(for: weight), size: size, relativeTo: textStyle(for: size))
    }

    private static func openRundeName(for weight: Font.Weight) -> String {
        switch weight {
        case .medium: "OpenRunde-Medium"
        case .semibold, .bold, .heavy, .black: "OpenRunde-Semibold"
        default: "OpenRunde-Regular"
        }
    }

    private static func textStyle(for size: CGFloat) -> Font.TextStyle {
        switch size {
        case 28...: .largeTitle
        case 22..<28: .title2
        case 18..<22: .title3
        case 15..<18: .body
        case 13.5..<15: .subheadline
        default: .footnote
        }
    }
}

public extension View {
    func typo(_ size: CGFloat, weight: Font.Weight = .regular) -> some View {
        font(.typo(size, weight: weight))
            .tracking(size * -0.02)
    }
}
