import ColorCore
import ColorPlatform
import SwiftUI

extension DesignTokens {
    /// Where the kit draws text, described for the legibility solver: the frame's gradient, the panel that groups an
    /// open folder's rows, then the hover, current and selection fills of rows, and the badge and tile fills a tinted
    /// glyph sits on. Increase Contrast raises the row fills and the selection's floor by `increasedContrastFactor`
    /// (capped at 1); the badge, tile and panel fills stay, since raising a fill under a text lowers its contrast:
    /// outlines mark them instead. `ColorRoles` solves it with `Legibility.fit`, which draws a bright hue lighter where
    /// the full opacities would leave a text under 4.5:1.
    public func surfaces(in appearance: Appearance) -> Surfaces {
        let increased = appearance.isIncreasedContrast
        return Surfaces(
            gradient: gradient.spec(isDark: appearance.isDark),
            contentTop: emphasis.contentTop,
            fills: [emphasis.hover, emphasis.current].map { emphasis.contrasted($0, increased) },
            selection: Surfaces.Selection(
                floor: emphasis.contrasted(appearance.isDark ? emphasis.selectedDark : emphasis.selectedLight, increased),
                cap: emphasis.selectionCap, visibility: emphasis.selectionVisibility),
            tintFills: [emphasis.badgeFill, emphasis.tileFill],
            neutralFills: [emphasis.layer])
    }
}

/// The colours a view of the kit may use for one Theme, tokens and appearance. Views ask for a role, never for a hue
/// and an opacity of their own. Text colours come from the legibility solver, so they reach 4.5:1 on every surface
/// the kit draws text on; glyphs, the focus ring and outlines reach 3:1.
public struct ColorRoles: Sendable {
    public let theme: Theme
    public let tokens: DesignTokens
    public let appearance: Appearance
    public let legibility: Legibility
    private let resolved: ResolvedColors
    private let focus: RGBA

    public init(theme: Theme, tokens: DesignTokens, appearance: Appearance) {
        self.theme = theme
        self.tokens = tokens
        self.appearance = appearance
        legibility = Legibility.fitted(theme, surfaces: tokens.surfaces(in: appearance), in: appearance)
        resolved = ResolvedColors(theme, in: appearance)
        focus = RGBA.keyboardFocus(in: appearance)
    }

    private var increased: Bool { appearance.isIncreasedContrast }
    private var emphasis: DesignTokens.Emphasis { tokens.emphasis }

    /// The share every opacity of the Theme's hue is drawn at: 1, or less for a bright hue in dark (`Legibility.fit`).
    public var hueScale: Double { legibility.hueScale }

    /// The Theme's primary hue, raw. Fills take it at an opacity; no text or glyph is drawn in it.
    public var tint: Color { theme.primary.color }

    public var frameStops: [Gradient.Stop] {
        let spec = tokens.gradient.spec(isDark: appearance.isDark)
        return [
            .init(color: theme.primary.color.opacity(spec.top * hueScale), location: 0),
            .init(color: theme.secondary.color.opacity(spec.middle * hueScale), location: 0.5),
            .init(color: theme.primary.color.opacity(spec.bottom * hueScale), location: 1),
        ]
    }

    /// Opacity of the selected row's fill, as solved: the floor at `hueScale`, raised until the row shows.
    public var selectionOpacity: Double { legibility.selected }
    public var hoverOpacity: Double { emphasis.contrasted(emphasis.hover, increased) * hueScale }
    public var currentOpacity: Double { emphasis.contrasted(emphasis.current, increased) * hueScale }

    public var selectionFill: Color { tint.opacity(selectionOpacity) }
    public var hoverFill: Color { tint.opacity(hoverOpacity) }
    public var currentFill: Color { tint.opacity(currentOpacity) }
    public var tileOpacity: Double { emphasis.tileFill * hueScale }
    public var badgeOpacity: Double { emphasis.badgeFill * hueScale }
    /// The panel grouping rows, in `.primary`: neither scaled nor raised by Increase Contrast.
    public var layerOpacity: Double { emphasis.layer }
    public var tileFill: Color { tint.opacity(tileOpacity) }
    public var badgeFill: Color { tint.opacity(badgeOpacity) }
    public var glassTint: Color { tint.opacity(emphasis.glassTint) }
    public var layerFill: Color { Color.primary.opacity(layerOpacity) }

    /// Secondary text on the frame and on rows: the label colour at the solved alpha, instead of the system's
    /// secondary label, which falls under 4.5:1 on a tinted frame.
    public var secondaryText: Color { Color(rgba: resolved.label, alpha: legibility.secondaryAlpha) }
    public var secondaryTextRGBA: RGBA {
        RGBA(red: resolved.label.red, green: resolved.label.green, blue: resolved.label.blue, alpha: legibility.secondaryAlpha)
    }

    /// Text and glyphs drawn in the Theme's colour: the primary hue mixed with ink by the solved share.
    public var tintText: Color { Color(rgba: tintTextRGBA) }
    public var tintTextRGBA: RGBA { resolved.primary.mixed(with: resolved.ink, by: legibility.tintMix) }

    /// The outline of a selected or current row under Increase Contrast: the secondary ink, 4.5:1 on the row's fill
    /// and on the frame around it (the system separator stays near 1.2:1 there).
    public var outline: Color { secondaryText }

    /// The keyboard focus ring: the system's focus colour made opaque and mixed with ink until it reaches 3:1 on every
    /// surface a row sits on (drawn translucent, it falls to 1.5:1 on a bright frame).
    public var focusRing: Color { Color(rgba: focusRingRGBA) }
    public var focusRingRGBA: RGBA {
        legibility.focusRing(focus, ink: resolved.ink, minimum: emphasis.nonTextContrast)
    }

    /// A band of the Theme's colour (the active profile, say): the primary hue, opaque, and the text on it, white or
    /// black, at 4.5:1 at least.
    public var bandFill: Color { Color(rgba: resolved.primary, alpha: 1) }
    public var bandText: Color { Self.ink(on: theme.primary, in: appearance, minimum: emphasis.textContrast) }

    /// A symbol on the opaque primary hue (a field pill's circle): white, or black where white stays under 3:1.
    public var primaryGlyph: Color { Self.ink(on: theme.primary, in: appearance, minimum: emphasis.nonTextContrast) }

    /// White, or black where white stays under `minimum` on `hue` drawn opaque in `appearance`.
    public static func ink(on hue: Hue, in appearance: Appearance, minimum: Double) -> Color {
        Contrast.ink(on: RGBA(hue.systemColor, in: appearance), minimum: minimum) == .white ? .white : .black
    }

    /// The same for any colour, resolved in `environment` (a tile's own colour).
    public static func ink(on color: Color, in environment: EnvironmentValues, minimum: Double) -> Color {
        let resolved = color.resolve(in: environment)
        func clipped(_ channel: Float) -> Double { min(1, max(0, Double(channel))) }
        let rgba = RGBA(red: clipped(resolved.red), green: clipped(resolved.green), blue: clipped(resolved.blue))
        return Contrast.ink(on: rgba, minimum: minimum) == .white ? .white : .black
    }
}

extension Legibility {
    /// An opaque version of `focus`, mixed with `ink` until it reaches `minimum` on every surface solved.
    func focusRing(_ focus: RGBA, ink: RGBA, minimum: Double) -> RGBA {
        let opaque = RGBA(red: focus.red, green: focus.green, blue: focus.blue)
        return opaque.mixed(with: ink, by: mix(of: opaque, toward: ink, reaching: minimum))
    }
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
