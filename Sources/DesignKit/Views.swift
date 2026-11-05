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
/// mirroring what is inside the column. Deprecated with `ColumnSurface`, which it is built on.
@available(*, deprecated, message: "Use SidebarSplitView, the system NavigationSplitView sidebar, with the kit's roles in .frame. Removed in 0.3.")
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
/// (`SurfacePlacement.column`). Give it its width through the content (or the split item hosting it). Deprecated in
/// 0.2.6, removed in 0.3: neither client draws a column surface. The column is a system `NavigationSplitView` sidebar,
/// flush with the window's edge, its list plain with `.scrollContentBackground(.hidden)`, the kit's views in it in
/// `.frame`.
@available(*, deprecated, message: "Use SidebarSplitView, the system NavigationSplitView sidebar, with the kit's roles in .frame. Removed in 0.3.")
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
    @available(*, deprecated, message: "Use SidebarSplitView, the system NavigationSplitView sidebar, with the kit's roles in .frame. Removed in 0.3.")
    public func columnSurface(side: ColumnSide = .left) -> some View {
        ColumnSurface(side: side) { self }
    }
}

/// Content set in its column: inset by `Spacing.canvasInset`, rounded (`Radius.canvas`), outlined by a 1 pt
/// `.separator` line (`.secondary` under Increase Contrast).
public struct ContentCanvas<Content: View>: View {
    @Environment(\.designTokens) private var tokens
    @Environment(\.kitContrast) private var contrast
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

extension View {
    /// Draws the kit's tile fill behind the view: a rounded square of `size` filled with the Theme's tile fill, the view
    /// centred in it in `ColorRoles.tintText` (4.5:1 on it). For a client's own tile content (a logo, an account's
    /// initial) that `TileContent` has no case for. Hide it from VoiceOver yourself if it is decorative.
    public func tileFill(_ size: TileSize = .standard) -> some View {
        modifier(TileFillModifier(size: size))
    }

    /// Draws the kit's badge fill behind the view: a capsule in the Theme's badge fill, the view padded in it and set
    /// in `ColorRoles.tintText` (4.5:1 on it). For a client's count or label next to a row's title.
    public func badgeFill() -> some View {
        modifier(BadgeFillModifier())
    }
}

private struct TileFillModifier: ViewModifier {
    @Environment(\.designTokens) private var tokens
    let size: TileSize

    func body(content: Content) -> some View {
        let side = size.side(tokens.size)
        WithColorRoles { roles in
            content
                .foregroundStyle(roles.tintText)
                .frame(width: side, height: side)
                .background(roles.tileFill, in: RoundedRectangle(cornerRadius: size.radius(tokens.radius), style: .continuous))
        }
    }
}

private struct BadgeFillModifier: ViewModifier {
    @Environment(\.designTokens) private var tokens

    func body(content: Content) -> some View {
        WithColorRoles { roles in
            content
                .foregroundStyle(roles.tintText)
                .padding(.horizontal, tokens.spacing.badgeHorizontal)
                .padding(.vertical, tokens.spacing.badgeVertical)
                .background(roles.badgeFill, in: Capsule(style: .continuous))
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

/// The background of a `ListRow`, on its own: hover, current and selection fills in the Theme's colour, the outline
/// under Increase Contrast or the bar at the leading edge otherwise, and the focus ring. It fills the row minus half the
/// row gap above and below and stays inside the column's margin, so two backgrounds never touch. For a row that is a
/// `List` cell (`listRowBackground(ListRowBackground(state:))`), whose content is a `ListRowContent` or any view with
/// the row's padding; the cell's insets must cancel the `List`'s own margin (`Spacing.listCellMargin`) so the background lines up as it
/// does behind a `ListRow` in a stack (`listRowCell(state:placement:)` does both). Hidden from VoiceOver.
public struct ListRowBackground: View {
    @Environment(\.designTokens) private var tokens
    @Environment(\.kitContrast) private var contrast
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let state: RowState
    private let placement: RowPlacement

    public init(state: RowState = RowState(), placement: RowPlacement = .free(firstInSection: false)) {
        self.state = state
        self.placement = placement
    }

    public var body: some View {
        let spacing = tokens.spacing
        let shape = RoundedRectangle(cornerRadius: tokens.radius.row, style: .continuous)
        let indent = placement.indent(spacing)
        WithColorRoles { roles in
            Color.clear
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
                .padding(.horizontal, placement.sideInset(spacing))
                .padding(.top, placement.topInset(spacing))
                .padding(.bottom, spacing.rowGap / 2)
                .animation(MotionRole.hoverFill.animation(reduceMotion: reduceMotion), value: state)
                .accessibilityHidden(true)
        }
    }

    private func fill(_ roles: ColorRoles) -> Color {
        if state.isSelected { return roles.selectionFill }
        if state.isCurrent { return roles.currentFill }
        if state.isHovered { return roles.hoverFill }
        return .clear
    }
}

extension RowPlacement {
    func indent(_ spacing: DesignTokens.Spacing) -> CGFloat {
        if case .layer(let level) = self, level > 1 { return CGFloat(level - 1) * spacing.layerIndent }
        return 0
    }

    func sideInset(_ spacing: DesignTokens.Spacing) -> CGFloat {
        switch self {
        case .free: spacing.listMargin - spacing.rowInsetHorizontal
        case .layer: spacing.layerInset
        }
    }

    func topInset(_ spacing: DesignTokens.Spacing) -> CGFloat {
        if case .free(true) = self { return spacing.sectionHeaderBottom }
        return spacing.rowGap / 2
    }
}

/// A row of a list column: a tile, a column of text (title, then optional detail lines), a trailing accessory. Its
/// background (`ListRowBackground`: hover, current, selection in the Theme's colour) fills the row minus half the row gap
/// above and below and stays inside the column's margin, so two backgrounds never touch. Under Increase Contrast a
/// selected or current row is outlined in `ColorRoles.outline`; otherwise a selected row carries a bar at its leading
/// edge (`ColorRoles.selectionMarker`, 3:1), since its fill alone shows at about 1.3:1. Selected: VoiceOver says so.
/// A row that is a `List` cell is a `ListRowContent` with `listRowCell(state:)`, not a `ListRow`.
public struct ListRow<Leading: View, Trailing: View>: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let content: ListRowContent<Leading, Trailing>
    private let state: RowState
    private let placement: RowPlacement

    public init(
        _ title: String, details: [String] = [], state: RowState = RowState(),
        placement: RowPlacement = .free(firstInSection: false),
        @ViewBuilder leading: () -> Leading, @ViewBuilder trailing: () -> Trailing = { EmptyView() }
    ) {
        self.content = ListRowContent(title, details: details, state: state, placement: placement, leading: leading, trailing: trailing)
        self.state = state
        self.placement = placement
    }

    public var body: some View {
        content
            .background { ListRowBackground(state: state, placement: placement) }
            .animation(MotionRole.hoverFill.animation(reduceMotion: reduceMotion), value: state)
    }
}

/// What a `ListRow` shows, without its background: the tile, the text, the trailing accessory, at the row's paddings
/// (`Spacing.rowInsetHorizontal` and the row's vertical insets inside, then the margin and the row gap round the
/// background it leaves room for), one VoiceOver element with the button trait, "selected" said. For a `List` cell,
/// whose background is the cell's: `ListRowContent(…).listRowCell(state:)`.
public struct ListRowContent<Leading: View, Trailing: View>: View {
    @Environment(\.designTokens) private var tokens
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
            .padding(.leading, placement.indent(spacing))
            .padding(.horizontal, placement.sideInset(spacing))
            .padding(.top, placement.topInset(spacing))
            .padding(.bottom, spacing.rowGap / 2)
            .contentShape(.rect)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(state.isSelected ? [.isSelected, .isButton] : .isButton)
        }
    }
}

extension View {
    /// Makes the view a `List` cell drawn like a `ListRow`: `ListRowBackground(state:placement:)` as the cell's
    /// background, no separator, and the cell's insets set so the background and the content sit where they do in a
    /// column of `ListRow`s. A `List` cell keeps a margin of `Spacing.listCellMargin` round its content on macOS even
    /// with zero insets, which a negative inset cancels; the kit does that here. The content is a `ListRowContent`, or
    /// the client's own view at the same paddings.
    public func listRowCell(state: RowState = RowState(), placement: RowPlacement = .free(firstInSection: false)) -> some View {
        modifier(ListRowCellModifier(state: state, placement: placement))
    }
}

private struct ListRowCellModifier: ViewModifier {
    @Environment(\.designTokens) private var tokens
    let state: RowState
    let placement: RowPlacement

    func body(content: Content) -> some View {
        let margin = tokens.spacing.listCellMargin
        content
            .listRowInsets(EdgeInsets(top: 0, leading: -margin, bottom: 0, trailing: -margin))
            .listRowSeparator(.hidden)
            .listRowBackground(ListRowBackground(state: state, placement: placement))
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
    @Environment(\.kitContrast) private var contrast
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

/// Which way a `StatusLine`'s chevron points.
public enum StatusLineChevron: Sendable, Equatable {
    case up, down
}

/// Where a `StatusLine` shows its count: right after the title, or at the end of the line, before the chevron.
public enum StatusLineCountPlacement: Sendable, Equatable {
    case afterTitle, trailing
}

/// The status line at the top of a column: what the list shows now, in one row a little taller than a compact row.
/// A small tile, the state ("Personal · Inbox"), a count, and a chevron that says whether the zone under it is open.
/// With `fillsWhenOpen` the row is also filled while open, in the current-row fill (outlined under Increase Contrast),
/// so it reads as the start of the zone under it; a hover shows the hover fill instead, open or not. The tile is the
/// kit's (`TileContent`) or any view of the client's, drawn in a `Size.statusTile` square.
///
/// The chevron points up while open and down while closed, unless `chevron` says otherwise (a line being pulled open
/// turns its chevron before it opens, and is not filled until then); a change of direction replaces the symbol
/// (`indicatorRotation`, immediate under Reduce Motion). The count sits after the title or, with `countPlacement`
/// `.trailing`, at the end of the line. A title too long for the line is cut at `truncationMode` (`.middle` keeps both
/// ends of "Personal · A long folder name · Inbox"). The line is at least `Size.statusLine` tall and grows with its text
/// (larger type sizes).
public struct StatusLine<Leading: View>: View {
    @Environment(\.designTokens) private var tokens
    @Environment(\.kitContrast) private var contrast
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let leading: Leading
    private let title: String
    private let count: Int?
    private let isOpen: Bool
    private let fillsWhenOpen: Bool
    private let state: RowState
    private let chevron: StatusLineChevron
    private let countPlacement: StatusLineCountPlacement
    private let truncationMode: Text.TruncationMode

    /// `chevron` nil points it up while open, down while closed.
    public init(
        title: String, count: Int? = nil, isOpen: Bool, fillsWhenOpen: Bool = false, state: RowState = RowState(),
        chevron: StatusLineChevron? = nil, countPlacement: StatusLineCountPlacement = .afterTitle,
        truncationMode: Text.TruncationMode = .tail, @ViewBuilder tile: () -> Leading
    ) {
        self.leading = tile()
        self.title = title
        self.count = count
        self.isOpen = isOpen
        self.fillsWhenOpen = fillsWhenOpen
        self.state = state
        self.chevron = chevron ?? (isOpen ? .up : .down)
        self.countPlacement = countPlacement
        self.truncationMode = truncationMode
    }

    public var body: some View {
        let shape = RoundedRectangle(cornerRadius: tokens.radius.row, style: .continuous)
        let isFilled = isOpen && fillsWhenOpen
        WithColorRoles { roles in
            HStack(spacing: tokens.spacing.compactTileToText) {
                leading
                    .frame(width: tokens.size.statusTile, height: tokens.size.statusTile)
                    .accessibilityHidden(true)
                Text(title).role(tokens.type.rowTitleEmphasized).lineLimit(1).truncationMode(truncationMode)
                if countPlacement == .afterTitle { countText(roles) }
                Spacer(minLength: 0)
                if countPlacement == .trailing { countText(roles) }
                Image(systemName: chevron == .up ? "chevron.up" : "chevron.down")
                    .font(tokens.type.accessory.font)
                    .foregroundStyle(roles.secondaryText)
                    .contentTransition(.symbolEffect(.replace))
                    .animation(MotionRole.indicatorRotation.animation(reduceMotion: reduceMotion), value: chevron)
            }
            .padding(.horizontal, tokens.spacing.rowInsetHorizontal)
            .padding(.vertical, tokens.spacing.rowInsetVertical)
            .frame(minHeight: tokens.size.statusLine)
            .background { shape.fill(state.isHovered ? roles.hoverFill : isFilled ? roles.currentFill : .clear) }
            .overlay {
                if isFilled && contrast == .increased {
                    shape.strokeBorder(roles.outline, lineWidth: tokens.size.stroke).accessibilityHidden(true)
                }
            }
            .focusRing(state.isFocused, in: shape)
            .padding(.horizontal, tokens.spacing.listMargin - tokens.spacing.rowInsetHorizontal)
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isButton)
        }
    }

    @ViewBuilder
    private func countText(_ roles: ColorRoles) -> some View {
        if let count {
            Text(count, format: .number).role(tokens.type.count).foregroundStyle(roles.secondaryText)
        }
    }
}

extension StatusLine where Leading == Tile {
    public init(
        tile: TileContent, title: String, count: Int? = nil, isOpen: Bool, fillsWhenOpen: Bool = false,
        state: RowState = RowState(), chevron: StatusLineChevron? = nil,
        countPlacement: StatusLineCountPlacement = .afterTitle, truncationMode: Text.TruncationMode = .tail
    ) {
        self.init(
            title: title, count: count, isOpen: isOpen, fillsWhenOpen: fillsWhenOpen, state: state, chevron: chevron,
            countPlacement: countPlacement, truncationMode: truncationMode
        ) {
            Tile(tile, size: .status)
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

/// A button in a target of `Size.toolbarButton` (never under `minTarget`): a symbol alone, or, without a symbol, its
/// title alone as a label (`Type.buttonLabel`, `Spacing.buttonLabelHorizontal` either side, never narrower than the
/// target). The title is its VoiceOver label and its help. Dimmed to `Emphasis.disabled` when disabled, to
/// `Emphasis.pressed` while pressed; a keyboard focus shows the kit's focus ring (`ColorRoles.focusRing`, 3:1).
public struct IconButton: View {
    @Environment(\.designTokens) private var tokens
    private let title: String
    private let systemImage: String?
    private let action: () -> Void

    public init(_ title: String, systemImage: String, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.action = action
    }

    /// A label-only button: `title` is what it shows.
    public init(_ title: String, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = nil
        self.action = action
    }

    public var body: some View {
        let side = max(tokens.size.toolbarButton, tokens.size.minTarget)
        let shape = RoundedRectangle(cornerRadius: tokens.radius.row, style: .continuous)
        WithColorRoles { roles in
            Button(action: action) {
                Group {
                    if let systemImage {
                        Label(title, systemImage: systemImage)
                            .labelStyle(.iconOnly)
                            .frame(width: side, height: side)
                    } else {
                        Text(title)
                            .role(tokens.type.buttonLabel)
                            .lineLimit(1)
                            .padding(.horizontal, tokens.spacing.buttonLabelHorizontal)
                            .frame(minWidth: side, minHeight: side)
                    }
                }
                .controlFocusRing(in: shape)
                .contentShape(.rect)
            }
            .buttonStyle(PressedOpacityStyle())
            .focusEffectDisabled()
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

/// The size of a `ThemeGlyph`: `Size.glyphCircle` (24 pt), or `Size.glyphCircleSmall` (16 pt, a search header's).
public enum GlyphSize: Sendable, CaseIterable {
    case standard, small

    func side(_ size: DesignTokens.Size) -> CGFloat {
        switch self {
        case .standard: size.glyphCircle
        case .small: size.glyphCircleSmall
        }
    }

    func text(_ type: DesignTokens.TypeScale) -> TextRole {
        switch self {
        case .standard: type.glyphCircle
        case .small: type.glyphCircleSmall
        }
    }

    /// The point size of an emoji in this circle: its text style's size times `TypeScale.glyphEmojiScale`, capped by
    /// `DesignTokens.glyphEmojiSize(textSize:circle:)`. The rail's glyphs and `ThemeGlyph` both draw an emoji at it.
    func emojiSize(_ tokens: DesignTokens, _ dynamicTypeSize: DynamicTypeSize) -> CGFloat {
        tokens.glyphEmojiSize(textSize: text(tokens.type).pointSize(dynamicTypeSize), circle: side(tokens.size))
    }
}

/// The circle that stands for a Theme-coloured item (a space): the primary hue, opaque, with an emoji, a symbol (white,
/// or black where white stays under 3:1) or an initial (white, or black where white stays under 4.5:1), at `size`. An
/// emoji wins over a symbol, a symbol over the initial. The emoji keeps its own colours (no ink, no tint) and is drawn
/// at the rail's emoji size for that circle (`TypeScale.glyphEmojiScale`, `DesignTokens.glyphEmojiSize(textSize:circle:)`),
/// so that it fills the circle the way an initial does. The glyph is hidden from accessibility: the item it stands for
/// carries the name, never the emoji's description.
public struct ThemeGlyph: View {
    @Environment(\.designTokens) private var tokens
    @Environment(\.theme) private var environmentTheme
    @Environment(\.colorScheme) private var scheme
    @Environment(\.kitContrast) private var contrast
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    private let symbol: String?
    private let emoji: String?
    private let name: String
    private let theme: Theme?
    private let size: GlyphSize

    /// `emoji` (a Space's, say) is drawn instead of `symbol` and the initial when it is not nil or empty.
    public init(
        name: String, symbol: String? = nil, emoji: String? = nil, theme: Theme? = nil, size: GlyphSize = .standard
    ) {
        self.name = name
        self.symbol = symbol
        self.emoji = emoji.flatMap { $0.isEmpty ? nil : $0 }
        self.theme = theme
        self.size = size
    }

    public var body: some View {
        let hue = (theme ?? environmentTheme ?? Palette.standard.themes[0]).primary
        let appearance = Appearance(isDark: scheme == .dark, isIncreasedContrast: contrast == .increased)
        let minimum = symbol == nil ? tokens.emphasis.textContrast : tokens.emphasis.nonTextContrast
        let ink = ColorRoles.ink(on: hue, in: appearance, minimum: minimum)
        Group {
            if let emoji {
                Text(emoji).font(.system(size: size.emojiSize(tokens, dynamicTypeSize)))
            } else if let symbol {
                Image(systemName: symbol).foregroundStyle(ink)
            } else {
                Text(name.first.map { String($0).uppercased() } ?? "").foregroundStyle(ink)
            }
        }
        .font(size.text(tokens.type).font)
        .frame(width: size.side(tokens.size), height: size.side(tokens.size))
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

/// What a banner's action button does.
public struct BannerAction {
    public let title: String
    public let perform: () -> Void

    public init(_ title: String, perform: @escaping () -> Void) {
        self.title = title
        self.perform = perform
    }
}

/// A discreet message on glass over the top of a column or a canvas: a symbol, an optional title over the message, and
/// either the client's own actions or, from `init(systemImage:title:message:action:onClose:)`, the kit's: one action
/// button and a close button. The title is in the label colour and semibold, the message under it in the secondary ink,
/// the action in the label colour and semibold (all 4.5:1 on glass), the close button a plain `xmark` named "Close".
/// The message shows in full by default, on as many lines as it takes, and the banner grows with it; `messageLineLimit`
/// caps it (the end is then cut with an ellipsis). The title takes 2 lines at most.
public struct Banner<Actions: View>: View {
    @Environment(\.designTokens) private var tokens
    private let systemImage: String
    private let title: String?
    private let message: String
    private let messageLineLimit: Int?
    private let actions: Actions

    public init(
        systemImage: String, message: String, messageLineLimit: Int? = nil, @ViewBuilder actions: () -> Actions
    ) {
        self.systemImage = systemImage
        self.title = nil
        self.message = message
        self.messageLineLimit = messageLineLimit
        self.actions = actions()
    }

    /// A banner with a title over its message, and the client's own actions.
    public init(
        systemImage: String, title: String, message: String, messageLineLimit: Int? = nil,
        @ViewBuilder actions: () -> Actions
    ) {
        self.systemImage = systemImage
        self.title = title
        self.message = message
        self.messageLineLimit = messageLineLimit
        self.actions = actions()
    }

    public var body: some View {
        WithColorRoles { roles in
            HStack(alignment: title == nil ? .center : .top, spacing: tokens.spacing.pillActionGap) {
                Image(systemName: systemImage).foregroundStyle(roles.tintText).accessibilityHidden(true)
                VStack(alignment: .leading, spacing: tokens.spacing.bannerLines) {
                    if let title {
                        Text(title).role(tokens.type.bannerTitle).lineLimit(2).fixedSize(horizontal: false, vertical: true)
                    }
                    Text(message)
                        .role(tokens.type.banner)
                        .foregroundStyle(title == nil ? AnyShapeStyle(.primary) : AnyShapeStyle(roles.secondaryText))
                        .lineLimit(messageLineLimit)
                        .fixedSize(horizontal: false, vertical: true)
                }
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

/// The kit's banner actions: an optional action button, then an optional close button.
public struct BannerButtons: View {
    @Environment(\.designTokens) private var tokens
    private let action: BannerAction?
    private let onClose: (() -> Void)?

    init(action: BannerAction?, onClose: (() -> Void)?) {
        self.action = action
        self.onClose = onClose
    }

    public var body: some View {
        HStack(spacing: tokens.spacing.pillActionGap) {
            if let action {
                let shape = Capsule(style: .continuous)
                Button(action: action.perform) {
                    Text(action.title)
                        .role(tokens.type.buttonLabel)
                        .lineLimit(1)
                        .padding(.horizontal, tokens.spacing.buttonLabelHorizontal)
                        .frame(minHeight: tokens.size.minTarget)
                        .controlFocusRing(in: shape)
                        .contentShape(shape)
                }
                .buttonStyle(PressedOpacityStyle())
                .focusEffectDisabled()
            }
            if let onClose {
                let side = max(tokens.size.toolbarButton, tokens.size.minTarget)
                WithColorRoles { roles in
                    Button(action: onClose) {
                        Label {
                            Text("Close", tableName: "DesignKit", bundle: .module)
                        } icon: {
                            Image(systemName: "xmark")
                        }
                        .labelStyle(.iconOnly)
                        .frame(width: side, height: side)
                        .controlFocusRing(in: Circle())
                        .contentShape(.circle)
                    }
                    .buttonStyle(PressedOpacityStyle())
                    .focusEffectDisabled()
                    .foregroundStyle(roles.secondaryText)
                }
            }
        }
    }
}

extension Banner where Actions == BannerButtons {
    /// A banner with the kit's own buttons: an `action` and a close button that calls `onClose`; each is left out when
    /// nil.
    public init(
        systemImage: String, title: String? = nil, message: String, messageLineLimit: Int? = nil,
        action: BannerAction? = nil, onClose: (() -> Void)? = nil
    ) {
        self.systemImage = systemImage
        self.title = title
        self.message = message
        self.messageLineLimit = messageLineLimit
        self.actions = BannerButtons(action: action, onClose: onClose)
    }
}

/// One segment of a `SegmentedPill`.
public struct SegmentedPillItem<ID: Hashable>: Identifiable {
    public let id: ID
    public let title: String
    public let systemImage: String?

    public init(id: ID, title: String, systemImage: String? = nil) {
        self.id = id
        self.title = title
        self.systemImage = systemImage
    }
}

/// A glass capsule of segments, one selected: a segmented selector (a view's mode, a filter) in the kit's shapes. The
/// selected segment is filled with the selection fill and set semibold, with a marker bar under its title
/// (`ColorRoles.selectionMarker`, 3:1) outside Increase Contrast, an outline in `ColorRoles.outline` under it, so it is
/// never shown by colour alone. The others are in the secondary ink. Each segment is a target of at least `minTarget`,
/// dims to `Emphasis.pressed` while pressed and to `Emphasis.disabled` when the pill is disabled, and shows the kit's
/// focus ring on keyboard focus. VoiceOver reads a named group of buttons, the selected one "selected".
public struct SegmentedPill<ID: Hashable>: View {
    @Environment(\.designTokens) private var tokens
    @Environment(\.kitContrast) private var contrast
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let items: [SegmentedPillItem<ID>]
    private let selection: Binding<ID>
    private let label: String

    public init(_ items: [SegmentedPillItem<ID>], selection: Binding<ID>, label: String) {
        self.items = items
        self.selection = selection
        self.label = label
    }

    public var body: some View {
        WithColorRoles { roles in
            HStack(spacing: tokens.spacing.segmentGap) {
                ForEach(items) { item in segment(item, roles: roles) }
            }
            .padding(tokens.spacing.segmentPadding)
            .frame(height: tokens.size.segmentedPill)
            .surface(.glass(tint: 0), in: Capsule(style: .continuous))
            .animation(MotionRole.rowState.animation(reduceMotion: reduceMotion), value: selection.wrappedValue)
            .accessibilityElement(children: .contain)
            .accessibilityLabel(label)
        }
    }

    private func textRole(_ isSelected: Bool) -> TextRole {
        isSelected ? tokens.type.segmentSelected : tokens.type.segment
    }

    private func segment(_ item: SegmentedPillItem<ID>, roles: ColorRoles) -> some View {
        let isSelected = item.id == selection.wrappedValue
        let shape = Capsule(style: .continuous)
        return Button { selection.wrappedValue = item.id } label: {
            HStack(spacing: tokens.spacing.segmentContent) {
                if let symbol = item.systemImage {
                    Image(systemName: symbol).accessibilityHidden(true)
                }
                Text(item.title).role(textRole(isSelected)).lineLimit(1)
            }
            .font(textRole(isSelected).font)
            .foregroundStyle(isSelected ? AnyShapeStyle(.primary) : AnyShapeStyle(roles.secondaryText))
            .padding(.horizontal, tokens.spacing.segmentHorizontal)
            .frame(
                minWidth: tokens.size.minTarget,
                minHeight: tokens.size.segmentedPill - 2 * tokens.spacing.segmentPadding)
            .background {
                if isSelected {
                    shape.fill(roles.selectionFill)
                        .overlay { if contrast == .increased { shape.strokeBorder(roles.outline, lineWidth: tokens.size.stroke) } }
                        .accessibilityHidden(true)
                }
            }
            .overlay(alignment: .bottom) {
                if isSelected && contrast != .increased {
                    Capsule(style: .continuous)
                        .fill(roles.selectionMarker)
                        .frame(width: tokens.size.segmentMarker, height: tokens.size.selectionMarker)
                        .padding(.bottom, tokens.spacing.segmentMarkerGap)
                        .accessibilityHidden(true)
                }
            }
            .controlFocusRing(in: shape)
            .contentShape(shape)
        }
        .buttonStyle(PressedOpacityStyle())
        .focusEffectDisabled()
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
