#if os(macOS)
import AppKit
import ColorCore
import ColorUI
import DesignKit
import Foundation
import SwiftUI
import Testing

/// `RowPlacement.sideBySide` (issue #49): rows laid next to each other in one line, with no side inset of their own,
/// and since 0.2.10 (issue #56) no row gap above or below, as in `.stacked`.
@MainActor
@Suite(.enabled(if: ProcessInfo.processInfo.operatingSystemVersion.majorVersion == 27))
struct SideBySideTests {
    let theme = Palette.standard.themes[0]
    let tokens = DesignTokens.standard
    var freeInset: Int { Int(tokens.spacing.listMargin - tokens.spacing.rowInsetHorizontal) }

    func render(_ view: some View, scheme: ColorScheme) throws -> Raster {
        try raster(view.frame(width: 320).theme(theme).environment(\.colorScheme, scheme))
    }

    /// Along the line `y` of `raster`, the runs of filled and clear pixels, left to right.
    func runs(_ raster: Raster, y: Int) -> [(filled: Bool, length: Int)] {
        var runs: [(Bool, Int)] = []
        for x in 0..<raster.width {
            let filled = raster.alpha(x: x, y: y) > 0.02
            if runs.last?.0 == filled { runs[runs.count - 1].1 += 1 } else { runs.append((filled, 1)) }
        }
        return runs.map { (filled: $0.0, length: $0.1) }
    }

    func line(_ placement: RowPlacement, spacing: CGFloat = 0) -> some View {
        let hovered = RowState(isHovered: true)
        return HStack(spacing: spacing) {
            ListRowBackground(state: hovered, placement: placement).frame(width: 100, height: 40)
            ListRowBackground(state: hovered, placement: placement).frame(width: 100, height: 40)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @Test(arguments: [ColorScheme.light, .dark])
    func sideBySideBackgroundsTouch(_ scheme: ColorScheme) throws {
        let free = try render(line(.free(firstInSection: false)), scheme: scheme)
        let side = try render(line(.sideBySide), scheme: scheme)
        // Free rows side by side: each keeps its side inset, so two fills stand twice the inset apart.
        #expect(runs(free, y: 20).map(\.filled) == [false, true, false, true, false])
        #expect(runs(free, y: 20)[0].length == freeInset)
        #expect(runs(free, y: 20)[2].length == 2 * freeInset)
        // Side by side: one fill from the line's edge, 200 pt wide.
        #expect(runs(side, y: 20).map(\.filled) == [true, false])
        #expect(runs(side, y: 20)[0].length == 200)
        // No row gap above or below: filled from the top row of pixels to the bottom one.
        #expect(side.alpha(x: 50, y: 0) > 0.02 && side.alpha(x: 50, y: 39) > 0.02)
    }

    /// Down the column `x` of `raster`, the runs of filled and clear pixels, top to bottom.
    func columnRuns(_ raster: Raster, x: Int) -> [(filled: Bool, length: Int)] {
        var runs: [(Bool, Int)] = []
        for y in 0..<raster.height {
            let filled = raster.alpha(x: x, y: y) > 0.02
            if runs.last?.0 == filled { runs[runs.count - 1].1 += 1 } else { runs.append((filled, 1)) }
        }
        return runs.map { (filled: $0.0, length: $0.1) }
    }

    /// Issue #56: a 40 pt side-by-side tile (Oisillon's "All" account) fills all 40 pt, with no gap above or below, as a
    /// stacked one does; 0.2.9 kept half a row gap at each end, a 36 pt fill, as a free row still does.
    @Test(arguments: [ColorScheme.light, .dark])
    func aSideBySideTileIsFortyPointsTall(_ scheme: ColorScheme) throws {
        let hovered = RowState(isHovered: true)
        func tile(_ placement: RowPlacement) throws -> Raster {
            try render(ListRowBackground(state: hovered, placement: placement).frame(width: 100, height: 40), scheme: scheme)
        }
        let side = try tile(.sideBySide)
        let stacked = try tile(.stacked)
        let free = try tile(.free(firstInSection: false))
        #expect(side.height == 40)
        #expect(columnRuns(side, x: 160).map(\.filled) == [true])
        #expect(columnRuns(side, x: 160).map(\.length) == [40])
        #expect(columnRuns(stacked, x: 160).map(\.length) == [40])
        let gap = Int(tokens.spacing.rowGap / 2)
        #expect(columnRuns(free, x: 160).map(\.length) == [gap, 40 - 2 * gap, gap])
    }

    @Test(arguments: [ColorScheme.light, .dark])
    func neighboursStandAsTheClientLaysThem(_ scheme: ColorScheme) throws {
        let side = try render(line(.sideBySide, spacing: 4), scheme: scheme)
        #expect(runs(side, y: 20).map(\.filled) == [true, false, true, false])
        #expect(runs(side, y: 20).map(\.length).prefix(3) == [100, 4, 100])
    }

    /// Padded by a free row's side inset, a line of them starts where a free row's background does.
    @Test(arguments: [ColorScheme.light, .dark])
    func aPaddedLineSitsOnTheColumnsMargin(_ scheme: ColorScheme) throws {
        let free = try render(ListRowBackground(state: RowState(isHovered: true)).frame(height: 40), scheme: scheme)
        let side = try render(line(.sideBySide).padding(.horizontal, CGFloat(freeInset)), scheme: scheme)
        #expect(runs(free, y: 20).first?.length == runs(side, y: 20).first?.length)
        #expect(runs(side, y: 20).first?.length == freeInset)
    }

    /// A row's content loses the free row's side insets, twice the inset narrower, and its row gap: as tall as a stacked
    /// row, a row gap shorter than a free one.
    @Test func aSideBySideRowIsAsTallAsAStackedOneAndNarrower() throws {
        func row(_ placement: RowPlacement) throws -> Raster {
            try raster(
                ListRowContent("Work", placement: placement) { Tile(.initial("W"), size: .compact) }.fixedSize().theme(theme))
        }
        let free = try row(.free(firstInSection: false))
        let stacked = try row(.stacked)
        let side = try row(.sideBySide)
        #expect(side.height == stacked.height)
        #expect(free.height - side.height == Int(tokens.spacing.rowGap))
        #expect(free.width - side.width == 2 * freeInset)
    }
}
#endif
