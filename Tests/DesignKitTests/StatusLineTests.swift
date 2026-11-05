import ColorCore
import ColorPlatform
import ColorUI
import DesignKit
import Foundation
import SwiftUI
import Testing

/// The status line's options from issue #32, on an offscreen render: a chevron apart from `isOpen`, a trailing count,
/// middle truncation, hover over the open fill, and a height that grows with the text.
@MainActor
@Suite(.enabled(if: ProcessInfo.processInfo.operatingSystemVersion.majorVersion == 27))
struct StatusLineTests {
    let theme = Palette.standard.themes[0]

    func render(_ line: some View, scheme: ColorScheme = .light, tokens: DesignTokens = .standard) throws -> Raster {
        try raster(
            line.frame(width: 320)
                .designTokens(tokens)
                .theme(theme)
                .environment(\.colorScheme, scheme)
                .background(page(scheme)))
    }

    /// The window's plain background, as the solver resolves it.
    func page(_ scheme: ColorScheme) -> Color {
        let background = ResolvedColors(theme, in: scheme == .dark ? .dark : .light).background
        return Color(.sRGB, red: background.red, green: background.green, blue: background.blue)
    }

    func over(_ opacity: Double, scheme: ColorScheme = .light) -> RGBA {
        let colors = ResolvedColors(theme, in: scheme == .dark ? .dark : .light)
        return colors.primary.opacity(opacity).composited(over: colors.background)
    }

    /// The columns where two renders differ, left to right.
    func differingColumns(_ a: Raster, _ b: Raster) -> [Int] {
        (0..<min(a.width, b.width)).filter { x in
            (0..<min(a.height, b.height)).contains { y in Contrast.ratio(a.color(x: x, y: y), b.color(x: x, y: y)) > 1.05 }
        }
    }

    @Test(arguments: [ColorScheme.light, .dark])
    func theChevronTurnsApartFromIsOpen(_ scheme: ColorScheme) throws {
        let closed = try render(StatusLine(tile: .initial("A"), title: "All", isOpen: false), scheme: scheme)
        let open = try render(StatusLine(tile: .initial("A"), title: "All", isOpen: true), scheme: scheme)
        let pulled = try render(StatusLine(tile: .initial("A"), title: "All", isOpen: false, chevron: .up), scheme: scheme)
        let openDown = try render(StatusLine(tile: .initial("A"), title: "All", isOpen: true, chevron: .down), scheme: scheme)
        #expect(!closed.matches(open), "the chevron follows isOpen by default")
        #expect(pulled.matches(open), "a closed line can point its chevron up")
        #expect(openDown.matches(closed), "an open line can point it down")
        // Pulled with the open fill asked for: the chevron is up, the line stays unfilled until it is open.
        let pulledFilled = try render(
            StatusLine(tile: .initial("A"), title: "All", isOpen: false, fillsWhenOpen: true, chevron: .up), scheme: scheme)
        #expect(pulledFilled.matches(open))
    }

    @Test func theCountCanSitAtTheEndOfTheLine() throws {
        let none = try render(StatusLine(tile: .initial("A"), title: "All", isOpen: false))
        let after = try render(StatusLine(tile: .initial("A"), title: "All", count: 12, isOpen: false))
        let trailing = try render(StatusLine(tile: .initial("A"), title: "All", count: 12, isOpen: false, countPlacement: .trailing))
        let afterColumns = differingColumns(none, after)
        let trailingColumns = differingColumns(none, trailing)
        #expect(!afterColumns.isEmpty && !trailingColumns.isEmpty)
        #expect((afterColumns.max() ?? 320) < 120, "after the title: \(afterColumns.min() ?? -1)…\(afterColumns.max() ?? -1)")
        // The chevron's 7 pt glyph ends 12 pt from the trailing edge; the count ends before it.
        #expect((trailingColumns.min() ?? 0) > 240, "at the end: \(trailingColumns.min() ?? -1)…\(trailingColumns.max() ?? -1)")
        #expect((trailingColumns.max() ?? 320) < 300)
    }

    @Test func aLongTitleCanBeCutInTheMiddle() throws {
        let title = "Personal · A folder whose name is far too long for the line · Inbox"
        let tail = try render(StatusLine(tile: .initial("P"), title: title, isOpen: false))
        let middle = try render(StatusLine(tile: .initial("P"), title: title, isOpen: false, truncationMode: .middle))
        #expect(!tail.matches(middle))
        let short = try render(StatusLine(tile: .initial("P"), title: "Inbox", isOpen: false))
        let shortMiddle = try render(StatusLine(tile: .initial("P"), title: "Inbox", isOpen: false, truncationMode: .middle))
        #expect(short.matches(shortMiddle), "a title that fits is not cut")
    }

    /// Across `raster`, the clear runs of at least 4 columns (between glyphs, not inside a word), left to right.
    func clearRuns(_ raster: Raster) -> [Int] {
        var runs: [(clear: Bool, length: Int)] = []
        for x in 0..<raster.width {
            let clear = (0..<raster.height).allSatisfy { raster.alpha(x: x, y: $0) < 0.15 }
            if runs.last?.clear == clear { runs[runs.count - 1].length += 1 } else { runs.append((clear, 1)) }
        }
        return runs.filter { $0.clear && $0.length >= 4 }.map(\.length)
    }

    /// The clear columns between a title cut short and the count: from the right, past the trailing margin, the
    /// chevron and the space before it, then the count.
    func titleToCountGap(_ raster: Raster) -> Int {
        let runs = clearRuns(raster)
        return runs.count >= 3 ? runs[runs.count - 3] : -1
    }

    /// Issue #57: `titleToCount` keeps more space between a title cut short and its count. At 0, the default, the line
    /// draws as 0.2.9 did: the gaps are the ones measured on 0.2.9's render of this line (the line's own 8 pt between
    /// the title and the count, 9 clear columns with the glyphs' side bearings, or 22 with the count at the end).
    @Test(arguments: [ColorScheme.light, .dark], [StatusLineCountPlacement.afterTitle, .trailing])
    func aTitleCutShortKeepsItsSpaceToTheCount(_ scheme: ColorScheme, _ placement: StatusLineCountPlacement) throws {
        let title = "Personal · A folder whose name is far too long for the line · Inbox"
        func line(_ titleToCount: CGFloat?) throws -> Raster {
            if let titleToCount {
                return try raster(
                    StatusLine(tile: .initial("P"), title: title, count: 128, isOpen: false, countPlacement: placement,
                               titleToCount: titleToCount)
                        .frame(width: 320).theme(theme).environment(\.colorScheme, scheme))
            }
            return try raster(
                StatusLine(tile: .initial("P"), title: title, count: 128, isOpen: false, countPlacement: placement)
                    .frame(width: 320).theme(theme).environment(\.colorScheme, scheme))
        }
        let byDefault = try line(nil)
        let zero = try line(0)
        let xs = try line(DesignTokens.Spacing.xs)
        #expect(byDefault.matches(zero))
        #expect(titleToCountGap(zero) == (placement == .afterTitle ? 9 : 22), "0.2.9's gap: \(clearRuns(zero))")
        // At `Spacing.xs` the gap is at least the line's own spacing (twice with the count at the end, the spacer between)
        // and 4 pt more. After the title the count moves 4 pt further; at the end the cut title already left more.
        let spacing = Int(DesignTokens.standard.spacing.compactTileToText)
        let floor = (placement == .afterTitle ? spacing : 2 * spacing) + Int(DesignTokens.Spacing.xs)
        #expect(titleToCountGap(xs) >= floor, "\(titleToCountGap(zero)) → \(titleToCountGap(xs))")
        if placement == .afterTitle {
            #expect(titleToCountGap(xs) - titleToCountGap(zero) == Int(DesignTokens.Spacing.xs))
        } else {
            #expect(titleToCountGap(xs) >= titleToCountGap(zero))
        }
        #expect(byDefault.height == xs.height)
        // Without a count there is nothing to keep apart: the line draws as before.
        let bare = try render(StatusLine(tile: .initial("P"), title: title, isOpen: false), scheme: scheme)
        let bareXS = try render(
            StatusLine(tile: .initial("P"), title: title, isOpen: false, titleToCount: DesignTokens.Spacing.xs),
            scheme: scheme)
        #expect(bare.matches(bareXS))
    }

    @Test(arguments: [ColorScheme.light, .dark])
    func hoverCanShowOverTheOpenFill(_ scheme: ColorScheme) throws {
        let roles = ColorRoles(theme: theme, tokens: .standard, appearance: scheme == .dark ? .dark : .light)
        let hovered = RowState(isHovered: true)
        let open = try render(StatusLine(tile: .initial("A"), title: "All", isOpen: true, fillsWhenOpen: true), scheme: scheme)
        let kept = try render(
            StatusLine(tile: .initial("A"), title: "All", isOpen: true, fillsWhenOpen: true, state: hovered), scheme: scheme)
        let over = try render(
            StatusLine(tile: .initial("A"), title: "All", isOpen: true, fillsWhenOpen: true, state: hovered,
                       hoverOverOpenFill: true),
            scheme: scheme)
        let closed = try render(
            StatusLine(tile: .initial("A"), title: "All", isOpen: false, fillsWhenOpen: true, state: hovered,
                       hoverOverOpenFill: true),
            scheme: scheme)
        // The fill starts 4 pt in, the tile 8 pt further: sample between them.
        #expect(Contrast.ratio(open.color(x: 8, y: 19), self.over(roles.currentOpacity, scheme: scheme)) < 1.02)
        #expect(Contrast.ratio(kept.color(x: 8, y: 19), self.over(roles.currentOpacity, scheme: scheme)) < 1.02,
                "by default the open fill stays under the pointer")
        #expect(Contrast.ratio(over.color(x: 8, y: 19), self.over(roles.hoverOpacity, scheme: scheme)) < 1.02,
                "with hoverOverOpenFill the hover fill shows")
        #expect(Contrast.ratio(closed.color(x: 8, y: 19), self.over(roles.hoverOpacity, scheme: scheme)) < 1.02)
    }

    @Test func theChevronTransitionIsTheClients() throws {
        // A transition shows only while the chevron changes: at rest every transition draws the same chevron.
        let replace = try render(StatusLine(tile: .initial("A"), title: "All", isOpen: true))
        let none = try render(StatusLine(tile: .initial("A"), title: "All", isOpen: true, chevronTransition: .identity))
        #expect(replace.matches(none))
    }

    @Test func theLineIsAtLeastItsHeightAndGrowsWithItsText() throws {
        let standard = try render(StatusLine(tile: .initial("A"), title: "All", count: 3, isOpen: false))
        #expect(standard.height == 38)
        var large = DesignTokens.standard
        large.type.rowTitleEmphasized = TextRole(.largeTitle, .bold)
        let grown = try render(StatusLine(tile: .initial("A"), title: "All", count: 3, isOpen: false), tokens: large)
        #expect(grown.height > 38, "the text is taller than the line: \(grown.height)")
    }
}
