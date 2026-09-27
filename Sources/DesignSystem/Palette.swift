import SwiftUI

enum Palette {
    static let notch = Color.black
    static let card = Color.black
    static let ringTrack = Color.white.opacity(0.19)
    static let textSecondary = Color.white.opacity(0.65)
    static let ample = Color(red: 0, green: 1, blue: 0.53)
    static let watch = Color(red: 0.95, green: 1, blue: 0)
    static let critical = Color(red: 1, green: 0.25, blue: 0)
    static func usage(_ fraction: Double?) -> Color {
        guard let fraction else { return textSecondary }
        if fraction >= 0.7 { return critical }
        return fraction >= 0.5 ? watch : ample
    }
}
