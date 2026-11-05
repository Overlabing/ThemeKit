#if os(macOS)
import AppKit
import DesignKit
import Foundation
import SwiftUI
import Testing

/// What a scroll step costs in the 400-row hosted list of `ListHoverTests`, for the record (issue #48): the list
/// scrolled by a row's height at a time, each step laid out and drawn. Opt in with
/// `THEMEKIT_TIMING=1 swift test --filter ListScrollTimingTests`; it prints and asserts nothing.
@MainActor
@Suite(.serialized, .enabled(if: ProcessInfo.processInfo.environment["THEMEKIT_TIMING"] != nil))
struct ListScrollTimingTests {
    static func median(_ samples: [Duration]) -> Duration { samples.sorted()[samples.count / 2] }

    static func milliseconds(_ duration: Duration) -> String {
        let (seconds, attoseconds) = duration.components
        return String(format: "%.3f ms", Double(seconds) * 1e3 + Double(attoseconds) / 1e15)
    }

    @Test(arguments: [ListHoverTests.Cell.list, .sidebar])
    func aScrollStep(_ cell: ListHoverTests.Cell) throws {
        let hover = ListHover()
        let host = ListHoverTests.Host(ListHoverTests.KitList(hover: hover, cell: cell))
        defer { host.close() }
        let scroll = try #require(host.window.contentView?.firstScrollView)
        let clock = ContinuousClock()
        var samples: [Duration] = []
        for pass in 0..<3 {
            scroll.contentView.scroll(to: .zero)
            scroll.reflectScrolledClipView(scroll.contentView)
            host.settle()
            let end = (scroll.documentView?.frame.height ?? 0) - scroll.contentView.bounds.height
            var y = 0.0
            while y < end {
                y = min(end, y + 36)
                samples.append(clock.measure {
                    scroll.contentView.scroll(to: CGPoint(x: 0, y: y))
                    scroll.reflectScrolledClipView(scroll.contentView)
                    host.window.contentView?.layoutSubtreeIfNeeded()
                    host.window.contentView?.displayIfNeeded()
                    RunLoop.current.run(until: Date())
                })
            }
            if pass == 0 { samples.removeAll() }
        }
        print("TIMING scroll \(cell) \(ListHoverTests.rows) rows: \(samples.count) steps of 36 pt, median "
            + "\(Self.milliseconds(Self.median(samples))), p90 \(Self.milliseconds(samples.sorted()[samples.count * 9 / 10]))")
    }
}

extension NSView {
    /// The first scroll view at or under this view: a hosted `List`'s table.
    var firstScrollView: NSScrollView? {
        if let scroll = self as? NSScrollView { return scroll }
        for child in subviews { if let found = child.firstScrollView { return found } }
        return nil
    }
}
#endif
