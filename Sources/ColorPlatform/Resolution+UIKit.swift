#if canImport(UIKit) && !canImport(AppKit)
import ColorCore
import UIKit

extension Hue {
    /// The UIKit system colour of the hue (the twin of the AppKit one).
    public var systemColor: UIColor {
        switch self {
        case .indigo: .systemIndigo
        case .blue: .systemBlue
        case .orange: .systemOrange
        case .pink: .systemPink
        case .teal: .systemTeal
        case .green: .systemGreen
        case .red: .systemRed
        case .purple: .systemPurple
        case .mint: .systemMint
        case .cyan: .systemCyan
        case .brown: .systemBrown
        case .yellow: .systemYellow
        }
    }
}

extension Appearance {
    /// The traits whose system colours this case draws with.
    public var traits: UITraitCollection {
        // The non-deprecated mutation closure is main-actor isolated; dynamic colors resolve off the main thread.
        UITraitCollection(traitsFrom: [
            UITraitCollection(userInterfaceStyle: isDark ? .dark : .light),
            UITraitCollection(accessibilityContrast: isIncreasedContrast ? .high : .normal),
        ])
    }

    /// The case matching the traits UIKit hands a dynamic colour (an unspecified trait counts as the default one).
    public init(_ traits: UITraitCollection) {
        self.init(isDark: traits.userInterfaceStyle == .dark, isIncreasedContrast: traits.accessibilityContrast == .high)
    }
}

extension RGBA {
    /// The colour in sRGB as drawn with `traits`. UIKit answers in extended sRGB: a wide gamut colour is clipped to
    /// 0…1, as the sRGB conversion does on macOS.
    public init(_ color: UIColor, traits: UITraitCollection) {
        var (red, green, blue, alpha) = (CGFloat.zero, CGFloat.zero, CGFloat.zero, CGFloat.zero)
        color.resolvedColor(with: traits).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        func clipped(_ channel: CGFloat) -> Double { min(1, max(0, Double(channel))) }
        self.init(red: clipped(red), green: clipped(green), blue: clipped(blue), alpha: clipped(alpha))
    }

    /// The colour as drawn in `appearance`.
    public init(_ color: UIColor, in appearance: Appearance) {
        self.init(color, traits: appearance.traits)
    }
}

extension NativeColor {
    /// A colour the system resolves per appearance.
    public static func dynamic(_ resolve: @escaping @Sendable (Appearance) -> NativeColor) -> NativeColor {
        UIColor { resolve(Appearance($0)) }
    }
}

extension ResolvedColors {
    /// The Theme's system colours, resolved in `appearance`, with `accents` as the further hues to solve text in.
    public init(_ theme: Theme, accents: [Hue] = [], in appearance: Appearance) {
        let traits = appearance.traits
        func rgba(_ color: UIColor) -> RGBA { RGBA(color, traits: traits) }
        self.init(
            background: rgba(.systemBackground), label: rgba(.label), secondaryLabel: rgba(.secondaryLabel),
            primary: rgba(theme.primary.systemColor), secondary: rgba(theme.secondary.systemColor),
            accents: accents.map { rgba($0.systemColor) })
    }
}
#endif
