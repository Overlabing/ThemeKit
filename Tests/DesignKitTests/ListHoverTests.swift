#if os(macOS)
import AppKit
import ColorCore
import ColorUI
@testable import DesignKit
import Foundation
import Observation
import SwiftUI
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

        var body: some View {
            switch cell {
            case .list:
                List(0..<ListHoverTests.rows, id: \.self) { index in
                    ListRowContent("Row \(index)") { Tile(.initial("R")) }.listRowCell(hoverID: index)
                }
                .listHover(hover)
            case .sidebar:
                List(0..<ListHoverTests.rows, id: \.self) { index in
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
