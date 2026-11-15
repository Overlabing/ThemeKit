import AppKit
import ColorCore
import ColorUI
import DesignKit
import SwiftUI

// The 0.2.13 change: an AppKit sidebar on the window's own background. `DesignKitGallery 0.2.13 <output directory>`
// draws the same window twice per appearance, offscreen: `system`, the default system sidebar item, and `window`, the
// column on `.windowBackground` in a `SeamlessSplitViewController`. The system's material does not render offscreen,
// so `system` shows the column's place, not its tone: compare the divider and the column's edge.

@MainActor
private func sidebarWindow(surface: SidebarSurface, isDark: Bool, increased: Bool) -> (NSWindow, NSView, NSSplitViewController) {
    let size = CGSize(width: 900, height: 520)
    let theme = RailCompare.theme
    let column = List {
        ForEach(["Mail", "Calendar", "Design notes", "Swift Forums"], id: \.self) { title in
            Text(title).sidebarRowCell(state: RowState(isSelected: title == "Calendar"))
        }
    }
    .sidebarColumn()
    .accessibilityOverrides(increaseContrast: increased, reduceTransparency: increased)
    .theme(theme)
    let split = surface == .windowBackground ? SeamlessSplitViewController() : NSSplitViewController()
    split.addSplitViewItem(NSSplitViewItem.sidebar(hosting: column, surface: surface))
    let detail = NSHostingController(rootView: Text("A page").frame(maxWidth: .infinity, maxHeight: .infinity)
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
    let window = NSWindow(contentRect: CGRect(origin: CGPoint(x: -20000, y: 0), size: size), styleMask: [.borderless],
                          backing: .buffered, defer: false)
    window.isReleasedWhenClosed = false
    window.appearance = NSAppearance(named: isDark ? .darkAqua : .aqua)
    window.contentView = content
    window.orderFrontRegardless()
    return (window, content, split)
}

@MainActor
func run0213(output: URL) {
    do {
        try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
        for mode in RailCompare.modes {
            for (name, surface) in [("system", SidebarSurface.systemMaterial), ("window", .windowBackground)] {
                let (window, content, split) = sidebarWindow(surface: surface, isDark: mode.isDark, increased: mode.increased)
                content.layoutSubtreeIfNeeded()
                RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.8))
                content.layoutSubtreeIfNeeded()
                guard let rep = content.bitmapImageRepForCachingDisplay(in: content.bounds) else { throw CocoaError(.fileWriteUnknown) }
                content.cacheDisplay(in: content.bounds, to: rep)
                let url = output.appending(path: "kit-0.2.13-sidebar-\(name)-\(mode.name).png")
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
