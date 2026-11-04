#if canImport(AppKit)
import AppKit
import ColorCore

extension Hue {
    /// The AppKit system colour of the hue (the same as SwiftUI's `Color.indigo`…, measured identical in sRGB).
    public var systemColor: NSColor {
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
    /// The AppKit appearance whose system colours this case draws with.
    public var appearanceName: NSAppearance.Name {
        switch self {
        case .light: .aqua
        case .dark: .darkAqua
        case .lightIncreasedContrast: .accessibilityHighContrastAqua
        case .darkIncreasedContrast: .accessibilityHighContrastDarkAqua
        }
    }

    /// The case matching an appearance AppKit hands a dynamic colour (vibrant variants fold into their base).
    public init(_ appearance: NSAppearance) {
        let names: [NSAppearance.Name] = [
            .aqua, .darkAqua, .accessibilityHighContrastAqua, .accessibilityHighContrastDarkAqua,
            .vibrantLight, .vibrantDark, .accessibilityHighContrastVibrantLight, .accessibilityHighContrastVibrantDark,
        ]
        switch appearance.bestMatch(from: names) {
        case .darkAqua, .vibrantDark: self = .dark
        case .accessibilityHighContrastAqua, .accessibilityHighContrastVibrantLight: self = .lightIncreasedContrast
        case .accessibilityHighContrastDarkAqua, .accessibilityHighContrastVibrantDark: self = .darkIncreasedContrast
        default: self = .light
        }
    }
}

extension RGBA {
    /// The colour in sRGB as drawn under the current drawing appearance.
    public init(_ color: NSColor) {
        let srgb = color.usingColorSpace(.sRGB) ?? color.usingColorSpace(.genericRGB) ?? .black
        self.init(
            red: Double(srgb.redComponent), green: Double(srgb.greenComponent), blue: Double(srgb.blueComponent),
            alpha: Double(srgb.alphaComponent))
    }

    /// The colour as drawn in `appearance`. AppKit answers plain Aqua when asked for a high contrast appearance by name
    /// (measured on macOS 27): Increase Contrast resolves like its base here.
    public init(_ color: NSColor, in appearance: Appearance) {
        var resolved = RGBA.black
        let nsAppearance = NSAppearance(named: appearance.appearanceName) ?? NSAppearance(named: .aqua)!
        nsAppearance.performAsCurrentDrawingAppearance { resolved = RGBA(color) }
        self = resolved
    }
}

extension RGBA {
    /// The keyboard focus indicator's colour in `appearance` (the user's accent colour, translucent).
    public static func keyboardFocus(in appearance: Appearance) -> RGBA {
        RGBA(.keyboardFocusIndicatorColor, in: appearance)
    }

    /// The separator's colour in `appearance`.
    public static func separator(in appearance: Appearance) -> RGBA {
        RGBA(.separatorColor, in: appearance)
    }
}

extension NativeColor {
    /// A colour the system resolves per appearance.
    public static func dynamic(_ resolve: @escaping @Sendable (Appearance) -> NativeColor) -> NativeColor {
        NSColor(name: nil) { resolve(Appearance($0)) }
    }
}

extension ResolvedColors {
    /// The Theme's system colours, resolved in `appearance`, with `accents` as the further hues to solve text in.
    public init(_ theme: Theme, accents: [Hue] = [], in appearance: Appearance) {
        var resolved: ResolvedColors?
        let nsAppearance = NSAppearance(named: appearance.appearanceName) ?? NSAppearance(named: .aqua)!
        nsAppearance.performAsCurrentDrawingAppearance {
            resolved = ResolvedColors(
                background: RGBA(.windowBackgroundColor), label: RGBA(.labelColor),
                secondaryLabel: RGBA(.secondaryLabelColor), primary: RGBA(theme.primary.systemColor),
                secondary: RGBA(theme.secondary.systemColor), accents: accents.map { RGBA($0.systemColor) })
        }
        self = resolved!
    }
}
#endif
