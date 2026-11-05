import SwiftUI
#if canImport(AppKit)
import AppKit
#endif

// The system sidebar, dressed by the kit: a `NavigationSplitView` flush with the window's edges, the Theme's gradient
// behind it, the system's own sidebar material and its inactive-window dimming kept as they are.

// MARK: Window

/// A sidebar beside a detail, in a window coloured by its Theme: a system `NavigationSplitView` with the window's
/// gradient behind it (`WindowBackground`) and the kit's window chrome (`sidebarWindowChrome()`). Put the sidebar's
/// `List` in `sidebar` with `sidebarColumn(…)`, the detail in `detail`, in a `SidebarDetail` for the inset card. The
/// head field is the system's sidebar search (`.searchable(text:placement: .sidebar,…)` on this view), or the client's
/// own field in `sidebarColumn(field:…)`.
public struct SidebarSplitView<Sidebar: View, Detail: View>: View {
    private let columnVisibility: Binding<NavigationSplitViewVisibility>?
    private let sidebar: Sidebar
    private let detail: Detail

    /// `columnVisibility` lets the app show or hide the sidebar itself; without it the system's toggle owns it.
    public init(
        columnVisibility: Binding<NavigationSplitViewVisibility>? = nil, @ViewBuilder sidebar: () -> Sidebar,
        @ViewBuilder detail: () -> Detail
    ) {
        self.columnVisibility = columnVisibility
        self.sidebar = sidebar()
        self.detail = detail()
    }

    public var body: some View {
        Group {
            if let columnVisibility {
                NavigationSplitView(columnVisibility: columnVisibility) { sidebar } detail: { detail }
            } else {
                NavigationSplitView { sidebar } detail: { detail }
            }
        }
        .sidebarWindowChrome()
        .background { WindowBackground().ignoresSafeArea(.all) }
    }
}

extension View {
    /// The window of a sidebar app on the Mac: the toolbar lets the gradient through, has no title (the window keeps
    /// one for VoiceOver and the Window menu), and in full screen slides away until the pointer reaches the top of the
    /// screen, so the gradient and the content run to the top. Nothing on iOS.
    public func sidebarWindowChrome() -> some View {
        #if os(macOS)
        toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
            .windowToolbarFullScreenVisibility(.onHover)
            .toolbar(removing: .title)
        #else
        self
        #endif
    }
}

#if os(macOS)
extension NSSplitViewItem {
    /// The system sidebar item for an AppKit window: `NSSplitViewItem(sidebarWithViewController:)` hosting `column` (a
    /// `List` with `sidebarColumn(field:header:bottomBar:)`), between `Size.columnMin` and `columnMax`, `columnIdeal`
    /// wide at first. The window is `.fullSizeContentView` with a transparent title bar and no title shown, its toolbar
    /// holds `sidebarToolbarItems` (`.iconOnly`), and a `WindowBackground` lies under the split view, as
    /// `SidebarSplitView` sets them in SwiftUI.
    @MainActor
    public static func sidebar(hosting column: some View, tokens: DesignTokens = .standard) -> NSSplitViewItem {
        let controller = NSHostingController(rootView: column.designTokens(tokens))
        controller.sizingOptions = []
        controller.view.frame.size.width = tokens.size.columnIdeal
        let item = NSSplitViewItem(sidebarWithViewController: controller)
        item.minimumThickness = tokens.size.columnMin
        item.maximumThickness = tokens.size.columnMax
        return item
    }

    /// The toolbar of a window with a kit sidebar: the system's sidebar button at the column's trailing edge, where
    /// `NavigationSplitView` puts it, and the separator that follows the column's width.
    public static let sidebarToolbarItems: [NSToolbarItem.Identifier] = [.flexibleSpace, .toggleSidebar, .sidebarTrackingSeparator]
}
#endif

// MARK: Column

extension View {
    /// The sidebar column around its `List`: the kit's column widths (`Size.columnMin`, `columnIdeal`, `columnMax`), a
    /// plain list on the gradient (no content background, no section separators, no system selection platter: the
    /// cells' `ListRowBackground` is the selection), and `bottomBar` pinned to the column's bottom edge in a
    /// `safeAreaBar`, the `SpaceRail` for instance. The list scrolls under the bar, and fades out under it before the
    /// window's edge.
    public func sidebarColumn<BottomBar: View>(@ViewBuilder bottomBar: () -> BottomBar) -> some View {
        modifier(SidebarColumn(field: EmptyView(), header: EmptyView(), bottomBar: bottomBar()))
    }

    /// The sidebar column with a header row under the head field (`Spacing.statusLineToList` above the list), a
    /// `StatusLine` for instance.
    public func sidebarColumn<Header: View, BottomBar: View>(
        @ViewBuilder header: () -> Header, @ViewBuilder bottomBar: () -> BottomBar
    ) -> some View {
        modifier(SidebarColumn(field: EmptyView(), header: header(), bottomBar: bottomBar()))
    }

    /// The sidebar column with the client's own head field (an address field, say) where the system's sidebar search
    /// would sit, at the top of the column under the window's controls, then the header.
    public func sidebarColumn<Field: View, Header: View, BottomBar: View>(
        @ViewBuilder field: () -> Field, @ViewBuilder header: () -> Header, @ViewBuilder bottomBar: () -> BottomBar
    ) -> some View {
        modifier(SidebarColumn(field: field(), header: header(), bottomBar: bottomBar()))
    }

    /// A sidebar `List` cell drawn like a `ListRow`: `ListRowBackground(state:placement:)` behind it, no separator, and
    /// insets that keep the `List`'s own margin (`Spacing.listCellMargin`). The background sits where a `ListRow`'s
    /// does; the content (a tile, the text, a trailing accessory, with no padding of its own) sits `listCellMargin`
    /// further in on both sides, `listCellMargin + rowInsetHorizontal` from the background's edge. Use it in a
    /// `sidebarColumn`; elsewhere `listRowCell(state:placement:)`.
    public func sidebarRowCell(state: RowState = RowState(), placement: RowPlacement = .free(firstInSection: false)) -> some View {
        modifier(SidebarRowCell(state: state, placement: placement))
    }
}

private struct SidebarColumn<Field: View, Header: View, BottomBar: View>: ViewModifier {
    @Environment(\.designTokens) private var tokens
    let field: Field
    let header: Header
    let bottomBar: BottomBar
    @State private var barHeight: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .listStyle(.plain)
            .listSectionSeparator(.hidden)
            .scrollContentBackground(.hidden)
            .mask { BarFade(barHeight: barHeight, fade: tokens.spacing.barFade).ignoresSafeArea(.all, edges: .bottom) }
            #if os(macOS)
            .background(ListSelectionPlatterOff())
            #endif
            .safeAreaBar(edge: .top, spacing: Header.self == EmptyView.self ? 0 : tokens.spacing.statusLineToList) {
                VStack(spacing: 0) {
                    if Field.self != EmptyView.self {
                        field
                            .frame(minHeight: tokens.size.sidebarField)
                            .padding(.horizontal, tokens.spacing.sidebarFieldSide)
                            .padding(.top, tokens.spacing.sidebarFieldTop)
                            .padding(.bottom, tokens.spacing.sidebarFieldBottom)
                    }
                    if Header.self != EmptyView.self { header }
                }
            }
            .safeAreaBar(edge: .bottom, spacing: 0) {
                bottomBar.onGeometryChange(for: CGFloat.self) { $0.size.height } action: { barHeight = $0 }
            }
            .navigationSplitViewColumnWidth(min: tokens.size.columnMin, ideal: tokens.size.columnIdeal, max: tokens.size.columnMax)
            #if os(macOS)
            .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
            #endif
    }
}

/// What the list shows of itself: all of it above the bottom bar, then a fade over the bar's first `fade` points, then
/// nothing down to the window's edge. Without it a row under the bar shows below the bar's controls, against the edge.
private struct BarFade: View {
    let barHeight: CGFloat
    let fade: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
            LinearGradient(colors: [.black, .clear], startPoint: .top, endPoint: .bottom)
                .frame(height: min(fade, barHeight))
            Color.clear.frame(height: max(0, barHeight - fade))
        }
    }
}

private struct SidebarRowCell: ViewModifier {
    @Environment(\.designTokens) private var tokens
    let state: RowState
    let placement: RowPlacement

    func body(content: Content) -> some View {
        let spacing = tokens.spacing
        let vertical = spacing.rowInsetVertical + spacing.textLines
        let side = placement.sideInset(spacing) + spacing.rowInsetHorizontal
        content
            .listRowInsets(EdgeInsets(
                top: placement.topInset(spacing) + vertical, leading: side + placement.indent(spacing),
                bottom: spacing.rowGap / 2 + vertical, trailing: side))
            .listRowSeparator(.hidden)
            .listRowBackground(ListRowBackground(state: state, placement: placement))
    }
}

#if os(macOS)
/// Turns off the selection platter AppKit draws behind a selected `List` row (the `NSTableView` under the list), so the
/// cell's `ListRowBackground` is the only selection shown. SwiftUI has no API for it on macOS. Without a table found
/// nothing changes and the platter stays.
private struct ListSelectionPlatterOff: NSViewRepresentable {
    private static let attempts = 10
    private static let retryDelay = 0.05

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.setAccessibilityElement(false)
        // The list's table does not exist yet when this view is made: look again over the next turns.
        Self.retry(from: view, attempts: Self.attempts)
        return view
    }

    func updateNSView(_ view: NSView, context: Context) {
        _ = Self.apply(from: view)
    }

    @MainActor
    private static func retry(from view: NSView, attempts: Int) {
        DispatchQueue.main.asyncAfter(deadline: .now() + (attempts == Self.attempts ? 0 : retryDelay)) { [weak view] in
            guard let view, view.window != nil || attempts > 1 else { return }
            if apply(from: view) || attempts <= 1 { return }
            retry(from: view, attempts: attempts - 1)
        }
    }

    @MainActor
    private static func apply(from view: NSView) -> Bool {
        guard let table = nearestTable(from: view) else { return false }
        if table.selectionHighlightStyle != .none { table.selectionHighlightStyle = .none }
        return true
    }

    /// This view is a sibling of the list in a hosting view: up from it, the first scroll view whose document is a table.
    @MainActor
    private static func nearestTable(from view: NSView) -> NSTableView? {
        var current: NSView? = view
        while let node = current {
            if let table = firstTable(in: node) { return table }
            current = node.superview
        }
        return nil
    }

    @MainActor
    private static func firstTable(in view: NSView) -> NSTableView? {
        if let scroll = view as? NSScrollView, let table = scroll.documentView as? NSTableView { return table }
        for sub in view.subviews { if let table = firstTable(in: sub) { return table } }
        return nil
    }
}
#endif

// MARK: Detail

/// The detail beside a sidebar: the content in a card on the plain background, inset `Spacing.canvasInset` from the
/// column's edges and from the window's top edge on the Mac (under its transparent toolbar), rounded `Radius.canvas`,
/// with a 1 pt `.separator` line centred on its edge. `bottomBar` floats over the card's bottom, `Spacing.pillFloat`
/// from its edges: the detail's actions on glass, say.
public struct SidebarDetail<Content: View, BottomBar: View>: View {
    @Environment(\.designTokens) private var tokens
    private let content: Content
    private let bottomBar: BottomBar

    public init(@ViewBuilder content: () -> Content, @ViewBuilder bottomBar: () -> BottomBar = { EmptyView() }) {
        self.content = content()
        self.bottomBar = bottomBar()
    }

    public var body: some View {
        let shape = RoundedRectangle(cornerRadius: tokens.radius.canvas, style: .continuous)
        content
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.background, in: shape)
            .clipShape(shape)
            .overlay { shape.stroke(.separator, lineWidth: tokens.size.stroke).accessibilityHidden(true) }
            .overlay(alignment: .bottom) {
                bottomBar
                    .padding(.horizontal, tokens.spacing.pillFloat)
                    .padding(.bottom, tokens.spacing.pillFloat)
            }
            .padding(tokens.spacing.canvasInset)
            #if os(macOS)
            .ignoresSafeArea(.container, edges: .top)
            .toolbarBackgroundVisibility(.hidden, for: .windowToolbar)
            #endif
    }
}
