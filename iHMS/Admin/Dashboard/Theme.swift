import SwiftUI

struct Theme {
    static let background = Color(hex: "000000")
    static let surface = Color(hex: "111111")
    static let primaryText = Color.white
    static let secondaryText = Color(hex: "8E8E93")
    static let accent = Color.blue 
    static let cardBackground = Color(hex: "1C1C1E") // Dark Charcoal
    static let gridLine = Color(hex: "3A3A3C")
    
    static let cornerRadius: CGFloat = 16
    static let shadowRadius: CGFloat = 5
    static let shadowY: CGFloat = 2
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
            (a, r, g, b) = (255, 1, 1, 0)
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
