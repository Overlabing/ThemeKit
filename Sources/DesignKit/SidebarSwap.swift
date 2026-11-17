import SwiftUI

// A sidebar swap, as Zen opens its settings and its library: the column's content gives way to a list of sections,
// grouped under headings, with a back arrow at the bottom left, and the detail shows the chosen section instead of the
// app's content. The app's content stays where it is, alive, under the section; the back arrow, Escape, or the
// command that opened the swap brings it back as it was.

// MARK: Model

/// One section of a sidebar swap: its row in the column (symbol and title) and its pane's head (title and subtitle).
public struct SidebarSwapSection<ID: Hashable & Sendable>: Identifiable, Hashable, Sendable {
    public let id: ID
    public var title: String
    public var subtitle: String?
    public var systemImage: String

    public init(_ id: ID, title: String, subtitle: String? = nil, systemImage: String) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.systemImage = systemImage
    }
}

/// Sections under one heading of the column, "This Profile" say.
public struct SidebarSwapGroup<ID: Hashable & Sendable>: Identifiable, Hashable, Sendable {
    public let id: String
    public var title: String
    public var sections: [SidebarSwapSection<ID>]

    public init(id: String, title: String, sections: [SidebarSwapSection<ID>]) {
        self.id = id
        self.title = title
        self.sections = sections
    }
}

/// The state of one window's sidebar swap: whether it is shown, its groups, and the section shown. One per window: a
/// swap shown in one window leaves the others as they are.
@MainActor
@Observable
public final class SidebarSwapModel<ID: Hashable & Sendable> {
    /// The groups in the column's order. Never empty, and no group is empty.
    public private(set) var groups: [SidebarSwapGroup<ID>]
    public private(set) var isPresented = false
    /// The section the detail shows, and the selected row. It stays when the swap goes, so it opens there again.
    public private(set) var selection: ID
    /// Called after the selection changes, with the new one: where an app stores the last section.
    @ObservationIgnored public var onSelect: ((ID) -> Void)?

    /// `selection` is the section to start on, the one stored last say; the first section when it is nil or not listed.
    public init(groups: [SidebarSwapGroup<ID>], selection: ID? = nil) {
        let listed = groups.filter { !$0.sections.isEmpty }
        precondition(!listed.isEmpty, "A sidebar swap needs a section")
        self.groups = listed
        let sections = listed.flatMap(\.sections)
        self.selection = selection.flatMap { id in sections.contains { $0.id == id } ? id : nil } ?? sections[0].id
    }

    /// Every section, in the column's order.
    public var sections: [SidebarSwapSection<ID>] { groups.flatMap(\.sections) }

    /// The section shown.
    public var current: SidebarSwapSection<ID> {
        sections.first { $0.id == selection } ?? sections[0]
    }

    /// The group holding a section.
    public func group(of id: ID) -> SidebarSwapGroup<ID>? {
        groups.first { $0.sections.contains { $0.id == id } }
    }

    /// Shows `id`, if the column lists it. False when it does not.
    @discardableResult
    public func select(_ id: ID) -> Bool {
        guard sections.contains(where: { $0.id == id }) else { return false }
        guard id != selection else { return true }
        selection = id
        onSelect?(id)
        return true
    }

    /// The section `offset` rows away in the column, across its groups: an arrow key. False at either end.
    @discardableResult
    public func selectAdjacent(_ offset: Int) -> Bool {
        let all = sections
        guard let index = all.firstIndex(where: { $0.id == selection }), all.indices.contains(index + offset) else {
            return false
        }
        return select(all[index + offset].id)
    }

    /// Shows the swap on `id`, or on the section shown last when it is nil or not listed.
    public func present(_ id: ID? = nil) {
        if let id { select(id) }
        isPresented = true
    }

    /// Gives the column and the detail back to the app's content.
    public func dismiss() {
        isPresented = false
    }

    /// What the command that opens the swap does: shown on `id` (or shown at all, when `id` is nil), it returns; otherwise
    /// it shows the swap on `id`. Returns `isPresented` after it.
    @discardableResult
    public func toggle(_ id: ID? = nil) -> Bool {
        if isPresented, id == nil || id == selection {
            dismiss()
        } else {
            present(id)
        }
        return isPresented
    }

    /// New groups, a window that lists fewer sections say. The selection stays if it is still listed, else it is the
    /// first section; `onSelect` is not called for that, since the user chose nothing.
    public func setGroups(_ groups: [SidebarSwapGroup<ID>]) {
        let listed = groups.filter { !$0.sections.isEmpty }
        precondition(!listed.isEmpty, "A sidebar swap needs a section")
        guard listed != self.groups else { return }
        self.groups = listed
        if !listed.flatMap(\.sections).contains(where: { $0.id == selection }) {
            selection = listed[0].sections[0].id
        }
    }
}

// MARK: Column

extension View {
    /// The column of a window with a sidebar swap: this view (the app's own column) while the swap is not shown, `swap`
    /// (a `SidebarSwapList`) while it is.
    public func sidebarSwap<ID: Hashable & Sendable, Swap: View>(
        _ model: SidebarSwapModel<ID>, @ViewBuilder swap: () -> Swap
    ) -> some View {
        modifier(SidebarSwapColumn(model: model, swap: swap()))
    }
}

private struct SidebarSwapColumn<ID: Hashable & Sendable, Swap: View>: ViewModifier {
    let model: SidebarSwapModel<ID>
    let swap: Swap

    func body(content: Content) -> some View {
        if model.isPresented { swap } else { content }
    }
}

/// The column of a sidebar swap: `title` at the top, the app's `header` under it (a menu naming what the sections
/// apply to, say), then the sections under their groups' headings, and the back arrow at the bottom left. A plain
/// `List` in the kit's column (`sidebarColumn`), its rows `sidebarRowCell`s. Clicking a row or moving with the arrow
/// keys shows its section; Escape or the back arrow returns. For VoiceOver it is a list whose groups have headings, the
/// shown section selected.
///
/// On the Mac the column keeps the kit's sidebar head with its sidebar button, and `titleBar` takes its trailing slot
/// (`EmptyView()` for none): pass the `sidebarButtonShortcut` the app's own column passes.
public struct SidebarSwapList<ID: Hashable & Sendable, TitleBar: View, Header: View>: View {
    @Environment(\.designTokens) private var tokens
    private let model: SidebarSwapModel<ID>
    private let title: String
    private let sidebarButtonShortcut: String?
    private let titleBar: TitleBar
    private let header: Header

    public init(
        _ model: SidebarSwapModel<ID>, title: String, sidebarButtonShortcut: String? = nil,
        @ViewBuilder titleBar: () -> TitleBar, @ViewBuilder header: () -> Header
    ) {
        self.model = model
        self.title = title
        self.sidebarButtonShortcut = sidebarButtonShortcut
        self.titleBar = titleBar()
        self.header = header()
    }

    public var body: some View {
        let selection = Binding<ID?>(get: { model.selection }, set: { if let id = $0 { model.select(id) } })
        list(selection: selection)
            .onExitCommand { model.dismiss() }
    }

    private func list(selection: Binding<ID?>) -> some View {
        List(selection: selection) {
            ForEach(model.groups) { group in
                // A row with the header trait, not a `Section` header: a plain list pins its section headers on a band of
                // their own over the gradient.
                SidebarSwapGroupHeader(title: group.title)
                ForEach(group.sections) { section in
                    SidebarSwapRow(section: section, isSelected: section.id == model.selection)
                        .tag(section.id)
                }
            }
        }
        // On the list alone: on the column it would rename the head's and the bottom bar's buttons too.
        .accessibilityLabel(title)
        .modifier(SidebarSwapListColumn(
            title: title, sidebarButtonShortcut: sidebarButtonShortcut, titleBar: titleBar, header: header,
            back: SidebarSwapBackButton(model: model)))
    }
}

private struct SidebarSwapListColumn<TitleBar: View, Header: View, Back: View>: ViewModifier {
    @Environment(\.designTokens) private var tokens
    let title: String
    let sidebarButtonShortcut: String?
    let titleBar: TitleBar
    let header: Header
    let back: Back

    func body(content: Content) -> some View {
        #if os(macOS)
        content.sidebarColumn(sidebarButtonShortcut: sidebarButtonShortcut) {
            titleBar
        } field: {
            EmptyView()
        } fieldAccessory: {
            EmptyView()
        } header: {
            head
        } bottomBar: {
            back
        }
        #else
        content.sidebarColumn { head } bottomBar: { back }
        #endif
    }

    private var head: some View {
        VStack(alignment: .leading, spacing: tokens.spacing.swapTitleToHeader) {
            Text(title)
                .role(tokens.type.swapTitle)
                .accessibilityAddTraits(.isHeader)
            if Header.self != EmptyView.self { header }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, tokens.spacing.listMargin)
    }
}

/// A group's heading in the column: small uppercase, on the rows' text, a heading for VoiceOver, never selected.
private struct SidebarSwapGroupHeader: View {
    @Environment(\.designTokens) private var tokens
    let title: String

    var body: some View {
        let spacing = tokens.spacing
        WithColorRoles { roles in
            Text(title)
                .role(tokens.type.groupHeader)
                .tracking(spacing.headerTracking)
                .foregroundStyle(roles.secondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityAddTraits(.isHeader)
        }
        .listRowInsets(EdgeInsets(
            top: spacing.sectionHeaderBottom * 2, leading: spacing.rowInsetHorizontal + spacing.listCellMargin,
            bottom: spacing.sectionHeaderBottom, trailing: spacing.rowInsetHorizontal))
        .listRowSeparator(.hidden)
        .listRowBackground(Color.clear)
        .selectionDisabled()
    }
}

/// A section's row: its symbol on a tinted tile, its title.
private struct SidebarSwapRow<ID: Hashable & Sendable>: View {
    @Environment(\.designTokens) private var tokens
    let section: SidebarSwapSection<ID>
    let isSelected: Bool

    var body: some View {
        HStack(spacing: tokens.spacing.compactTileToText) {
            Tile(.tintedSymbol(section.systemImage), size: .small)
            Text(section.title)
                .role(isSelected ? tokens.type.rowTitleEmphasized : tokens.type.rowTitle)
                .lineLimit(1)
            Spacer(minLength: 0)
        }
        .contentShape(.rect)
        .accessibilityElement(children: .combine)
        .sidebarRowCell(state: RowState(isSelected: isSelected), hoverID: AnyHashable(section.id))
    }
}

/// The back arrow at the bottom left of the column: it gives the column and the detail back to the app's content.
private struct SidebarSwapBackButton<ID: Hashable & Sendable>: View {
    @Environment(\.designTokens) private var tokens
    let model: SidebarSwapModel<ID>

    var body: some View {
        let title = String(localized: "Back", table: "DesignKit", bundle: .module,
                           comment: "The back arrow at the bottom of a sidebar showing settings or a library: its VoiceOver label.")
        let help = String(localized: "Back (Esc)", table: "DesignKit", bundle: .module,
                          comment: "Help tag of the back arrow at the bottom of a sidebar showing settings or a library: its title and its key.")
        IconButtonRow {
            IconButton(title, systemImage: "arrow.left", help: help) { model.dismiss() }
        } trailing: {
            EmptyView()
        }
        .font(tokens.type.sidebarHeadSymbol.font)
        .padding(.bottom, tokens.spacing.switcherBottom)
    }
}

// MARK: Detail

/// A section's pane in the detail: its title and subtitle, then `content`, from the top, `Spacing.swapPaneMargin` in
/// from the card's edges and at most `Size.swapPaneWidth` wide. Escape in it returns, as the back arrow does, unless a
/// view inside it takes Escape itself. VoiceOver reaches it as one container named after the section.
public struct SidebarSwapPane<Content: View>: View {
    @Environment(\.designTokens) private var tokens
    private let title: String
    private let subtitle: String?
    private let onExit: (() -> Void)?
    private let content: Content

    public init(title: String, subtitle: String? = nil, onExit: (() -> Void)? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.onExit = onExit
        self.content = content()
    }

    /// The pane of `model`'s section, Escape returning.
    public init<ID: Hashable & Sendable>(_ model: SidebarSwapModel<ID>, @ViewBuilder content: () -> Content) {
        self.init(title: model.current.title, subtitle: model.current.subtitle, onExit: { model.dismiss() },
                  content: content)
    }

    public var body: some View {
        let margin = tokens.spacing.swapPaneMargin
        WithColorRoles { roles in
            VStack(alignment: .leading, spacing: tokens.spacing.swapPaneHeadToContent) {
                VStack(alignment: .leading, spacing: tokens.spacing.textLines) {
                    Text(title)
                        .role(tokens.type.swapPaneTitle)
                        .accessibilityAddTraits(.isHeader)
                    if let subtitle {
                        Text(subtitle)
                            .role(tokens.type.swapPaneSubtitle)
                            .foregroundStyle(roles.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.horizontal, margin)
                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .padding(.top, margin)
            .frame(maxWidth: tokens.size.swapPaneWidth, maxHeight: .infinity, alignment: .topLeading)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .accessibilityElement(children: .contain)
            .accessibilityLabel(title)
            .modifier(ExitCommand(action: onExit))
        }
    }
}

private struct ExitCommand: ViewModifier {
    let action: (() -> Void)?

    func body(content: Content) -> some View {
        #if os(macOS)
        if let action { content.onExitCommand(perform: action) } else { content }
        #else
        content
        #endif
    }
}

/// The detail of a window with a sidebar swap, in SwiftUI: `content` (the app's detail) while the swap is not shown;
/// while it is, `pane` for the shown section in a `SidebarSwapPane`, over `content`, which stays alive, hidden, out of
/// VoiceOver and the hit test, so it comes back as it was. An AppKit window does the same with its own views: it hides
/// its content view (removing it would reload a web view) and shows a `SidebarSwapPane` in a hosting view over it.
public struct SidebarSwapDetail<ID: Hashable & Sendable, Content: View, Pane: View>: View {
    private let model: SidebarSwapModel<ID>
    private let content: Content
    private let pane: (SidebarSwapSection<ID>) -> Pane

    public init(
        _ model: SidebarSwapModel<ID>, @ViewBuilder content: () -> Content,
        @ViewBuilder pane: @escaping (SidebarSwapSection<ID>) -> Pane
    ) {
        self.model = model
        self.content = content()
        self.pane = pane
    }

    public var body: some View {
        let isPresented = model.isPresented
        ZStack {
            content
                .opacity(isPresented ? 0 : 1)
                .allowsHitTesting(!isPresented)
                .accessibilityHidden(isPresented)
            if isPresented {
                SidebarSwapPane(model) { pane(model.current) }
                    .id(model.selection)
            }
        }
    }
}
