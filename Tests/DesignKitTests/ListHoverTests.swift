#if os(macOS)
import AppKit
import ColorCore
import ColorUI
@testable import DesignKit
import Foundation
import Observation
import SwiftUI
import Synchronization
import Testing

/// A hover step re-evaluates only the rows it touches (issue #38): the row it leaves and the row it enters, whatever the
/// list's length. Counted on `ListRowBackground`'s body in a real `List`, hosted in a window that is never shown.
@MainActor
@Suite(.serialized)
struct ListHoverTests {
    static let rows = 400

    /// The old way, for comparison: the list's body reads the hovered id and hands every row its `RowState`.
    @Observable final class ClientHover {
        var hovered: Int?
    }

    enum Cell { case list, sidebar }

    struct KitList: View {
        let hover: ListHover
        let cell: Cell
        var rows = ListHoverTests.rows

        var body: some View {
            switch cell {
            case .list:
                List(0..<rows, id: \.self) { index in
                    ListRowContent("Row \(index)") { Tile(.initial("R")) }.listRowCell(hoverID: index)
                }
                .listHover(hover)
            case .sidebar:
                List(0..<rows, id: \.self) { index in
                    Text("Row \(index)").sidebarRowCell(hoverID: index)
                }
                .listHover(hover)
                .sidebarColumn()
            }
        }
    }

    struct ClientList: View {
        let hover: ClientHover

        var body: some View {
            List(0..<ListHoverTests.rows, id: \.self) { index in
                ListRowContent("Row \(index)") { Tile(.initial("R")) }
                    .listRowCell(state: RowState(isHovered: hover.hovered == index))
            }
        }
    }

    final class Host {
        let window: NSWindow

        @MainActor init(_ view: some View) {
            let hosting = NSHostingView(rootView: view.theme(Palette.standard.themes[0]).frame(width: 360, height: 600))
            hosting.frame = CGRect(x: 0, y: 0, width: 360, height: 600)
            window = NSWindow(contentRect: hosting.frame, styleMask: [.borderless], backing: .buffered, defer: false)
            window.isReleasedWhenClosed = false
            window.contentView = hosting
            settle()
        }

        @MainActor func settle() {
            window.contentView?.layoutSubtreeIfNeeded()
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.3))
            window.contentView?.layoutSubtreeIfNeeded()
            window.contentView?.displayIfNeeded()
        }

        @MainActor func close() { window.contentView = nil }
    }

    /// How many backgrounds `step` re-evaluates once the list has settled.
    func evaluations(_ host: Host, _ step: () -> Void) -> Int {
        host.settle()
        ListRowBackground.evaluations.withLock { $0 = 0 }
        step()
        host.settle()
        return ListRowBackground.evaluations.withLock { $0 }
    }

    @Test(arguments: [Cell.list, .sidebar])
    func aHoverStepReEvaluatesOnlyTheRowsItTouches(_ cell: Cell) {
        let hover = ListHover()
        let host = Host(KitList(hover: hover, cell: cell))
        defer { host.close() }
        let enter = evaluations(host) { hover.setHovered(3, true) }
        let move = evaluations(host) { hover.setHovered(3, false); hover.setHovered(4, true) }
        let across = evaluations(host) { hover.move(to: 9) }
        let leave = evaluations(host) { hover.setHovered(9, false) }
        print("HOVER \(cell): enter \(enter), move \(move), across \(across), leave \(leave) of \(Self.rows) rows")
        #expect(enter == 1)
        #expect(move == 2)
        #expect(across == 2)
        #expect(leave == 1)
        #expect(hover.hoveredID == nil)
    }

    /// The same steps with the hovered id in the list's body, as clients did before: printed, for the record. Here SwiftUI
    /// skips the rows whose `RowState` did not change; a client's rows that it cannot compare (Oisillon's) re-evaluate
    /// every shown row, which the kit's hover avoids whatever the rows hold.
    @Test func theOldWayForTheRecord() {
        let hover = ClientHover()
        let host = Host(ClientList(hover: hover))
        defer { host.close() }
        let enter = evaluations(host) { hover.hovered = 3 }
        let move = evaluations(host) { hover.hovered = 4 }
        print("HOVER client state: enter \(enter), move \(move) of \(Self.rows) rows")
    }

    @Test func theHoveredRowFollowsEntersAndLeavesInAnyOrder() {
        let hover = ListHover()
        hover.setHovered("a", true)
        #expect(hover.hoveredID == AnyHashable("a"))
        hover.setHovered("b", true)
        hover.setHovered("a", false)
        #expect(hover.hoveredID == AnyHashable("b"), "a late leave of the previous row changes nothing")
        #expect(hover.isHovered("b") && !hover.isHovered("a"))
        hover.setHovered("b", false)
        #expect(hover.hoveredID == nil && !hover.isHovered("b"))
        hover.move(to: "c")
        #expect(hover.isHovered("c"), "a row asked about after it was hovered starts hovered")
    }

    /// Scrolled from top to bottom through 5,000 rows, the store keeps at most `ListHover.capacity` of them (issue #48),
    /// where 0.2.8 kept every row ever drawn, and a hover step still re-evaluates the rows it touches alone.
    @Test(arguments: [Cell.list, .sidebar])
    func theStoreStaysBoundedOverALongScroll(_ cell: Cell) throws {
        let hover = ListHover()
        let host = Host(KitList(hover: hover, cell: cell, rows: 5_000))
        defer { host.close() }
        let scroll = try #require(host.window.contentView?.firstScrollView)
        let table = try #require(scroll.documentView as? NSTableView)
        var most = 0
        while true {
            let end = table.frame.height - scroll.contentView.bounds.height
            let y = scroll.contentView.bounds.minY
            guard y < end else { break }
            scroll.contentView.scroll(to: CGPoint(x: 0, y: min(end, y + scroll.contentView.bounds.height / 2)))
            scroll.reflectScrolledClipView(scroll.contentView)
            host.window.contentView?.layoutSubtreeIfNeeded()
            host.window.contentView?.displayIfNeeded()
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.002))
            most = max(most, hover.storedRows)
        }
        host.settle()
        let shown = table.rows(in: scroll.contentView.bounds)
        print("STORE \(cell): at most \(most) rows stored over 5000, \(hover.storedRows) at the end, rows \(shown) shown")
        #expect(shown.upperBound == 5_000, "the list is scrolled to its end")
        #expect(most <= ListHover.capacity)
        #expect(most >= ListHover.capacity / 2, "the scroll went through more rows than the store keeps")
        let row = shown.location + shown.length / 2
        let enter = evaluations(host) { hover.setHovered(row, true) }
        let move = evaluations(host) { hover.setHovered(row, false); hover.setHovered(row + 1, true) }
        print("STORE \(cell): enter \(enter), move \(move), stored \(hover.storedRows)")
        #expect(enter == 1)
        #expect(move == 2)
    }

    /// The store's two generations, without a list: 5,000 ids asked about in turn leave at most `capacity` stored; the
    /// hovered row is kept however long ago it was asked about; a dropped row asked about again reads the hover as it
    /// is; and a view still observing a dropped row is told, after the update that dropped it, so that it asks again.
    @Test func theStoreKeepsTheHoveredRowAndTellsTheDroppedOnes() async throws {
        let hover = ListHover()
        #expect(!hover.isHovered(0))
        hover.move(to: 0)
        let told = Mutex(false)
        withObservationTracking { _ = hover.isHovered(1) } onChange: { told.withLock { $0 = true } }
        var most = 0
        for id in 2..<5_002 {
            _ = hover.isHovered(id)
            most = max(most, hover.storedRows)
        }
        #expect(most <= ListHover.capacity)
        #expect(hover.isHovered(0), "the hovered row is kept")
        for _ in 0..<20 where !told.withLock({ $0 }) { try await Task.sleep(for: .milliseconds(5)) }
        #expect(told.withLock { $0 }, "the view observing the dropped row 1 is told")
        hover.move(to: 1)
        #expect(hover.isHovered(1) && !hover.isHovered(0), "row 1, asked about again, reads the hover as it is")
        hover.move(to: 3)
        #expect(hover.isHovered(3), "a row dropped and hovered since starts hovered when it asks")
    }

    /// The hovered row draws the hover fill; another row draws none. Rendered unhovered first: an `ImageRenderer`
    /// render of a background keeps the fill of the one rendered before it (seen on 0.2.7 too, with `RowState`).
    @Test func theHoveredRowDrawsTheHoverFill() throws {
        let theme = Palette.standard.themes[0]
        let hover = ListHover()
        hover.move(to: 1)
        let plain = try raster(ListRowBackground().frame(width: 300, height: 40).theme(theme))
        let other = try raster(ListRowBackground(hoverID: 2).environment(hover).frame(width: 300, height: 40).theme(theme))
        let hovered = try raster(ListRowBackground(hoverID: 1).environment(hover).frame(width: 300, height: 40).theme(theme))
        #expect(plain.alphaSum == 0)
        #expect(other.matches(plain), "another row is not hovered")
        #expect(hovered.alphaSum > 0, "the hovered row has its fill")
    }
}
#endif
