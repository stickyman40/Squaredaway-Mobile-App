import SwiftUI

enum AppTheme {
    enum Colors {
        static let backgroundPrimary = Color(hex: "#0A0A0F")
        static let backgroundSecondary = Color(hex: "#12121A")
        static let backgroundCard = Color(hex: "#1A1A26")
        static let backgroundElevated = Color(hex: "#1F1F2E")

        static let accentPrimary = Color(hex: "#7B4FE0")
        static let accentSecondary = Color(hex: "#9D6FFF")
        static let accentLight = Color(hex: "#B89AFF")
        static let accentGlow = Color(hex: "#7B4FE0").opacity(0.35)

        static let gradientStart = Color(hex: "#7B4FE0")
        static let gradientEnd = Color(hex: "#4F2EA8")

        static let textPrimary = Color.white
        static let textSecondary = Color(hex: "#A0A0B8")
        static let textTertiary = Color(hex: "#5C5C7A")
        static let textPlaceholder = Color(hex: "#4A4A65")

        static let success = Color(hex: "#34C759")
        static let error = Color(hex: "#FF453A")
        static let warning = Color(hex: "#FF9F0A")

        static let glassBorder = Color.white.opacity(0.08)
        static let glassBackground = Color.white.opacity(0.04)
        static let glassTint = Color(hex: "#7B4FE0").opacity(0.05)
    }

    enum Gradients {
        static let primaryButton = LinearGradient(
            colors: [Colors.gradientStart, Colors.gradientEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let purpleGlow = RadialGradient(
            colors: [Colors.accentPrimary.opacity(0.4), Color.clear],
            center: .center,
            startRadius: 0,
            endRadius: 200
        )

        static let splashBackground = LinearGradient(
            colors: [Color(hex: "#0A0A0F"), Color(hex: "#130D1F"), Color(hex: "#0A0A0F")],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    enum Typography {
        static let displayLarge = Font.system(size: 34, weight: .bold)
        static let displayMedium = Font.system(size: 28, weight: .bold)
        static let titleLarge = Font.system(size: 22, weight: .semibold)
        static let titleMedium = Font.system(size: 18, weight: .semibold)
        static let titleSmall = Font.system(size: 16, weight: .semibold)
        static let bodyLarge = Font.system(size: 17)
        static let bodyMedium = Font.system(size: 15)
        static let bodySmall = Font.system(size: 13)
        static let caption = Font.system(size: 12)
        static let label = Font.system(size: 11, weight: .medium)
        static let button = Font.system(size: 16, weight: .semibold)
    }

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }

    enum Radius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 28
        static let full: CGFloat = 999
    }

    enum Shadows {
        static let cardRadius: CGFloat = 12
        static let cardY: CGFloat = 4
        static let glowRadius: CGFloat = 24
        static let glowOpacity: Double = 0.35
    }

    enum Animation {
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.25)
        static let spring = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.75)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.5)
        static let splash = SwiftUI.Animation.easeOut(duration: 0.8)
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
