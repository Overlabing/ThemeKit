import ColorCore
import ColorUI
import SwiftUI

// The kit's views. Each reads `designTokens` and the Theme from the environment, and asks `ColorRoles` for colours.

// MARK: Window

/// The window background: the plain `.background`, then the Theme's vertical gradient (primary, secondary, primary).
/// A flat layer behind the whole window, under the toolbar too; only a change of Theme animates it (`themeChange`).
public struct WindowBackground: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init() {}

    public var body: some View {
        WithColorRoles { roles in
            Rectangle()
                .fill(.background)
                .overlay { LinearGradient(stops: roles.frameStops, startPoint: .top, endPoint: .bottom) }
                .animation(MotionRole.themeChange.animation(reduceMotion: reduceMotion), value: roles.theme)
                .accessibilityHidden(true)
        }
    }
}

/// Which side of the window a column sits on.
public enum ColumnSide: String, Sendable, CaseIterable {
    case left
    case right
}

/// A list column beside a detail, on the window background. The column sits on its own surface (`ColumnSurface`),
/// `Size.columnIdeal` wide; the detail sits in a content canvas, on the gradient. `.right` mirrors the layout without
/// mirroring what is inside the column.
public struct ColumnLayout<Column: View, Detail: View>: View {
    @Environment(\.designTokens) private var tokens
    private let side: ColumnSide
    private let column: Column
    private let detail: Detail

    public init(side: ColumnSide = .left, @ViewBuilder column: () -> Column, @ViewBuilder detail: () -> Detail) {
        self.side = side
        self.column = column()
        self.detail = detail()
    }

    public var body: some View {
        let columnView = ColumnSurface(side: side) {
            column.frame(width: tokens.size.columnIdeal)
        }
        HStack(spacing: 0) {
            if side == .left { columnView }
            ContentCanvas { detail }
            if side == .right { columnView }
        }
        .background { WindowBackground().ignoresSafeArea() }
    }
}

/// A list column's own surface, so the column reads apart from the page beside it: inset from the window's edges by
/// `Spacing.columnInset` (top, bottom, the outer side; the canvas beside it keeps its own inset), rounded
/// (`Radius.column`), filled with the plain window background at `Emphasis.column(isDark:)` over the gradient (darker
/// than the frame in dark, lighter in light, a trace of the Theme left), and edged in `ColorRoles.columnEdge` (3:1
/// against the gradient and the fill). Opaque under Reduce Transparency. The content starts `Spacing.columnTop` under
/// the window's top edge and is clipped to the surface; the views in it solve their colours on the column's fill
/// (`SurfacePlacement.column`). Drawn with the kit's pieces, never a system sidebar, whose labels dim in an inactive
/// window. Give it its width through the content (or the split item hosting it).
public struct ColumnSurface<Content: View>: View {
    @Environment(\.designTokens) private var tokens
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let side: ColumnSide
    private let content: Content

    public init(side: ColumnSide = .left, @ViewBuilder content: () -> Content) {
        self.side = side
        self.content = content()
    }

    public var body: some View {
        let shape = RoundedRectangle(cornerRadius: tokens.radius.column, style: .continuous)
        let inset = tokens.spacing.columnInset
        let animation = MotionRole.themeChange.animation(reduceMotion: reduceMotion)
        WithColorRoles { roles in
            content
                .padding(.top, tokens.spacing.columnTop - inset)
                .frame(maxHeight: .infinity, alignment: .top)
                .environment(\.surfacePlacement, .column)
                .background {
                    shape.fill(.background.opacity(reduceTransparency ? 1 : roles.columnFillOpacity))
                        .accessibilityHidden(true)
                }
                .clipShape(shape)
                .overlay {
                    shape.strokeBorder(roles.columnEdge, lineWidth: tokens.size.stroke)
                        .animation(animation, value: roles.theme)
                        .accessibilityHidden(true)
                        .allowsHitTesting(false)
                }
                .padding(.vertical, inset)
                .padding(side == .left ? .leading : .trailing, inset)
        }
    }
}

extension View {
    /// Sets the view on a list column's own surface (`ColumnSurface`), on `side` of the window.
    public func columnSurface(side: ColumnSide = .left) -> some View {
        ColumnSurface(side: side) { self }
    }
}

/// Content set in its column: inset by `Spacing.canvasInset`, rounded (`Radius.canvas`), outlined by a 1 pt
/// `.separator` line (`.secondary` under Increase Contrast).
public struct ContentCanvas<Content: View>: View {
    @Environment(\.designTokens) private var tokens
    @Environment(\.colorSchemeContrast) private var contrast
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        let shape = RoundedRectangle(cornerRadius: tokens.radius.canvas, style: .continuous)
        content
            .clipShape(shape)
            .overlay {
                shape.strokeBorder(
                    contrast == .increased ? AnyShapeStyle(.secondary) : AnyShapeStyle(.separator),
                    lineWidth: tokens.size.stroke)
                    .accessibilityHidden(true)
            }
            .padding(tokens.spacing.canvasInset)
    }
}

// MARK: Rows

/// The size of a tile: the row's 32 pt, a compact row's 28 pt, a small 22 pt, or a status line's 20 pt.
public enum TileSize: Sendable {
    case standard, compact, small, status

    func side(_ size: DesignTokens.Size) -> CGFloat {
        switch self {
        case .standard: size.tile
        case .compact: size.compactTile
        case .small: size.smallTile
        case .status: size.statusTile
        }
    }

    func radius(_ radius: DesignTokens.Radius) -> CGFloat {
        switch self {
        case .standard: radius.tile
        case .compact: radius.compactTile
        case .small: radius.smallTile
        case .status: radius.statusTile
        }
    }
}

/// What a tile shows.
public enum TileContent: Sendable, Equatable {
    /// A symbol on a solid colour: white, or black where white stays under 3:1 on that colour.
    case symbol(String, Color)
    /// A symbol in the Theme's tint, on the tile fill.
    case tintedSymbol(String)
    /// An initial in the Theme's tint, on the tile fill: the fallback when there is no icon.
    case initial(String)
}

/// A rounded square at the leading edge of a row.
public struct Tile: View {
    @Environment(\.designTokens) private var tokens
    @Environment(\.self) private var environment
    private let content: TileContent
    private let size: TileSize

    public init(_ content: TileContent, size: TileSize = .standard) {
        self.content = content
        self.size = size
    }

    public var body: some View {
        let side = size.side(tokens.size)
        let shape = RoundedRectangle(cornerRadius: size.radius(tokens.radius), style: .continuous)
        WithColorRoles { roles in
            Group {
                switch content {
                case .symbol(let name, let color):
                    shape.fill(color).overlay {
                        Image(systemName: name).foregroundStyle(
                            ColorRoles.ink(on: color, in: environment, minimum: tokens.emphasis.nonTextContrast))
                    }
                case .tintedSymbol(let name):
                    shape.fill(roles.tileFill).overlay { Image(systemName: name).foregroundStyle(roles.tintText) }
                case .initial(let letter):
                    shape.fill(roles.tileFill).overlay {
                        Text(letter).role(tokens.type.initial).foregroundStyle(roles.tintText)
                    }
                }
            }
            .font(tokens.type.initial.font)
            .frame(width: side, height: side)
            .accessibilityHidden(true)
        }
    }
}

/// The interaction state of a row.
public struct RowState: Sendable, Equatable {
    public var isSelected: Bool
    public var isCurrent: Bool
    public var isHovered: Bool
    public var isFocused: Bool

    public init(isSelected: Bool = false, isCurrent: Bool = false, isHovered: Bool = false, isFocused: Bool = false) {
        self.isSelected = isSelected
        self.isCurrent = isCurrent
        self.isHovered = isHovered
        self.isFocused = isFocused
    }
}

/// Where a row sits: free in the column (after a section header or not), or inside a nested panel.
public enum RowPlacement: Sendable, Equatable {
    case free(firstInSection: Bool)
    /// Inside a `LayerPanel`; `level` 1 has no indent, level 2 is indented by `Spacing.layerIndent`.
    case layer(level: Int)
}

/// A row of a list column: a tile, a column of text (title, then optional detail lines), a trailing accessory. Its
/// background (hover, current, selection in the Theme's colour) fills the row minus half the row gap above and below
/// and stays inside the column's margin, so two backgrounds never touch. Under Increase Contrast a selected or current
/// row is outlined in `ColorRoles.outline`; otherwise a selected row carries a bar at its leading edge
/// (`ColorRoles.selectionMarker`, 3:1), since its fill alone shows at about 1.3:1. Selected: VoiceOver says so.
public struct ListRow<Leading: View, Trailing: View>: View {
    @Environment(\.designTokens) private var tokens
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let title: String
    private let details: [String]
    private let state: RowState
    private let placement: RowPlacement
    private let leading: Leading
    private let trailing: Trailing

    public init(
        _ title: String, details: [String] = [], state: RowState = RowState(),
        placement: RowPlacement = .free(firstInSection: false),
        @ViewBuilder leading: () -> Leading, @ViewBuilder trailing: () -> Trailing = { EmptyView() }
    ) {
        self.title = title
        self.details = details
        self.state = state
        self.placement = placement
        self.leading = leading()
        self.trailing = trailing()
    }

    public var body: some View {
        let spacing = tokens.spacing
        let shape = RoundedRectangle(cornerRadius: tokens.radius.row, style: .continuous)
        WithColorRoles { roles in
            HStack(alignment: details.isEmpty ? .center : .top, spacing: spacing.tileToText) {
                leading
                VStack(alignment: .leading, spacing: spacing.textLines) {
                    Text(title)
                        .role(state.isSelected ? tokens.type.rowTitleEmphasized : tokens.type.rowTitle)
                        .lineLimit(1)
                    ForEach(details, id: \.self) { line in
                        Text(line).role(tokens.type.rowDetail).foregroundStyle(roles.secondaryText).lineLimit(1)
                    }
                }
                Spacer(minLength: 0)
                trailing
            }
            .padding(.vertical, spacing.textLines)
            .padding(.vertical, spacing.rowInsetVertical)
            .padding(.horizontal, spacing.rowInsetHorizontal)
            .padding(.leading, indent)
            .background { shape.fill(fill(roles)).padding(.leading, indent) }
            .overlay {
                if contrast == .increased && (state.isSelected || state.isCurrent) {
                    shape.strokeBorder(roles.outline, lineWidth: tokens.size.stroke).padding(.leading, indent)
                }
            }
            .overlay(alignment: .leading) {
                if contrast != .increased && state.isSelected {
                    Capsule(style: .continuous)
                        .fill(roles.selectionMarker)
                        .frame(width: tokens.size.selectionMarker)
                        .padding(.vertical, spacing.selectionMarkerVertical)
                        .padding(.leading, indent + spacing.selectionMarkerLeading)
                        .accessibilityHidden(true)
                }
            }
            .focusRing(state.isFocused, in: shape)
            .padding(.horizontal, sideInset)
            .padding(.top, topInset)
            .padding(.bottom, spacing.rowGap / 2)
            .contentShape(.rect)
            .animation(MotionRole.hoverFill.animation(reduceMotion: reduceMotion), value: state)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(state.isSelected ? [.isSelected, .isButton] : .isButton)
        }
    }

    private var indent: CGFloat {
        if case .layer(let level) = placement, level > 1 { return CGFloat(level - 1) * tokens.spacing.layerIndent }
        return 0
    }

    private var sideInset: CGFloat {
        switch placement {
        case .free: tokens.spacing.listMargin - tokens.spacing.rowInsetHorizontal
        case .layer: tokens.spacing.layerInset
        }
    }

    private var topInset: CGFloat {
        if case .free(true) = placement { return tokens.spacing.sectionHeaderBottom }
        return tokens.spacing.rowGap / 2
    }

    private func fill(_ roles: ColorRoles) -> Color {
        if state.isSelected { return roles.selectionFill }
        if state.isCurrent { return roles.currentFill }
        if state.isHovered { return roles.hoverFill }
        return .clear
    }
}

/// A folder as a row: its tinted tile, its name, a count, a chevron turning a quarter (`indicatorRotation`) when open.
/// Its children go in a `LayerPanel` right under it.
public struct FolderRow: View {
    @Environment(\.designTokens) private var tokens
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let title: String
    private let count: Int?
    private let isOpen: Bool
    private let state: RowState
    private let symbol: String

    public init(_ title: String, count: Int? = nil, isOpen: Bool, state: RowState = RowState(), symbol: String = "folder") {
        self.title = title
        self.count = count
        self.isOpen = isOpen
        self.state = state
        self.symbol = symbol
    }

    public var body: some View {
        WithColorRoles { roles in
            ListRow(title, state: state) {
                Tile(.tintedSymbol(symbol))
            } trailing: {
                HStack(spacing: tokens.spacing.pillActionGap) {
                    if let count {
                        Text(count, format: .number).role(tokens.type.count).foregroundStyle(roles.secondaryText)
                    }
                    Image(systemName: "chevron.right")
                        .font(tokens.type.accessory.font)
                        .foregroundStyle(roles.secondaryText)
                        .rotationEffect(isOpen ? .degrees(tokens.size.disclosureDegrees) : .zero)
                        .animation(MotionRole.indicatorRotation.animation(reduceMotion: reduceMotion), value: isOpen)
                }
            }
            .accessibilityValue(isOpen ? Text("Expanded", tableName: "DesignKit", bundle: .module) : Text("Collapsed", tableName: "DesignKit", bundle: .module))
        }
    }
}

/// The background that groups an open folder's children: a continuous `.primary` panel at `Emphasis.layer`, rounded
/// concentric to the rows inside it. First-level children are not indented; the panel says they belong.
public struct LayerPanel<Content: View>: View {
    @Environment(\.designTokens) private var tokens
    @Environment(\.colorSchemeContrast) private var contrast
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        let shape = RoundedRectangle(cornerRadius: tokens.radius.layer, style: .continuous)
        VStack(spacing: 0) { content }
            .padding(.vertical, tokens.spacing.layerInset - tokens.spacing.rowGap / 2)
            .background {
                shape.fill(Color.primary.opacity(tokens.emphasis.layer))
                    .overlay { if contrast == .increased { shape.strokeBorder(.separator, lineWidth: tokens.size.stroke) } }
            }
            .padding(.horizontal, tokens.spacing.listMargin - tokens.spacing.rowInsetHorizontal)
    }
}

/// A short header over a group of rows, on the column's margin.
public struct SectionHeader: View {
    @Environment(\.designTokens) private var tokens
    private let title: String
    private let isGroupHeader: Bool

    /// `isGroupHeader`: small uppercase, letter-spaced (a group of a zone); otherwise a section title.
    public init(_ title: String, isGroupHeader: Bool = false) {
        self.title = title
        self.isGroupHeader = isGroupHeader
    }

    public var body: some View {
        WithColorRoles { roles in
            Text(title)
                .role(isGroupHeader ? tokens.type.groupHeader : tokens.type.sectionHeader)
                .tracking(isGroupHeader ? tokens.spacing.headerTracking : 0)
                .foregroundStyle(roles.secondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, tokens.spacing.listMargin)
                .accessibilityAddTraits(.isHeader)
        }
    }
}

/// A hairline across the column, on its margin: separates two groups of rows without a header.
public struct ColumnSeparator: View {
    @Environment(\.designTokens) private var tokens

    public init() {}

    public var body: some View {
        Rectangle()
            .fill(.separator)
            .frame(height: tokens.size.hairline)
            .padding(.horizontal, tokens.spacing.listMargin)
            .padding(.vertical, tokens.spacing.rowGap)
            .accessibilityHidden(true)
    }
}

/// The status line at the top of a column: what the list shows now, in one row a little taller than a compact row.
/// A small tile, the state ("Personal · Inbox"), a count, and a chevron that says whether the zone under it is open.
public struct StatusLine: View {
    @Environment(\.designTokens) private var tokens
    private let tile: TileContent
    private let title: String
    private let count: Int?
    private let isOpen: Bool
    private let state: RowState

    public init(tile: TileContent, title: String, count: Int? = nil, isOpen: Bool, state: RowState = RowState()) {
        self.tile = tile
        self.title = title
        self.count = count
        self.isOpen = isOpen
        self.state = state
    }

    public var body: some View {
        WithColorRoles { roles in
            HStack(spacing: tokens.spacing.compactTileToText) {
                Tile(tile, size: .status)
                Text(title).role(tokens.type.rowTitleEmphasized).lineLimit(1)
                if let count {
                    Text(count, format: .number).role(tokens.type.count).foregroundStyle(roles.secondaryText)
                }
                Spacer(minLength: 0)
                Image(systemName: isOpen ? "chevron.up" : "chevron.down")
                    .font(tokens.type.accessory.font)
                    .foregroundStyle(roles.secondaryText)
            }
            .padding(.horizontal, tokens.spacing.rowInsetHorizontal)
            .frame(height: tokens.size.statusLine)
            .background {
                RoundedRectangle(cornerRadius: tokens.radius.row, style: .continuous)
                    .fill(state.isHovered ? roles.hoverFill : .clear)
            }
            .focusRing(state.isFocused, in: RoundedRectangle(cornerRadius: tokens.radius.row, style: .continuous))
            .padding(.horizontal, tokens.spacing.listMargin - tokens.spacing.rowInsetHorizontal)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isButton)
        }
    }
}

/// The shape of rows still loading: a tile and placeholder text lines per row, static (nothing shimmers), read by
/// VoiceOver as one label. Show it only after the `placeholderFade` delay.
public struct SkeletonRows: View {
    @Environment(\.designTokens) private var tokens
    private let count: Int
    private let label: String
    private static let lines = ["Placeholder title of a row", "A shorter title", "A rather longer placeholder title"]

    public init(count: Int, label: String) {
        self.count = count
        self.label = label
    }

    public var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<count, id: \.self) { index in
                ListRow(Self.lines[index % Self.lines.count], details: [Self.lines[(index + 1) % Self.lines.count]]) {
                    RoundedRectangle(cornerRadius: tokens.radius.tile, style: .continuous)
                        .fill(.quaternary)
                        .frame(width: tokens.size.tile, height: tokens.size.tile)
                }
                .redacted(reason: .placeholder)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(label)
    }
}

// MARK: Controls

/// A plain button style whose label dims while pressed, and more while disabled (`Emphasis.disabled`).
public struct PressedOpacityStyle: ButtonStyle {
    @Environment(\.designTokens) private var tokens
    @Environment(\.isEnabled) private var isEnabled

    public init() {}

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label.opacity(opacity(isPressed: configuration.isPressed))
    }

    private func opacity(isPressed: Bool) -> Double {
        if !isEnabled { return tokens.emphasis.disabled }
        return isPressed ? tokens.emphasis.pressed : 1
    }
}

/// A symbol-only button in a target of `Size.toolbarButton` (never under `minTarget`); its title is its VoiceOver
/// label and its help.
public struct IconButton: View {
    @Environment(\.designTokens) private var tokens
    private let title: String
    private let systemImage: String
    private let action: () -> Void

    public init(_ title: String, systemImage: String, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.action = action
    }

    public var body: some View {
        let side = max(tokens.size.toolbarButton, tokens.size.minTarget)
        WithColorRoles { roles in
            Button(action: action) {
                Label(title, systemImage: systemImage)
                    .labelStyle(.iconOnly)
                    .frame(width: side, height: side)
                    .contentShape(.rect)
            }
            .buttonStyle(PressedOpacityStyle())
            .foregroundStyle(roles.secondaryText)
            .help(title)
        }
    }
}

/// Icon buttons in a row: a leading group and a trailing group, on the column's margin.
public struct IconButtonRow<Leading: View, Trailing: View>: View {
    @Environment(\.designTokens) private var tokens
    private let leading: Leading
    private let trailing: Trailing

    public init(@ViewBuilder leading: () -> Leading, @ViewBuilder trailing: () -> Trailing) {
        self.leading = leading()
        self.trailing = trailing()
    }

    public var body: some View {
        HStack(spacing: 0) {
            leading
            Spacer(minLength: tokens.spacing.pillActionGap)
            trailing
        }
        .padding(.horizontal, tokens.spacing.listMargin - tokens.spacing.rowInsetHorizontal)
    }
}

/// A glass capsule with a circular tile in the Theme's colour, a title and a trailing accessory: a field or a chooser at
/// the top of a column. The tile is concentric to the capsule; its symbol is white, or black where white stays under
/// 3:1. The placeholder is in the secondary ink. Text is never centred.
public struct FieldPill<Trailing: View>: View {
    @Environment(\.designTokens) private var tokens
    private let systemImage: String
    private let title: String
    private let placeholder: String
    private let trailing: Trailing

    public init(systemImage: String, title: String, placeholder: String, @ViewBuilder trailing: () -> Trailing = { EmptyView() }) {
        self.systemImage = systemImage
        self.title = title
        self.placeholder = placeholder
        self.trailing = trailing()
    }

    public var body: some View {
        let tile = tokens.size.pill - 2 * tokens.spacing.pillVertical
        WithColorRoles { roles in
            HStack(spacing: tokens.spacing.pillTileToText) {
                Image(systemName: systemImage)
                    .font(tokens.type.initial.font)
                    .foregroundStyle(roles.primaryGlyph)
                    .frame(width: tile, height: tile)
                    .background(roles.tint, in: .circle)
                    .accessibilityHidden(true)
                Text(title.isEmpty ? placeholder : title)
                    .role(tokens.type.pillTitle)
                    .foregroundStyle(title.isEmpty ? AnyShapeStyle(roles.secondaryText) : AnyShapeStyle(.primary))
                    .lineLimit(1)
                Spacer(minLength: 0)
                trailing
            }
            .padding(.leading, tokens.spacing.pillLeading)
            .padding(.trailing, tokens.spacing.pillTrailing)
            .padding(.vertical, tokens.spacing.pillVertical)
            .frame(height: tokens.size.pill)
            .surface(.glass(tint: 0), in: Capsule(style: .continuous))
            .padding(.horizontal, tokens.spacing.listMargin)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(placeholder)
            .accessibilityValue(title)
        }
    }
}

/// The circle that stands for a Theme-coloured item (a space): the primary hue, opaque, with a symbol (white, or black
/// where white stays under 3:1) or an initial (white, or black where white stays under 4.5:1).
public struct ThemeGlyph: View {
    @Environment(\.designTokens) private var tokens
    @Environment(\.theme) private var environmentTheme
    @Environment(\.colorScheme) private var scheme
    @Environment(\.colorSchemeContrast) private var contrast
    private let symbol: String?
    private let name: String
    private let theme: Theme?

    public init(name: String, symbol: String? = nil, theme: Theme? = nil) {
        self.name = name
        self.symbol = symbol
        self.theme = theme
    }

    public var body: some View {
        let hue = (theme ?? environmentTheme ?? Palette.standard.themes[0]).primary
        let appearance = Appearance(isDark: scheme == .dark, isIncreasedContrast: contrast == .increased)
        let minimum = symbol == nil ? tokens.emphasis.textContrast : tokens.emphasis.nonTextContrast
        Group {
            if let symbol {
                Image(systemName: symbol)
            } else {
                Text(name.first.map { String($0).uppercased() } ?? "")
            }
        }
        .font(tokens.type.glyphCircle.font)
        .foregroundStyle(ColorRoles.ink(on: hue, in: appearance, minimum: minimum))
        .frame(width: tokens.size.glyphCircle, height: tokens.size.glyphCircle)
        .background(hue.color, in: .circle)
        .accessibilityHidden(true)
    }
}

/// One item of the switcher.
public struct SwitcherItem: Identifiable, Sendable, Equatable {
    public let id: String
    public let name: String
    public let symbol: String?
    public let theme: Theme
    /// The key that selects the item, as the app binds it ("⌃1", say), shown in its help after the name; none when nil.
    public let shortcut: String?

    public init(id: String, name: String, symbol: String? = nil, theme: Theme, shortcut: String? = nil) {
        self.id = id
        self.name = name
        self.symbol = symbol
        self.theme = theme
        self.shortcut = shortcut
    }

    /// The item's help: its name, then its shortcut in parentheses when it has one.
    public var help: String { shortcut.map { "\(name) (\($0))" } ?? name }
}

/// A glass bar of items at the bottom of a column (spaces): each item is its glyph; the selected one stretches into a
/// capsule tinted with its Theme and shows its name. The shapes merge and morph in one `GlassEffectContainer`
/// (`themeChange`, the role of a change of space too; no morph under Reduce Motion). Absent with a single item. An
/// item's help is its name and the shortcut the app gives it (`SwitcherItem.shortcut`).
@available(*, deprecated, message: "Use SpaceRail. GlassSwitcher is removed in 0.3.")
public struct GlassSwitcher: View {
    @Environment(\.designTokens) private var tokens
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.glassRendering) private var glassRendering
    @Namespace private var namespace
    private let items: [SwitcherItem]
    private let selection: String
    private let label: String
    private let select: (String) -> Void

    public init(_ items: [SwitcherItem], selection: String, label: String, select: @escaping (String) -> Void) {
        self.items = items
        self.selection = selection
        self.label = label
        self.select = select
    }

    public var body: some View {
        if items.count > 1 {
            Group {
                if usesGlass {
                    GlassEffectContainer(spacing: tokens.spacing.glassMerge) { bar }
                } else {
                    bar
                }
            }
            .animation(MotionRole.themeChange.animation(reduceMotion: reduceMotion), value: selection)
            .padding(.horizontal, tokens.spacing.listMargin)
            .padding(.bottom, tokens.spacing.switcherBottom)
            .accessibilityElement(children: .contain)
            .accessibilityLabel(label)
        }
    }

    private var usesGlass: Bool { !reduceTransparency && glassRendering == .liquidGlass }

    private var bar: some View {
        HStack(spacing: tokens.spacing.switcherItemGap) {
            ForEach(items) { item in
                itemView(item, isSelected: item.id == selection)
            }
        }
        .padding(tokens.spacing.switcherPadding)
        .surface(.glass(tint: 0), in: Capsule(style: .continuous))
    }

    @ViewBuilder
    private func itemView(_ item: SwitcherItem, isSelected: Bool) -> some View {
        let tint = item.theme.primary.color
        let button = Button { select(item.id) } label: {
            HStack(spacing: tokens.spacing.pillTileToText) {
                ThemeGlyph(name: item.name, symbol: item.symbol, theme: item.theme)
                if isSelected {
                    Text(item.name).role(tokens.type.switcherLabel).lineLimit(1)
                        .transition(MotionRole.themeChange.transition(AnyTransition(.blurReplace), reduceMotion: reduceMotion))
                }
            }
            .frame(maxWidth: isSelected ? .infinity : tokens.size.switcherItemWidth, minHeight: tokens.size.switcherItemHeight)
            .contentShape(.capsule)
        }
        .buttonStyle(PressedOpacityStyle())
        .help(item.help)
        .accessibilityLabel(item.name)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        if usesGlass {
            button
                .glassEffect(isSelected ? .regular.tint(tint.opacity(tokens.emphasis.glassTint)).interactive() : .identity, in: .capsule)
                .glassEffectID(item.id, in: namespace)
        } else {
            button.background {
                if isSelected {
                    Capsule().fill(tint.opacity(tokens.emphasis.glassTint))
                }
            }
        }
    }
}

/// A discreet message on glass over the top of a column or a canvas, with an optional action and a close button.
public struct Banner<Actions: View>: View {
    @Environment(\.designTokens) private var tokens
    private let systemImage: String
    private let message: String
    private let actions: Actions

    public init(systemImage: String, message: String, @ViewBuilder actions: () -> Actions) {
        self.systemImage = systemImage
        self.message = message
        self.actions = actions()
    }

    public var body: some View {
        WithColorRoles { roles in
            HStack(spacing: tokens.spacing.pillActionGap) {
                Image(systemName: systemImage).foregroundStyle(roles.tintText).accessibilityHidden(true)
                Text(message).role(tokens.type.banner).lineLimit(2).fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 0)
                actions
            }
            .padding(.vertical, tokens.spacing.bannerVertical)
            .padding(.horizontal, tokens.spacing.bannerHorizontal)
            .surface(.glass(tint: 0), in: RoundedRectangle(cornerRadius: tokens.radius.banner, style: .continuous))
            .accessibilityElement(children: .contain)
        }
    }
}
