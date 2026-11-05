#if os(macOS)
import AppKit
#endif
import ColorCore
import DesignKit
import SwiftUI
import Testing

/// An emoji glyph is drawn at its own size: the glyph circle's text style times `glyphEmojiScale`, capped so that its
/// artwork stays inside the circle (issue #20).
struct RailEmojiSizeTests {
    let tokens = DesignTokens.standard

    @Test func theEmojiScaleIsPinned() {
        #expect(tokens.type.glyphEmojiScale == 1.3)
        #expect(DesignTokens.glyphEmojiMaxShare == 0.55)
    }

    /// macOS's caption is 10 pt: the emoji is 13 pt. iOS's is 12 pt (more under Dynamic Type): the cap, 13.2 pt.
    @Test func anEmojiIsTheCaptionTimesTheScaleUpToTheCap() {
        #expect(abs(tokens.glyphEmojiSize(textSize: 10) - 13) < 1e-9)
        #expect(abs(tokens.glyphEmojiSize(textSize: 12) - 13.2) < 1e-9)
        #expect(abs(tokens.glyphEmojiSize(textSize: 20) - 13.2) < 1e-9)
        var small = tokens
        small.size.glyphCircle = 16
        #expect(abs(small.glyphEmojiSize(textSize: 10) - 8.8) < 1e-9, "the cap follows the circle")
    }
}

#if os(macOS)
/// The rail's emoji read back from an offscreen render: a quiet 📚, a quiet initial (H) and the selected 📖, side by
/// side. Every ink pixel lies inside its 24 pt circle, and an emoji's artwork spans about twice the initial's height.
/// (At the glyph font's own size an emoji's artwork already spans 11 to 13 pt; 1.3 makes it fill two thirds of the
/// circle, the largest tenth at which a square emoji's corners stay inside it.)
@MainActor
struct RailEmojiRenderTests {
    struct Box: Equatable {
        var minX = Int.max, minY = Int.max, maxX = Int.min, maxY = Int.min
        var width: Int { maxX - minX + 1 }
        var height: Int { maxY - minY + 1 }
        mutating func add(_ x: Int, _ y: Int) {
            minX = min(minX, x); maxX = max(maxX, x); minY = min(minY, y); maxY = max(maxY, y)
        }
    }

    static let theme = Palette.standard.themes[0]

    func rail(_ scheme: ColorScheme) throws -> Raster {
        let spaces = [
            SpaceRailSpace(id: "books", name: "Books", glyph: .emoji("📚"), theme: Self.theme),
            SpaceRailSpace(id: "home", name: "Home", theme: Self.theme),
            SpaceRailSpace(id: "reading", name: "Reading", glyph: .emoji("📖"), theme: Self.theme),
        ]
        return try raster(SpaceRail(spaces: spaces, selection: "reading", selectSpace: { _ in })
            .frame(width: 300)
            .theme(Self.theme)
            .environment(\.colorScheme, scheme))
    }

    /// The `index`th target's glyph circle: centre and the row's top. The row is the bottom 36 pt above an 8 pt margin;
    /// targets are 28 pt from x 10, the circle 2…26 from the row's top.
    func circle(_ index: Int, in raster: Raster) -> (cx: Double, cy: Double, top: Int, left: Int) {
        let top = raster.height - 8 - 36
        let left = 10 + 28 * index
        return (Double(left) + 14, Double(top) + 14, top, left)
    }

    func distance(_ x: Int, _ y: Int, _ c: (cx: Double, cy: Double, top: Int, left: Int)) -> Double {
        ((Double(x) + 0.5 - c.cx) * (Double(x) + 0.5 - c.cx) + (Double(y) + 0.5 - c.cy) * (Double(y) + 0.5 - c.cy)).squareRoot()
    }

    /// The ink of a quiet glyph: every pixel drawn in its target, above the marker.
    func quietInk(_ index: Int, _ raster: Raster) -> (Box, outside: Int) {
        let c = circle(index, in: raster)
        var box = Box()
        var outside = 0
        for y in c.top..<(c.top + 28) {
            for x in c.left..<(c.left + 28) where raster.alpha(x: x, y: y) > 0.25 {
                box.add(x, y)
                if distance(x, y, c) > 12.5 { outside += 1 }
            }
        }
        return (box, outside)
    }

    /// The ink of the selected emoji: pixels inside the circle that differ from its fill, and anything drawn outside it.
    func selectedInk(_ index: Int, _ raster: Raster) -> (Box, outside: Int) {
        let c = circle(index, in: raster)
        let fill = raster.color(x: Int(c.cx), y: c.top + 3)
        var box = Box()
        var outside = 0
        for y in c.top..<(c.top + 28) {
            for x in c.left..<(c.left + 28) {
                let d = distance(x, y, c)
                if d > 12.5 {
                    // The marker sits under the circle, 28…31 from the row's top: outside these rows nothing is drawn.
                    if y < c.top + 27, raster.alpha(x: x, y: y) > 0.25 { outside += 1 }
                } else if d < 11, Contrast.ratio(raster.color(x: x, y: y), fill) > 1.3 {
                    box.add(x, y)
                }
            }
        }
        return (box, outside)
    }

    @Test(arguments: [ColorScheme.light, .dark])
    func anEmojiFillsItsCircleTheWayAnInitialDoesAndStaysInside(_ scheme: ColorScheme) throws {
        let raster = try rail(scheme)
        let (emoji, emojiOutside) = quietInk(0, raster)
        let (initial, initialOutside) = quietInk(1, raster)
        let (selected, selectedOutside) = selectedInk(2, raster)
        #expect(emojiOutside == 0 && initialOutside == 0 && selectedOutside == 0, "nothing drawn outside the circles")
        // The caption's H is 7 pt tall (8 with its antialiased edge in dark); at 1.0 an emoji was 11 to 13 pt, at 1.3
        // it is 14 to 16, about twice the H.
        #expect((7...8).contains(initial.height), "initial \(initial)")
        #expect((14...18).contains(emoji.height) && (14...18).contains(emoji.width), "quiet emoji \(emoji)")
        #expect((12...18).contains(selected.height) && (14...18).contains(selected.width), "selected emoji \(selected)")
        #expect(emoji.height >= initial.height + 6)
    }
}

/// A Space rail panel draws its focus ring only when it was opened from the keyboard, or after the first arrow or Tab.
@MainActor
struct RailPanelFocusRenderTests {
    let model = SpaceRailModel(spaces: [SpaceRailSpace(id: "a", name: "A", theme: Palette.standard.themes[0])], selection: "a")
    let commands = [[SpaceRailCommand(id: "new", title: "New Space in Personal…", systemImage: "plus"),
                     SpaceRailCommand(id: "edit", title: "Edit Profile…")]]

    /// Drawn through AppKit, offscreen with no window: `ImageRenderer` draws no scroll view, so no panel.
    func render(focus: String, showsFocusRing: Bool) throws -> Raster {
        let panel = SpaceRailPanel(model: model, commands: commands, showsSpaces: false, focus: focus,
                                   showsFocusRing: showsFocusRing, selectSpace: { _ in }, perform: { _ in })
            .theme(Palette.standard.themes[0])
        let hosting = NSHostingView(rootView: panel)
        hosting.frame = NSRect(origin: .zero, size: hosting.fittingSize)
        hosting.layoutSubtreeIfNeeded()
        let rep = try #require(hosting.bitmapImageRepForCachingDisplay(in: hosting.bounds))
        hosting.cacheDisplay(in: hosting.bounds, to: rep)
        let image = try #require(rep.cgImage)
        var data = [UInt8](repeating: 0, count: image.width * image.height * 4)
        data.withUnsafeMutableBytes { buffer in
            let context = CGContext(
                data: buffer.baseAddress, width: image.width, height: image.height, bitsPerComponent: 8,
                bytesPerRow: image.width * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
            context?.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        }
        return Raster(width: image.width, height: image.height, data: data)
    }

    @Test func aPanelOpenedWithThePointerDrawsNoRing() throws {
        let none = try render(focus: "nothing", showsFocusRing: true)
        let pointer = try render(focus: "new", showsFocusRing: false)
        let keyboard = try render(focus: "new", showsFocusRing: true)
        #expect(pointer.data == none.data, "no ring on the first row")
        #expect(keyboard.data != none.data, "the ring on the first row")
    }
}
#endif

/// The keyboard inside a Space rail panel (`SpaceRailPanelFocus`).
struct RailPanelFocusTests {
    let ids = ["new", "profile", "edit"]

    @Test func openedWithThePointerTheFirstArrowShowsTheRingWithoutMoving() {
        var focus = SpaceRailPanelFocus(row: "new", showsRing: false)
        #expect(focus.press(.activate, in: ids) == .ignored, "Return picks nothing it does not show")
        #expect(focus.press(.down, in: ids) == .revealed)
        #expect(focus == SpaceRailPanelFocus(row: "new", showsRing: true))
        #expect(focus.press(.down, in: ids) == .moved)
        #expect(focus.row == "profile")
        #expect(focus.press(.activate, in: ids) == .pick("profile"))
    }

    @Test func openedWithThePointerTabShowsTheRingThenGoesToTheSystem() {
        var focus = SpaceRailPanelFocus(row: "new", showsRing: false)
        #expect(focus.press(.tab, in: ids) == .revealed)
        #expect(focus == SpaceRailPanelFocus(row: "new", showsRing: true))
        #expect(focus.press(.tab, in: ids) == .ignored)
        #expect(focus.row == "new")
    }

    @Test func anUpArrowShowsTheRingTooAndARowThatIsGoneFallsBackToTheFirst() {
        var focus = SpaceRailPanelFocus(row: "gone", showsRing: false)
        #expect(focus.press(.up, in: ids) == .revealed)
        #expect(focus == SpaceRailPanelFocus(row: "new", showsRing: true))
    }

    @Test func openedFromTheKeyboardTheRingStartsOnTheFirstRowAndArrowsMove() {
        var focus = SpaceRailPanelFocus(row: "new", showsRing: true)
        #expect(focus.press(.activate, in: ids) == .pick("new"))
        #expect(focus.press(.up, in: ids) == .moved)
        #expect(focus.row == "new", "stops at the top")
        #expect(focus.press(.down, in: ids) == .moved)
        #expect(focus.press(.down, in: ids) == .moved)
        #expect(focus.press(.down, in: ids) == .moved)
        #expect(focus.row == "edit", "stops at the bottom")
        #expect(focus.press(.tab, in: ids) == .ignored)
    }

    @Test func escapeClosesEitherWay() {
        var pointer = SpaceRailPanelFocus(row: "new", showsRing: false)
        var keyboard = SpaceRailPanelFocus(row: "new", showsRing: true)
        #expect(pointer.press(.escape, in: ids) == .dismiss)
        #expect(keyboard.press(.escape, in: ids) == .dismiss)
        #expect(!pointer.showsRing)
    }
}
