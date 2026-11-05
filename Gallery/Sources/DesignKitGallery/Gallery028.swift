import AppKit
import ColorCore
import ColorUI
import DesignKit
import SwiftUI

// The 0.2.8 additions, rendered offscreen on the window's gradient, light and dark, one sheet per change.
// `DesignKitGallery 0.2.8 <output directory>`.

private struct Labelled<Content: View>: View {
    let title: String
    let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            Text(title).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                .padding(.horizontal, DesignTokens.standard.spacing.listMargin)
            content
        }
    }
}

/// One sheet of the 0.2.8 gallery: a column of labelled examples on the window's gradient.
private struct Sheet028<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.l) { content }
            .padding(.vertical, DesignTokens.Spacing.l)
            .frame(width: DesignTokens.standard.size.columnIdeal)
            .frame(maxHeight: .infinity, alignment: .top)
            .background { WindowBackground() }
    }
}

/// The status line's 0.2.8 options (issue #32).
struct StatusLine028Sheet: View {
    var body: some View {
        Sheet028 {
            Labelled("Closed; open; closed with its chevron turned up (pulled), unfilled") {
                VStack(spacing: 0) {
                    StatusLine(tile: .initial("A"), title: "All · Inbox", count: 12, isOpen: false, fillsWhenOpen: true)
                    StatusLine(tile: .initial("A"), title: "All · Inbox", count: 12, isOpen: true, fillsWhenOpen: true)
                    StatusLine(tile: .initial("A"), title: "All · Inbox", count: 12, isOpen: false, fillsWhenOpen: true,
                               chevron: .up)
                }
            }
            Labelled("The count at the end of the line") {
                StatusLine(tile: .initial("A"), title: "All · Inbox", count: 12, isOpen: false, countPlacement: .trailing)
            }
            Labelled("A long title cut at the tail, then in the middle") {
                VStack(spacing: 0) {
                    StatusLine(tile: .initial("P"), title: "Personal · Receipts and invoices from 2026 · Inbox", count: 3,
                               isOpen: false)
                    StatusLine(tile: .initial("P"), title: "Personal · Receipts and invoices from 2026 · Inbox", count: 3,
                               isOpen: false, truncationMode: .middle)
                }
            }
            Labelled("Open and hovered: the open fill kept (default), then hoverOverOpenFill") {
                VStack(spacing: 0) {
                    StatusLine(tile: .initial("A"), title: "All · Inbox", count: 12, isOpen: true, fillsWhenOpen: true,
                               state: RowState(isHovered: true))
                    StatusLine(tile: .initial("A"), title: "All · Inbox", count: 12, isOpen: true, fillsWhenOpen: true,
                               state: RowState(isHovered: true), hoverOverOpenFill: true)
                }
            }
            Labelled("Larger text: the line grows past its 38 pt") {
                StatusLine(tile: .initial("A"), title: "All · Inbox", count: 12, isOpen: false)
                    .designTokens(Self.largeTitle)
            }
        }
    }

    static var largeTitle: DesignTokens {
        var tokens = DesignTokens.standard
        tokens.type.rowTitleEmphasized = TextRole(.title, .semibold)
        tokens.type.count = TextRole(.title3)
        return tokens
    }
}

/// A detail made of two cards (issue #31): a canvas and a reply card under it, each `sidebarDetailCard()`, in one
/// `sidebarDetailInset()`; beside it `SidebarDetail`'s single card for comparison.
struct DetailCards028Sheet: View {
    @Environment(\.designTokens) private var tokens

    var body: some View {
        HStack(spacing: 0) {
            SidebarDetail {
                Text("SidebarDetail: one card").font(.callout).foregroundStyle(.secondary)
            }
            VStack(spacing: tokens.spacing.canvasInset) {
                Text("sidebarDetailCard(): the canvas").font(.callout).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .sidebarDetailCard()
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.s) {
                    Text("Reply").font(.headline)
                    Text("A second card under it, in the same inset.").font(.callout).foregroundStyle(.secondary)
                }
                .padding(tokens.spacing.canvasInset)
                .frame(maxWidth: .infinity, alignment: .leading)
                .sidebarDetailCard()
            }
            .sidebarDetailInset()
        }
        .background { WindowBackground() }
    }
}

/// `tileFill`'s shapes and sizes (issue #35).
struct TileFill028Sheet: View {
    @Environment(\.designTokens) private var tokens

    var body: some View {
        let gap = DesignTokens.Spacing.m
        Sheet028 {
            Labelled("Kit sizes, rounded square then circle: standard, compact, small, status") {
                HStack(spacing: gap) {
                    ForEach([TileSize.standard, .compact, .small, .status], id: \.self) { size in
                        Text("A").font(tokens.type.initial.font).tileFill(size)
                    }
                    ForEach([TileSize.standard, .compact, .small, .status], id: \.self) { size in
                        Text("A").font(tokens.type.initial.font).tileFill(size, shape: .circle)
                    }
                }
                .padding(.horizontal, tokens.spacing.listMargin)
            }
            Labelled("A side of the client's: 48 pt, rounded in proportion, and round") {
                HStack(spacing: gap) {
                    Image(systemName: "person.fill").font(.title2).tileFill(.side(48))
                    Image(systemName: "person.fill").font(.title2).tileFill(.side(48), shape: .circle)
                }
                .padding(.horizontal, tokens.spacing.listMargin)
            }
            Labelled("Following the text, at least small (22 pt): A, AB, 128, then larger type") {
                HStack(spacing: gap) {
                    Text("A").font(.caption.bold()).tileFill(.fitting(minimum: .small), shape: .circle)
                    Text("AB").font(.caption.bold()).tileFill(.fitting(minimum: .small), shape: .circle)
                    Text("128").font(.caption.bold()).tileFill(.fitting(minimum: .small))
                    Text("AB").font(.title.bold()).tileFill(.fitting(minimum: .small), shape: .circle)
                    Text("AB").font(.largeTitle.bold()).tileFill(.fitting(minimum: .small))
                }
                .padding(.horizontal, tokens.spacing.listMargin)
            }
        }
    }
}

@MainActor
func run028(output: URL) {
    let sheets: [(name: String, size: CGSize, view: AnyView)] = [
        ("status-line", CGSize(width: 360, height: 560), AnyView(StatusLine028Sheet())),
        ("detail-cards", CGSize(width: 760, height: 420), AnyView(DetailCards028Sheet())),
        ("tile-fill", CGSize(width: 360, height: 300), AnyView(TileFill028Sheet())),
    ]
    do {
        for theme in [Palette.standard.themes[0], Palette.standard.themes[1]] {
            for isDark in [false, true] {
                for sheet in sheets {
                    let url = output.appending(path: "kit-0.2.8-\(sheet.name)-\(theme.id)-\(isDark ? "dark" : "light").png")
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
