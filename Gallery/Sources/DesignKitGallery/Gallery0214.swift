import AppKit
import ColorCore
import ColorUI
import DesignKit
import SwiftUI

// The 0.2.14 change: the sidebar head laid out as in Zen. `DesignKitGallery 0.2.14 <output directory>` draws a titled
// window off every display, its column under a `.unifiedCompact` toolbar with no items, per appearance: `page`, the title bar
// row with three buttons and a field with an accessory, and `empty`, a placeholder in the field and no accessory. Only
// the Increase Contrast and Reduce Transparency appearances: the pill's glass does not draw in an offscreen cached
// display, and the list under it draws nothing either; with Reduce Transparency the pill is opaque. The window's own
// buttons do not draw either, only the room the row leaves them.

private final class EmptyToolbar: NSObject, NSToolbarDelegate {
    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        NSSplitViewItem.sidebarHeadToolbarItems
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        NSSplitViewItem.sidebarHeadToolbarItems
    }
}

private struct SampleField: View {
    let text: String?
    @Environment(\.designTokens) private var tokens

    var body: some View {
        WithColorRoles { roles in
            Text(text ?? "Search or address")
                .foregroundStyle(text == nil ? AnyShapeStyle(roles.secondaryText) : AnyShapeStyle(.primary))
                .lineLimit(1)
        }
    }
}

/// A titled window the system would move onto a screen when ordered in: it stays where it is put, off every display.
private final class OffscreenWindow: NSWindow {
    override func constrainFrameRect(_ frameRect: NSRect, to screen: NSScreen?) -> NSRect { frameRect }
}

@MainActor
private func headWindow(page: Bool, isDark: Bool, increased: Bool, toolbar: EmptyToolbar) -> (NSWindow, NSSplitViewController) {
    let size = CGSize(width: 900, height: 520)
    let theme = RailCompare.theme
    let column = List {
        ForEach(["Mail", "Calendar", "Design notes", "Swift Forums"], id: \.self) { title in
            Text(title).sidebarRowCell(state: RowState(isSelected: page && title == "Calendar"))
        }
    }
    .sidebarColumn(sidebarButtonShortcut: "⌘B") {
        IconButton("Back", systemImage: "arrow.left") {}
        IconButton("Forward", systemImage: "arrow.right") {}.disabled(true)
        IconButton("Reload", systemImage: "arrow.clockwise") {}.disabled(!page)
    } field: {
        SampleField(text: page ? "example.com" : nil)
    } fieldAccessory: {
        if page {
            IconButton("Extension", systemImage: "puzzlepiece.extension") {}
            IconButton("Copy Link", systemImage: "link") {}
        }
    } header: {
        EmptyView()
    } bottomBar: {
        EmptyView()
    }
    .accessibilityOverrides(increaseContrast: increased, reduceTransparency: increased)
    .theme(theme)
    let split = SeamlessSplitViewController()
    split.addSplitViewItem(NSSplitViewItem.sidebar(hosting: column, surface: .windowBackground))
    let detail = NSHostingController(rootView: Text(page ? "A page" : "")
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sidebarDetailCard().padding(DesignTokens.standard.spacing.canvasInset)
        .accessibilityOverrides(increaseContrast: increased, reduceTransparency: increased).theme(theme))
    split.addSplitViewItem(NSSplitViewItem(viewController: detail))
    let content = NSView(frame: CGRect(origin: .zero, size: size))
    let background = NSHostingView(rootView: WindowBackground().ignoresSafeArea(.all)
        .accessibilityOverrides(increaseContrast: increased, reduceTransparency: increased).theme(theme))
    for view in [background, split.view] {
        view.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(view)
        NSLayoutConstraint.activate([
            view.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: content.trailingAnchor),
            view.topAnchor.constraint(equalTo: content.topAnchor),
            view.bottomAnchor.constraint(equalTo: content.bottomAnchor),
        ])
    }
    let window = OffscreenWindow(contentRect: CGRect(origin: CGPoint(x: -20000, y: 0), size: size),
                          styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
                          backing: .buffered, defer: false)
    window.isReleasedWhenClosed = false
    window.titlebarAppearsTransparent = true
    window.titleVisibility = .hidden
    window.toolbarStyle = .unifiedCompact
    let bar = NSToolbar(identifier: "Gallery0214")
    bar.delegate = toolbar
    window.toolbar = bar
    window.appearance = NSAppearance(named: isDark ? .darkAqua : .aqua)
    window.contentView = content
    window.setContentSize(size)
    window.setFrameOrigin(CGPoint(x: -20000, y: 0))
    // Ordered in, never key and off every display, as the other renders: a `List` draws nothing in a window that is not.
    window.orderFrontRegardless()
    guard window.frame.minX == -20000 else { fatalError("the render window reached a display: \(window.frame)") }
    return (window, split)
}

@MainActor
func run0214(output: URL) {
    let toolbar = EmptyToolbar()
    do {
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        for mode in RailCompare.modes where mode.increased {
            for (name, page) in [("page", true), ("empty", false)] {
                let (window, split) = headWindow(page: page, isDark: mode.isDark, increased: mode.increased,
                                                 toolbar: toolbar)
                // The content alone: the window's own buttons do not draw in a cached display, the gap left for them does.
                guard let frame = window.contentView else { throw CocoaError(.fileWriteUnknown) }
                for _ in 0..<8 {
                    frame.layoutSubtreeIfNeeded()
                    RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
                }
                guard let rep = frame.bitmapImageRepForCachingDisplay(in: frame.bounds) else { throw CocoaError(.fileWriteUnknown) }
                frame.cacheDisplay(in: frame.bounds, to: rep)
                let url = output.appending(path: "kit-0.2.14-head-\(name)-\(mode.name).png")
                guard let data = rep.representation(using: .png, properties: [:]) else { throw CocoaError(.fileWriteUnknown) }
                try data.write(to: url)
                window.orderOut(nil)
                window.contentView = nil
                withExtendedLifetime(split) {}
                print("OK: \(url.lastPathComponent)")
            }
        }
    } catch {
        print("FAILED: \(error)")
        exit(1)
    }
}
