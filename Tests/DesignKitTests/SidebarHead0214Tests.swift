#if os(macOS)
import AppKit
@testable import DesignKit
import Foundation
import SwiftUI
import Testing

/// 0.2.14's sidebar head, as in Zen: a title bar row on the line of the window's buttons (the sidebar button, space,
/// the app's buttons) and a field pill the column's width with the app's accessory inside it.
@MainActor
@Suite(.enabled(if: ProcessInfo.processInfo.operatingSystemVersion.majorVersion == 27))
struct SidebarHead0214Tests {
    /// Frames of the app's views in the column's hosting view, top-left origin, by name.
    @MainActor
    final class Frames {
        var byName: [String: CGRect] = [:]
    }

    struct Probe: ViewModifier {
        let name: String
        let frames: Frames

        func body(content: Content) -> some View {
            content.onGeometryChange(for: CGRect.self) { $0.frame(in: .global) } action: { frames.byName[name] = $0 }
        }
    }

    /// Counts `toggleSidebar(_:)` instead of collapsing the column, as an app's split controller does.
    final class Split: SeamlessSplitViewController {
        var toggles = 0
        override func toggleSidebar(_ sender: Any?) { toggles += 1 }
    }

    final class Toolbar: NSObject, NSToolbarDelegate {
        func toolbarDefaultItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
            NSSplitViewItem.sidebarHeadToolbarItems
        }

        func toolbarAllowedItemIdentifiers(_ toolbar: NSToolbar) -> [NSToolbarItem.Identifier] {
            NSSplitViewItem.sidebarHeadToolbarItems
        }
    }

    static func column(frames: Frames, accessory: Bool = true) -> some View {
        List { Text("Row").sidebarRowCell() }
            .sidebarColumn(sidebarButtonShortcut: "⌘B") {
                Button("Back") {}.frame(width: 28, height: 28).modifier(Probe(name: "back", frames: frames))
                Button("Reload") {}.frame(width: 28, height: 28).modifier(Probe(name: "reload", frames: frames))
            } field: {
                Text(verbatim: "example.com").modifier(Probe(name: "field", frames: frames))
            } fieldAccessory: {
                if accessory {
                    Button("Copy") {}.frame(width: 28, height: 28).modifier(Probe(name: "accessory", frames: frames))
                }
            } header: {
                EmptyView()
            } bottomBar: {
                EmptyView()
            }
    }

    /// A Zen-like AppKit window: the column on the window's background under a transparent `.unifiedCompact` toolbar
    /// with no items. Without `fullSizeContentView` the column starts under the title bar instead, as in full screen.
    @MainActor
    final class SampleWindow {
        let window: NSWindow
        let split = Split()
        let frames = Frames()
        let toolbar = Toolbar()

        init(fullSizeContent: Bool = true, accessory: Bool = true) {
            split.addSplitViewItem(.sidebar(hosting: SidebarHead0214Tests.column(frames: frames, accessory: accessory),
                                            surface: .windowBackground))
            split.addSplitViewItem(NSSplitViewItem(viewController: NSHostingController(rootView: SidebarDetail { Color.white })))
            var style: NSWindow.StyleMask = [.titled, .closable, .miniaturizable, .resizable]
            if fullSizeContent { style.insert(.fullSizeContentView) }
            window = NSWindow(contentRect: CGRect(x: -20000, y: -20000, width: 1100, height: 760), styleMask: style,
                              backing: .buffered, defer: false)
            window.isReleasedWhenClosed = false
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.toolbarStyle = .unifiedCompact
            let bar = NSToolbar(identifier: "SidebarHead0214Tests")
            bar.delegate = toolbar
            window.toolbar = bar
            window.contentViewController = split
            window.setContentSize(CGSize(width: 1100, height: 760))
        }

        /// Lays the window out and lets the main queue run: the head learns the title bar's geometry from it.
        func settle() async {
            for _ in 0..<6 {
                window.layoutIfNeeded()
                try? await Task.sleep(for: .milliseconds(50))
            }
        }

        var column: NSView { split.splitViewItems[0].viewController.view }

        /// The window's own hit test at a point of the column, top-left origin. The `.global` frames the probes record
        /// are the window's, also top-left: the same as the column's where the column runs under the title bar.
        func hit(x: CGFloat, y: CGFloat) -> NSView? {
            let point = column.convert(CGPoint(x: x, y: column.isFlipped ? y : column.bounds.height - y), to: nil)
            return window.contentView?.superview?.hitTest(point)
        }

        /// The zoom button's frame in the column, top-left origin.
        var zoomButton: CGRect {
            let button = window.standardWindowButton(.zoomButton)!
            var frame = column.convert(button.convert(button.bounds, to: nil), from: nil)
            if !column.isFlipped { frame.origin.y = column.bounds.height - frame.maxY }
            return frame
        }

        /// The runs of a horizontal line through the column that the window's hit test gives to something other than the
        /// row's drag area, from `start`: where the row's buttons are.
        func buttonRuns(y: CGFloat, from start: CGFloat) -> [ClosedRange<CGFloat>] {
            var runs: [ClosedRange<CGFloat>] = []
            var runStart: CGFloat?
            var x = start
            while x <= column.bounds.width {
                let isButton = !(hit(x: x, y: y) is TitleBarDragView)
                if isButton, runStart == nil { runStart = x }
                if !isButton, let begin = runStart { runs.append(begin...(x - 1)); runStart = nil }
                x += 1
            }
            if let begin = runStart { runs.append(begin...column.bounds.width) }
            return runs
        }

        /// The head's own view, the one the sidebar button sends its action from.
        var probe: TitleBarProbeView? {
            func find(_ view: NSView) -> TitleBarProbeView? {
                (view as? TitleBarProbeView) ?? view.subviews.lazy.compactMap(find).first
            }
            return find(column)
        }

        func close() {
            window.contentViewController = nil
            window.close()
        }
    }

    @Test func theRowTakesTheTitleBarBandPastTheWindowsButtonsOrItsOwnHeightFromTheEdge() {
        let tokens = DesignTokens.standard
        #expect(SidebarTitleBarLayout(metrics: .init(band: 40, windowButtonsEnd: 72), tokens: tokens)
            == SidebarTitleBarLayout(metrics: .init(band: 40, windowButtonsEnd: 72), tokens: tokens))
        let titled = SidebarTitleBarLayout(metrics: .init(band: 40, windowButtonsEnd: 72), tokens: tokens)
        #expect([titled.band, titled.rowHeight, titled.leading] == [40, 40, 80])
        let fullScreen = SidebarTitleBarLayout(metrics: .init(band: 0, windowButtonsEnd: nil), tokens: tokens)
        #expect([fullScreen.band, fullScreen.rowHeight, fullScreen.leading] == [0, 40, 10])
    }

    @Test func aDoubleClickDoesWhatTheUserSetForTitleBars() {
        #expect(TitleBarDoubleClick(preference: nil, minimizeFlag: false) == .zoom)
        #expect(TitleBarDoubleClick(preference: nil, minimizeFlag: true) == .minimize)
        #expect(TitleBarDoubleClick(preference: "Maximize", minimizeFlag: true) == .zoom)
        #expect(TitleBarDoubleClick(preference: "Fill", minimizeFlag: false) == .zoom)
        #expect(TitleBarDoubleClick(preference: "Minimize", minimizeFlag: false) == .minimize)
        #expect(TitleBarDoubleClick(preference: "None", minimizeFlag: false) == .none)
    }

    @Test func theTitleBarRowSitsOnTheLineOfTheWindowsButtonsAndThePillUnderIt() async throws {
        let sample = SampleWindow()
        await sample.settle()
        defer { sample.close() }
        let width = sample.column.bounds.width
        let zoom = sample.zoomButton
        let back = try #require(sample.frames.byName["back"])
        let reload = try #require(sample.frames.byName["reload"])
        let field = try #require(sample.frames.byName["field"])
        let accessory = try #require(sample.frames.byName["accessory"])
        #expect(width == 360)
        #expect(zoom.midY == 20, "the window's buttons sit in the middle of the 40 pt band")
        #expect(abs(back.midY - zoom.midY) < 0.5)
        #expect(abs(reload.midY - zoom.midY) < 0.5)
        #expect(abs(reload.maxX - (width - 10)) < 0.5, "the app's buttons end on the field's side margin")
        #expect(abs(reload.minX - back.maxX - 2) < 0.5)
        // The pill: 2 pt under the band, 36 pt tall, 10 pt from the column's sides.
        #expect(abs(field.minX - (10 + 12)) < 0.5)
        #expect(abs(field.midY - (40 + 2 + 18)) < 0.5)
        #expect(abs(accessory.maxX - (width - 10 - 4)) < 0.5)
        #expect(abs(accessory.midY - field.midY) < 0.5)
    }

    @Test func theSidebarButtonFollowsTheWindowsButtonsAndSendsToggleSidebar() async throws {
        let sample = SampleWindow()
        await sample.settle()
        defer { sample.close() }
        let zoom = sample.zoomButton
        let button = try #require(sample.buttonRuns(y: zoom.midY, from: zoom.maxX + 1).first { $0.upperBound - $0.lowerBound > 4 })
        #expect(button == (zoom.maxX + 8)...(zoom.maxX + 8 + 27), "28 pt wide, 8 pt after the zoom button")
        #expect(sample.split.toggles == 0)
        let anchor = SidebarHeadAnchor()
        anchor.view = try #require(sample.probe)
        anchor.toggleSidebar()
        #expect(sample.split.toggles == 1, "the action reaches the split controller up the column's responder chain")
    }

    @Test func theRowsEmptyPartDragsTheWindowAndItsButtonsKeepTheirClicks() async throws {
        let sample = SampleWindow()
        await sample.settle()
        defer { sample.close() }
        let reload = try #require(sample.frames.byName["reload"])
        let empty = sample.hit(x: 200, y: 20)
        #expect(empty is TitleBarDragView, "\(String(describing: empty))")
        let onButton = sample.hit(x: reload.midX, y: reload.midY)
        #expect(onButton != nil)
        #expect(!(onButton is TitleBarDragView))
        let onPill = sample.hit(x: 200, y: 60)
        #expect(!(onPill is TitleBarDragView), "the pill is not part of the title bar")
    }

    @Test func withNoTitleBarBandTheRowTakesItsOwnHeightFromTheColumnsEdge() async throws {
        let sample = SampleWindow(fullSizeContent: false)
        await sample.settle()
        defer { sample.close() }
        let back = try #require(sample.frames.byName["back"])
        let field = try #require(sample.frames.byName["field"])
        // The column starts under the window's 40 pt title bar.
        #expect(abs(back.midY - (40 + 20)) < 0.5)
        #expect(abs(field.midY - (40 + 40 + 2 + 18)) < 0.5)
        // The first 2 pt of the column are the split's, not the row's.
        let button = try #require(sample.buttonRuns(y: 20, from: 0).first { $0.upperBound - $0.lowerBound > 4 })
        #expect(button == 10...37, "no window buttons in the row: the button starts on the side margin")
    }

    @Test func anEmptyAccessoryKeepsTheFieldsInsetOnBothSides() async throws {
        let sample = SampleWindow(accessory: false)
        await sample.settle()
        defer { sample.close() }
        let field = try #require(sample.frames.byName["field"])
        #expect(abs(field.minX - 22) < 0.5)
        #expect(sample.frames.byName["accessory"] == nil)
    }

    @Test func theCatalogTranslatesTheSidebarButton() throws {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appending(path: "Sources/DesignKit/Resources/DesignKit.xcstrings")
        let catalog = try JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any]
        let strings = try #require(catalog?["strings"] as? [String: Any])
        func value(_ key: String, _ language: String) -> String? {
            let entry = strings[key] as? [String: Any]
            let localization = (entry?["localizations"] as? [String: Any])?[language] as? [String: Any]
            return (localization?["stringUnit"] as? [String: Any])?["value"] as? String
        }
        #expect(value("Hide Sidebar", "fr") == "Masquer la barre latérale")
        #expect(value("Hide Sidebar (%@)", "fr") == "Masquer la barre latérale (%@)")
    }
}
#endif
