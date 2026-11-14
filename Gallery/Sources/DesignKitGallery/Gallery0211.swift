import AppKit
import ColorCore
import ColorUI
import DesignKit
import SwiftUI

// The 0.2.11 changes: the Space rail after (`RailCompareSheet`), and the focus ring after a click and after a navigation
// key, on the rail and on sidebar rows. `DesignKitGallery 0.2.11 <output directory>`.

/// The same focused rail and rows, once as a click leaves them (no ring; the rail's caption names the current Space)
/// and once as Tab or an arrow does (the ring; the caption names the focused Space). The app's code is the same in
/// both: it passes its focus as it is, the kit decides from the last input (`FocusInputTracker`).
struct FocusSheet0211: View {
    let clicked: FocusInputTracker
    let keyboard: FocusInputTracker

    init() {
        clicked = FocusInputTracker()
        clicked.record(.pointer)
        keyboard = FocusInputTracker()
        keyboard.record(.keyboard)
    }

    private func rail(_ tracker: FocusInputTracker) -> some View {
        SpaceRail(spaces: RailCompare.spaces, selection: "home", commands: RailSample.spaceCommands, selectSpace: { _ in })
            .spaceRailPreviewState(SpaceRailPreviewState(focused: .space("pro")))
            .focusInputTracker(tracker)
            .frame(width: DesignTokens.standard.size.columnIdeal)
    }

    private func rows(_ tracker: FocusInputTracker) -> some View {
        VStack(spacing: 0) {
            ListRow("Inbox", state: RowState(isHovered: false)) { Tile(.tintedSymbol("tray"), size: .compact) }
            ListRow("Release notes", state: RowState(isSelected: true, isFocused: true)) {
                Tile(.initial("R"), size: .compact)
            }
            ListRow("Archive") { Tile(.tintedSymbol("archivebox"), size: .compact) }
        }
        .focusInputTracker(tracker)
    }

    var body: some View {
        Sheet028 {
            Labelled("Rail focused by a click on Pro: no ring, the caption names Home") { rail(clicked) }
            Labelled("Rail focused from the keyboard: the ring, the caption names Pro") { rail(keyboard) }
            Labelled("Sidebar row clicked (Release notes): no ring") { rows(clicked) }
            Labelled("Sidebar row focused from the keyboard: the ring") { rows(keyboard) }
        }
    }
}

@MainActor
func run0211(output: URL) {
    do {
        try runRailCompare(output: output, prefix: "kit-0.2.11-rail-after", title: "0.2.11")
        for mode in RailCompare.modes {
            let url = output.appending(path: "kit-0.2.11-focus-\(mode.name).png")
            try renderOffscreenWindow(
                FocusSheet0211()
                    .accessibilityOverrides(increaseContrast: mode.increased, reduceTransparency: mode.increased)
                    .theme(RailCompare.theme),
                size: CGSize(width: 360, height: 520), isDark: mode.isDark, to: url)
            print("OK: \(url.lastPathComponent)")
        }
    } catch {
        print("FAILED: \(error)")
        exit(1)
    }
}
