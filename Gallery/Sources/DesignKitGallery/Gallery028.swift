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

@MainActor
func run028(output: URL) {
    let sheets: [(name: String, size: CGSize, view: AnyView)] = [
        ("status-line", CGSize(width: 360, height: 560), AnyView(StatusLine028Sheet())),
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
