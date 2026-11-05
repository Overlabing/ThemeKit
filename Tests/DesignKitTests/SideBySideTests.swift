#if os(macOS)
import AppKit
import ColorCore
import ColorUI
import DesignKit
import Foundation
import SwiftUI
import Testing

/// `RowPlacement.sideBySide` (issue #49): rows laid next to each other in one line, with no side inset of their own.
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
        // Above and below, half a row gap clear, like a free row.
        let gap = Int(tokens.spacing.rowGap / 2)
        #expect(side.alpha(x: 50, y: gap - 1) == 0 && side.alpha(x: 50, y: gap) > 0.02)
        #expect(side.alpha(x: 50, y: 40 - gap) == 0 && side.alpha(x: 50, y: 39 - gap) > 0.02)
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

    /// A row's content keeps the free row's height and loses its side insets: twice the inset narrower.
    @Test func aSideBySideRowIsAsTallAndNarrower() throws {
        let free = try raster(ListRowContent("Work") { Tile(.initial("W"), size: .compact) }.fixedSize().theme(theme))
        let side = try raster(
            ListRowContent("Work", placement: .sideBySide) { Tile(.initial("W"), size: .compact) }.fixedSize().theme(theme))
        #expect(free.height == side.height)
        #expect(free.width - side.width == 2 * freeInset)
    }
}
#endif
