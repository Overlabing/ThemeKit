import ColorCore
import ColorPlatform
import SwiftUI
import Synchronization

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

    /// The same inside a list column (`ColumnSurface`): every surface sits on the column's own fill, the plain
    /// background at `Emphasis.column(isDark:)` over the gradient, or on the plain background alone (Reduce
    /// Transparency).
    @available(*, deprecated, message: "Use SidebarSplitView, the system NavigationSplitView sidebar, with the kit's roles in .frame. Removed in 0.3.")
    public func columnSurfaces(in appearance: Appearance) -> Surfaces { columnFillSurfaces(in: appearance) }

    /// `columnSurfaces(in:)`, for the kit's own use until it is removed: the legibility audit keeps its column cases
    /// and the rail's divider keeps its ink.
    func columnFillSurfaces(in appearance: Appearance) -> Surfaces {
        var described = surfaces(in: appearance)
        described.backdrop = emphasis.column(isDark: appearance.isDark)
        return described
    }

    /// The surfaces of `placement`.
    public func surfaces(in appearance: Appearance, placement: SurfacePlacement) -> Surfaces {
        placement == .frame ? surfaces(in: appearance) : columnFillSurfaces(in: appearance)
    }
}

/// Where a view of the kit sits, which decides the surfaces its colours are solved on.
public enum SurfacePlacement: String, Sendable, CaseIterable, Hashable {
    /// On the window's gradient. A system `NavigationSplitView` sidebar, a popover and a sheet take this one too.
    case frame
    /// Inside a list column's own surface (`ColumnSurface`).
    @available(*, deprecated, message: "Use SidebarSplitView, the system NavigationSplitView sidebar, with the kit's roles in .frame. Removed in 0.3.")
    case column

    /// Written out: a deprecated case keeps Swift from synthesizing it. The legibility audit walks both until 0.3.
    public static let allCases: [SurfacePlacement] = [.frame, .deprecatedColumn]
}

/// The colours a view of the kit may use for one Theme, tokens and appearance. Views ask for a role, never for a hue
/// and an opacity of their own. Text colours come from the legibility solver, so they reach 4.5:1 on every surface
/// the kit draws text on; glyphs, the focus ring and outlines reach 3:1.
///
/// Building one is cheap: what it solves (the legibility, the system colours, the inks mixed from them) is solved once
/// per Theme, colour tokens (`emphasis`, `gradient`, `accents`), appearance and placement, then shared by every
/// `ColorRoles` of that key, from any thread. A row's body builds its roles on every evaluation (`WithColorRoles`), and
/// a hover re-evaluates every visible row.
public struct ColorRoles: Sendable {
    public let theme: Theme
    public let tokens: DesignTokens
    public let appearance: Appearance
    public let placement: SurfacePlacement
    /// What the roles hand out, shared by every `ColorRoles` of the same key (`Solved.cached`).
    let solved: Solved

    /// `placement` `.column` (deprecated) solves the inks, the selection fill, the marker and the focus ring on the
    /// column's own fill instead of the gradient. The hue keeps the share the frame was solved at (`hueScale`), since
    /// the column's fill lets the same gradient through.
    public init(theme: Theme, tokens: DesignTokens, appearance: Appearance, placement: SurfacePlacement = .frame) {
        self.theme = theme
        self.tokens = tokens
        self.appearance = appearance
        self.placement = placement
        solved = Solved.cached(
            Solved.Key(theme: theme, tokens: tokens, appearance: appearance, placement: placement), tokens: tokens)
    }

    /// The solved legibility: the opacities and the mixes every text and mark is drawn at.
    public var legibility: Legibility { solved.values.legibility }
    private var resolved: ResolvedColors { solved.values.resolved }
    /// `tokens.accents` resolved against `theme`.
    private var accentHues: [Hue] { solved.values.accentHues }

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
    public var secondaryTextRGBA: RGBA { solved.values.secondaryText }

    /// Text and glyphs drawn in the Theme's colour: the primary hue mixed with ink by the solved share.
    public var tintText: Color { Color(rgba: tintTextRGBA) }
    public var tintTextRGBA: RGBA { solved.values.tintText }

    /// The hue `DesignTokens.accents` gives index `index`, resolved against the Theme (`.primary` is its primary hue);
    /// an index past the end wraps, a negative one counts from the end. Draw a dot or a tile in it; draw text in
    /// `accentInk(at:)`. With no accents the Theme's own hue.
    public func accentHue(at index: Int) -> Hue {
        let hues = accentHues
        return hues.isEmpty ? theme.primary : hues[((index % hues.count) + hues.count) % hues.count]
    }

    /// Text in the accent hue of index `index` (an account's name, say): the hue mixed with ink by the solved share, so
    /// it reaches 4.5:1 on every surface text sits on, the column's fill included when the roles are solved there. The
    /// raw hue falls as low as 1.0:1 on them (the worst accent).
    public func accentInk(at index: Int) -> Color { Color(rgba: accentInkRGBA(at: index)) }
    public func accentInkRGBA(at index: Int) -> RGBA {
        let inks = solved.values.accentInks
        guard !inks.isEmpty else { return tintTextRGBA }
        return inks[((index % inks.count) + inks.count) % inks.count]
    }

    /// The outline of a selected or current row under Increase Contrast: the secondary ink, 4.5:1 on the row's fill
    /// and on the frame around it (the system separator stays near 1.2:1 there).
    public var outline: Color { secondaryText }

    /// The marker of the selected row outside Increase Contrast (a bar at its leading edge): the primary hue mixed with
    /// ink until it reaches 3:1 on every surface a row sits on, the selection's fill included. The fill alone differs
    /// from the gradient by about 1.3:1. Increase Contrast draws `outline` instead.
    public var selectionMarker: Color { Color(rgba: selectionMarkerRGBA) }
    public var selectionMarkerRGBA: RGBA { solved.values.selectionMarker }

    /// The keyboard focus ring: the system's focus colour made opaque and mixed with ink until it reaches 3:1 on every
    /// surface a row sits on (drawn translucent, it falls to 1.5:1 on a bright frame).
    public var focusRing: Color { Color(rgba: focusRingRGBA) }
    public var focusRingRGBA: RGBA { solved.values.focusRing }

    /// The column's own fill: the plain background at this opacity over the gradient (1 under Reduce Transparency).
    @available(*, deprecated, message: "Use SidebarSplitView, the system NavigationSplitView sidebar, with the kit's roles in .frame. Removed in 0.3.")
    public var columnFillOpacity: Double { emphasis.column(isDark: appearance.isDark) }

    /// The edge of the column's surface: the label's ink at the alpha that reaches 3:1 against the gradient around
    /// the column and against the column's own fill, at every height, with or without Reduce Transparency.
    @available(*, deprecated, message: "Use SidebarSplitView, the system NavigationSplitView sidebar, with the kit's roles in .frame. Removed in 0.3.")
    public var columnEdge: Color { Color(rgba: edgeRGBA) }
    @available(*, deprecated, message: "Use SidebarSplitView, the system NavigationSplitView sidebar, with the kit's roles in .frame. Removed in 0.3.")
    public var columnEdgeRGBA: RGBA { edgeRGBA }

    /// `columnEdgeRGBA`, for the rail's divider until the column is removed.
    private var edgeRGBA: RGBA { solved.values.edge }

    /// The smallest alpha of the ink (to 1/1000) at which the edge, drawn over the column's fill, reaches `minimum`
    /// against the bare gradient beside it and against that fill; 1 when even the opaque ink falls short.
    @available(*, deprecated, message: "Use SidebarSplitView, the system NavigationSplitView sidebar, with the kit's roles in .frame. Removed in 0.3.")
    public static func columnEdgeAlpha(
        colors: ResolvedColors, frame: Surfaces, column: Surfaces, hueScale: Double, minimum: Double
    ) -> Double {
        edgeAlpha(colors: colors, frame: frame, column: column, hueScale: hueScale, minimum: minimum)
    }

    /// `columnEdgeAlpha`, for the kit's own use until it is removed (the audit, the rail's divider).
    static func edgeAlpha(
        colors: ResolvedColors, frame: Surfaces, column: Surfaces, hueScale: Double, minimum: Double
    ) -> Double {
        let pairs = edgeNeighbours(colors: colors, frame: frame, column: column, hueScale: hueScale)
        return Legibility.solveMinimum(from: 0, to: 1) { alpha in
            pairs.allSatisfy { fill, outside in
                let edge = colors.ink.opacity(alpha).composited(over: fill)
                return Contrast.ratio(edge, fill) >= minimum && Contrast.ratio(edge, outside) >= minimum
            }
        }
    }

    /// Each place along the column's edge: the column's fill there (the edge is drawn over it) and the bare gradient
    /// just outside, sampled top to bottom; then the plain background (Reduce Transparency) beside every gradient
    /// sample.
    @available(*, deprecated, message: "Use SidebarSplitView, the system NavigationSplitView sidebar, with the kit's roles in .frame. Removed in 0.3.")
    public static func columnEdgeNeighbours(
        colors: ResolvedColors, frame: Surfaces, column: Surfaces, hueScale: Double
    ) -> [(fill: RGBA, outside: RGBA)] {
        edgeNeighbours(colors: colors, frame: frame, column: column, hueScale: hueScale)
    }

    /// `columnEdgeNeighbours`, for the kit's own use until it is removed.
    static func edgeNeighbours(
        colors: ResolvedColors, frame: Surfaces, column: Surfaces, hueScale: Double
    ) -> [(fill: RGBA, outside: RGBA)] {
        let spec = frame.scaled(by: hueScale).gradient
        let outside = stride(from: 0.0, through: 1.0, by: 0.02).map {
            spec.color(at: $0, primary: colors.primary, secondary: colors.secondary, over: colors.background)
        }
        return outside.map { (colors.background.opacity(column.backdrop).composited(over: $0), $0) }
            + outside.map { (colors.background, $0) }
    }

    /// A dot standing for one Space of a folded Profile in the Space rail. The dot is drawn in `hue` (that Space's
    /// Theme), opaque, mixed with ink until it reaches 3:1 on every surface solved here. The raw hue alone falls
    /// short: yellow on a light column is about 1.5:1.
    public func railDot(_ hue: Hue) -> Color { Color(rgba: railDotRGBA(hue)) }
    public func railDotRGBA(_ hue: Hue) -> RGBA {
        solved.values.railDots[hue] ?? Solved.railDot(hue, in: appearance, legibility: legibility, ink: resolved.ink,
                                                      minimum: emphasis.nonTextContrast)
    }

    /// The hairline between the Space rail's groups. It uses the column edge's ink, so it reaches 3:1 on the column's
    /// fill. The system separator stays near 1.3:1 there.
    public var railDivider: Color { Color(rgba: edgeRGBA) }

    /// A band of the Theme's colour (the active profile, say): the primary hue, opaque, and the text on it, white or
    /// black, at 4.5:1 at least.
    public var bandFill: Color { Color(rgba: resolved.primary, alpha: 1) }
    public var bandText: Color { solved.values.bandTextIsWhite ? .white : .black }

    /// A symbol on the opaque primary hue (a field pill's circle): white, or black where white stays under 3:1.
    public var primaryGlyph: Color { solved.values.primaryGlyphIsWhite ? .white : .black }

    /// White, or black where white stays under `minimum` on `hue` drawn opaque in `appearance`.
    public static func ink(on hue: Hue, in appearance: Appearance, minimum: Double) -> Color {
        inkIsWhite(on: hue, in: appearance, minimum: minimum) ? .white : .black
    }

    static func inkIsWhite(on hue: Hue, in appearance: Appearance, minimum: Double) -> Bool {
        Contrast.ink(on: RGBA(hue.systemColor, in: appearance), minimum: minimum) == .white
    }

    /// The same for any colour, resolved in `environment` (a tile's own colour).
    public static func ink(on color: Color, in environment: EnvironmentValues, minimum: Double) -> Color {
        let resolved = color.resolve(in: environment)
        func clipped(_ channel: Float) -> Double { min(1, max(0, Double(channel))) }
        let rgba = RGBA(red: clipped(resolved.red), green: clipped(resolved.green), blue: clipped(resolved.blue))
        return Contrast.ink(on: rgba, minimum: minimum) == .white ? .white : .black
    }
}

extension ColorRoles {
    /// Everything `ColorRoles` solves for one key, solved once and shared: the legibility, the resolved system colours
    /// and every ink mixed from them. Immutable, so any thread may read it.
    final class Solved: Sendable {
        /// What the solved colours depend on. Of the tokens only the colour ones count (`emphasis`, `gradient`,
        /// `accents`): two sets of tokens that differ in spacing or type share their colours.
        struct Key: Hashable, Sendable {
            let theme: Theme
            let accents: [Accent]
            let emphasis: DesignTokens.Emphasis
            let gradient: DesignTokens.WindowGradient
            let appearance: Appearance
            let placement: SurfacePlacement

            init(theme: Theme, tokens: DesignTokens, appearance: Appearance, placement: SurfacePlacement) {
                self.theme = theme
                accents = tokens.accents
                emphasis = tokens.emphasis
                gradient = tokens.gradient
                self.appearance = appearance
                self.placement = placement
            }
        }

        struct Values: Sendable, Equatable {
            let legibility: Legibility
            let resolved: ResolvedColors
            let accentHues: [Hue]
            let secondaryText: RGBA
            let tintText: RGBA
            /// One per accent hue, in `accentHues`' order.
            let accentInks: [RGBA]
            let selectionMarker: RGBA
            let focusRing: RGBA
            /// The column's edge and the rail's divider.
            let edge: RGBA
            /// Every hue's rail dot.
            let railDots: [Hue: RGBA]
            let bandTextIsWhite: Bool
            let primaryGlyphIsWhite: Bool
        }

        let values: Values

        /// Solves `key`'s colours with `tokens`, whose colour tokens are `key`'s. Use `cached(_:tokens:)`.
        init(_ key: Key, tokens: DesignTokens) {
            let appearance = key.appearance
            let emphasis = tokens.emphasis
            let accentHues = tokens.accentHues(in: key.theme)
            let frame = Legibility.fitted(
                key.theme, accents: accentHues, surfaces: tokens.surfaces(in: appearance), in: appearance)
            let legibility = key.placement == .frame
                ? frame
                : Legibility.of(
                    key.theme, accents: accentHues, surfaces: tokens.columnFillSurfaces(in: appearance),
                    hueScale: frame.hueScale, in: appearance)
            let resolved = ResolvedColors(key.theme, accents: accentHues, in: appearance)
            let ink = resolved.ink
            let minimum = emphasis.nonTextContrast
            values = Values(
                legibility: legibility,
                resolved: resolved,
                accentHues: accentHues,
                secondaryText: RGBA(
                    red: resolved.label.red, green: resolved.label.green, blue: resolved.label.blue,
                    alpha: legibility.secondaryAlpha),
                tintText: resolved.primary.mixed(with: ink, by: legibility.tintMix),
                accentInks: resolved.accents.indices.map { resolved.accents[$0].mixed(with: ink, by: legibility.accentMix[$0]) },
                selectionMarker: resolved.primary.mixed(
                    with: ink, by: legibility.mix(of: resolved.primary, toward: ink, reaching: minimum)),
                focusRing: legibility.focusRing(RGBA.keyboardFocus(in: appearance), ink: ink, minimum: minimum),
                edge: ink.opacity(ColorRoles.edgeAlpha(
                    colors: resolved, frame: tokens.surfaces(in: appearance),
                    column: tokens.columnFillSurfaces(in: appearance), hueScale: legibility.hueScale, minimum: minimum)),
                railDots: Dictionary(uniqueKeysWithValues: Hue.allCases.map { hue in
                    (hue, Self.railDot(hue, in: appearance, legibility: legibility, ink: ink, minimum: minimum))
                }),
                bandTextIsWhite: ColorRoles.inkIsWhite(on: key.theme.primary, in: appearance, minimum: emphasis.textContrast),
                primaryGlyphIsWhite: ColorRoles.inkIsWhite(on: key.theme.primary, in: appearance, minimum: minimum))
        }

        /// `hue`, opaque, mixed with `ink` until it reaches `minimum` on every surface `legibility` was solved on.
        static func railDot(_ hue: Hue, in appearance: Appearance, legibility: Legibility, ink: RGBA, minimum: Double) -> RGBA {
            let raw = RGBA(hue.systemColor, in: appearance)
            let opaque = RGBA(red: raw.red, green: raw.green, blue: raw.blue)
            return opaque.mixed(with: ink, by: legibility.mix(of: opaque, toward: ink, reaching: minimum))
        }

        /// The colours of `key`, solved with `tokens` the first time and shared after. Solved outside the lock, so two
        /// threads asking for a new key at once may both solve it; the first stored wins and both get it.
        static func cached(_ key: Key, tokens: DesignTokens) -> Solved {
            if let known = cache.withLock({ $0[key] }) { return known }
            let solved = Solved(key, tokens: tokens)
            return cache.withLock { cache in
                if let known = cache[key] { return known }
                cache[key] = solved
                return solved
            }
        }

        /// How many keys are solved so far.
        static var cachedCount: Int { cache.withLock { $0.count } }

        private static let cache = Mutex<[Key: Solved]>([:])
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
    /// Where the views below sit: `.frame`, which a system `NavigationSplitView` sidebar, a popover and a sheet take
    /// too. `ColumnSurface` (deprecated) sets `.column`, so their colours are solved on the column's fill.
    @Entry public var surfacePlacement: SurfacePlacement = .frame
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
    @Environment(\.surfacePlacement) private var placement
    @Environment(\.theme) private var theme
    @Environment(\.colorScheme) private var scheme
    @Environment(\.kitContrast) private var contrast
    private let content: (ColorRoles) -> Content

    public init(@ViewBuilder _ content: @escaping (ColorRoles) -> Content) {
        self.content = content
    }

    public var body: some View {
        content(ColorRoles(
            theme: theme ?? Palette.standard.themes[0], tokens: tokens,
            appearance: Appearance(isDark: scheme == .dark, isIncreasedContrast: contrast == .increased),
            placement: placement))
    }
}
