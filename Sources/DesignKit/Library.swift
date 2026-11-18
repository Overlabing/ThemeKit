import SwiftUI

// The Library, as Zen draws it: the window's sidebar gives way to a rail of items (History, Downloads, Settings…), the
// chosen item's content is drawn on the window's own chrome, with no card, and the page's card is pushed toward the
// trailing edge, a strip of it still in sight. The page is never rebuilt: it moves aside and comes back as it was.

// MARK: Model

/// One item of the Library's rail: its symbol and its caption.
public struct LibraryItem<ID: Hashable & Sendable>: Identifiable, Hashable, Sendable {
    public let id: ID
    public var title: String
    public var systemImage: String

    public init(_ id: ID, title: String, systemImage: String) {
        self.id = id
        self.title = title
        self.systemImage = systemImage
    }
}

/// The state of one window's Library: whether it is open, its items, and the item shown. One per window.
@MainActor
@Observable
public final class LibraryModel<ID: Hashable & Sendable> {
    /// The rail's items, in order. Never empty.
    public private(set) var items: [LibraryItem<ID>]
    public private(set) var isPresented = false
    /// The item shown, and the selected one in the rail. It stays when the Library closes, so it opens there again.
    public private(set) var selection: ID
    /// Called after the selection changes, with the new one: where an app stores the last item.
    @ObservationIgnored public var onSelect: ((ID) -> Void)?

    /// `selection` is the item to start on, the one stored last say; the first item when it is nil or not listed.
    public init(items: [LibraryItem<ID>], selection: ID? = nil) {
        precondition(!items.isEmpty, "A Library needs an item")
        self.items = items
        self.selection = selection.flatMap { id in items.contains { $0.id == id } ? id : nil } ?? items[0].id
    }

    /// The item shown.
    public var current: LibraryItem<ID> {
        items.first { $0.id == selection } ?? items[0]
    }

    /// Shows `id`, if the rail lists it. False when it does not.
    @discardableResult
    public func select(_ id: ID) -> Bool {
        guard items.contains(where: { $0.id == id }) else { return false }
        guard id != selection else { return true }
        selection = id
        onSelect?(id)
        return true
    }

    /// The item `offset` places away in the rail: an arrow key. False at either end.
    @discardableResult
    public func selectAdjacent(_ offset: Int) -> Bool {
        guard let index = items.firstIndex(where: { $0.id == selection }), items.indices.contains(index + offset) else {
            return false
        }
        return select(items[index + offset].id)
    }

    /// Opens the Library on `id`, or on the item shown last when it is nil or not listed.
    public func present(_ id: ID? = nil) {
        if let id { select(id) }
        isPresented = true
    }

    /// Gives the window back to its sidebar and its page.
    public func dismiss() {
        isPresented = false
    }

    /// What a command that opens the Library does: open on `id` (or open at all, when `id` is nil), it closes;
    /// otherwise it opens on `id`. Returns `isPresented` after it.
    @discardableResult
    public func toggle(_ id: ID? = nil) -> Bool {
        if isPresented, id == nil || id == selection {
            dismiss()
        } else {
            present(id)
        }
        return isPresented
    }

    /// New items, a window that lists fewer say. The selection stays if it is still listed, else it is the first item;
    /// `onSelect` is not called for that, since the user chose nothing.
    public func setItems(_ items: [LibraryItem<ID>]) {
        precondition(!items.isEmpty, "A Library needs an item")
        guard items != self.items else { return }
        self.items = items
        if !items.contains(where: { $0.id == selection }) { selection = items[0].id }
    }
}

// MARK: Push

/// Where the Library's views stand at `progress`, from 0 (closed) to 1 (open), as Zen moves them: the Library slides in
/// from the leading edge; the page's card moves toward the trailing edge by the Library's width less the sidebar's,
/// keeping its size, so `Size.libraryPeek` of it stays in sight; the sidebar fades and shrinks a little over the first
/// third of the way. An AppKit window applies these to its own views; `LibraryLayout` does it in SwiftUI.
public struct LibraryPush: Equatable, Sendable {
    /// The Library's width: the window's, less the strip of page left in sight.
    public let libraryWidth: CGFloat
    public let sidebarWidth: CGFloat

    public init(windowWidth: CGFloat, sidebarWidth: CGFloat, tokens: DesignTokens = .standard) {
        libraryWidth = max(tokens.size.libraryRail, windowWidth - tokens.size.libraryPeek)
        self.sidebarWidth = sidebarWidth
    }

    /// How far the page's card has moved toward the trailing edge.
    public func detailOffset(_ progress: CGFloat) -> CGFloat {
        clamp(progress) * max(0, libraryWidth - sidebarWidth)
    }

    /// How far the Library sits from its place, toward the leading edge (negative).
    public func libraryOffset(_ progress: CGFloat) -> CGFloat {
        -(1 - clamp(progress)) * libraryWidth
    }

    /// The sidebar's opacity: gone a third of the way in.
    public func sidebarOpacity(_ progress: CGFloat) -> CGFloat {
        1 - min(1, clamp(progress) * 3)
    }

    /// The sidebar's scale: 96 % once it is gone.
    public func sidebarScale(_ progress: CGFloat) -> CGFloat {
        1 - min(1, clamp(progress) * 3) * 0.04
    }

    private func clamp(_ progress: CGFloat) -> CGFloat { min(1, max(0, progress)) }

    /// The motion of the push and of its return: a spring with Zen's stiffness 720, damping 47 and mass 1.2 (about a
    /// third of a second, a hint of overshoot). With Reduce Motion the views stay in place and cross-fade instead.
    public static func animation(reduceMotion: Bool) -> Animation {
        reduceMotion ? .easeInOut(duration: MotionDuration.quick.rawValue)
            : .interpolatingSpring(mass: 1.2, stiffness: 720, damping: 47)
    }

    /// The same motion for Core Animation: its settling time and a curve close to the spring's.
    public static let duration: TimeInterval = 0.38
    public static let timingControlPoints: (Float, Float, Float, Float) = (0.36, 0.06, 0, 0.94)
}

// MARK: Rail

/// The Library's rail, on the window's chrome: below the window's buttons, its items as a symbol over a caption, the
/// shown one filled in the Theme's colour, then the back arrow (←) at the bottom, with `bottom` (more buttons) after
/// it. Up and Down move between the items; Escape and ← close the Library. For VoiceOver the rail is a group named
/// `title` whose items are buttons, the shown one selected.
public struct LibraryRail<ID: Hashable & Sendable, Bottom: View>: View {
    @Environment(\.designTokens) private var tokens
    private let model: LibraryModel<ID>
    private let title: String
    private let bottom: Bottom
    @FocusState private var isFocused: Bool

    public init(_ model: LibraryModel<ID>, title: String, @ViewBuilder bottom: () -> Bottom = { EmptyView() }) {
        self.model = model
        self.title = title
        self.bottom = bottom()
    }

    public var body: some View {
        VStack(spacing: tokens.spacing.libraryRailItemGap) {
            ForEach(model.items) { item in
                LibraryRailButton(item: item, isSelected: item.id == model.selection) { model.select(item.id) }
            }
            Spacer(minLength: 0)
            HStack(spacing: tokens.spacing.sidebarHeadButtonGap) {
                LibraryBackButton(model: model)
                bottom
            }
            .font(tokens.type.sidebarHeadSymbol.font)
            .padding(.bottom, tokens.spacing.switcherBottom)
        }
        .padding(.top, tokens.size.sidebarTitleBar + DesignTokens.Spacing.s)
        .padding(.horizontal, DesignTokens.Spacing.xs)
        .frame(width: tokens.size.libraryRail)
        .frame(maxHeight: .infinity)
        .focusable()
        .focused($isFocused)
        .focusEffectDisabled()
        .onKeyPress(.upArrow) { model.selectAdjacent(-1) ? .handled : .ignored }
        .onKeyPress(.downArrow) { model.selectAdjacent(1) ? .handled : .ignored }
        .modifier(LibraryExitCommand(action: { model.dismiss() }))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(title)
    }
}

/// An item of the rail: its symbol over its caption, filled in the Theme's colour while shown.
private struct LibraryRailButton<ID: Hashable & Sendable>: View {
    @Environment(\.designTokens) private var tokens
    let item: LibraryItem<ID>
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        WithColorRoles { roles in
            Button(action: action) {
                VStack(spacing: DesignTokens.Spacing.xxs) {
                    Image(systemName: item.systemImage)
                        .font(tokens.type.sidebarHeadSymbol.font)
                        .frame(height: tokens.size.pillSymbol)
                    Text(item.title)
                        .role(tokens.type.libraryRailCaption)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .foregroundStyle(isSelected ? AnyShapeStyle(roles.tintText) : AnyShapeStyle(roles.secondaryText))
                .frame(maxWidth: .infinity, minHeight: tokens.size.libraryRailItem)
                .background {
                    ListRowBackground(state: RowState(isSelected: isSelected), placement: .free(firstInSection: false),
                                      hoverID: AnyHashable(item.id))
                }
                .contentShape(.rect)
            }
            .buttonStyle(PressedOpacityStyle())
            .focusEffectDisabled()
            .help(item.title)
            .accessibilityLabel(item.title)
            .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
        }
    }
}

/// The back arrow at the bottom of the rail: it closes the Library.
private struct LibraryBackButton<ID: Hashable & Sendable>: View {
    let model: LibraryModel<ID>

    var body: some View {
        let title = String(localized: "Back", table: "DesignKit", bundle: .module,
                           comment: "The back arrow at the bottom of the Library's rail: its VoiceOver label.")
        let help = String(localized: "Back (Esc)", table: "DesignKit", bundle: .module,
                          comment: "Help tag of the back arrow at the bottom of the Library's rail: its title and its key.")
        IconButton(title, systemImage: "arrow.left", help: help) { model.dismiss() }
    }
}

// MARK: Pane

/// An item's content in the Library, in the chrome's style: no card, its title and subtitle on the window's own
/// background, then `content`, from the top, `Spacing.libraryPaneMargin` in and at most `Size.libraryPaneWidth` wide.
/// Escape in it closes the Library, unless a view inside takes Escape itself. VoiceOver reaches it as one container
/// named after its title.
public struct LibraryPane<Content: View>: View {
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

    public var body: some View {
        let margin = tokens.spacing.libraryPaneMargin
        WithColorRoles { roles in
            VStack(alignment: .leading, spacing: tokens.spacing.libraryPaneHeadToContent) {
                VStack(alignment: .leading, spacing: tokens.spacing.textLines) {
                    Text(title)
                        .role(tokens.type.libraryPaneTitle)
                        .accessibilityAddTraits(.isHeader)
                    if let subtitle {
                        Text(subtitle)
                            .role(tokens.type.libraryPaneSubtitle)
                            .foregroundStyle(roles.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.horizontal, margin)
                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
            .padding(.top, tokens.size.sidebarTitleBar + DesignTokens.Spacing.s)
            .frame(maxWidth: tokens.size.libraryPaneWidth, maxHeight: .infinity, alignment: .topLeading)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .accessibilityElement(children: .contain)
            .accessibilityLabel(title)
            .modifier(LibraryExitCommand(action: onExit))
        }
    }
}

private struct LibraryExitCommand: ViewModifier {
    let action: (() -> Void)?

    func body(content: Content) -> some View {
        #if os(macOS)
        if let action { content.onExitCommand(perform: action) } else { content }
        #else
        content
        #endif
    }
}

// MARK: SwiftUI layout

/// The Library in a SwiftUI window: `sidebar` and `detail` side by side, and while the Library is open, `library` (a
/// `LibraryRail` beside a `LibraryPane`, on the window's chrome) slides in from the leading edge as the sidebar fades and
/// `detail` moves toward the trailing edge (`LibraryPush`). `sidebar` and `detail` stay alive all along, so a page in
/// `detail` keeps its state. A click on the part of `detail` left in sight closes the Library. With Reduce Motion
/// nothing moves: the Library and the sidebar cross-fade. An AppKit window does the same with its own views.
public struct LibraryLayout<ID: Hashable & Sendable, Sidebar: View, Detail: View, Library: View>: View {
    @Environment(\.designTokens) private var tokens
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let model: LibraryModel<ID>
    private let sidebarWidth: CGFloat
    private let sidebar: Sidebar
    private let detail: Detail
    private let library: Library

    public init(
        _ model: LibraryModel<ID>, sidebarWidth: CGFloat, @ViewBuilder sidebar: () -> Sidebar,
        @ViewBuilder detail: () -> Detail, @ViewBuilder library: () -> Library
    ) {
        self.model = model
        self.sidebarWidth = sidebarWidth
        self.sidebar = sidebar()
        self.detail = detail()
        self.library = library()
    }

    public var body: some View {
        let progress: CGFloat = model.isPresented ? 1 : 0
        GeometryReader { geometry in
            let push = LibraryPush(windowWidth: geometry.size.width, sidebarWidth: sidebarWidth, tokens: tokens)
            ZStack(alignment: .leading) {
                HStack(spacing: 0) {
                    sidebar
                        .frame(width: sidebarWidth)
                        .opacity(push.sidebarOpacity(progress))
                        .scaleEffect(reduceMotion ? 1 : push.sidebarScale(progress))
                        .allowsHitTesting(!model.isPresented)
                        .accessibilityHidden(model.isPresented)
                    detail
                        .overlay {
                            if model.isPresented {
                                Color.clear
                                    .contentShape(.rect)
                                    .onTapGesture { model.dismiss() }
                                    .accessibilityElement()
                                    .accessibilityLabel(String(localized: "Back", table: "DesignKit", bundle: .module,
                                                               comment: "The back arrow at the bottom of the Library's rail: its VoiceOver label."))
                                    .accessibilityAddTraits(.isButton)
                            }
                        }
                        .offset(x: reduceMotion ? 0 : push.detailOffset(progress))
                }
                if model.isPresented {
                    library
                        .frame(width: push.libraryWidth)
                        .transition(reduceMotion ? .opacity : .move(edge: .leading))
                }
            }
            .clipped()
            .animation(LibraryPush.animation(reduceMotion: reduceMotion), value: model.isPresented)
        }
    }
}
