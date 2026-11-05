import AppKit
import ColorCore
import ColorUI
import DesignKit
import SwiftUI

// The 0.2.10 changes, rendered offscreen on the window's gradient, light and dark, one sheet per change.
// `DesignKitGallery 0.2.10 <output directory>`.

/// Rows side by side in one line (issue #56): no row gap above or below since 0.2.10, as stacked rows, between free
/// rows. The 40 pt tiles are Oisillon's accounts row.
struct SideBySide0210Sheet: View {
    private var freeInset: CGFloat {
        let spacing = DesignTokens.standard.spacing
        return spacing.listMargin - spacing.rowInsetHorizontal
    }

    private func line(spacing: CGFloat = 0) -> some View {
        HStack(spacing: spacing) {
            ListRow("Work", state: RowState(isHovered: true), placement: .sideBySide) { Tile(.initial("W"), size: .compact) }
            ListRow("Home", state: RowState(isSelected: true), placement: .sideBySide) { Tile(.initial("H"), size: .compact) }
            ListRow("News", state: RowState(isCurrent: true), placement: .sideBySide) { Tile(.initial("N"), size: .compact) }
        }
        .padding(.horizontal, freeInset)
    }

    private var tiles: some View {
        HStack(spacing: DesignTokens.Spacing.xs) {
            ListRowBackground(state: RowState(isCurrent: true), placement: .sideBySide)
                .overlay { Text(verbatim: "All").font(.callout.weight(.semibold)) }
                .frame(width: 56, height: 40)
            ForEach(["W", "H", "N"], id: \.self) { initial in
                ListRowBackground(state: RowState(isHovered: initial == "W"), placement: .sideBySide)
                    .overlay { Tile(.initial(initial), size: .compact) }
                    .frame(width: 40, height: 40)
            }
        }
        .padding(.horizontal, freeInset)
    }

    var body: some View {
        Sheet028 {
            Labelled(".sideBySide between free rows: no row gap of its own") {
                VStack(spacing: 0) {
                    ListRow("All accounts", state: RowState(isHovered: true)) { Tile(.tintedSymbol("tray.2"), size: .compact) }
                    line()
                    ListRow("Archive", state: RowState(isHovered: true)) { Tile(.tintedSymbol("archivebox"), size: .compact) }
                }
            }
            Labelled(".stacked, for comparison") {
                VStack(spacing: 0) {
                    ListRow("Inbox", state: RowState(isHovered: true), placement: .stacked) { Tile(.initial("I"), size: .compact) }
                    ListRow("Sent", state: RowState(isCurrent: true), placement: .stacked) { Tile(.initial("S"), size: .compact) }
                }
            }
            Labelled("40 pt side-by-side tiles, 4 pt apart: 40 pt fills") {
                tiles
            }
        }
    }
}

/// `StatusLine`'s `titleToCount` (issue #57): a title cut short, its count after it or at the end, at 0 (the default,
/// as 0.2.9) and at `Spacing.xs`.
struct StatusLineSpacing0210Sheet: View {
    private let title = "Personal · A folder whose name is far too long for the line · Inbox"

    var body: some View {
        Sheet028 {
            Labelled("After the title, titleToCount 0 (the default)") {
                StatusLine(tile: .initial("P"), title: title, count: 128, isOpen: false)
            }
            Labelled("After the title, titleToCount Spacing.xs") {
                StatusLine(tile: .initial("P"), title: title, count: 128, isOpen: false, titleToCount: DesignTokens.Spacing.xs)
            }
            Labelled("At the end, titleToCount 0 (the default)") {
                StatusLine(tile: .initial("P"), title: title, count: 128, isOpen: false, countPlacement: .trailing)
            }
            Labelled("At the end, titleToCount Spacing.xs") {
                StatusLine(tile: .initial("P"), title: title, count: 128, isOpen: false, countPlacement: .trailing,
                           titleToCount: DesignTokens.Spacing.xs)
            }
        }
    }
}

@MainActor
func run0210(output: URL) {
    let sheets: [(name: String, size: CGSize, view: AnyView)] = [
        ("side-by-side-rows", CGSize(width: 360, height: 330), AnyView(SideBySide0210Sheet())),
        ("status-line-title-to-count", CGSize(width: 360, height: 310), AnyView(StatusLineSpacing0210Sheet())),
    ]
    do {
        for theme in [Palette.standard.themes[0], Palette.standard.themes[1]] {
            for isDark in [false, true] {
                for sheet in sheets {
                    let url = output.appending(path: "kit-0.2.10-\(sheet.name)-\(theme.id)-\(isDark ? "dark" : "light").png")
                    try renderView(sheet.view.theme(theme), size: sheet.size, isDark: isDark, to: url)
                    print("OK: \(url.lastPathComponent)")
                }
            }
        }
    } catch {
        print("FAILED: \(error)")
        exit(1)
    }
}
