import SwiftUI

extension Color {
    static let appBackground = Color(.systemGroupedBackground)
    static let appSurface = Color(.secondarySystemGroupedBackground)
    static let appCardBackground = Color(.tertiarySystemGroupedBackground)
    static let agroGreen = Color(red: 0.29, green: 0.49, blue: 0.31)
    static let agroGold = Color(red: 0.83, green: 0.64, blue: 0.29)
    static let frostRed = Color(red: 0.91, green: 0.30, blue: 0.24)
}

extension LinearGradient {
    static let moistureCard = LinearGradient(
        colors: [Color(red: 0.05, green: 0.22, blue: 0.42), Color(red: 0.10, green: 0.48, blue: 0.62)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let et0Card = LinearGradient(
        colors: [Color(red: 0.55, green: 0.27, blue: 0.07), Color(red: 0.82, green: 0.41, blue: 0.12)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let tempCard = LinearGradient(
        colors: [Color(red: 0.04, green: 0.36, blue: 0.31), Color(red: 0.08, green: 0.60, blue: 0.44)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let vpdCard = LinearGradient(
        colors: [Color(red: 0.29, green: 0.08, blue: 0.55), Color(red: 0.45, green: 0.14, blue: 0.72)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
    static let frostCard = LinearGradient(
        colors: [Color(red: 0.70, green: 0.08, blue: 0.18), Color(red: 0.90, green: 0.20, blue: 0.12)],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
}

extension Double {
    func formattedTemperature() -> String {
        String(format: "%.1f°C", self)
    }
}

extension DateFormatter {
    static let greekTime: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "el_GR")
        f.dateFormat = "HH:mm"
        return f
    }()
    static let greekDate: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "el_GR")
        f.dateFormat = "EEEE d MMMM"
        return f
    }()
}
