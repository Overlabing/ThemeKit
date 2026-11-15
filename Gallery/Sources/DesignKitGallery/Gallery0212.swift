import AppKit
import ColorCore
import ColorUI
import DesignKit
import SwiftUI

// The 0.2.12 changes: the keyboard focus ring (none on a selected row, a thin ring in the Theme's hue inside any other
// focused element) and the full screen window chrome of an AppKit sidebar window. `DesignKitGallery 0.2.12 <output
// directory>` renders the focus sheets offscreen. `DesignKitGallery fullscreen <output directory> <variant>
// <light|dark>` puts a real window in full screen twice and captures the display: the toolbar hidden until the pointer
// reaches the top (`hidden`), and the toolbar always shown (`pinned`), which is the band the pointer reveals. It takes
// the whole screen for about fifteen seconds, so run it only when nobody is using the Mac.

/// The rows and the rail focused from the keyboard, as an app passes them: `isFocused` from its `@FocusState`, the kit
/// decides the rest.
struct FocusSheet0212: View {
    let keyboard: FocusInputTracker

    init() {
        keyboard = FocusInputTracker()
        keyboard.record(.keyboard)
    }

    private func rows(selectedFocused: Bool) -> some View {
        VStack(spacing: 0) {
            ListRow("Inbox") { Tile(.tintedSymbol("tray"), size: .compact) }
            ListRow("Release notes", state: RowState(isSelected: true, isFocused: selectedFocused)) {
                Tile(.initial("R"), size: .compact)
            }
            ListRow("Archive", state: RowState(isFocused: !selectedFocused)) {
                Tile(.tintedSymbol("archivebox"), size: .compact)
            }
        }
        .focusInputTracker(keyboard)
    }

    private func rail(_ focused: String) -> some View {
        SpaceRail(spaces: RailCompare.spaces, selection: "home", commands: RailSample.spaceCommands, selectSpace: { _ in })
            .spaceRailPreviewState(SpaceRailPreviewState(focused: .space(focused)))
            .focusInputTracker(keyboard)
            .frame(width: DesignTokens.standard.size.columnIdeal)
    }

    var body: some View {
        Sheet028 {
            Labelled("Selected row focused (Release notes): no ring, the selection shows it") { rows(selectedFocused: true) }
            Labelled("Unselected row focused (Archive): a thin ring in the Theme's hue") { rows(selectedFocused: false) }
            Labelled("Rail focused on Pro: the ring inside the target") { rail("pro") }
            Labelled("Rail focused on the current Space (Home): the ring too") { rail("home") }
        }
    }
}

@MainActor
func run0212(output: URL) {
    do {
        for mode in RailCompare.modes {
            let url = output.appending(path: "kit-0.2.12-focus-\(mode.name).png")
            try renderOffscreenWindow(
                FocusSheet0212()
                    .accessibilityOverrides(increaseContrast: mode.increased, reduceTransparency: mode.increased)
                    .theme(RailCompare.theme),
                size: CGSize(width: 360, height: 600), isDark: mode.isDark, to: url)
            print("OK: \(url.lastPathComponent)")
        }
    } catch {
        print("FAILED: \(error)")
        exit(1)
    }
}

// MARK: Full screen

/// An AppKit sidebar window as an app builds one from the kit (`NSSplitViewItem.sidebar(hosting:)`, a
/// `WindowBackground` under the split, the kit's toolbar items, the toolbar hidden in full screen until the pointer
/// reaches the top). `variant`: `before`, the window as the docs build it; `swiftui-toolbar`, the window's root an
/// `NSHostingController` that creates the toolbar itself (`sceneBridgingOptions = .all`, `sidebarWindowChrome()`, no
/// NSToolbar of the app's); `hide`, the toolbar hidden while in full screen (`NSToolbar.isVisible`). In 0.2.12 none
/// paints the Theme into the full screen toolbar band: `before` and `swiftui-toolbar` show the system's grey band,
/// `hide` shows no band (and no sidebar button) in full screen.
@MainActor
final class FullScreenSample: NSObject, NSWindowDelegate, NSToolbarDelegate {
    let window: NSWindow
    let split = NSSplitViewController()
    let variant: String
    let autoHides: Bool

    init(variant: String, autoHides: Bool, isDark: Bool) {
        self.variant = variant
        self.autoHides = autoHides
        window = NSWindow(
            contentRect: CGRect(x: 200, y: 200, width: 1000, height: 680),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered, defer: false)
        super.init()
        window.isReleasedWhenClosed = false
        window.appearance = NSAppearance(named: isDark ? .darkAqua : .aqua)
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.title = "Full screen sample"
        window.collectionBehavior.insert(.fullScreenPrimary)
        window.delegate = self
        let theme = RailCompare.theme
        let column = List {
            ForEach(["Mail", "Calendar", "Design notes", "Swift Forums"], id: \.self) { title in
                Text(title).sidebarRowCell(state: RowState(isSelected: title == "Calendar"))
            }
        }
        .sidebarColumn()
        .theme(theme)
        let sidebar = NSSplitViewItem.sidebar(hosting: column)
        let detail = NSHostingController(rootView: Text("A page").frame(maxWidth: .infinity, maxHeight: .infinity)
            .sidebarDetailCard().padding(DesignTokens.standard.spacing.canvasInset).theme(theme))
        split.addSplitViewItem(sidebar)
        split.addSplitViewItem(NSSplitViewItem(viewController: detail))
        let content = NSViewController()
        content.view = NSView(frame: CGRect(x: 0, y: 0, width: 1000, height: 680))
        let background = NSHostingView(rootView: WindowBackground().ignoresSafeArea(.all).theme(theme))
        for view in [background, split.view] {
            view.translatesAutoresizingMaskIntoConstraints = false
            content.view.addSubview(view)
            NSLayoutConstraint.activate([
                view.leadingAnchor.constraint(equalTo: content.view.leadingAnchor),
                view.trailingAnchor.constraint(equalTo: content.view.trailingAnchor),
                view.topAnchor.constraint(equalTo: content.view.topAnchor),
                view.bottomAnchor.constraint(equalTo: content.view.bottomAnchor),
            ])
        }
        content.addChild(split)
        if variant == "swiftui-toolbar" {
            // SwiftUI creates the window's toolbar itself (scene bridging, no NSToolbar of the app's).
            let host = NSHostingController(rootView: SplitHost(controller: content).ignoresSafeArea(.all)
                .toolbar {
                    ToolbarItem(placement: .navigation) {
                        Button("Sidebar", systemImage: "sidebar.left") {
                            NSApp.sendAction(#selector(NSSplitViewController.toggleSidebar(_:)), to: nil, from: nil)
                        }
                    }
                }
                .sidebarWindowChrome())
            host.sceneBridgingOptions = .all
            window.contentViewController = host
        } else {
            window.contentViewController = content
        }
        guard variant != "swiftui-toolbar" else { return }
        let toolbar = NSToolbar(identifier: "FullScreenSample")
        toolbar.delegate = self
        toolbar.displayMode = .iconOnly
        toolbar.allowsUserCustomization = false
        window.toolbar = toolbar
    }

    func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        NSSplitViewItem.sidebarToolbarItems
    }

    func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
        NSSplitViewItem.sidebarToolbarItems
    }

    func toolbar(_ toolbar: NSToolbar, itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
                 willBeInsertedIntoToolbar flag: Bool) -> NSToolbarItem? {
        nil
    }

    func windowWillEnterFullScreen(_ notification: Notification) {
        if variant == "hide" { window.toolbar?.isVisible = false }
    }

    func windowWillExitFullScreen(_ notification: Notification) {
        if variant == "hide" { window.toolbar?.isVisible = true }
    }

    func window(_ window: NSWindow, willUseFullScreenPresentationOptions proposed: NSApplication.PresentationOptions)
        -> NSApplication.PresentationOptions {
        autoHides ? proposed.union([.autoHideToolbar, .autoHideMenuBar]) : proposed
    }

    /// Where the column and the detail sit in the window, to see whether anything moves when the band shows.
    var layout: String {
        split.splitViewItems.map { item in
            let frame = item.viewController.view.convert(item.viewController.view.bounds, to: nil)
            return "\(Int(frame.minX)),\(Int(frame.minY)) \(Int(frame.width))x\(Int(frame.height))"
                + " safeTop \(Int(item.viewController.view.safeAreaInsets.top))"
        }.joined(separator: " | ")
    }
}

/// An AppKit view controller inside SwiftUI.
struct SplitHost: NSViewControllerRepresentable {
    let controller: NSViewController
    func makeNSViewController(context: Context) -> NSViewController { controller }
    func updateNSViewController(_ controller: NSViewController, context: Context) {}
}

@MainActor
func wait(_ seconds: Double) {
    RunLoop.current.run(until: Date(timeIntervalSinceNow: seconds))
}

@MainActor
func captureDisplay(to url: URL) {
    let process = Process()
    process.executableURL = URL(filePath: "/usr/sbin/screencapture")
    process.arguments = ["-x", "-m", url.path]
    try? process.run()
    process.waitUntilExit()
    print(FileManager.default.fileExists(atPath: url.path) ? "OK: \(url.lastPathComponent)" : "FAILED: \(url.lastPathComponent)")
}

@MainActor
func runFullScreen(output: URL, variant: String, isDark: Bool) {
    let app = NSApplication.shared
    app.setActivationPolicy(.regular)
    try? FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
    let scheme = isDark ? "dark" : "light"
    for autoHides in [true, false] {
        let sample = FullScreenSample(variant: variant, autoHides: autoHides, isDark: isDark)
        sample.window.makeKeyAndOrderFront(nil)
        app.activate()
        wait(1)
        let windowed = output.appending(path: "kit-0.2.12-fullscreen-\(variant)-\(scheme)-windowed.png")
        if autoHides {
            let process = Process()
            process.executableURL = URL(filePath: "/usr/sbin/screencapture")
            process.arguments = ["-x", "-o", "-l", "\(sample.window.windowNumber)", windowed.path]
            try? process.run()
            process.waitUntilExit()
            print("OK: \(windowed.lastPathComponent)")
        }
        print("INFO: toolbar items \(sample.window.toolbar?.items.map(\.itemIdentifier.rawValue) ?? [])")
        sample.window.toggleFullScreen(nil)
        wait(3)
        print("INFO: full screen \(sample.window.styleMask.contains(.fullScreen)), autoHides \(autoHides)")
        if autoHides {
            // The toolbar hidden, as it is until the pointer reaches the top of the screen.
            print("INFO: hidden  \(sample.layout)")
            captureDisplay(to: output.appending(path: "kit-0.2.12-fullscreen-\(variant)-\(scheme)-hidden.png"))
        } else {
            print("INFO: pinned  \(sample.layout)")
            captureDisplay(to: output.appending(path: "kit-0.2.12-fullscreen-\(variant)-\(scheme)-pinned.png"))
        }
        sample.window.toggleFullScreen(nil)
        wait(2.5)
        sample.window.close()
        wait(0.5)
    }
}
