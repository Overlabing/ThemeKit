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

/// A hue named relative to a Theme, or a fixed one: what `DesignTokens.accents` lists so that an order can follow the
/// Theme ("the Theme's own hues first"). `.primary` and `.secondary` resolve against the Theme they are drawn in.
public enum Accent: Hashable, Sendable {
    case primary
    case secondary
    case hue(Hue)

    /// The system hue this accent is in `theme`.
    public func hue(in theme: Theme) -> Hue {
        switch self {
        case .primary: theme.primary
        case .secondary: theme.secondary
        case .hue(let hue): hue
        }
    }
}

extension Sequence where Element == Accent {
    /// Each accent resolved against `theme`, in order. A duplicate keeps its place: `[.primary, .hue(.indigo)]` in a
    /// Theme whose primary is indigo gives indigo twice, since an index (an account's, say) names the slot.
    public func hues(in theme: Theme) -> [Hue] { map { $0.hue(in: theme) } }
}
