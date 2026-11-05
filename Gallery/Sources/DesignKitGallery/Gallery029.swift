import AppKit
import ColorCore
import ColorUI
import DesignKit
import SwiftUI

// The 0.2.9 additions, rendered offscreen on the window's gradient, light and dark, one sheet per change.
// `DesignKitGallery 0.2.9 <output directory>`.

/// Rows side by side in one line (issue #49), beside free ones.
struct SideBySide029Sheet: View {
    private var freeInset: CGFloat {
        let spacing = DesignTokens.standard.spacing
        return spacing.listMargin - spacing.rowInsetHorizontal
    }

    private func line(_ placement: RowPlacement, spacing: CGFloat = 0) -> some View {
        HStack(spacing: spacing) {
            ListRow("Work", state: RowState(isHovered: true), placement: placement) { Tile(.initial("W"), size: .compact) }
            ListRow("Home", state: RowState(isSelected: true), placement: placement) { Tile(.initial("H"), size: .compact) }
            ListRow("News", state: RowState(isCurrent: true), placement: placement) { Tile(.initial("N"), size: .compact) }
        }
    }

    var body: some View {
        Sheet028 {
            Labelled("A free row, for the column's margin") {
                ListRow("All accounts", state: RowState(isHovered: true)) { Tile(.tintedSymbol("tray.2"), size: .compact) }
            }
            Labelled("Free rows side by side: each keeps its side inset") {
                line(.free(firstInSection: false))
            }
            Labelled(".sideBySide, no spacing: the fills touch") {
                line(.sideBySide).padding(.horizontal, freeInset)
            }
            Labelled(".sideBySide, 4 pt apart") {
                line(.sideBySide, spacing: DesignTokens.Spacing.xs).padding(.horizontal, freeInset)
            }
        }
    }
}

/// The rail's panels opened by its preview state in 300 pt columns (issue #50), then in a 360 pt one: inside the column,
/// the margin clear on both sides. Each column's edges are outlined.
struct RailPanels029Sheet: View {
    var body: some View {
        HStack(spacing: DesignTokens.Spacing.l) {
            column(SpaceRailPreviewState(panel: .spaces), width: 300)
            column(SpaceRailPreviewState(panel: .commands, panelFocus: "profile"), width: 300)
            column(SpaceRailPreviewState(panel: .spaces), width: 360)
        }
        .padding(DesignTokens.Spacing.l)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background { WindowBackground() }
    }

    private func column(_ state: SpaceRailPreviewState, width: CGFloat) -> some View {
        VStack(spacing: 0) {
            Text(verbatim: "\(Int(width)) pt").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                .padding(.top, DesignTokens.Spacing.s)
            Spacer(minLength: 0)
            SpaceRail(profiles: RailPanels028Sheet.profiles, selection: "w2", commands: RailPanels028Sheet.commands,
                      selectSpace: { _ in }, selectProfile: { _ in })
                .spaceRailPreviewState(state)
        }
        .frame(width: width)
        .overlay { Rectangle().strokeBorder(.secondary.opacity(0.5), lineWidth: 1) }
    }
}

@MainActor
func run029(output: URL) {
    let sheets: [(name: String, size: CGSize, view: AnyView)] = [
        ("side-by-side-rows", CGSize(width: 360, height: 330), AnyView(SideBySide029Sheet())),
        ("rail-panels-narrow", CGSize(width: 1040, height: 800), AnyView(RailPanels029Sheet())),
    ]
    do {
        for theme in [Palette.standard.themes[0], Palette.standard.themes[1]] {
            for isDark in [false, true] {
                for sheet in sheets {
                    let url = output.appending(path: "kit-0.2.9-\(sheet.name)-\(theme.id)-\(isDark ? "dark" : "light").png")
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
