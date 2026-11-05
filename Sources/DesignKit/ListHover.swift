import Observation
import SwiftUI

/// Which row of a list the pointer is over, observed row by row: a hover step re-evaluates the row it leaves and the row
/// it enters, never the others, however long the list. A row asks `isHovered(_:)` for its own id and observes only
/// that; `hoveredID` is observed apart, by whoever reads it.
///
/// `sidebarColumn` puts one in the environment of its `List`, and a cell with `listRowCell(state:placement:hoverID:)` or
/// `sidebarRowCell(state:placement:hoverID:)` tracks the pointer into it and draws its hover fill from it, so a client
/// passes neither `RowState.isHovered` nor a hovered id down to its rows. Hand your own to the list with `listHover(_:)`
/// to read `hoveredID` (a hovered row's own buttons, say), or to set it (`move(to:)`).
@MainActor
@Observable
public final class ListHover {
    /// The hovered row's id, nil when the pointer is over none. Reading it re-evaluates the reader on every hover step:
    /// a row reads `isHovered(_:)` instead.
    public private(set) var hoveredID: AnyHashable?
    /// `hoveredID`, unobserved: what a row's body reads when it first asks, so that it observes its own row alone.
    @ObservationIgnored private var current: AnyHashable?
    /// The rows asked about lately, in two generations: a row asked about goes into `recent`; when `recent` is full it
    /// becomes `older` and the `older` before it is dropped, so the store holds at most `capacity` rows however many ids
    /// a long scroll asks about (issue #48). A row asked about again while in `older` comes back into `recent`, and the
    /// hovered row is never dropped.
    @ObservationIgnored private var recent: [AnyHashable: Row] = [:]
    @ObservationIgnored private var older: [AnyHashable: Row] = [:]

    /// How many rows the store holds at most: two generations of `capacity / 2`, many times the rows a column shows.
    static let capacity = 512

    /// How many rows the store holds now, for the tests.
    var storedRows: Int { recent.count + older.count }

    public init() {}

    /// Whether the row `id` is hovered. Observes that row alone: the reader is re-evaluated when that row is entered or
    /// left, not on other hover steps.
    public func isHovered(_ id: AnyHashable) -> Bool { row(id).isHovered }

    /// The pointer entered (`isInside` true) or left the row `id`. Leaving a row that is no longer the hovered one
    /// changes nothing, so the order of a leave and the next enter does not matter.
    public func setHovered(_ id: AnyHashable, _ isInside: Bool) {
        if isInside {
            move(to: id)
        } else if current == id {
            move(to: nil)
        }
    }

    /// Makes `id` the hovered row (none when nil). Touches the row left and the row entered alone, and stores neither:
    /// a row not asked about yet starts hovered when it asks.
    public func move(to id: AnyHashable?) {
        guard id != current else { return }
        if let old = current { stored(old)?.isHovered = false }
        current = id
        hoveredID = id
        if let id { stored(id)?.isHovered = true }
    }

    private func stored(_ id: AnyHashable) -> Row? { recent[id] ?? older[id] }

    private func row(_ id: AnyHashable) -> Row {
        if let known = recent[id] { return known }
        let row = older.removeValue(forKey: id) ?? Row(isHovered: id == current)
        recent[id] = row
        if recent.count >= Self.capacity / 2 { rotate() }
        return row
    }

    /// `recent` becomes `older`, and the `older` before it is dropped, keeping the hovered row. A dropped row that a view
    /// still shows (one asked about long ago and not since) re-evaluates that view, once, after this update, so that it
    /// asks again and observes the row that is stored: its hover is never missed.
    private func rotate() {
        var dropped = older
        older = recent
        recent = [:]
        if let current, let row = dropped.removeValue(forKey: current) { recent[current] = row }
        guard !dropped.isEmpty else { return }
        Task { @MainActor in
            for row in dropped.values { row.retire() }
        }
    }

    /// One row's hover, observed on its own.
    @Observable
    final class Row {
        var isHovered: Bool

        init(isHovered: Bool) {
            self.isHovered = isHovered
        }

        /// Tells the views that observe this row that it is no longer stored, so that they ask again.
        func retire() {
            withMutation(keyPath: \.isHovered) {}
        }
    }
}

extension View {
    /// Hands `hover` to the lists below: the kit's cells with a `hoverID` track the pointer into it and draw from it.
    /// `sidebarColumn` already sets one of its own; set yours on the `List` (inside `sidebarColumn`) to read it.
    public func listHover(_ hover: ListHover) -> some View {
        environment(hover)
    }

    /// Tracks the pointer over this view as the row `id` of the `ListHover` in the environment, for a cell of the
    /// client's own whose background is a `ListRowBackground(…, hoverID: id)`. The kit's cells do it themselves.
    public func listHoverTracking(id: AnyHashable) -> some View {
        modifier(ListHoverTracking(id: id))
    }
}

private struct ListHoverTracking: ViewModifier {
    @Environment(ListHover.self) private var hover: ListHover?
    let id: AnyHashable

    func body(content: Content) -> some View {
        content.onHover { inside in hover?.setHovered(id, inside) }
    }
}

/// A kit cell's hover, given its `hoverID`: tracked into the environment's `ListHover` and read from it by the cell's
/// `ListRowBackground`; without one, kept in the cell's own state. Either way a hover step re-evaluates this cell alone.
struct CellHover: ViewModifier {
    @Environment(ListHover.self) private var hover: ListHover?
    @State private var isHovered = false
    let id: AnyHashable?
    let background: (_ localHover: Bool) -> ListRowBackground

    func body(content: Content) -> some View {
        if let id {
            if let hover {
                content
                    .onHover { inside in hover.setHovered(id, inside) }
                    .listRowBackground(background(false))
            } else {
                content
                    .onHover { isHovered = $0 }
                    .listRowBackground(background(isHovered))
            }
        } else {
            content.listRowBackground(background(false))
        }
    }
}
