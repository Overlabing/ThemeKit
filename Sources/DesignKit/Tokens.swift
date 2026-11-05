import ColorCore
import SwiftUI

/// Every layout, shape, emphasis and type value a view of the kit uses, as one value carried by the environment
/// (`designTokens`). Views never write a raw number: a new value becomes a token first. `standard` is the only preset;
/// an app adjusts a copy of it rather than inventing its own.
public struct DesignTokens: Sendable, Equatable {
    public var spacing = Spacing()
    public var radius = Radius()
    public var emphasis = Emphasis()
    public var size = Size()
    public var type = TypeScale()
    public var gradient = WindowGradient()
    /// The hues that colour things by index (an account, say), in order: `ColorRoles.accentInk(at:)` solves a text ink
    /// for each at 4.5:1 on every surface. An index past the end wraps. `.primary` and `.secondary` follow the Theme
    /// (`accentHues(in:)`), so `[.primary, .secondary, .hue(.mint)]` puts the Theme's own hues first; a hue listed twice
    /// keeps both slots. The default is the twelve system hues, `Hue.allCases`, in that order.
    public var accents: [Accent] = Hue.allCases.map(Accent.hue)

    public init() {}

    /// The kit's tokens.
    public static let standard = DesignTokens()

    /// `accents` resolved against `theme`: the hues `ColorRoles` and the legibility audit solve and draw for it.
    public func accentHues(in theme: Theme) -> [Hue] { accents.hues(in: theme) }
}

extension DesignTokens {
    /// The spacing scale (2, 4, 8, 12, 16, 24), and the semantic values picked from it.
    public struct Spacing: Sendable, Equatable {
        public static let xxs: CGFloat = 2
        public static let xs: CGFloat = 4
        public static let s: CGFloat = 8
        public static let m: CGFloat = 12
        public static let l: CGFloat = 16
        public static let xl: CGFloat = 24
        public static let scale: [CGFloat] = [xxs, xs, s, m, l, xl]

        /// Vertical gap between the backgrounds (hover, selection) of two adjacent rows: they never touch.
        public var rowGap: CGFloat = xs
        /// Inset of a row's background around its content.
        public var rowInsetVertical: CGFloat = xs
        public var rowInsetHorizontal: CGFloat = s
        /// Side margin of a list column: rows, pills, banners and the switcher align on it.
        public var listMargin: CGFloat = m
        /// Inset of a row's background inside a nested panel, and the indent of a second nesting level (none for the
        /// first).
        public var layerInset: CGFloat = xs
        public var layerIndent: CGFloat = m
        /// Under a section header, before the first row's background.
        public var sectionHeaderBottom: CGFloat = 6
        /// Tile to text in a row, and in a compact row (28 pt tile).
        public var tileToText: CGFloat = 10
        public var compactTileToText: CGFloat = s
        /// Between the text lines of a row, and the row's own vertical padding.
        public var textLines: CGFloat = xxs
        /// Merge distance of adjacent glass shapes in one `GlassEffectContainer`.
        public var glassMerge: CGFloat = 6
        /// Banner insets, in its shape.
        public var bannerVertical: CGFloat = 6
        public var bannerHorizontal: CGFloat = m
        /// Inset of a content canvas inside its column, and the canvas's inner margin.
        public var canvasInset: CGFloat = m
        /// Inset of a list column's surface from the window's edges (top, bottom, outer side). Equal to `canvasInset`,
        /// so the column and the canvas beside it line up and keep the same gap to the window and to each other.
        @available(*, deprecated, message: "ColumnSurface is deprecated: use a system NavigationSplitView sidebar. Removed in 0.3.")
        public var columnInset: CGFloat = m
        /// From the window's top edge (the top of the layout, when the content runs under the title bar) to the
        /// column's first row: `columnInset`, then the column's own margin (`listMargin`) inside its surface.
        @available(*, deprecated, message: "ColumnSurface is deprecated: use a system NavigationSplitView sidebar. Removed in 0.3.")
        public var columnTop: CGFloat = xl
        /// Between two icon buttons in a pill, and between two groups of buttons.
        public var pillActionGap: CGFloat = s
        /// Between a floating pill and the edges of what it floats over.
        public var pillFloat: CGFloat = m
        /// Letter spacing of small uppercase group headers.
        public var headerTracking: CGFloat = 0.6
        /// A field pill around its 32 pt circular tile: leading, trailing, vertical, and tile to title.
        public var pillLeading: CGFloat = 5
        public var pillTrailing: CGFloat = 14
        public var pillVertical: CGFloat = 5
        public var pillTileToText: CGFloat = s
        /// The switcher: between items, its inner padding, and its margin to the column's bottom edge.
        public var switcherItemGap: CGFloat = xxs
        public var switcherPadding: CGFloat = xs
        public var switcherBottom: CGFloat = s
        /// From the status line (or the controls in its place) to the list.
        public var statusLineToList: CGFloat = 10
        /// Gap between a focus ring and the shape it surrounds.
        public var focusRingOffset: CGFloat = xxs
        /// The selected row's marker: from the leading edge of the row's background, and from its top and bottom.
        public var selectionMarkerLeading: CGFloat = xxs
        public var selectionMarkerVertical: CGFloat = s
        /// The Space rail: from a glyph to its marker, either side of the divider before a folded Profile, between the
        /// dots of a folded Profile, from the hover caption to the row, and inside a folded Profile's target.
        public var railMarkerGap: CGFloat = xxs
        public var railGroupGap: CGFloat = xs
        public var railDotGap: CGFloat = xs
        public var railCaption: CGFloat = xs
        public var railFoldPadding: CGFloat = xs
        /// A badge's fill around its text: sideways and up and down.
        public var badgeHorizontal: CGFloat = s
        public var badgeVertical: CGFloat = xxs
        /// A label-only icon button: from its label to the edge of its target, each side.
        public var buttonLabelHorizontal: CGFloat = s
        /// A segmented pill: between its segments and from them to its edge, and from a segment's label to its edge.
        public var segmentGap: CGFloat = xxs
        public var segmentPadding: CGFloat = xs
        public var segmentHorizontal: CGFloat = m
        /// Between a segment's symbol and its title, and from the title to the marker bar under it.
        public var segmentContent: CGFloat = xs
        public var segmentMarkerGap: CGFloat = xxs
        /// The margin a `List` cell keeps round its content on macOS even with zero insets (measured on macOS 27; a
        /// negative inset cancels it), none on iOS. `listRowCell(state:)` cancels it.
        public var listCellMargin: CGFloat = Self.platformListCellMargin
        /// A banner: between its title and its message.
        public var bannerLines: CGFloat = xxs

        public init() {}

        public static var platformListCellMargin: CGFloat {
            #if os(macOS)
            s
            #else
            0
            #endif
        }
    }

    /// Corner radii, always `.continuous`. Nested shapes stay concentric: outer = inner + the inset between them.
    public struct Radius: Sendable, Equatable {
        /// Tiles, by side: 8 for 32 pt, 7 for 28 pt, 6 for 22 pt, 5 for 20 pt.
        public var tile: CGFloat = 8
        public var compactTile: CGFloat = 7
        public var smallTile: CGFloat = 6
        public var statusTile: CGFloat = 5
        public var row: CGFloat = 8
        /// A panel holding rows: `row + Spacing.layerInset`, so it stays concentric.
        public var layer: CGFloat = 12
        public var banner: CGFloat = 12
        public var canvas: CGFloat = 12
        /// A list column's surface: `row` plus the 4 pt from the surface's edge to a row's background
        /// (`listMargin - rowInsetHorizontal`), so the rows' backgrounds stay concentric to it.
        @available(*, deprecated, message: "ColumnSurface is deprecated: use a system NavigationSplitView sidebar. Removed in 0.3.")
        public var column: CGFloat = 12

        public init() {}
    }

    /// Opacities, of the Theme's primary hue unless named otherwise.
    public struct Emphasis: Sendable, Equatable {
        public var hover: Double = 0.10
        /// A secondary selection: the current item inside an open group.
        public var current: Double = 0.16
        /// The selected row: a floor per appearance, raised by the legibility solver until the row differs from the
        /// gradient under it by `selectionVisibility` (a contrast ratio), capped at `selectionCap`.
        public var selectedLight: Double = 0.30
        public var selectedDark: Double = 0.25
        public var selectionCap: Double = 0.5
        public var selectionVisibility: Double = 1.3
        /// A small tinted badge's fill. Like every opacity of the hue here, drawn times `ColorRoles.hueScale`.
        public var badgeFill: Double = 0.14
        /// A tile's fill when it has no icon (an initial).
        public var tileFill: Double = 0.25
        /// Tint of the selected glass capsule.
        public var glassTint: Double = 0.35
        /// A nested panel's background, in `.primary` (not the hue).
        public var layer: Double = 0.06
        /// A list column's own surface: the plain window background (`.background`, not the hue) laid over the
        /// gradient at this opacity, per appearance. The column reads darker than the page frame in dark and lighter in
        /// light, and keeps a trace of the Theme. Opaque under Reduce Transparency.
        public var columnLight: Double = 0.5
        public var columnDark: Double = 0.5
        /// A discreet item: its tile, glyph and fill at this share.
        public var discreet: Double = 0.5
        /// Relative luminance above which a background counts as light (a floating control takes the light
        /// appearance on it).
        public var lightBackgroundLuminance: Double = 0.4
        /// Increase Contrast multiplies the row fills (hover, current, the selection's floor) by this, capped at 1. The
        /// badge, tile and panel fills and the glass tint stay: raising a fill under a text lowers its contrast.
        public var increasedContrastFactor: Double = 1.8
        /// The contrast every text reaches.
        public var textContrast: Double = 4.5
        /// The contrast every glyph, focus ring and outline reaches.
        public var nonTextContrast: Double = 3
        /// Where row content starts, as a share of the window height: above it, text sits on the bare gradient.
        public var contentTop: Double = 0.1
        /// Where the switcher's zone starts, as a share of the window height: the selected capsule sits on the glass
        /// over the gradient from there down (solver).
        public var switcherTop: Double = 0.85
        /// A pressed plain control's opacity.
        public var pressed: Double = 0.6
        /// A disabled plain control's opacity. Disabled controls carry no contrast requirement (WCAG 1.4.3, 1.4.11).
        public var disabled: Double = 0.4

        public init() {}

        /// The column's backdrop in one appearance.
        public func column(isDark: Bool) -> Double { isDark ? columnDark : columnLight }

        public func contrasted(_ opacity: Double, _ increased: Bool) -> Double {
            increased ? min(1, opacity * increasedContrastFactor) : opacity
        }
    }

    /// Fixed dimensions, in points.
    public struct Size: Sendable, Equatable {
        /// Smallest hit target: 28 pt for a pointer, 44 pt for a finger.
        public var minTarget: CGFloat = Self.platformMinTarget
        /// Stroke under Increase Contrast or Reduce Transparency, and around a canvas.
        public var stroke: CGFloat = 1
        public var hairline: CGFloat = 0.5
        public var focusRing: CGFloat = 2
        /// The selected row's marker bar: its width.
        public var selectionMarker: CGFloat = 3
        /// Row tiles: standard 32 pt, compact 28 pt, small 22 pt, status 20 pt.
        public var tile: CGFloat = 32
        public var compactTile: CGFloat = 28
        public var smallTile: CGFloat = 22
        public var statusTile: CGFloat = 20
        /// A compact row (40 pt), and the status line (38 pt).
        public var compactRow: CGFloat = 40
        public var statusLine: CGFloat = 38
        /// An unread or status dot.
        public var dot: CGFloat = 8
        /// A floating pill: its height, an icon button in it, its symbols, and the divider between button groups.
        public var floatingPill: CGFloat = 56
        public var pillButton: CGFloat = 36
        public var pillSymbol: CGFloat = 20
        public var pillDivider: CGFloat = 22
        /// The turn of an open folder's chevron, in degrees.
        public var disclosureDegrees: Double = 90
        /// A toolbar's icon button.
        public var toolbarButton: CGFloat = 28
        /// A palette swatch and its ring.
        public var swatch: CGFloat = 14
        public var swatchRing: CGFloat = 1.5
        /// A field pill: 42 pt high with its 32 pt circular tile.
        public var pill: CGFloat = 42
        /// The switcher and the Space rail: an item's glyph circle. The glass switcher (deprecated): an unselected
        /// item's width, every item's minimum height.
        public var glyphCircle: CGFloat = 24
        /// A small glyph circle (`ThemeGlyph` at `GlyphSize.small`: a search header's).
        public var glyphCircleSmall: CGFloat = 16
        public var switcherItemWidth: CGFloat = 52
        public var switcherItemHeight: CGFloat = 40
        /// A list column: minimum, ideal and maximum widths.
        public var columnMin: CGFloat = 300
        public var columnIdeal: CGFloat = 360
        public var columnMax: CGFloat = 480
        /// The Space rail: its row (a target, plus room for the marker under it), the active Space's marker length (its
        /// thickness is `selectionMarker`), the divider's height, the width kept for a folded Profile's "+n" count, and
        /// how many dots a folded Profile shows before that count.
        public var railHeight: CGFloat = Self.platformMinTarget + Spacing.s
        public var railMarker: CGFloat = Spacing.m
        public var railDivider: CGFloat = Spacing.l
        public var railCount: CGFloat = Spacing.l
        public var railDotsMax: Int = 4
        /// The tallest a Space rail panel grows before it scrolls.
        public var railPanelMaxHeight: CGFloat = 480
        /// A segmented pill: its height (a target, plus the padding above and below its segments), and the marker bar
        /// under the selected segment's title (its thickness is `selectionMarker`).
        public var segmentedPill: CGFloat = Self.platformMinTarget + 2 * Spacing.xs
        public var segmentMarker: CGFloat = Spacing.m

        public init() {}

        public static var platformMinTarget: CGFloat {
            #if os(iOS)
            44
            #else
            28
            #endif
        }
    }

    /// Type roles on the system font: a text style and a weight, never a point size, so the system's sizes and
    /// Dynamic Type apply.
    public struct TypeScale: Sendable, Equatable {
        public var rowTitle = TextRole(.body)
        public var rowTitleEmphasized = TextRole(.body, .semibold)
        public var rowDetail = TextRole(.caption)
        /// Small uppercase group headers, letter-spaced (`Spacing.headerTracking`).
        public var groupHeader = TextRole(.caption, .semibold, uppercased: true)
        public var sectionHeader = TextRole(.subheadline, .semibold)
        public var count = TextRole(.caption)
        public var pillTitle = TextRole(.body, .semibold)
        public var initial = TextRole(.callout, .bold)
        public var glyphCircle = TextRole(.caption, .bold)
        public var glyphCircleSmall = TextRole(.caption2, .bold)
        /// An emoji glyph (a Space's, in the rail and its panel, and `ThemeGlyph`'s) is drawn at its circle's text size
        /// (`glyphCircle`, or `glyphCircleSmall` in a small `ThemeGlyph`) times this, so that it fills its circle the
        /// way an initial does instead of sitting small in it. Capped by `DesignTokens.glyphEmojiSize(textSize:circle:)`
        /// so its artwork stays inside the circle.
        public var glyphEmojiScale: CGFloat = 1.3
        public var switcherLabel = TextRole(.callout, .semibold)
        public var banner = TextRole(.callout)
        public var bannerTitle = TextRole(.callout, .semibold)
        /// The label of a button that has no symbol (a label-only icon button, a banner's action).
        public var buttonLabel = TextRole(.callout, .semibold)
        /// A segmented pill's titles: the others, and the selected one.
        public var segment = TextRole(.callout)
        public var segmentSelected = TextRole(.callout, .semibold)
        public var accessory = TextRole(.caption, .semibold)

        public init() {}
    }

    /// The window gradient's opacities per appearance: top (primary hue), middle (secondary), bottom (primary).
    public struct WindowGradient: Sendable, Equatable {
        public var light: GradientSpec = .light
        public var dark: GradientSpec = .dark

        public init() {}

        public func spec(isDark: Bool) -> GradientSpec { isDark ? dark : light }
    }
}

extension DesignTokens {
    /// The share of `Size.glyphCircle` an emoji glyph's size never exceeds: 0.55, 13.2 pt in the 24 pt circle. An
    /// emoji's artwork spans about 1.25 times its size (Apple Color Emoji), so at this size the corners of a square one
    /// (16.5 pt, half a diagonal of 11.7 pt) stay inside the circle's 12 pt radius.
    public static let glyphEmojiMaxShare: CGFloat = 0.55

    /// The point size of an emoji glyph when `glyphCircle`'s text style is `textSize` points: `textSize` times
    /// `TypeScale.glyphEmojiScale`, at most `glyphEmojiMaxShare` of `Size.glyphCircle`. On macOS, 10 pt caption: 13 pt.
    public func glyphEmojiSize(textSize: CGFloat) -> CGFloat {
        glyphEmojiSize(textSize: textSize, circle: size.glyphCircle)
    }

    /// The same in a circle `circle` points wide (`Size.glyphCircleSmall` for a small `ThemeGlyph`): the scale is the
    /// same, the cap is `glyphEmojiMaxShare` of that circle. On macOS, 10 pt caption2 in the 16 pt circle: 8.8 pt.
    public func glyphEmojiSize(textSize: CGFloat, circle: CGFloat) -> CGFloat {
        min(textSize * type.glyphEmojiScale, circle * Self.glyphEmojiMaxShare)
    }
}

/// A text style and weight, with optional tracking and upper case.
public struct TextRole: Sendable, Equatable {
    public var style: Font.TextStyle
    public var weight: Font.Weight
    public var tracking: CGFloat
    public var uppercased: Bool

    public init(_ style: Font.TextStyle, _ weight: Font.Weight = .regular, tracking: CGFloat = 0, uppercased: Bool = false) {
        self.style = style
        self.weight = weight
        self.tracking = tracking
        self.uppercased = uppercased
    }

    public var font: Font { .system(style, weight: weight) }
}
