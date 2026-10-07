import SwiftUI

enum NovaTheme {
    static let bg0 = Color(red: 0.04, green: 0.05, blue: 0.10)
    static let bg1 = Color(red: 0.08, green: 0.11, blue: 0.20)
    static let accent = Color(red: 0.35, green: 0.55, blue: 1.0)
    static let mint = Color(red: 0.20, green: 0.83, blue: 0.60)
    static let card = Color.white.opacity(0.07)
    static let stroke = Color.white.opacity(0.12)

    static var bgGradient: LinearGradient {
        LinearGradient(colors: [bg0, bg1], startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

struct GlassCard<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        content
            .padding(16)
            .background(NovaTheme.card)
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(NovaTheme.stroke, lineWidth: 1))
            .cornerRadius(20)
    }
}

func pingColor(_ ms: Int?) -> Color {
    guard let ms = ms else { return .gray }
    if ms < 150 { return NovaTheme.mint }
    if ms < 350 { return .yellow }
    return .red
}
