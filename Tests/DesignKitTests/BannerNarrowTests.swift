import ColorCore
import ColorUI
@testable import DesignKit
import Foundation
import SwiftUI
import Testing

/// A banner at narrow widths (issue #44): at 300 pt the action goes under the message instead of being cut, and a long
/// host breaks at a dot rather than in the middle of a word. Offscreen renders, light and dark.
@MainActor
@Suite(.enabled(if: ProcessInfo.processInfo.operatingSystemVersion.majorVersion == 27))
struct BannerNarrowTests {
    static let message = "Could not reach imap.mail.averyverylonghostname.example.com"
    let theme = Palette.standard.themes[0]

    func render(_ view: some View, width: CGFloat, scheme: ColorScheme) throws -> Raster {
        try raster(
            view.frame(width: width)
                .environment(\.glassRendering, .material)
                .theme(theme)
                .environment(\.colorScheme, scheme))
    }

    func banner(action: Bool) -> some View {
        Banner(
            systemImage: "exclamationmark.triangle", message: Self.message,
            action: action ? BannerAction("Try Again") {} : nil, onClose: {})
    }

    /// The rows and columns where two renders of the same size differ.
    func difference(_ a: Raster, _ b: Raster) -> (rows: ClosedRange<Int>, columns: ClosedRange<Int>)? {
        var rows: [Int] = [], columns: [Int] = []
        for y in 0..<min(a.height, b.height) {
            for x in 0..<min(a.width, b.width) where Contrast.ratio(a.color(x: x, y: y), b.color(x: x, y: y)) > 1.3
                || abs(a.alpha(x: x, y: y) - b.alpha(x: x, y: y)) > 0.2 {
                rows.append(y)
                columns.append(x)
            }
        }
        guard let top = rows.min(), let bottom = rows.max(), let left = columns.min(), let right = columns.max() else {
            return nil
        }
        return (top...bottom, left...right)
    }

    @Test(arguments: [ColorScheme.light, .dark])
    func atThreeHundredPointsTheActionGoesUnderTheMessageWhole(_ scheme: ColorScheme) throws {
        let withAction = try render(banner(action: true), width: 300, scheme: scheme)
        let without = try render(banner(action: false), width: 300, scheme: scheme)
        #expect(withAction.height > without.height, "a row for the action: \(withAction.height) against \(without.height)")
        // The action's own pixels: compare the bottom rows, where the banner without action has its bottom edge.
        let label = try render(
            Text("Try Again").role(DesignTokens.standard.type.buttonLabel).fixedSize(), width: 120, scheme: scheme)
        let labelInk = (0..<label.width).filter { x in (0..<label.height).contains { label.alpha(x: x, y: $0) > 0.3 } }
        let actionRows = (withAction.height - 40)..<withAction.height
        let actionInk = try #require(Self.inkColumns(withAction, rows: actionRows, beyond: 30))
        #expect(actionInk.count >= labelInk.count - 1,
                "the whole label, not cut: \(actionInk.count) pt of ink against \(labelInk.count)")
    }

    @Test(arguments: [ColorScheme.light, .dark])
    func whereItFitsTheActionStaysBeside(_ scheme: ColorScheme) throws {
        let withAction = try render(banner(action: true), width: 560, scheme: scheme)
        let without = try render(banner(action: false), width: 560, scheme: scheme)
        #expect(withAction.height == without.height, "beside the message, on its rows")
    }

    @Test func aShortActionStaysBesideAtThreeHundredAndTwenty() throws {
        // "Undo" and the close button leave the text its 160 pt: beside it, the banner as tall as with the close alone.
        let undo = try render(
            Banner(systemImage: "arrow.uturn.backward", message: "Moved to Archive.", action: BannerAction("Undo") {},
                   onClose: {}),
            width: 320, scheme: .light)
        let close = try render(
            Banner(systemImage: "arrow.uturn.backward", message: "Moved to Archive.", onClose: {}), width: 320, scheme: .light)
        #expect(undo.height == close.height)
    }

    @Test func hostsBreakAfterTheirDots() {
        #expect(Banner<EmptyView>.breakingAfterDots("imap.mail.example.com") == "imap.\u{200B}mail.\u{200B}example.\u{200B}com")
        #expect(Banner<EmptyView>.breakingAfterDots("Saved. Done.") == "Saved. Done.", "a sentence's dot is left alone")
        #expect(Banner<EmptyView>.breakingAfterDots("version 0.2.8") == "version 0.2.8", "so is a number's")
        #expect(Banner<EmptyView>.breakingAfterDots(".hidden") == ".hidden")
    }

    @Test(arguments: [ColorScheme.light, .dark])
    func aLongHostBreaksAtADot(_ scheme: ColorScheme) throws {
        // The host alone on the message's lines: broken at its dots it reads as two lines whose first ends at a dot,
        // the same as the host written with a line break after that dot.
        let host = "imap.mail.averyverylonghostname.example.com"
        let kit = try render(Banner(systemImage: "wifi", message: host) { EmptyView() }, width: 220, scheme: scheme)
        let split = try render(
            Banner(systemImage: "wifi", message: "imap.mail.\naveryverylonghostname.example.com") { EmptyView() },
            width: 220, scheme: scheme)
        #expect(kit.matches(split, tolerance: 2), "broken after a dot, as written by hand")
    }

    /// The columns holding ink (alpha or contrast against the row's first pixel) in `rows`, from `beyond` on.
    static func inkColumns(_ raster: Raster, rows: Range<Int>? = nil, beyond: Int = 0) -> [Int]? {
        let rows = rows ?? 0..<raster.height
        let columns = (beyond..<raster.width).filter { x in
            rows.contains { y in
                let base = raster.color(x: max(0, beyond - 1), y: y)
                return Contrast.ratio(raster.color(x: x, y: y), base) > 2
            }
        }
        return columns.isEmpty ? nil : columns
    }
}
