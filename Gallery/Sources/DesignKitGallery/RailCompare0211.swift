import AppKit
import ColorCore
import ColorUI
import DesignKit
import SwiftUI

// The Space rail in one strip per state, for a before and after comparison of 0.2.11: three Spaces (a house, sparkles,
// a briefcase), the house current; idle, hovering another Space, and with the keyboard focus on one. It uses only API
// that 0.2.10 has too, so the same sheet renders against either version. Drawn in a borderless window off every
// screen (x −20000), ordered front without becoming key or active, in the window's own appearance.

enum RailCompare {
    static let spaces = [
        SpaceRailSpace(id: "home", name: "Home", glyph: .symbol("house.fill"), theme: RailSample.theme["orange-pink"]!,
                       shortcut: "⌃1"),
        SpaceRailSpace(id: "ideas", name: "Ideas", glyph: .symbol("sparkles"), theme: RailSample.theme["purple-pink"]!,
                       shortcut: "⌃2"),
        SpaceRailSpace(id: "pro", name: "Pro", glyph: .symbol("briefcase.fill"), theme: RailSample.theme["indigo-blue"]!,
                       shortcut: "⌃3"),
    ]
    static let theme = RailSample.theme["orange-pink"]!
    static let modes: [(name: String, isDark: Bool, increased: Bool)] = [
        ("light", false, false), ("dark", true, false), ("light-contrast", false, true), ("dark-contrast", true, true),
    ]
    static let size = CGSize(width: 392, height: 380)
}

struct RailCompareSheet: View {
    let title: String

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.l) {
            // Takes the window's first focus, so that no rail is focused by the window alone (0.2.10 shows the
            // window's focus in a preview).
            Color.clear.frame(width: 1, height: 1).focusable()
            Text(title).font(.headline)
            strip("Idle: nothing hovered or focused", SpaceRailPreviewState())
            strip("Hovering Ideas", SpaceRailPreviewState(hovered: .space("ideas")))
            strip("Keyboard focus on Pro", SpaceRailPreviewState(focused: .space("pro")))
        }
        .padding(DesignTokens.Spacing.l)
        .frame(width: RailCompare.size.width, height: RailCompare.size.height, alignment: .topLeading)
        .background { WindowBackground() }
    }

    private func strip(_ label: String, _ state: SpaceRailPreviewState) -> some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
            Text(label).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            SpaceRail(spaces: RailCompare.spaces, selection: "home", commands: RailSample.spaceCommands,
                      selectSpace: { _ in })
                .spaceRailPreviewState(state)
                .frame(width: DesignTokens.standard.size.columnIdeal)
        }
    }
}

/// Draws `view` in a borderless window at x −20000, ordered front without becoming key or active, its appearance set
/// on the window (`.aqua` or `.darkAqua`), and saves what the window shows.
@MainActor
func renderOffscreenWindow(_ view: some View, size: CGSize, isDark: Bool, to url: URL) throws {
    _ = NSApplication.shared
    let hosting = NSHostingView(
        rootView: view.designTokens(.standard).environment(\.glassRendering, .material)
            .frame(width: size.width, height: size.height))
    let window = NSWindow(
        contentRect: CGRect(x: -20000, y: 0, width: size.width, height: size.height), styleMask: [.borderless],
        backing: .buffered, defer: false)
    window.isReleasedWhenClosed = false
    window.appearance = NSAppearance(named: isDark ? .darkAqua : .aqua)
    window.contentView = hosting
    window.orderFrontRegardless()
    defer {
        window.orderOut(nil)
        window.contentView = nil
    }
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
    guard let data = try draw().representation(using: .png, properties: [:]) else {
        throw CocoaError(.fileWriteUnknown, userInfo: [NSFilePathErrorKey: url.path])
    }
    try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    try data.write(to: url)
}

/// One sheet per appearance: `<prefix>-<light|dark|light-contrast|dark-contrast>.png`.
@MainActor
func runRailCompare(output: URL, prefix: String, title: String) throws {
    for mode in RailCompare.modes {
        let url = output.appending(path: "\(prefix)-\(mode.name).png")
        try renderOffscreenWindow(
            RailCompareSheet(title: title)
                .accessibilityOverrides(increaseContrast: mode.increased, reduceTransparency: mode.increased)
                .theme(RailCompare.theme),
            size: RailCompare.size, isDark: mode.isDark, to: url)
        print("OK: \(url.lastPathComponent)")
    }
}
