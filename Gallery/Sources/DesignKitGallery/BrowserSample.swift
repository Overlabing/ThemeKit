import ColorCore
import DesignKit
import SwiftUI

/// A browser's main window composed from the kit, the way a mail client's is: the column of Tabs on its own surface,
/// the page in a content canvas on the window's gradient, no bar above the page. The address field and Back, Forward, Reload sit
/// where a status line sits, at the top of the column.
struct BrowserSample: View {
    @Environment(\.designTokens) private var tokens
    let side: ColumnSide
    var rail = RailSample.standard

    var body: some View {
        ColumnLayout(side: side) { column } detail: { PlaceholderPage(title: "A page") }
    }

    private var column: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: tokens.spacing.pillActionGap) {
                FieldPill(systemImage: "lock.fill", title: "example.com", placeholder: "Address")
                    .padding(.horizontal, -tokens.spacing.listMargin)
                IconButton("Back", systemImage: "chevron.left") {}
                IconButton("Forward", systemImage: "chevron.right") {}
                IconButton("Reload", systemImage: "arrow.clockwise") {}
            }
            .padding(.horizontal, tokens.spacing.listMargin)
            .padding(.bottom, tokens.spacing.statusLineToList)
            ListRow("Mail") { Tile(.symbol("envelope.fill", .blue)) }
            ListRow("Calendar") { Tile(.symbol("calendar", .red)) }
            FolderRow("Reading", count: 2, isOpen: true)
            LayerPanel {
                ListRow("Design notes", placement: .layer(level: 1)) { Tile(.symbol("doc.text.fill", .orange)) }
                ListRow("Swift Forums", placement: .layer(level: 1)) { Tile(.initial("S")) }
            }
            ColumnSeparator()
            ListRow("New Tab") { Tile(.tintedSymbol("plus")) } trailing: {
                Text(verbatim: "⌘T").font(tokens.type.count.font).foregroundStyle(.secondary)
            }
            ListRow("Swift Testing", details: ["developer.apple.com"], state: RowState(isSelected: true)) {
                Tile(.symbol("hammer.fill", .orange))
            }
            ListRow("Lo-fi beats to code to", details: ["Playing"]) { Tile(.symbol("play.rectangle.fill", .red)) } trailing: {
                Image(systemName: "speaker.wave.2.fill").font(tokens.type.accessory.font).foregroundStyle(.secondary)
            }
            ListRow("WebKit features", details: ["webkit.org"], state: RowState(isHovered: true)) {
                Tile(.symbol("safari.fill", .blue))
            }
            ListRow("Weather in Lyon", details: ["weather.example"]) { Tile(.initial("W")) }
            Spacer(minLength: 0)
            rail.rail
        }
    }
}
