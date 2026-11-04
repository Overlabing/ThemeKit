#if os(macOS)
import AppKit
import ColorCore
import ColorUI
import DesignKit
import Foundation
import SwiftUI
import Testing

/// A view hosted in a window that is never shown, drawn into a bitmap: the one way to get a real `List` (an
/// `NSTableView`) to draw, which `ImageRenderer` does not, with the window's own appearance (Increase Contrast included).
@MainActor
struct HostedPixels {
    let width: Int
    let height: Int
    let scale: Double
    let data: [UInt8]

    init(_ view: some View, size: CGSize, appearance: NSAppearance.Name) throws {
        let hosting = NSHostingView(rootView: view)
        hosting.frame = CGRect(origin: .zero, size: size)
        let window = NSWindow(contentRect: hosting.frame, styleMask: [.borderless], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.appearance = NSAppearance(named: appearance)
        window.contentView = hosting
        hosting.layoutSubtreeIfNeeded()
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.5))
        hosting.layoutSubtreeIfNeeded()
        let rep = try #require(hosting.bitmapImageRepForCachingDisplay(in: hosting.bounds))
        hosting.cacheDisplay(in: hosting.bounds, to: rep)
        let image = try #require(rep.cgImage)
        var bytes = [UInt8](repeating: 0, count: image.width * image.height * 4)
        let drawn = bytes.withUnsafeMutableBytes { buffer in
            guard let context = CGContext(
                data: buffer.baseAddress, width: image.width, height: image.height, bitsPerComponent: 8,
                bytesPerRow: image.width * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return false }
            context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
            return true
        }
        #expect(drawn)
        window.contentView = nil
        width = image.width
        height = image.height
        scale = Double(image.width) / size.width
        data = bytes
    }

    /// The colour at a point in the view's own coordinates (points, from the top left).
    func color(x: Double, y: Double) -> RGBA {
        let px = min(width - 1, Int(x * scale)), py = min(height - 1, Int(y * scale))
        let offset = (py * width + px) * 4
        return RGBA(red: Double(data[offset]) / 255, green: Double(data[offset + 1]) / 255, blue: Double(data[offset + 2]) / 255)
    }
}

/// `List` cells, drawn for real: a `List` is an `NSTableView`, which hands each cell the system's own Increase Contrast
/// and colour scheme instead of the SwiftUI environment around the list. The kit's views read its own override too
/// (`accessibilityOverrides`), so Increase Contrast can be seen in a cell without touching the system's setting.
@MainActor
@Suite(.enabled(if: ProcessInfo.processInfo.operatingSystemVersion.majorVersion == 27))
struct ListCellTests {
    static let size = CGSize(width: 320, height: 120)

    /// One row as a `List` cell: a `ListRowContent` with `listRowCell`, so `ListRowBackground` is the cell's background.
    func cell(
        _ state: RowState, theme: Theme, increaseContrast: Bool, appearance: NSAppearance.Name
    ) throws -> HostedPixels {
        let view = List {
            ListRowContent("Title", details: ["Detail"], state: state) { Tile(.initial("T")) }
                .listRowCell(state: state)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background { WindowBackground() }
        .theme(theme)
        .accessibilityOverrides(increaseContrast: increaseContrast)
        .frame(width: Self.size.width, height: Self.size.height)
        _ = try HostedPixels(view, size: Self.size, appearance: appearance)  // warm up
        return try HostedPixels(view, size: Self.size, appearance: appearance)
    }

    /// The row's background starts at 4 pt; its bar is 2 pt in and 3 pt wide; the row is 48 pt tall under 2 pt.
    @Test(arguments: [Palette.standard.themes[0], Palette.standard.themes[2]], [NSAppearance.Name.aqua, .darkAqua])
    func aSelectedCellShowsItsMarker(_ theme: Theme, _ appearance: NSAppearance.Name) throws {
        let pixels = try cell(RowState(isSelected: true), theme: theme, increaseContrast: false, appearance: appearance)
        let marker = pixels.color(x: 7.5, y: 26)
        let fill = pixels.color(x: 10.5, y: 26)
        #expect(Contrast.ratio(marker, fill) >= 2.9, "\(theme.id) \(appearance.rawValue)")
    }

    /// Under Increase Contrast the cell is outlined in the secondary ink instead (4.5:1 on its fill) and has no bar.
    @Test(arguments: [Palette.standard.themes[0], Palette.standard.themes[2]], [NSAppearance.Name.aqua, .darkAqua])
    func increaseContrastReachesTheCellBackground(_ theme: Theme, _ appearance: NSAppearance.Name) throws {
        let pixels = try cell(RowState(isSelected: true), theme: theme, increaseContrast: true, appearance: appearance)
        let outline = pixels.color(x: 4.5, y: 26)
        let fill = pixels.color(x: 10.5, y: 26)
        #expect(Contrast.ratio(outline, fill) >= 3, "outline \(theme.id) \(appearance.rawValue)")
        #expect(Contrast.ratio(pixels.color(x: 7.5, y: 26), fill) < 1.05, "no bar \(theme.id) \(appearance.rawValue)")
        let top = pixels.color(x: 60, y: 2.5)
        #expect(Contrast.ratio(top, fill) >= 3, "top edge \(theme.id) \(appearance.rawValue)")
    }

    /// A current row is outlined under Increase Contrast and a hovered one is not; a plain row has no fill.
    @Test func aCurrentCellIsOutlinedAndAHoveredOneIsNot() throws {
        let theme = Palette.standard.themes[0]
        let current = try cell(RowState(isCurrent: true), theme: theme, increaseContrast: true, appearance: .aqua)
        #expect(Contrast.ratio(current.color(x: 4.5, y: 26), current.color(x: 10.5, y: 26)) >= 3)
        let hovered = try cell(RowState(isHovered: true), theme: theme, increaseContrast: true, appearance: .aqua)
        #expect(Contrast.ratio(hovered.color(x: 4.5, y: 26), hovered.color(x: 10.5, y: 26)) < 1.05)
        let plain = try cell(RowState(), theme: theme, increaseContrast: true, appearance: .aqua)
        #expect(Contrast.ratio(plain.color(x: 4.5, y: 26), plain.color(x: 10.5, y: 26)) < 1.05)
        #expect(Contrast.ratio(hovered.color(x: 10.5, y: 26), plain.color(x: 10.5, y: 26)) > 1.05)
    }

    /// A cell lines up with a `ListRow` in a stack: the fill, the bar, the tile and the row's top edge start and end on
    /// the same pixels. The `List` keeps a margin round a cell's content that `listRowCell` cancels.
    @Test func aCellLinesUpWithTheRowInAStack() throws {
        let theme = Palette.standard.themes[0]
        let state = RowState(isSelected: true)
        let stack = try raster(
            ListRow("Title", details: ["Detail"], state: state) { Tile(.initial("T")) }
                .frame(width: 320)
                .background { WindowBackground() }
                .theme(theme))
        let hosted = try cell(state, theme: theme, increaseContrast: false, appearance: .aqua)
        func columns(_ color: (Double) -> RGBA, in range: Range<Int>) -> [Int] {
            range.filter { Contrast.ratio(color(Double($0) + 0.5), color(Double($0) - 0.5)) > 1.1 }
        }
        func rows(_ color: (Double) -> RGBA) -> [Int] {
            (1..<8).filter { Contrast.ratio(color(Double($0) + 0.5), color(Double($0) - 0.5)) > 1.1 }
        }
        let left = columns({ stack.color(x: Int($0), y: 26) }, in: 1..<24) + columns({ stack.color(x: Int($0), y: 26) }, in: 40..<50)
        #expect(left == [4, 6, 9, 12, 44], "the fill, the bar in and out, the tile in and out: \(left)")
        #expect(columns({ hosted.color(x: $0, y: 26) }, in: 1..<24) + columns({ hosted.color(x: $0, y: 26) }, in: 40..<50) == left)
        let right = columns({ stack.color(x: Int($0), y: 26) }, in: 300..<319)
        #expect(columns({ hosted.color(x: $0, y: 26) }, in: 300..<319) == right, "\(right)")
        let stackRows = rows { stack.color(x: 60, y: Int($0)) }
        #expect(stackRows == [2])
        #expect(rows { hosted.color(x: 60, y: $0) } == stackRows)
    }

    /// The margin a `List` keeps is the token's: a bare cell's content starts that far in with zero insets, and at the
    /// edge once the kit's negative inset cancels it.
    @Test func theListKeepsTheTokensMarginRoundACellsContent() throws {
        func redStart(_ insets: EdgeInsets) throws -> Int? {
            let view = List {
                Color(red: 1, green: 0, blue: 0).frame(height: 20)
                    .listRowInsets(insets)
                    .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color.white)
            .frame(width: 320, height: 60)
            let pixels = try HostedPixels(view, size: CGSize(width: 320, height: 60), appearance: .aqua)
            return (0..<320).first { x in
                let color = pixels.color(x: Double(x) + 0.5, y: 8)
                return color.red > 0.9 && color.blue < 0.1
            }
        }
        let margin = DesignTokens.standard.spacing.listCellMargin
        #expect(margin == 8)
        #expect(try redStart(EdgeInsets()) == Int(margin))
        #expect(try redStart(EdgeInsets(top: 0, leading: -margin, bottom: 0, trailing: -margin)) == 0)
    }
}
#endif
