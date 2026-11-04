import ColorCore
import SwiftUI
import Testing

/// An offscreen render read back as 8-bit sRGB pixels (premultiplied), at one pixel per point.
struct Raster {
    let width: Int
    let height: Int
    let data: [UInt8]

    func color(x: Int, y: Int) -> RGBA {
        let offset = (y * width + x) * 4
        return RGBA(red: Double(data[offset]) / 255, green: Double(data[offset + 1]) / 255, blue: Double(data[offset + 2]) / 255)
    }

    func alpha(x: Int, y: Int) -> Double { Double(data[(y * width + x) * 4 + 3]) / 255 }

    var alphaSum: Int { stride(from: 3, to: data.count, by: 4).reduce(0) { $0 + Int(data[$1]) } }

    /// The ratio between two pixels, `RGBA` rounded to 8 bits as the render has it.
    func contrast(_ a: (Int, Int), _ b: (Int, Int)) -> Double {
        Contrast.ratio(color(x: a.0, y: a.1), color(x: b.0, y: b.1))
    }
}

/// Renders `view` at one pixel per point. The first render in a process differs from the next ones: it is drawn twice.
@MainActor
func raster(_ view: some View) throws -> Raster {
    func once() throws -> Raster {
        let renderer = ImageRenderer(content: view)
        renderer.scale = 1
        let image = try #require(renderer.cgImage)
        var data = [UInt8](repeating: 0, count: image.width * image.height * 4)
        let drawn = data.withUnsafeMutableBytes { buffer in
            guard let context = CGContext(
                data: buffer.baseAddress, width: image.width, height: image.height, bitsPerComponent: 8,
                bytesPerRow: image.width * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return false }
            context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
            return true
        }
        #expect(drawn)
        return Raster(width: image.width, height: image.height, data: data)
    }
    _ = try once()
    return try once()
}
