import ColorCore
import ColorPlatform
import ColorUI
import DesignKit
import Foundation
import SwiftUI
import Testing

/// `sidebarDetailCard()` and `sidebarDetailInset()` (issue #31), and `tileFill`'s shapes and sizes (issue #35), on
/// offscreen renders.
@MainActor
@Suite(.enabled(if: ProcessInfo.processInfo.operatingSystemVersion.majorVersion == 27))
struct DetailCardAndTileFillTests {
    let theme = Palette.standard.themes[0]
    let tokens = DesignTokens.standard

    func render(_ view: some View, scheme: ColorScheme = .light) throws -> Raster {
        try raster(view.theme(theme).environment(\.colorScheme, scheme))
    }

    // MARK: #31

    @Test(arguments: [ColorScheme.light, .dark])
    func theDetailIsItsCardInItsInset(_ scheme: ColorScheme) throws {
        let detail = try render(
            SidebarDetail { Text("Page") }.frame(width: 300, height: 200).background(Color.gray), scheme: scheme)
        let composed = try render(
            Text("Page").frame(maxWidth: .infinity, maxHeight: .infinity).sidebarDetailCard().sidebarDetailInset()
                .frame(width: 300, height: 200).background(Color.gray),
            scheme: scheme)
        #expect(detail.matches(composed), "SidebarDetail is the card in its inset, as before")
    }

    @Test(arguments: [ColorScheme.light, .dark])
    func theCardAloneHasNoPadding(_ scheme: ColorScheme) throws {
        let card = try render(Color.clear.frame(width: 100, height: 60).sidebarDetailCard(), scheme: scheme)
        #expect((card.width, card.height) == (100, 60), "no padding: the card is the view's size")
        let page = try render(Color.clear.frame(width: 100, height: 60).background(.background), scheme: scheme)
        #expect(Contrast.ratio(card.color(x: 50, y: 30), page.color(x: 50, y: 30)) < 1.01, "on the plain background")
        #expect(card.alpha(x: 0, y: 0) < 0.5, "rounded: the corner is left out")
        #expect(card.alpha(x: 50, y: 0) > 0.99)
    }

    @Test func cardsStackInOneInset() throws {
        let stacked = try render(
            VStack(spacing: tokens.spacing.canvasInset) {
                Color.clear.frame(maxHeight: .infinity).sidebarDetailCard()
                Color.clear.frame(height: 40).sidebarDetailCard()
            }
            .sidebarDetailInset()
            .frame(width: 300, height: 200).background(Color.black))
        // Down the middle: the inset, the first card, the gap, the second card, the inset.
        let column = (0..<stacked.height).map { stacked.color(x: 150, y: $0).red > 0.5 }
        var runs: [(Bool, Int)] = []
        for light in column { if runs.last?.0 == light { runs[runs.count - 1].1 += 1 } else { runs.append((light, 1)) } }
        #expect(runs.map(\.0) == [false, true, false, true, false])
        #expect(runs[0].1 == 12 && runs[2].1 == 12 && runs[4].1 == 12, "\(runs)")
        #expect(runs[3].1 == 40)
    }

    // MARK: #35

    @Test func theDefaultTileFillIsUnchanged() throws {
        let plain = try render(Text("A").tileFill())
        let explicit = try render(Text("A").tileFill(.tile(.standard), shape: .roundedSquare))
        #expect((plain.width, plain.height) == (32, 32))
        #expect(plain.matches(explicit))
    }

    @Test(arguments: [ColorScheme.light, .dark])
    func aCircleTile(_ scheme: ColorScheme) throws {
        let circle = try render(Text("A").tileFill(.compact, shape: .circle), scheme: scheme)
        let square = try render(Text("A").tileFill(.compact), scheme: scheme)
        #expect((circle.width, circle.height) == (28, 28))
        // 3 pt in from a corner: inside the rounded square (radius 7), outside the circle.
        #expect(square.alpha(x: 3, y: 3) > 0.05)
        #expect(circle.alpha(x: 3, y: 3) == 0)
        #expect(circle.alpha(x: 14, y: 1) > 0.05, "the circle reaches the edge at its middle")
    }

    @Test func aTileOfAnySide() throws {
        let side = try render(Color.clear.frame(width: 1, height: 1).tileFill(.side(48)))
        #expect((side.width, side.height) == (48, 48))
        // The radius keeps the kit's proportion: 12 for 48 (8 for 32). 2 pt in from the corner is outside it.
        #expect(side.alpha(x: 2, y: 2) == 0)
        #expect(side.alpha(x: 24, y: 1) > 0.05)
    }

    @Test func aTileThatFollowsItsText() throws {
        let short = try render(Text("A").font(.caption).tileFill(.fitting(minimum: .small), shape: .circle))
        #expect((short.width, short.height) == (22, 22), "a short text keeps the minimum")
        let long = try render(Text("ABC").font(.title).tileFill(.fitting(minimum: .small), shape: .circle))
        #expect(long.width == long.height, "still a square")
        #expect(long.width > 40, "grown with its text: \(long.width)")
        let large = try render(Text("A").font(.largeTitle).tileFill(.fitting(minimum: .small)))
        #expect(large.width > 22 && large.width == large.height)
    }

    @Test(arguments: [ColorScheme.light, .dark])
    func theTextOnAnyTileReachesTheTint(_ scheme: ColorScheme) throws {
        let roles = ColorRoles(theme: theme, tokens: .standard, appearance: scheme == .dark ? .dark : .light)
        let page = ResolvedColors(theme, in: scheme == .dark ? .dark : .light).background
        let fill = ResolvedColors(theme, in: scheme == .dark ? .dark : .light).primary.opacity(roles.tileOpacity)
            .composited(over: page)
        let pageColor = Color(.sRGB, red: page.red, green: page.green, blue: page.blue)
        let tile = try render(
            Text("A").tileFill(.fitting(minimum: .standard), shape: .circle).background(pageColor), scheme: scheme)
        #expect(Contrast.ratio(tile.color(x: 16, y: 4), fill) < 1.02, "the tile fill, in a circle")
    }
}
