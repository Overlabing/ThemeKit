/// The system hues a Theme is made of: system colours, never hex, so they adapt to the appearance on their own.
/// `ColorPlatform` and `ColorUI` map each to its platform colour.
public enum Hue: String, Sendable, CaseIterable, Hashable {
    case indigo, blue, orange, pink, teal, green, red, purple, mint, cyan, brown, yellow
}

/// A gradient and tint: a stable id (store it to find the Theme again) and two system hues. The primary hue is the
/// tint and the outer gradient stops, the secondary one the middle stop.
public struct Theme: Sendable, Hashable, Identifiable {
    public let id: String
    public let primary: Hue
    public let secondary: Hue

    public init(id: String, primary: Hue, secondary: Hue) {
        self.id = id
        self.primary = primary
        self.secondary = secondary
    }
}

/// The named set of preset Themes a user picks from, in the order a picker offers them.
public struct Palette: Sendable, Equatable {
    public let themes: [Theme]

    public init(themes: [Theme]) {
        self.themes = themes
    }

    /// The preset Themes shipped with the module; indigo-blue leads.
    public static let standard = Palette(themes: [
        Theme(id: "indigo-blue", primary: .indigo, secondary: .blue),
        Theme(id: "orange-pink", primary: .orange, secondary: .pink),
        Theme(id: "teal-green", primary: .teal, secondary: .green),
        Theme(id: "red-orange", primary: .red, secondary: .orange),
        Theme(id: "purple-pink", primary: .purple, secondary: .pink),
        Theme(id: "mint-cyan", primary: .mint, secondary: .cyan),
        Theme(id: "brown-yellow", primary: .brown, secondary: .yellow),
    ])

    public func theme(id: String) -> Theme? { themes.first { $0.id == id } }
}
