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
        #expect(closed.data != open.data, "the chevron follows isOpen by default")
        #expect(pulled.data == open.data, "a closed line can point its chevron up")
        #expect(openDown.data == closed.data, "an open line can point it down")
        // Pulled with the open fill asked for: the chevron is up, the line stays unfilled until it is open.
        let pulledFilled = try render(
            StatusLine(tile: .initial("A"), title: "All", isOpen: false, fillsWhenOpen: true, chevron: .up), scheme: scheme)
        #expect(pulledFilled.data == open.data)
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
        #expect(tail.data != middle.data)
        let short = try render(StatusLine(tile: .initial("P"), title: "Inbox", isOpen: false))
        let shortMiddle = try render(StatusLine(tile: .initial("P"), title: "Inbox", isOpen: false, truncationMode: .middle))
        #expect(short.data == shortMiddle.data, "a title that fits is not cut")
    }

    @Test(arguments: [ColorScheme.light, .dark])
    func hoverShowsOverTheOpenFill(_ scheme: ColorScheme) throws {
        let roles = ColorRoles(theme: theme, tokens: .standard, appearance: scheme == .dark ? .dark : .light)
        let open = try render(StatusLine(tile: .initial("A"), title: "All", isOpen: true, fillsWhenOpen: true), scheme: scheme)
        let hovered = try render(
            StatusLine(tile: .initial("A"), title: "All", isOpen: true, fillsWhenOpen: true, state: RowState(isHovered: true)),
            scheme: scheme)
        // The fill starts 4 pt in, the tile 8 pt further: sample between them.
        #expect(Contrast.ratio(open.color(x: 8, y: 19), over(roles.currentOpacity, scheme: scheme)) < 1.02)
        #expect(Contrast.ratio(hovered.color(x: 8, y: 19), over(roles.hoverOpacity, scheme: scheme)) < 1.02,
                "hovered, the open line shows the hover fill")
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
