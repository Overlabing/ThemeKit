#if os(macOS)
import AppKit
import ColorCore
import ColorUI
import DesignKit
import Foundation
import SwiftUI
import Testing

/// 0.2.13's sidebar surface: a column on the window's own background, with no material, no tone and a divider that
/// draws nothing, beside the default system sidebar that stays as it was.
@MainActor
@Suite(.enabled(if: ProcessInfo.processInfo.operatingSystemVersion.majorVersion == 27))
struct SidebarSurface0213Tests {
    static func isRed(_ color: RGBA) -> Bool { color.red > 0.9 && color.green < 0.1 && color.blue < 0.1 }

    static func column() -> some View {
        List { Text("Row").sidebarRowCell() }.sidebarColumn { EmptyView() }
    }

    /// A window as an app builds it: a red background under the split, the column and a detail card beside it.
    @MainActor
    final class SampleWindow {
        let window: NSWindow
        let split: NSSplitViewController
        let content = NSView(frame: CGRect(x: 0, y: 0, width: 1100, height: 760))

        init(surface: SidebarSurface?, appearance: NSAppearance.Name = .aqua) {
            split = surface == .windowBackground ? SeamlessSplitViewController() : NSSplitViewController()
            let item = surface.map { NSSplitViewItem.sidebar(hosting: SidebarSurface0213Tests.column(), surface: $0) }
                ?? NSSplitViewItem.sidebar(hosting: SidebarSurface0213Tests.column())
            split.addSplitViewItem(item)
            split.addSplitViewItem(NSSplitViewItem(viewController: NSHostingController(
                rootView: SidebarDetail { Color.white })))
            content.wantsLayer = true
            content.layer?.backgroundColor = NSColor(srgbRed: 1, green: 0, blue: 0, alpha: 1).cgColor
            split.view.translatesAutoresizingMaskIntoConstraints = false
            content.addSubview(split.view)
            NSLayoutConstraint.activate([
                split.view.leadingAnchor.constraint(equalTo: content.leadingAnchor),
                split.view.trailingAnchor.constraint(equalTo: content.trailingAnchor),
                split.view.topAnchor.constraint(equalTo: content.topAnchor),
                split.view.bottomAnchor.constraint(equalTo: content.bottomAnchor),
            ])
            window = NSWindow(contentRect: content.frame, styleMask: [.titled, .resizable, .fullSizeContentView],
                              backing: .buffered, defer: false)
            window.isReleasedWhenClosed = false
            window.titlebarAppearsTransparent = true
            window.appearance = NSAppearance(named: appearance)
            window.contentView = content
            window.layoutIfNeeded()
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.3))
        }

        var column: NSSplitViewItem { split.splitViewItems[0] }

        func close() {
            window.contentView = nil
            window.close()
        }
    }

    static func effectViews(in view: NSView) -> [NSVisualEffectView] {
        (view as? NSVisualEffectView).map { [$0] } ?? view.subviews.flatMap(effectViews)
    }

    @Test func theDefaultSurfaceIsTheSystemSidebarAsBefore() {
        let item = NSSplitViewItem.sidebar(hosting: Self.column())
        #expect(item.behavior == .sidebar)
        #expect(NSSplitViewItem.sidebar(hosting: Self.column(), surface: .systemMaterial).behavior == .sidebar)
    }

    @Test func onTheWindowBackgroundTheColumnIsAPlainCollapsibleItemAtTheKitsWidths() {
        let item = NSSplitViewItem.sidebar(hosting: Self.column(), surface: .windowBackground)
        #expect(item.behavior == .default)
        #expect(item.canCollapse)
        #expect(item.minimumThickness == 300)
        #expect(item.maximumThickness == 480)
        let sample = SampleWindow(surface: .windowBackground)
        #expect(sample.split.splitViewItems.map(\.holdingPriority.rawValue) == [260, 250])
        #expect(sample.column.viewController.view.frame.width == 360, "\(sample.column.viewController.view.frame)")
        sample.column.isCollapsed = true
        sample.window.layoutIfNeeded()
        #expect(sample.split.splitViewItems[1].viewController.view.frame.width >= 1099)
        sample.close()
    }

    /// No material anywhere in the split, and the window's background shows through the column, at the divider, and
    /// round the card, in light and dark.
    @Test(arguments: [NSAppearance.Name.aqua, .darkAqua, .accessibilityHighContrastAqua, .accessibilityHighContrastDarkAqua])
    func theWindowsBackgroundShowsUnderTheColumnAndAtTheDivider(appearance: NSAppearance.Name) throws {
        let sample = SampleWindow(surface: .windowBackground, appearance: appearance)
        #expect(Self.effectViews(in: sample.split.view).isEmpty)
        let pixels = try HostedPixels(capturing: sample.content, size: sample.content.frame.size)
        let divider = sample.column.viewController.view.frame.maxX
        // In the column below its only row, on the divider, and between the divider and the card (12 pt inset).
        for x in [10.0, 180, 350, divider + 0.5, divider + 6] {
            #expect(Self.isRed(pixels.color(x: x, y: 600)), "x \(x) \(appearance.rawValue)")
        }
        #expect(!Self.isRed(pixels.color(x: divider + 40, y: 600)), "the card")
        sample.close()
    }

    @Test func theSeamlessDividerIsThinAndDrawsNothing() throws {
        let split = SeamlessSplitView()
        #expect(split.isVertical)
        #expect(split.dividerStyle == .thin)
        #expect(split.dividerColor.alphaComponent == 0)
        let rep = try #require(NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: 4, pixelsHigh: 4, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
            isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0))
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
        split.drawDivider(in: CGRect(x: 0, y: 0, width: 4, height: 4))
        NSGraphicsContext.restoreGraphicsState()
        #expect(rep.colorAt(x: 1, y: 1)?.alphaComponent == 0)
    }

    /// The divider keeps a resize zone over the card's margin, none once the column is collapsed, and dragging it
    /// still sets the column's width.
    @Test func theInvisibleDividerStillResizesTheColumn() {
        let sample = SampleWindow(surface: .windowBackground)
        let splitView = sample.split.splitView
        #expect(splitView is SeamlessSplitView)
        let drawn = CGRect(x: 360, y: 0, width: 1, height: 760)
        let effective = sample.split.splitView(splitView, effectiveRect: drawn, forDrawnRect: drawn, ofDividerAt: 0)
        #expect(effective.minX <= 360)
        #expect(effective.maxX >= 373)
        splitView.setPosition(420, ofDividerAt: 0)
        sample.window.layoutIfNeeded()
        #expect(sample.column.viewController.view.frame.width == 420)
        sample.column.isCollapsed = true
        sample.window.layoutIfNeeded()
        let shut = CGRect(x: 0, y: 0, width: 1, height: 760)
        #expect(sample.split.splitView(splitView, effectiveRect: shut, forDrawnRect: shut, ofDividerAt: 0) == shut)
        sample.close()
    }
}
#endif
