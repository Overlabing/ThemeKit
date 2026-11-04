import ColorCore
import ColorPlatform
import SwiftUI

extension DesignTokens {
    /// Where the kit draws text, described for the legibility solver: the frame's gradient, then the hover, current and
    /// selection fills of rows, and the badge and tile fills a tinted glyph sits on. Increase Contrast raises the row
    /// fills and the selection's floor by `increasedContrastFactor` (capped at 1); the badge and tile fills stay, since
    /// no text would reach 4.5:1 on their own raised tint over a raised selection.
    public func surfaces(in appearance: Appearance) -> Surfaces {
        let increased = appearance.isIncreasedContrast
        return Surfaces(
            gradient: gradient.spec(isDark: appearance.isDark),
            contentTop: emphasis.contentTop,
            fills: [emphasis.hover, emphasis.current].map { emphasis.contrasted($0, increased) },
            selection: Surfaces.Selection(
                floor: emphasis.contrasted(appearance.isDark ? emphasis.selectedDark : emphasis.selectedLight, increased),
                cap: emphasis.selectionCap, visibility: emphasis.selectionVisibility),
            tintFills: [emphasis.badgeFill, emphasis.tileFill])
    }
}

/// The colours a view of the kit may use for one Theme, tokens and appearance. Views ask for a role, never for a hue
/// and an opacity of their own. Text colours come from the legibility solver, so they reach 4.5:1 on every surface
/// the kit draws text on.
public struct ColorRoles: Sendable {
    public let theme: Theme
    public let tokens: DesignTokens
    public let appearance: Appearance
    public let legibility: Legibility
    private let resolved: ResolvedColors

    public init(theme: Theme, tokens: DesignTokens, appearance: Appearance) {
        self.theme = theme
        self.tokens = tokens
        self.appearance = appearance
        legibility = Legibility.of(theme, surfaces: tokens.surfaces(in: appearance), in: appearance)
        resolved = ResolvedColors(theme, in: appearance)
    }

    private var increased: Bool { appearance.isIncreasedContrast }
    private var emphasis: DesignTokens.Emphasis { tokens.emphasis }

    /// The Theme's primary hue, for glyphs and controls (3:1 is enough there).
    public var tint: Color { theme.primary.color }

    public var frameStops: [Gradient.Stop] {
        let spec = tokens.gradient.spec(isDark: appearance.isDark)
        return [
            .init(color: theme.primary.color.opacity(spec.top), location: 0),
            .init(color: theme.secondary.color.opacity(spec.middle), location: 0.5),
            .init(color: theme.primary.color.opacity(spec.bottom), location: 1),
        ]
    }

    /// Opacity of the selected row's fill, as solved: never below the token's floor.
    public var selectionOpacity: Double { legibility.selected }
    public var hoverOpacity: Double { emphasis.contrasted(emphasis.hover, increased) }

    public var selectionFill: Color { tint.opacity(selectionOpacity) }
    public var hoverFill: Color { tint.opacity(hoverOpacity) }
    public var tileFill: Color { tint.opacity(emphasis.contrasted(emphasis.tileFill, increased)) }
    public var glassTint: Color { tint.opacity(emphasis.glassTint) }
    public var currentFill: Color { tint.opacity(emphasis.contrasted(emphasis.current, increased)) }
    public var badgeFill: Color { tint.opacity(emphasis.contrasted(emphasis.badgeFill, increased)) }
    public var layerFill: Color { Color.primary.opacity(emphasis.contrasted(emphasis.layer, increased)) }

    /// Secondary text on the frame and on rows: the label colour at the solved alpha, instead of the system's
    /// secondary label, which falls under 4.5:1 on a tinted frame.
    public var secondaryText: Color { Color(rgba: resolved.label, alpha: legibility.secondaryAlpha) }
    public var secondaryTextRGBA: RGBA {
        RGBA(red: resolved.label.red, green: resolved.label.green, blue: resolved.label.blue, alpha: legibility.secondaryAlpha)
    }

    /// Text drawn in the Theme's colour: the primary hue mixed with ink by the solved share.
    public var tintText: Color { Color(rgba: tintTextRGBA) }
    public var tintTextRGBA: RGBA { resolved.primary.mixed(with: resolved.ink, by: legibility.tintMix) }
}

extension Color {
    init(rgba: RGBA, alpha: Double? = nil) {
        self.init(.sRGB, red: rgba.red, green: rgba.green, blue: rgba.blue, opacity: alpha ?? rgba.alpha)
    }
}

extension EnvironmentValues {
    /// The tokens every kit component reads.
    @Entry public var designTokens: DesignTokens = .standard
}

extension View {
    /// Sets the tokens for the views below. Pair it with ColorUI's `theme(_:)`, which sets the Theme they colour from.
    public func designTokens(_ tokens: DesignTokens) -> some View {
        environment(\.designTokens, tokens)
    }
}

/// Builds the colour roles from the environment (Theme, tokens, colour scheme, Increase Contrast) and hands them to
/// its content.
public struct WithColorRoles<Content: View>: View {
    @Environment(\.designTokens) private var tokens
    @Environment(\.theme) private var theme
    @Environment(\.colorScheme) private var scheme
    @Environment(\.colorSchemeContrast) private var contrast
    private let content: (ColorRoles) -> Content

    public init(@ViewBuilder _ content: @escaping (ColorRoles) -> Content) {
        self.content = content
    }

    public var body: some View {
        content(ColorRoles(
            theme: theme ?? Palette.standard.themes[0], tokens: tokens,
            appearance: Appearance(isDark: scheme == .dark, isIncreasedContrast: contrast == .increased)))
    }
}
