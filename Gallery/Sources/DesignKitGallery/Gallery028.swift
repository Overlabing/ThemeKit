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

/// Compact rows stacked without gaps (issue #34), beside free ones.
struct StackedRows028Sheet: View {
    var body: some View {
        Sheet028 {
            Labelled("Free rows: a row gap between the fills") {
                VStack(spacing: 0) {
                    ListRow("Inbox", state: RowState(isHovered: true)) { Tile(.tintedSymbol("tray"), size: .compact) }
                    ListRow("Sent", state: RowState(isSelected: true)) { Tile(.tintedSymbol("paperplane"), size: .compact) }
                    ListRow("Drafts", state: RowState(isCurrent: true)) { Tile(.tintedSymbol("doc"), size: .compact) }
                }
            }
            Labelled(".stacked: compact rows, no gap") {
                VStack(spacing: 0) {
                    ListRow("Inbox", state: RowState(isHovered: true), placement: .stacked) {
                        Tile(.tintedSymbol("tray"), size: .compact)
                    }
                    ListRow("Sent", state: RowState(isSelected: true), placement: .stacked) {
                        Tile(.tintedSymbol("paperplane"), size: .compact)
                    }
                    ListRow("Drafts", state: RowState(isCurrent: true), placement: .stacked) {
                        Tile(.tintedSymbol("doc"), size: .compact)
                    }
                }
            }
        }
    }
}

/// Skeleton rows as sidebar `List` cells, three lines, then the stack of two (issue #33). Hosted: a `List` draws only in
/// a window.
struct Skeleton028Sheet: View {
    var body: some View {
        HStack(spacing: 0) {
            List {
                Section {
                    SkeletonRows(count: 4, label: "Loading mail", lines: 3, placement: .free(firstInSection: true),
                                 style: .sidebarCells)
                } header: {
                    Text("sidebarCells, 3 lines").font(.caption.weight(.semibold))
                }
            }
            .sidebarColumn()
            .frame(width: 360)
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text("stack, 2 lines (the default)").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                    .padding(.horizontal, DesignTokens.standard.spacing.listMargin)
                SkeletonRows(count: 4, label: "Loading")
                Spacer(minLength: 0)
            }
            .padding(.top, DesignTokens.Spacing.l)
            .frame(width: 360)
        }
        .background { WindowBackground() }
    }
}

/// The rail's panels opened by its preview state (issue #37), at the bottom of a column: the `+` panel with a focused
/// row, then the "+n" panel.
struct RailPanels028Sheet: View {
    static let commands = [
        [SpaceRailCommand(id: "space", title: "New Space in Work…", systemImage: "plus"),
         SpaceRailCommand(id: "profile", title: "New Profile…", systemImage: "person.crop.circle.badge.plus")],
        [SpaceRailCommand(id: "edit", title: "Edit Spaces and Profiles…", systemImage: "pencil")],
    ]
    static let themes = Palette.standard.themes
    static let profiles = [
        SpaceRailProfile(id: "work", name: "Work", emoji: "💼", spaces: (1...8).map {
            SpaceRailSpace(id: "w\($0)", name: "Work \($0)", theme: themes[$0 % themes.count], shortcut: "⌃\($0)")
        }),
        SpaceRailProfile(id: "home", name: "Personal", emoji: "🏡", spaces: [
            SpaceRailSpace(id: "h1", name: "Home", glyph: .emoji("🏡"), theme: themes[4]),
            SpaceRailSpace(id: "h2", name: "Reading", glyph: .symbol("books.vertical"), theme: themes[2]),
        ]),
    ]

    var body: some View {
        HStack(spacing: 0) {
            column(SpaceRailPreviewState(panel: .commands, panelFocus: "profile"))
            column(SpaceRailPreviewState(panel: .spaces))
        }
        .background { WindowBackground() }
    }

    private func column(_ state: SpaceRailPreviewState) -> some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            SpaceRail(profiles: Self.profiles, selection: "w2", commands: Self.commands, selectSpace: { _ in },
                      selectProfile: { _ in })
                .spaceRailPreviewState(state)
        }
        .frame(width: 330)
    }
}

/// A banner at narrow widths (issue #44): at 300 pt the action goes under the message and the host breaks at a dot;
/// at 560 pt the action stays beside it.
struct BannerNarrow028Sheet: View {
    static let message = "Could not reach imap.mail.averyverylonghostname.example.com"

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.l) {
            Labelled("300 pt: the action under the message, the host broken at a dot") {
                Banner(systemImage: "exclamationmark.triangle", title: "Not connected", message: Self.message,
                       action: BannerAction("Try Again") {}, onClose: {})
                    .frame(width: 300)
                    .padding(.horizontal, DesignTokens.standard.spacing.listMargin)
            }
            Labelled("300 pt, no title, the client's own action") {
                Banner(systemImage: "wifi.exclamationmark", message: Self.message) {
                    Button("Try Again") {}.controlSize(.small)
                }
                .frame(width: 300)
                .padding(.horizontal, DesignTokens.standard.spacing.listMargin)
            }
            Labelled("560 pt: beside the message, as before") {
                Banner(systemImage: "exclamationmark.triangle", title: "Not connected", message: Self.message,
                       action: BannerAction("Try Again") {}, onClose: {})
                    .frame(width: 560)
                    .padding(.horizontal, DesignTokens.standard.spacing.listMargin)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, DesignTokens.Spacing.l)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background { WindowBackground() }
    }
}

@MainActor
func run028(output: URL) {
    let sheets: [(name: String, size: CGSize, view: AnyView)] = [
        ("status-line", CGSize(width: 360, height: 560), AnyView(StatusLine028Sheet())),
        ("detail-cards", CGSize(width: 760, height: 420), AnyView(DetailCards028Sheet())),
        ("tile-fill", CGSize(width: 360, height: 300), AnyView(TileFill028Sheet())),
        ("stacked-rows", CGSize(width: 360, height: 330), AnyView(StackedRows028Sheet())),
        ("rail-panels", CGSize(width: 660, height: 760), AnyView(RailPanels028Sheet())),
        ("banner-narrow", CGSize(width: 600, height: 420), AnyView(BannerNarrow028Sheet())),
    ]
    let hosted: [(name: String, size: CGSize, view: AnyView)] = [
        ("skeleton", CGSize(width: 720, height: 420), AnyView(Skeleton028Sheet())),
    ]
    do {
        for theme in [Palette.standard.themes[0], Palette.standard.themes[1]] {
            for isDark in [false, true] {
                for sheet in sheets {
                    let url = output.appending(path: "kit-0.2.8-\(sheet.name)-\(theme.id)-\(isDark ? "dark" : "light").png")
                    try renderView(sheet.view.theme(theme), size: sheet.size, isDark: isDark, to: url)
                    print("OK: \(url.lastPathComponent)")
                }
                for sheet in hosted {
                    let url = output.appending(path: "kit-0.2.8-\(sheet.name)-\(theme.id)-\(isDark ? "dark" : "light").png")
                    try renderHosted(sheet.view.theme(theme), size: sheet.size, isDark: isDark, to: url)
                    print("OK: \(url.lastPathComponent)")
                }
            }
        }
    } catch {
        print("FAILED: \(error)")
        exit(1)
    }
}
