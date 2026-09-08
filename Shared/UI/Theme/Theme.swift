import SwiftUI
import UIKit

public enum Theme {
    public static let background = dynamic(light: 0xFFFFFF, dark: 0x101012)
    public static let backgroundSubtle = dynamic(light: 0xFAFAFA, dark: 0x141416)

    public static let bg1 = dynamic(light: 0xFFFFFF, dark: 0x151517)
    public static let bg2 = dynamic(light: 0xF6F6F7, dark: 0x1C1C1F)
    public static let bg3 = dynamic(light: 0xEFF0F1, dark: 0x232326)

    public static let fg1 = dynamic(light: 0xB1B2B5, dark: 0x6E6E73)
    public static let fg2 = dynamic(light: 0x6E6F75, dark: 0x909096)
    public static let fg3 = dynamic(light: 0x525358, dark: 0xB9B9BE)
    public static let fg4 = dynamic(light: 0x17181C, dark: 0xEDEDEE)

    public static let primary = fg4
    public static let primaryForeground = background

    public static let green = solid(0x58D176)
    public static let amber = solid(0xFFB62E)
    public static let red = solid(0xFF3B30)
    public static let redText = dynamic(light: 0xF40107, dark: 0xFF3B30)
    public static let sky = dynamic(light: 0x4D8DFA, dark: 0x6BA1FF)

    public static let brand1 = dynamic(light: 0xEEF2FF, dark: 0x0F1339)
    public static let brand2 = dynamic(light: 0xD9E3FF, dark: 0x171D53)

    public static let ink = dynamic(light: 0x17181C, dark: 0x030304)
    public static let inkForeground = Color.white

    public static let ring = dynamic(light: 0x000000, dark: 0x232326, lightAlpha: 0.06, darkAlpha: 1)
    public static let shadow = dynamic(light: 0x000000, dark: 0x000000, lightAlpha: 0.08, darkAlpha: 0.25)

    public enum Radius {
        public static let notification: CGFloat = 22
        public static let sheet: CGFloat = 24
    }

    private static func solid(_ hex: UInt32) -> Color {
        Color(uiColor: UIColor(hex: hex, alpha: 1))
    }

    private static func dynamic(
        light: UInt32,
        dark: UInt32,
        lightAlpha: CGFloat = 1,
        darkAlpha: CGFloat = 1
    ) -> Color {
        Color(
            uiColor: UIColor { traits in
                traits.userInterfaceStyle == .dark
                    ? UIColor(hex: dark, alpha: darkAlpha)
                    : UIColor(hex: light, alpha: lightAlpha)
            }
        )
    }
}

public enum Motion {
    public static let swap = Animation.spring(duration: 0.3, bounce: 0)
    public static let entrance = Animation.easeOut(duration: 0.4)
    public static let cardSwap = Animation.easeOut(duration: 0.5)
}

private extension UIColor {
    convenience init(hex: UInt32, alpha: CGFloat) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: alpha
        )
    }
}
