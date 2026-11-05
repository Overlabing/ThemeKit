#if os(macOS)
import AppKit
import ColorCore
import ColorUI
import DesignKit
import Foundation
import SwiftUI
import Testing

/// The sidebar column, drawn for real in a window that is never shown (`HostedPixels`).
@MainActor
@Suite(.enabled(if: ProcessInfo.processInfo.operatingSystemVersion.majorVersion == 27))
struct SidebarTests {
    static let theme = Palette.standard.themes[0]

    static func isRed(_ color: RGBA) -> Bool { color.red > 0.9 && color.green < 0.1 && color.blue < 0.1 }

    /// A sidebar cell keeps the `List`'s own margin: its background starts 4 pt in, as a `ListRow`'s does, its marker
    /// from 6 to 9 pt, and its content runs from 20 pt to 21 pt short of the right edge.
    @Test func aSidebarCellKeepsTheListsMargin() throws {
        let state = RowState(isSelected: true)
        let view = List {
            Color(red: 1, green: 0, blue: 0).frame(height: 40)
                .sidebarRowCell(state: state)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background { WindowBackground() }
        .theme(Self.theme)
        .frame(width: 320, height: 80)
        let pixels = try HostedPixels(view, size: CGSize(width: 320, height: 80), appearance: .aqua)
        let red = (0..<320).filter { Self.isRed(pixels.color(x: Double($0) + 0.5, y: 28)) }
        #expect(red.first == 20)
        #expect(red.last == 298)
        func edges(_ range: Range<Int>) -> [Int] {
            range.filter { Contrast.ratio(pixels.color(x: Double($0) + 0.5, y: 28), pixels.color(x: Double($0) - 0.5, y: 28)) > 1.1 }
        }
        #expect(edges(1..<20) == [4, 6, 9], "the fill, the marker in and out")
        #expect(edges(300..<319) == [316], "the fill's right edge")
    }

    /// A row under the bottom bar is not drawn below the bar's controls: the list shows fully above the bar, fades over
    /// the bar's first `Spacing.barFade` points, and shows nothing from there to the column's bottom edge.
    @Test func theListFadesOutUnderTheBottomBar() throws {
        let size = CGSize(width: 320, height: 300)
        let view = List {
            ForEach(0..<12, id: \.self) { _ in
                Color(red: 1, green: 0, blue: 0).frame(height: 40).sidebarRowCell()
            }
        }
        .sidebarColumn { Color.clear.frame(height: 60) }
        .background(Color.white)
        .frame(width: size.width, height: size.height)
        let pixels = try HostedPixels(view, size: size, appearance: .aqua)
        let fade = DesignTokens.standard.spacing.barFade
        #expect(Self.isRed(pixels.color(x: 160, y: 300 - 60 - 4)), "above the bar")
        #expect(pixels.color(x: 160, y: 300 - 60 + fade / 2).green > 0.2, "half faded")
        for y in stride(from: 300 - 60 + fade + 1, to: 300, by: 4) {
            let color = pixels.color(x: 160, y: y)
            #expect(color.red > 0.99 && color.green > 0.99 && color.blue > 0.99, "nothing at \(y)")
        }
    }

    /// The column turns off AppKit's selection platter, so the cell's background is the only selection drawn.
    @Test func theColumnTurnsOffTheSelectionPlatter() async throws {
        let hosting = NSHostingView(rootView: List(selection: .constant(1 as Int?)) {
            Text("Row").tag(1).sidebarRowCell(state: RowState(isSelected: true))
        }
        .sidebarColumn { EmptyView() }
        .frame(width: 320, height: 120))
        hosting.frame = CGRect(x: 0, y: 0, width: 320, height: 120)
        let window = NSWindow(contentRect: hosting.frame, styleMask: [.borderless], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.contentView = hosting
        hosting.layoutSubtreeIfNeeded()
        try await Task.sleep(for: .milliseconds(600))
        let table = try #require(Self.firstTable(in: hosting))
        #expect(table.selectionHighlightStyle == .none)
        window.contentView = nil
    }

    /// AppKit: the kit's split item is the system's sidebar, between the column's minimum and maximum, and a window laid
    /// out around it gives the column its ideal width.
    @Test func anAppKitSidebarItemLaysOutAtTheIdealWidth() throws {
        let item = NSSplitViewItem.sidebar(hosting: List { Text("Row").sidebarRowCell() }.sidebarColumn { EmptyView() })
        #expect(item.behavior == .sidebar)
        #expect(item.minimumThickness == 300)
        #expect(item.maximumThickness == 480)
        let split = NSSplitViewController()
        split.addSplitViewItem(item)
        split.addSplitViewItem(NSSplitViewItem(viewController: NSHostingController(rootView: SidebarDetail { Text("Page") })))
        let window = NSWindow(contentViewController: split)
        window.styleMask = [.titled, .resizable, .fullSizeContentView]
        window.isReleasedWhenClosed = false
        window.setContentSize(CGSize(width: 1100, height: 760))
        window.layoutIfNeeded()
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.3))
        #expect(item.viewController.view.frame.width == 360)
        #expect(split.splitViewItems[1].viewController.view.frame.width == 740)
        window.close()
    }

    /// The detail's card: inset 12 pt from the detail's edges, its 1 pt line centred on the card's edge (half outside).
    @Test func theDetailCardIsInsetByTheCanvasInset() throws {
        let size = CGSize(width: 200, height: 120)
        let view = SidebarDetail { Color(red: 1, green: 0, blue: 0) }
            .background(Color.white)
            .frame(width: size.width, height: size.height)
        let pixels = try HostedPixels(view, size: size, appearance: .aqua)
        let red = (0..<200).filter { Self.isRed(pixels.color(x: Double($0) + 0.5, y: 60)) }
        #expect(red.first == 12)
        #expect(red.last == 187)
        let white = pixels.color(x: 11, y: 60)
        #expect(white.red > 0.99 && white.green > 0.99 && white.blue > 0.99)
    }

    // MARK: Empty and collapsing bars (#29)

    static let columnSize = CGSize(width: 320, height: 300)

    /// Twelve 40 pt red rows, more than the column holds, on white.
    static func rows() -> some View {
        List {
            ForEach(0..<12, id: \.self) { _ in
                Color(red: 1, green: 0, blue: 0).frame(height: 40).sidebarRowCell()
            }
        }
    }

    /// The 20 pt bands down the column's middle where no row is drawn. A row is 40 pt with a few points between rows,
    /// so with every row shown each band holds some red.
    static func bandsWithoutARow(_ pixels: HostedPixels, from top: Double = 0, to bottom: Double = columnSize.height) -> [Double] {
        stride(from: top, to: bottom, by: 20).filter { band in
            !stride(from: band, to: min(band + 20, bottom), by: 1).contains { isRed(pixels.color(x: 160, y: $0 + 0.5)) }
        }
    }

    static func hosted(_ view: some View) throws -> HostedPixels {
        try HostedPixels(view.background(Color.white).frame(width: columnSize.width, height: columnSize.height),
                         size: columnSize, appearance: .aqua)
    }

    /// A bar that draws nothing in its current state, as the rail does with one Space.
    struct StateEmptyBar: View {
        let isShown: Bool
        var body: some View {
            if isShown { Color(red: 0, green: 0, blue: 1).frame(height: 80) }
        }
    }

    /// `sidebarColumn()`: every row down to the column's bottom edge.
    @Test func withNoBottomBarEveryRowShows() throws {
        let pixels = try Self.hosted(Self.rows().sidebarColumn())
        #expect(Self.bandsWithoutARow(pixels) == [])
    }

    /// `bottomBar: { EmptyView() }` hid every row in 0.2.6 (the mask took the measured `EmptyView`'s height).
    @Test func anEmptyViewBarHidesNoRow() throws {
        let pixels = try Self.hosted(Self.rows().sidebarColumn { EmptyView() })
        #expect(Self.bandsWithoutARow(pixels) == [])
        let builder = try Self.hosted(Self.rows().sidebarColumn {})
        #expect(Self.bandsWithoutARow(builder) == [])
        let withHeader = try Self.hosted(Self.rows().sidebarColumn { EmptyView() } bottomBar: { EmptyView() })
        #expect(Self.bandsWithoutARow(withHeader) == [])
    }

    /// A bar that is empty in its state takes no height and hides no row; shown, it is drawn and the rows fade under it.
    @Test func aBarThatDrawsNothingHidesNoRow() throws {
        let empty = try Self.hosted(Self.rows().sidebarColumn { StateEmptyBar(isShown: false) })
        #expect(Self.bandsWithoutARow(empty) == [])
        let shown = try Self.hosted(Self.rows().sidebarColumn { StateEmptyBar(isShown: true) })
        #expect(Self.bandsWithoutARow(shown, to: 300 - 80) == [])
        let bar = shown.color(x: 160, y: 300 - 40)
        #expect(bar.blue > 0.9 && bar.red < 0.1, "the bar is drawn: \(bar)")
    }

    @Observable final class Spaces {
        var count = 2
    }

    struct CollapsingColumn: View {
        let spaces: Spaces
        var body: some View {
            SidebarTests.rows().sidebarColumn {
                if spaces.count > 1 { Color(red: 0, green: 0, blue: 1).frame(height: 80) }
            }
            .background(Color.white)
            .frame(width: SidebarTests.columnSize.width, height: SidebarTests.columnSize.height)
        }
    }

    /// A bar that empties (2 Spaces, then 1) gives its height back: the 80 pt the bar took show rows again, where 0.2.6
    /// kept them masked.
    @Test func aBarThatEmptiesGivesItsHeightBack() throws {
        let spaces = Spaces()
        let hosting = NSHostingView(rootView: CollapsingColumn(spaces: spaces))
        hosting.frame = CGRect(origin: .zero, size: Self.columnSize)
        let window = NSWindow(contentRect: hosting.frame, styleMask: [.borderless], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.appearance = NSAppearance(named: .aqua)
        window.contentView = hosting
        defer { window.contentView = nil }
        let two = try HostedPixels(capturing: hosting, size: Self.columnSize)
        #expect(Self.bandsWithoutARow(two, to: 300 - 80) == [])
        #expect(!Self.isRed(two.color(x: 160, y: 300 - 40)), "under the bar")
        spaces.count = 1
        let one = try HostedPixels(capturing: hosting, size: Self.columnSize)
        #expect(Self.bandsWithoutARow(one) == [])
        spaces.count = 2
        let again = try HostedPixels(capturing: hosting, size: Self.columnSize)
        #expect(!Self.isRed(again.color(x: 160, y: 300 - 40)), "the bar is back and the rows fade under it")
    }

    /// The platter switch-off on its own, on a `List` with nothing else of `sidebarColumn`.
    @Test func thePlatterTurnsOffWithoutTheColumn() async throws {
        let hosting = NSHostingView(rootView: List(selection: .constant(1 as Int?)) {
            Text("Row").tag(1).listRowCell(state: RowState(isSelected: true))
        }
        .listSelectionPlatterOff()
        .frame(width: 320, height: 120))
        hosting.frame = CGRect(x: 0, y: 0, width: 320, height: 120)
        let window = NSWindow(contentRect: hosting.frame, styleMask: [.borderless], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.contentView = hosting
        hosting.layoutSubtreeIfNeeded()
        try await Task.sleep(for: .milliseconds(600))
        let table = try #require(Self.firstTable(in: hosting))
        #expect(table.selectionHighlightStyle == .none)
        window.contentView = nil
    }

    // MARK: Column widths (#28)

    /// A column view of the client's, with `sidebarColumn` under a container of its body, as Oisillon's is.
    struct NestedColumn: View {
        var body: some View {
            VStack(spacing: 0) {
                List { Text("Row").sidebarRowCell() }.sidebarColumn()
            }
        }
    }

    /// The widths of the split's columns, the sidebar first, in a 1100 pt window that is never shown.
    static func splitWidths(_ view: some View) throws -> [CGFloat] {
        let hosting = NSHostingView(rootView: view)
        let window = NSWindow(
            contentRect: CGRect(x: 0, y: 0, width: 1100, height: 760), styleMask: [.titled, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.contentView = hosting
        hosting.layoutSubtreeIfNeeded()
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.6))
        hosting.layoutSubtreeIfNeeded()
        func split(in view: NSView) -> NSSplitView? {
            if let split = view as? NSSplitView { return split }
            for sub in view.subviews { if let split = split(in: sub) { return split } }
            return nil
        }
        let widths = try #require(split(in: hosting)).arrangedSubviews.map(\.frame.width)
        window.contentView = nil
        window.close()
        return widths
    }

    /// `SidebarSplitView` opens the column at `Size.columnIdeal` (360 pt) wherever `sidebarColumn` sits in the sidebar:
    /// at its root, or under a container of the client's (144 pt in 0.2.6, the split's default).
    @Test func theSplitOpensTheColumnAtTheIdealWidth() throws {
        let ideal = DesignTokens.standard.size.columnIdeal
        let atRoot = try Self.splitWidths(SidebarSplitView { List { Text("Row") }.sidebarColumn() } detail: { Text("Page") })
        #expect(atRoot.first == ideal)
        let nested = try Self.splitWidths(SidebarSplitView { NestedColumn() } detail: { Text("Page") })
        #expect(nested.first == ideal)
    }

    /// In a `NavigationSplitView` of the client's, `sidebarColumnWidth()` on the column's root gives it the widths,
    /// whatever is under it.
    @Test func aClientSplitTakesTheWidthsFromTheColumnsRoot() throws {
        let ideal = DesignTokens.standard.size.columnIdeal
        let nested = try Self.splitWidths(NavigationSplitView { NestedColumn().sidebarColumnWidth() } detail: { Text("Page") })
        #expect(nested.first == ideal)
        let atRoot = try Self.splitWidths(NavigationSplitView { List { Text("Row") }.sidebarColumn() } detail: { Text("Page") })
        #expect(atRoot.first == ideal)
    }

    static func firstTable(in view: NSView) -> NSTableView? {
        if let scroll = view as? NSScrollView, let table = scroll.documentView as? NSTableView { return table }
        for sub in view.subviews { if let table = firstTable(in: sub) { return table } }
        return nil
    }
}
#endif
