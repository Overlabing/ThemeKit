#if os(macOS)
import AppKit
import ColorCore
import ColorUI
import DesignKit
import Foundation
import SwiftUI
import Testing

/// `RowPlacement.stacked` (issue #34) and `SkeletonRows` as `List` cells, placed, with three lines (issue #33).
@MainActor
@Suite(.enabled(if: ProcessInfo.processInfo.operatingSystemVersion.majorVersion == 27))
struct SkeletonAndStackedTests {
    let theme = Palette.standard.themes[0]
    let tokens = DesignTokens.standard

    func render(_ view: some View, scheme: ColorScheme = .light) throws -> Raster {
        try raster(view.frame(width: 320).theme(theme).environment(\.colorScheme, scheme))
    }

    /// Down the middle of `raster`, the runs of filled and clear pixels, top to bottom.
    func runs(_ raster: Raster) -> [(filled: Bool, length: Int)] {
        var runs: [(Bool, Int)] = []
        for y in 0..<raster.height {
            let filled = raster.alpha(x: raster.width / 2, y: y) > 0.02
            if runs.last?.0 == filled { runs[runs.count - 1].1 += 1 } else { runs.append((filled, 1)) }
        }
        return runs.map { (filled: $0.0, length: $0.1) }
    }

    // MARK: #34

    @Test(arguments: [ColorScheme.light, .dark])
    func stackedBackgroundsTouch(_ scheme: ColorScheme) throws {
        let hovered = RowState(isHovered: true)
        let free = try render(VStack(spacing: 0) {
            ListRowBackground(state: hovered).frame(height: 40)
            ListRowBackground(state: hovered).frame(height: 40)
        }, scheme: scheme)
        let stacked = try render(VStack(spacing: 0) {
            ListRowBackground(state: hovered, placement: .stacked).frame(height: 40)
            ListRowBackground(state: hovered, placement: .stacked).frame(height: 40)
        }, scheme: scheme)
        // Free rows: half a row gap clear above each, half below, so the two fills stand a whole gap apart.
        #expect(runs(free).map(\.filled) == [false, true, false, true, false])
        #expect(runs(free)[2].length == Int(tokens.spacing.rowGap))
        // Stacked: one fill, top to bottom.
        #expect(runs(stacked).map(\.filled) == [true])
        // On the column's margin like a free row.
        #expect(stacked.alpha(x: 3, y: 20) == 0 && stacked.alpha(x: 5, y: 20) > 0.02)
    }

    @Test func aStackedRowLeavesNoGap() throws {
        let free = try render(ListRowContent("Inbox") { Tile(.initial("I"), size: .compact) })
        let stacked = try render(ListRowContent("Inbox", placement: .stacked) { Tile(.initial("I"), size: .compact) })
        #expect(free.height - stacked.height == Int(tokens.spacing.rowGap))
    }

    // MARK: #33

    /// The rows the kit drew before 0.2.8, written out: the default draws them still.
    struct OldSkeleton: View {
        @Environment(\.designTokens) private var tokens
        let count: Int
        static let lines = ["Placeholder title of a row", "A shorter title", "A rather longer placeholder title"]

        var body: some View {
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
        }
    }

    @Test func theDefaultDrawsAsBefore() throws {
        let old = try render(OldSkeleton(count: 4))
        let now = try render(SkeletonRows(count: 4, label: "Loading"))
        #expect(now.matches(old))
    }

    @Test func threeLinesAddALinePerRow() throws {
        let two = try render(SkeletonRows(count: 3, label: "Loading"))
        let three = try render(SkeletonRows(count: 3, label: "Loading", lines: 3))
        let one = try render(SkeletonRows(count: 3, label: "Loading", lines: 1))
        let perRow = (three.height - two.height) / 3
        #expect(three.height > two.height && (three.height - two.height) % 3 == 0)
        #expect(perRow >= 13 && perRow <= 18, "a caption line and the gap above it: \(perRow)")
        #expect(one.height <= two.height, "one line: the tile sets the height")
        #expect(try render(SkeletonRows(count: 3, label: "Loading", lines: 9)).matches(three), "3 at most")
    }

    @Test func aFirstInSectionPlacementCountsForTheFirstRowOnly() throws {
        let plain = try render(SkeletonRows(count: 3, label: "Loading"))
        let first = try render(SkeletonRows(count: 3, label: "Loading", placement: .free(firstInSection: true)))
        #expect(first.height - plain.height == Int(tokens.spacing.sectionHeaderBottom - tokens.spacing.rowGap / 2))
        let stacked = try render(SkeletonRows(count: 3, label: "Loading", placement: .stacked))
        #expect(plain.height - stacked.height == 3 * Int(tokens.spacing.rowGap))
    }

    /// In a real `List`, hosted in a window that is never shown: one table row per skeleton row, as tall as the row it
    /// stands for.
    @Test(arguments: [SkeletonRowsStyle.listCells, .sidebarCells])
    func eachRowIsAListCell(_ style: SkeletonRowsStyle) throws {
        let list = Group {
            if style == .sidebarCells {
                List { SkeletonRows(count: 5, label: "Loading", lines: 3, style: style) }.sidebarColumn()
            } else {
                List { SkeletonRows(count: 5, label: "Loading", lines: 3, style: style) }.listStyle(.plain)
            }
        }
        let size = CGSize(width: 360, height: 500)
        let hosting = NSHostingView(rootView: list.theme(theme).frame(width: size.width, height: size.height))
        hosting.frame = CGRect(origin: .zero, size: size)
        let window = NSWindow(contentRect: hosting.frame, styleMask: [.borderless], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.contentView = hosting
        defer { window.contentView = nil }
        hosting.layoutSubtreeIfNeeded()
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.5))
        let table = try #require(Self.table(in: hosting))
        #expect(table.numberOfRows == 5)
        let heights = (0..<table.numberOfRows).map { table.rect(ofRow: $0).height }
        #expect(Set(heights).count == 1, "\(heights)")
        #expect((heights.first ?? 0) > 50, "three lines: \(heights)")
    }

    static func table(in view: NSView) -> NSTableView? {
        if let table = view as? NSTableView { return table }
        for sub in view.subviews { if let table = table(in: sub) { return table } }
        return nil
    }
}
#endif
