import ColorCore
import ColorUI
import DesignKit
import SwiftUI

// Gallery content: every view of the kit with neutral sample content, a column composed from them, and a browser's
// main window composed the same way.

enum Sample {
    static let themes = [Palette.standard.themes[0], Palette.standard.themes[2]]
}

/// A neutral page standing for content.
struct PlaceholderPage: View {
    @Environment(\.colorScheme) private var scheme
    var title = "Content"

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title).font(.system(size: 30, weight: .bold, design: .serif)).foregroundStyle(.secondary)
            ForEach(Array([1.0, 0.92, 0.96, 0.55, 0, 0.98, 0.9, 0.4].enumerated()), id: \.offset) { _, share in
                GeometryReader { proxy in
                    Capsule().fill(Color.primary.opacity(share == 0 ? 0 : 0.08)).frame(width: proxy.size.width * share, height: 10)
                }
                .frame(height: 10)
            }
            Spacer()
        }
        .padding(48)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(scheme == .dark ? Color(white: 0.12) : .white)
    }
}

/// A list column composed from the kit: status line, a folder open on its panel, sections of rows, the switcher.
struct SampleColumn: View {
    @Environment(\.designTokens) private var tokens

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            StatusLine(tile: .tintedSymbol("tray.full"), title: "Work · Inbox", count: 4, isOpen: false)
                .padding(.bottom, tokens.spacing.statusLineToList)
            FolderRow("Projects", count: 2, isOpen: true)
            LayerPanel {
                ListRow("Roadmap", state: RowState(isCurrent: true), placement: .layer(level: 1)) {
                    Tile(.symbol("map.fill", .orange))
                }
                ListRow("Reviews", placement: .layer(level: 2)) { Tile(.initial("R")) }
            }
            SectionHeader("Today").padding(.top, tokens.spacing.listMargin)
            ListRow("Selected item", details: ["Second line", "Third line, quieter"], state: RowState(isSelected: true),
                    placement: .free(firstInSection: true)) {
                Tile(.symbol("star.fill", .yellow))
            }
            ListRow("Hovered item", details: ["A detail line"], state: RowState(isHovered: true)) { Tile(.initial("H")) }
            ListRow("Focused item", details: ["A detail line"], state: RowState(isFocused: true)) {
                Tile(.symbol("globe", .blue))
            }
            ColumnSeparator()
            ListRow("Plain item", details: ["A detail line"]) { Tile(.tintedSymbol("doc.text")) }
            Spacer(minLength: 0)
            RailSample.standard.rail
        }
    }
}

struct CompositionSheet: View {
    let side: ColumnSide

    var body: some View {
        ColumnLayout(side: side) { SampleColumn() } detail: { PlaceholderPage() }
    }
}

/// Every view with its states.
struct ComponentSheet: View {
    @Environment(\.designTokens) private var tokens

    var body: some View {
        HStack(alignment: .top, spacing: DesignTokens.Spacing.xl) {
            VStack(alignment: .leading, spacing: 0) {
                SectionHeader("Rows", isGroupHeader: true).padding(.bottom, tokens.spacing.sectionHeaderBottom)
                ListRow("Plain") { Tile(.symbol("star.fill", .yellow)) }
                ListRow("Hovered", state: RowState(isHovered: true)) { Tile(.initial("H")) }
                ListRow("Current", state: RowState(isCurrent: true)) { Tile(.tintedSymbol("bookmark")) }
                ListRow("Selected", state: RowState(isSelected: true)) { Tile(.tintedSymbol("bookmark.fill")) }
                ListRow("Selected, focused", state: RowState(isSelected: true, isFocused: true)) {
                    Tile(.tintedSymbol("bookmark.fill"))
                }
                FolderRow("Folder, closed", count: 12, isOpen: false)
                FolderRow("Folder, open", isOpen: true)
                LayerPanel {
                    ListRow("First level", placement: .layer(level: 1)) { Tile(.initial("F")) }
                    ListRow("Second level", state: RowState(isSelected: true), placement: .layer(level: 2)) {
                        Tile(.initial("S"))
                    }
                }
                ColumnSeparator()
                SkeletonRows(count: 2, label: "Loading")
            }
            .frame(width: tokens.size.columnIdeal)
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.l) {
                SectionHeader("Controls", isGroupHeader: true)
                StatusLine(tile: .initial("A"), title: "All · Inbox", count: 12, isOpen: true)
                FieldPill(systemImage: "magnifyingglass", title: "", placeholder: "Search")
                FieldPill(systemImage: "at", title: "Everything", placeholder: "Account") {
                    Image(systemName: "chevron.up.chevron.down").font(tokens.type.accessory.font).foregroundStyle(.secondary)
                }
                IconButtonRow {
                    IconButton("Toggle Column", systemImage: "sidebar.left") {}
                } trailing: {
                    IconButton("Back", systemImage: "arrow.left") {}
                    IconButton("Forward", systemImage: "arrow.right") {}.disabled(true)
                }
                HStack(spacing: DesignTokens.Spacing.s) {
                    Tile(.symbol("envelope.fill", .blue))
                    Tile(.tintedSymbol("folder"), size: .compact)
                    Tile(.initial("S"), size: .small)
                    Tile(.symbol("music.note", .pink), size: .status)
                    ThemeGlyph(name: "Work", symbol: "briefcase")
                    ThemeGlyph(name: "Home")
                }
                .padding(.horizontal, tokens.spacing.listMargin)
                Banner(systemImage: "wifi.exclamationmark", message: "Offline. Changes are kept and sent later.") {
                    Button("Retry") {}.controlSize(.small)
                }
                .padding(.horizontal, tokens.spacing.listMargin)
                RailSample.standard.rail
            }
            .frame(width: tokens.size.columnIdeal)
        }
        .padding(DesignTokens.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background { WindowBackground() }
    }
}
