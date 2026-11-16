#if os(macOS)
import AppKit
import SwiftUI

// The head of `sidebarColumn(sidebarButtonShortcut:titleBar:field:fieldAccessory:header:bottomBar:)`, as in Zen: a row
// on the line of the window's buttons with the sidebar button and the app's buttons, then a field pill the column's
// width with the app's accessory inside it.

/// The title bar row and the field pill, at the top of the column's top bar.
struct SidebarHead<TitleBar: View, Field: View, Accessory: View>: View {
    @Environment(\.designTokens) private var tokens
    let sidebarButtonShortcut: String?
    let titleBar: TitleBar
    let field: Field
    let accessory: Accessory
    @State private var metrics = SidebarTitleBarMetrics()
    @State private var anchor = SidebarHeadAnchor()

    var body: some View {
        let layout = SidebarTitleBarLayout(metrics: metrics, tokens: tokens)
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                SidebarButton(shortcut: sidebarButtonShortcut, anchor: anchor)
                Spacer(minLength: tokens.spacing.pillActionGap)
                HStack(spacing: tokens.spacing.sidebarHeadButtonGap) { titleBar }
            }
            .font(tokens.type.sidebarHeadSymbol.font)
            .padding(.leading, layout.leading)
            .padding(.trailing, tokens.spacing.sidebarFieldSide)
            .frame(height: layout.rowHeight)
            .background {
                ZStack {
                    TitleBarDragArea()
                    TitleBarProbe(anchor: anchor) { metrics = $0 }
                }
            }
            // The column's top bar starts under the window's title bar band: the row goes up into it.
            .padding(.top, -layout.band)
            if Field.self != EmptyView.self {
                SidebarFieldPill(field: field, accessory: accessory)
                    .padding(.horizontal, tokens.spacing.sidebarFieldSide)
                    .padding(.top, tokens.spacing.sidebarFieldPillTop)
                    .padding(.bottom, tokens.spacing.sidebarFieldBottom)
            }
        }
    }
}

/// Where the window's title bar lies over the column: the height of its band (0 when the column starts at the window's
/// top edge, in full screen say), and the trailing edge of the window's buttons in the column, when they sit in that
/// band.
struct SidebarTitleBarMetrics: Equatable, Sendable {
    var band: CGFloat = 0
    var windowButtonsEnd: CGFloat?
}

/// The title bar row's height and leading inset: the band, or `Size.sidebarTitleBar` where there is none; past the
/// window's buttons by `sidebarWindowButtonsGap`, or `sidebarFieldSide` from the column's edge with no buttons in the row.
struct SidebarTitleBarLayout: Equatable {
    let band: CGFloat
    let rowHeight: CGFloat
    let leading: CGFloat

    init(metrics: SidebarTitleBarMetrics, tokens: DesignTokens) {
        band = metrics.band
        rowHeight = metrics.band > 0 ? metrics.band : tokens.size.sidebarTitleBar
        leading = metrics.windowButtonsEnd.map { $0 + tokens.spacing.sidebarWindowButtonsGap }
            ?? tokens.spacing.sidebarFieldSide
    }
}

/// The view the sidebar button acts from: the split view controller holding the column is up its responder chain.
@MainActor
final class SidebarHeadAnchor {
    weak var view: NSView?

    /// `toggleSidebar(_:)` on the nearest split view controller up the chain. Not `tryToPerform`: a split view
    /// controller whose column is not a system sidebar item (`SidebarSurface.windowBackground`) says it does not
    /// respond to it, and the window, further up, takes the action and does nothing.
    func toggleSidebar() {
        var responder: NSResponder? = view
        while let current = responder {
            if let split = current as? NSSplitViewController {
                split.toggleSidebar(view)
                return
            }
            responder = current.nextResponder
        }
        NSApp.sendAction(#selector(NSSplitViewController.toggleSidebar(_:)), to: nil, from: view)
    }
}

/// The kit's sidebar button: `sidebar.left`, its help tag naming the shortcut when there is one.
private struct SidebarButton: View {
    let shortcut: String?
    let anchor: SidebarHeadAnchor

    var body: some View {
        let title = String(localized: "Hide Sidebar", table: "DesignKit", bundle: .module,
                           comment: "The sidebar button at the top of a sidebar: its VoiceOver label and help tag.")
        let help = shortcut.map {
            String(localized: "Hide Sidebar (\($0))", table: "DesignKit", bundle: .module,
                   comment: "Help tag of the sidebar button: its title and its keyboard shortcut, for example ⌘B.")
        } ?? title
        IconButton(title, systemImage: "sidebar.left", help: help) { anchor.toggleSidebar() }
    }
}

/// The field and its accessory in a glass pill the column's width: `Size.sidebarFieldPill` tall, rounded
/// `Radius.sidebarFieldPill`, the field `sidebarFieldPillLeading` from its leading edge, the accessory
/// `sidebarFieldPillTrailing` from its trailing edge.
struct SidebarFieldPill<Field: View, Accessory: View>: View {
    @Environment(\.designTokens) private var tokens
    let field: Field
    let accessory: Accessory

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: tokens.radius.sidebarFieldPill, style: .continuous)
        let hasAccessory = Accessory.self != EmptyView.self
        HStack(spacing: tokens.spacing.pillActionGap) {
            field
                .font(tokens.type.sidebarFieldTitle.font)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            if hasAccessory {
                HStack(spacing: tokens.spacing.sidebarHeadButtonGap) { accessory }
                    .font(tokens.type.sidebarHeadSymbol.font)
            }
        }
        .padding(.leading, tokens.spacing.sidebarFieldPillLeading)
        .padding(.trailing, hasAccessory ? tokens.spacing.sidebarFieldPillTrailing : tokens.spacing.sidebarFieldPillLeading)
        .frame(height: tokens.size.sidebarFieldPill)
        .surface(.glass(tint: 0), in: shape)
    }
}

/// Measures the window's title bar over the column, and anchors the sidebar button's action. It never takes a click.
private struct TitleBarProbe: NSViewRepresentable {
    let anchor: SidebarHeadAnchor
    let report: @MainActor (SidebarTitleBarMetrics) -> Void

    func makeNSView(context: Context) -> TitleBarProbeView {
        let view = TitleBarProbeView()
        update(view)
        return view
    }

    func updateNSView(_ view: TitleBarProbeView, context: Context) {
        update(view)
        view.measure()
    }

    private func update(_ view: TitleBarProbeView) {
        view.report = report
        anchor.view = view
    }
}

final class TitleBarProbeView: NSView {
    var report: (@MainActor (SidebarTitleBarMetrics) -> Void)?
    private var last: SidebarTitleBarMetrics?
    private var layoutObservation: NSKeyValueObservation?
    private var observers: [any NSObjectProtocol] = []

    override init(frame: NSRect) {
        super.init(frame: frame)
        setAccessibilityElement(false)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not used")
    }

    override func hitTest(_ point: NSPoint) -> NSView? { nil }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        observers.forEach(NotificationCenter.default.removeObserver)
        observers = []
        layoutObservation = nil
        guard let window else { return }
        layoutObservation = window.observe(\.contentLayoutRect) { [weak self] _, _ in
            MainActor.assumeIsolated { self?.measure() }
        }
        for name in [NSWindow.didResizeNotification, NSWindow.didEnterFullScreenNotification,
                     NSWindow.didExitFullScreenNotification] {
            observers.append(NotificationCenter.default.addObserver(forName: name, object: window, queue: .main) {
                [weak self] _ in MainActor.assumeIsolated { self?.measure() }
            })
        }
        measure()
    }

    override func layout() {
        super.layout()
        measure()
    }

    func measure() {
        guard let window else { return }
        let metrics = Self.metrics(of: window, in: self)
        guard metrics != last else { return }
        last = metrics
        let report = report
        // Never during SwiftUI's own update: the row's layout depends on what this reports.
        DispatchQueue.main.async { MainActor.assumeIsolated { report?(metrics) } }
    }

    /// The band is what the window's title bar and toolbar take off its content's top (`contentLayoutRect`). The
    /// buttons count when they are this window's own, shown, in that band and over `view`.
    static func metrics(of window: NSWindow, in view: NSView) -> SidebarTitleBarMetrics {
        let content = window.contentView?.frame ?? window.frame
        let band = max(0, content.maxY - window.contentLayoutRect.maxY)
        var end: CGFloat?
        if band > 0 {
            for kind: NSWindow.ButtonType in [.closeButton, .miniaturizeButton, .zoomButton] {
                guard let button = window.standardWindowButton(kind), button.window === window,
                      !button.isHiddenOrHasHiddenAncestor else { continue }
                let frame = button.convert(button.bounds, to: nil)
                guard frame.minY >= window.contentLayoutRect.maxY - 1 else { continue }
                let local = view.convert(frame, from: nil)
                if local.maxX > 0 { end = max(end ?? 0, local.maxX) }
            }
        }
        return SidebarTitleBarMetrics(band: band, windowButtonsEnd: end)
    }
}

/// The empty part of the title bar row: it drags the window, and a double click does what the system's title bar does.
private struct TitleBarDragArea: NSViewRepresentable {
    func makeNSView(context: Context) -> TitleBarDragView { TitleBarDragView() }
    func updateNSView(_ view: TitleBarDragView, context: Context) {}
}

final class TitleBarDragView: NSView {
    override init(frame: NSRect) {
        super.init(frame: frame)
        setAccessibilityElement(false)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not used")
    }

    override var mouseDownCanMoveWindow: Bool { false }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }

    override func mouseDown(with event: NSEvent) {
        guard let window else { return }
        if event.clickCount == 2 {
            TitleBarDoubleClick.current.perform(on: window)
        } else {
            window.performDrag(with: event)
        }
    }
}

/// What a double click on a title bar does, as the user set it in System Settings (Desktop & Dock, "Double-click a
/// window's title bar to"), read from the global `AppleActionOnDoubleClick` default.
enum TitleBarDoubleClick: Equatable {
    case zoom, minimize, none

    init(preference: String?, minimizeFlag: Bool) {
        switch preference {
        case "Minimize": self = .minimize
        case "None": self = .none
        case nil: self = minimizeFlag ? .minimize : .zoom
        default: self = .zoom
        }
    }

    static var current: TitleBarDoubleClick {
        let defaults = UserDefaults.standard
        return TitleBarDoubleClick(preference: defaults.string(forKey: "AppleActionOnDoubleClick"),
                                   minimizeFlag: defaults.bool(forKey: "AppleMiniaturizeOnDoubleClick"))
    }

    @MainActor
    func perform(on window: NSWindow) {
        switch self {
        case .zoom: window.performZoom(nil)
        case .minimize: window.performMiniaturize(nil)
        case .none: break
        }
    }
}
#endif
