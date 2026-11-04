import AppKit
import ColorCore
import ColorUI
import DesignKit
import SwiftUI

// The 0.2.4 additions, rendered offscreen: the controls (banner, status line, buttons, pill, glyph sizes, fills,
// accent inks, a tall panel) and a real `List` of rows, hosted in a window that is never shown.
// `DesignKitGallery client <output directory>`.

private struct Captioned<Content: View>: View {
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

/// The new controls on a list column's surface, for the window's Theme in one appearance.
struct ClientControlsSheet: View {
    @Environment(\.designTokens) private var tokens
    @Environment(\.theme) private var theme
    @Environment(\.colorScheme) private var scheme
    @Environment(\.kitContrastForGallery) private var increased
    @State private var mode = "grid"

    var body: some View {
        let appearance = Appearance(isDark: scheme == .dark, isIncreasedContrast: increased)
        let roles = ColorRoles(theme: theme ?? Palette.standard.themes[0], tokens: tokens, appearance: appearance, placement: .column)
        HStack(alignment: .top, spacing: DesignTokens.Spacing.xl) {
            column {
                Captioned("Banner: title, message, action, close") {
                    Banner(systemImage: "wifi.exclamationmark", title: "You are offline",
                           message: "Changes are kept and sent when you are back.",
                           action: BannerAction("Retry") {}, onClose: {})
                        .padding(.horizontal, tokens.spacing.listMargin)
                }
                Captioned("Banner: message and close") {
                    Banner(systemImage: "checkmark.circle", message: "Moved to Archive.", onClose: {})
                        .padding(.horizontal, tokens.spacing.listMargin)
                }
                Captioned("Banner: close focused") {
                    Banner(systemImage: "checkmark.circle", title: "Saved", message: "Draft kept in Drafts.",
                           action: BannerAction("Undo") {}, onClose: {})
                        .controlFocusPreview()
                        .padding(.horizontal, tokens.spacing.listMargin)
                }
                Captioned("Banner: the original, the client's own actions") {
                    Banner(systemImage: "wifi.exclamationmark", message: "Offline. Changes are kept and sent later.") {
                        Button("Retry") {}.controlSize(.small)
                    }
                        .padding(.horizontal, tokens.spacing.listMargin)
                }
                Captioned("Status line: closed, open, open with the open fill, hovered") {
                    VStack(spacing: 0) {
                        StatusLine(tile: .initial("A"), title: "All · Inbox", count: 12, isOpen: false)
                        StatusLine(tile: .initial("A"), title: "All · Inbox", count: 12, isOpen: true)
                        StatusLine(tile: .initial("A"), title: "All · Inbox", count: 12, isOpen: true, fillsWhenOpen: true)
                        StatusLine(tile: .initial("A"), title: "All · Inbox", count: 12, isOpen: false,
                                   fillsWhenOpen: true, state: RowState(isHovered: true))
                    }
                }
                Captioned("Status line: the client's own tile, a 20 pt square") {
                    VStack(spacing: 0) {
                        StatusLine(title: "Personal · iCloud", count: 4, isOpen: true, fillsWhenOpen: true) {
                            Image(systemName: "icloud.fill").foregroundStyle(.white)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(Color.blue, in: RoundedRectangle(cornerRadius: tokens.radius.statusTile, style: .continuous))
                        }
                        StatusLine(title: "Work · Exchange", isOpen: false) {
                            Text("W").font(.caption.bold()).tileFill(.status)
                        }
                    }
                }
            }
            column {
                Captioned("Segmented pill: List, Grid, Map") {
                    SegmentedPill(
                        [SegmentedPillItem(id: "list", title: "List", systemImage: "list.bullet"),
                         SegmentedPillItem(id: "grid", title: "Grid", systemImage: "square.grid.2x2"),
                         SegmentedPillItem(id: "map", title: "Map", systemImage: "map")],
                        selection: $mode, label: "View")
                        .padding(.horizontal, tokens.spacing.listMargin)
                }
                Captioned("Segmented pill: titles only, first selected") {
                    SegmentedPill(
                        [SegmentedPillItem(id: "all", title: "All"), SegmentedPillItem(id: "unread", title: "Unread"),
                         SegmentedPillItem(id: "flagged", title: "Flagged")],
                        selection: .constant("all"), label: "Filter")
                        .padding(.horizontal, tokens.spacing.listMargin)
                }
                Captioned("Segmented pill: disabled, and focused") {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.m) {
                        SegmentedPill(
                            [SegmentedPillItem(id: "all", title: "All"), SegmentedPillItem(id: "unread", title: "Unread")],
                            selection: .constant("unread"), label: "Filter")
                            .disabled(true)
                        SegmentedPill(
                            [SegmentedPillItem(id: "all", title: "All"), SegmentedPillItem(id: "unread", title: "Unread")],
                            selection: .constant("all"), label: "Filter")
                            .controlFocusPreview()
                    }
                    .padding(.horizontal, tokens.spacing.listMargin)
                    .padding(.vertical, DesignTokens.Spacing.xs)
                }
                Captioned("Icon button: symbol, label only, disabled, focused") {
                    HStack(spacing: DesignTokens.Spacing.m) {
                        IconButton("Back", systemImage: "arrow.left") {}
                        IconButton("Mark all read") {}
                        IconButton("Done") {}.disabled(true)
                        IconButton("Edit") {}.controlFocusPreview()
                        IconButton("Forward", systemImage: "arrow.right") {}.controlFocusPreview()
                    }
                    .padding(.horizontal, tokens.spacing.listMargin)
                    .padding(.vertical, DesignTokens.Spacing.xs)
                }
                Captioned("Theme glyph: standard 24 pt, small 16 pt") {
                    HStack(spacing: DesignTokens.Spacing.s) {
                        ThemeGlyph(name: "Work", symbol: "briefcase")
                        ThemeGlyph(name: "Home")
                        ThemeGlyph(name: "Work", symbol: "briefcase", size: .small)
                        ThemeGlyph(name: "Home", size: .small)
                    }
                    .padding(.horizontal, tokens.spacing.listMargin)
                }
                Captioned("Fill modifiers: tileFill on four sizes, badgeFill") {
                    HStack(spacing: DesignTokens.Spacing.s) {
                        Text("AB").font(tokens.type.initial.font).tileFill()
                        Image(systemName: "paperplane").tileFill(.compact)
                        Text("C").font(tokens.type.initial.font).tileFill(.small)
                        Text("D").font(tokens.type.glyphCircleSmall.font).tileFill(.status)
                        Text("12").font(tokens.type.count.font).badgeFill()
                        Text("Draft").font(tokens.type.count.font).badgeFill()
                    }
                    .padding(.horizontal, tokens.spacing.listMargin)
                }
                Captioned("Accent text inks by index (12), 4.5:1 on the column") {
                    VStack(alignment: .leading, spacing: DesignTokens.Spacing.xxs) {
                        ForEach(0..<6, id: \.self) { row in
                            HStack(spacing: DesignTokens.Spacing.m) {
                                ForEach(0..<2, id: \.self) { side in
                                    let index = row * 2 + side
                                    HStack(spacing: DesignTokens.Spacing.xs) {
                                        Circle().fill(roles.accentHue(at: index).color).frame(width: tokens.size.dot, height: tokens.size.dot)
                                        Text("Account \(index) · \(roles.accentHue(at: index).rawValue)")
                                            .role(tokens.type.rowTitle).foregroundStyle(roles.accentInk(at: index))
                                    }
                                    .frame(width: 160, alignment: .leading)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, tokens.spacing.listMargin)
                }
            }
        }
        .padding(DesignTokens.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background { WindowBackground() }
    }

    private func column<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        ColumnSurface {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.l) { content() }
                .frame(width: tokens.size.columnIdeal)
                .padding(.bottom, DesignTokens.Spacing.l)
        }
        .frame(maxHeight: .infinity, alignment: .top)
    }
}

extension EnvironmentValues {
    @Entry var kitContrastForGallery: Bool = false
}

/// The Space rail's panel with 8 + 8 Spaces: capped at `railPanelMaxHeight` and scrolling, over the same panel with
/// three, which is as tall as its rows.
struct TallPanelSheet: View {
    @Environment(\.designTokens) private var tokens

    var body: some View {
        let tall = RailSample.withProfiles(8, other: RailSample.personalEight, selection: "work")
        let short = RailSample.withProfiles(3, selection: "work")
        HStack(alignment: .top, spacing: DesignTokens.Spacing.xl) {
            Captioned("\"+n\" with 8 + 8: capped at \(Int(tokens.size.railPanelMaxHeight)) pt, scrolls") {
                PanelLookalike(sample: tall, focus: "ops")
            }
            Captioned("\"+n\" with 3 + 3: as tall as its rows") {
                PanelLookalike(sample: short)
            }
        }
        .padding(DesignTokens.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background { WindowBackground() }
    }
}

/// A real `List` of rows: each row is a `ListRow` with `ListRowBackground` as its cell background.
struct ListCellsSheet: View {
    @Environment(\.designTokens) private var tokens
    @Environment(\.theme) private var theme

    var body: some View {
        let states: [(String, [String], RowState)] = [
            ("Plain", ["A detail line"], RowState()),
            ("Hovered", ["A detail line"], RowState(isHovered: true)),
            ("Current", ["A detail line"], RowState(isCurrent: true)),
            ("Selected", ["A detail line"], RowState(isSelected: true)),
            ("Selected, focused", ["A detail line"], RowState(isSelected: true, isFocused: true)),
        ]
        List {
            ForEach(states, id: \.0) { title, details, state in
                ListRowContent(title, details: details, state: state) {
                    Text(title.prefix(1)).font(tokens.type.initial.font).tileFill()
                } trailing: {
                    Text("3").font(tokens.type.count.font).badgeFill()
                }
                .listRowCell(state: state)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .padding(.top, tokens.spacing.columnTop)
        .frame(width: tokens.size.columnIdeal)
        .background(.background.opacity(tokens.emphasis.column(isDark: false)))
        .frame(width: tokens.size.columnIdeal + 2 * tokens.spacing.columnInset)
        .background { WindowBackground() }
    }
}

/// Draws `view` in a window that is never shown (a real `List` draws only so), with the window's own appearance.
@MainActor
func renderHosted(_ view: some View, size: CGSize, isDark: Bool, to url: URL) throws {
    _ = NSApplication.shared
    let hosting = NSHostingView(
        rootView: view.designTokens(.standard).environment(\.glassRendering, .material)
            .frame(width: size.width, height: size.height))
    hosting.frame = CGRect(origin: .zero, size: size)
    let window = NSWindow(contentRect: hosting.frame, styleMask: [.borderless], backing: .buffered, defer: false)
    window.isReleasedWhenClosed = false
    window.appearance = NSAppearance(named: isDark ? .darkAqua : .aqua)
    window.contentView = hosting
    func draw() throws -> NSBitmapImageRep {
        hosting.layoutSubtreeIfNeeded()
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.6))
        hosting.layoutSubtreeIfNeeded()
        guard let rep = hosting.bitmapImageRepForCachingDisplay(in: hosting.bounds) else {
            throw CocoaError(.fileWriteUnknown, userInfo: [NSFilePathErrorKey: url.path])
        }
        hosting.cacheDisplay(in: hosting.bounds, to: rep)
        return rep
    }
    _ = try draw()
    let rep = try draw()
    guard let data = rep.representation(using: .png, properties: [:]) else {
        throw CocoaError(.fileWriteUnknown, userInfo: [NSFilePathErrorKey: url.path])
    }
    try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    try data.write(to: url)
    window.contentView = nil
}

@MainActor
func runClient(output: URL) {
    do {
        var files: [URL] = []
        for theme in Sample.themes {
            for isDark in [false, true] {
                let mode = isDark ? "dark" : "light"
                for increased in [false, true] {
                    let suffix = increased ? "-contrast-transparency" : ""
                    let sheet = output.appending(path: "kit-0.2.4-controls-\(theme.id)-\(mode)\(suffix).png")
                    try renderView(
                        ClientControlsSheet().environment(\.kitContrastForGallery, increased)
                            .accessibilityOverrides(increaseContrast: increased, reduceTransparency: increased).theme(theme),
                        size: CGSize(width: 860, height: 900), isDark: isDark, to: sheet)
                    files.append(sheet)
                    print("OK: \(sheet.lastPathComponent)")
                    let list = output.appending(path: "kit-0.2.4-list-cells-\(theme.id)-\(mode)\(increased ? "-contrast" : "").png")
                    try renderHosted(
                        ListCellsSheet().accessibilityOverrides(increaseContrast: increased).theme(theme),
                        size: CGSize(width: 372, height: 340), isDark: isDark, to: list)
                    files.append(list)
                    print("OK: \(list.lastPathComponent)")
                }
                let panel = output.appending(path: "kit-0.2.4-panel-scroll-\(theme.id)-\(mode).png")
                try renderHosted(TallPanelSheet().theme(theme), size: CGSize(width: 760, height: 600), isDark: isDark, to: panel)
                files.append(panel)
                print("OK: \(panel.lastPathComponent)")
            }
        }
    } catch {
        print("FAILED: \(error)")
        exit(1)
    }
}
