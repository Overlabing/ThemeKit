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

    static func firstTable(in view: NSView) -> NSTableView? {
        if let scroll = view as? NSScrollView, let table = scroll.documentView as? NSTableView { return table }
        for sub in view.subviews { if let table = firstTable(in: sub) { return table } }
        return nil
    }
}
#endif
