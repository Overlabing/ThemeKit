import ColorCore
import DesignKit
import SwiftUI
import Testing

/// `ThemeGlyph`'s emoji (issue #22): drawn at the rail's emoji size for its circle, in its own colours, and an emoji
/// and an initial fill their circle alike at each size.
struct ThemeGlyphEmojiSizeTests {
    /// The rail's scale and cap, applied to each circle: 13 pt in the 24 pt circle (macOS's 10 pt caption), the cap
    /// (8.8 pt, 0.55 of 16) in the small one (10 pt caption2 times 1.3 is 13).
    @Test func theEmojiSizeFollowsTheCircle() {
        let tokens = DesignTokens.standard
        #expect(abs(tokens.glyphEmojiSize(textSize: 10, circle: tokens.size.glyphCircle) - 13) < 1e-9)
        #expect(tokens.glyphEmojiSize(textSize: 10, circle: tokens.size.glyphCircle) == tokens.glyphEmojiSize(textSize: 10))
        #expect(abs(tokens.glyphEmojiSize(textSize: 10, circle: tokens.size.glyphCircleSmall) - 8.8) < 1e-9)
        #expect(abs(tokens.glyphEmojiSize(textSize: 20, circle: 40) - 22) < 1e-9, "the cap is a share of the circle")
    }
}

#if os(macOS)
@MainActor
struct ThemeGlyphEmojiRenderTests {
    static let theme = Palette.standard.themes[0]

    struct Box: Equatable, CustomStringConvertible {
        var minX = Int.max, minY = Int.max, maxX = Int.min, maxY = Int.min
        var width: Int { maxX - minX + 1 }
        var height: Int { maxY - minY + 1 }
        var description: String { "\(width)×\(height)" }
        mutating func add(_ x: Int, _ y: Int) {
            minX = min(minX, x); maxX = max(maxX, x); minY = min(minY, y); maxY = max(maxY, y)
        }
    }

    func glyph(_ size: GlyphSize, emoji: String? = nil, _ scheme: ColorScheme) throws -> Raster {
        try raster(ThemeGlyph(name: "Home", emoji: emoji, theme: Self.theme, size: size).environment(\.colorScheme, scheme))
    }

    /// What is drawn over the circle's fill (pixels that differ from it by more than 1.3:1), and how many of them lie
    /// outside the circle.
    func ink(_ raster: Raster) -> (box: Box, outside: Int) {
        let fill = raster.color(x: raster.width / 2, y: 1)
        let radius = Double(raster.width) / 2
        var box = Box()
        var outside = 0
        for y in 0..<raster.height {
            for x in 0..<raster.width {
                let dx = Double(x) + 0.5 - radius, dy = Double(y) + 0.5 - radius
                let distance = (dx * dx + dy * dy).squareRoot()
                if distance > radius - 1.5 {
                    // The circle's antialiased edge, and the transparent corners.
                    if distance > radius + 0.5, raster.alpha(x: x, y: y) > 0.25 { outside += 1 }
                } else if Contrast.ratio(raster.color(x: x, y: y), fill) > 1.3 {
                    box.add(x, y)
                }
            }
        }
        return (box, outside)
    }

    /// The emoji is drawn as a bare `Text` at the rail's emoji size would be, over the hue: no ink, no tint.
    @Test(arguments: [ColorScheme.light, .dark])
    func theEmojiKeepsItsOwnColours(_ scheme: ColorScheme) throws {
        let tokens = DesignTokens.standard
        for (size, side) in [(GlyphSize.standard, tokens.size.glyphCircle), (.small, tokens.size.glyphCircleSmall)] {
            let points = tokens.glyphEmojiSize(textSize: 10, circle: side)
            let reference = try raster(
                Text("📚").font(.system(size: points))
                    .frame(width: side, height: side)
                    .background(Self.theme.primary.color, in: .circle)
                    .environment(\.colorScheme, scheme))
            let drawn = try glyph(size, emoji: "📚", scheme)
            // A colour emoji is rasterised with a little noise from one render to the next: a few pixels of the
            // standard size may move by one level (6 to 12 of 576 seen). An ink or a tint would move the whole emoji.
            let deltas = zip(drawn.data, reference.data).map { abs(Int($0) - Int($1)) }
            #expect((drawn.width, drawn.height) == (reference.width, reference.height))
            #expect((deltas.max() ?? 0) <= 1, "\(size) \(scheme): \(deltas.max() ?? 0) levels apart")
        }
    }

    /// At each size the emoji and the initial stay inside their circle and the emoji is never the smaller. In the
    /// standard circle the emoji spans what the rail's selected emoji spans (one helper, issue #20); in the small one
    /// it spans the same share of the circle (16/24 of it, to a pixel). Measured on macOS 27: 📚 is 13×14 in 24 pt and
    /// 9×10 in 16 pt; the initial H is 7×8 in both, since caption and caption2 are both 10 pt there.
    @Test(arguments: [ColorScheme.light, .dark])
    func anEmojiAndAnInitialMatchAtEachSize(_ scheme: ColorScheme) throws {
        let rail = RailEmojiRenderTests()
        let railSelected = rail.selectedInk(2, try rail.rail(scheme)).0
        let standard = ink(try glyph(.standard, emoji: "📖", scheme))
        #expect(abs(standard.box.width - railSelected.width) <= 1 && abs(standard.box.height - railSelected.height) <= 1,
                "ThemeGlyph \(standard.box), the rail \(railSelected)")
        let tokens = DesignTokens.standard
        let share = tokens.size.glyphCircleSmall / tokens.size.glyphCircle
        let large = ink(try glyph(.standard, emoji: "📚", scheme))
        let small = ink(try glyph(.small, emoji: "📚", scheme))
        #expect(abs(Double(small.box.width) - Double(large.box.width) * share) <= 1, "\(small.box) against \(large.box)")
        #expect(abs(Double(small.box.height) - Double(large.box.height) * share) <= 1, "\(small.box) against \(large.box)")
        for (size, emoji) in [(GlyphSize.standard, large), (.small, small)] {
            let initial = ink(try glyph(size, scheme))
            #expect(emoji.outside == 0 && initial.outside == 0 && standard.outside == 0, "\(size): nothing outside")
            #expect(emoji.box.width >= initial.box.width && emoji.box.height >= initial.box.height,
                    "\(size): emoji \(emoji.box), initial \(initial.box)")
            #expect((7...8).contains(initial.box.height), "\(size): initial \(initial.box)")
        }
    }
}
#endif
