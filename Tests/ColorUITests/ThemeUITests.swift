import ColorCore
import ColorPlatform
import ColorUI
import Foundation
import SwiftUI
import Testing

struct ThemeNameTests {
    private func name(of theme: Theme, in locale: String) -> String {
        var resource = theme.displayName
        resource.locale = Locale(identifier: locale)
        return String(localized: resource)
    }

    @Test func standardThemesHaveEnglishNames() {
        let names = Palette.standard.themes.map { name(of: $0, in: "en") }
        #expect(names == [
            "Indigo and blue", "Orange and pink", "Teal and green", "Red and orange", "Purple and pink", "Mint and cyan",
            "Brown and yellow",
        ])
    }

    @Test func standardThemesHaveFrenchTranslations() {
        let names = Palette.standard.themes.map { name(of: $0, in: "fr") }
        #expect(names == [
            "Indigo et bleu", "Orange et rose", "Bleu canard et vert", "Rouge et orange", "Violet et rose",
            "Menthe et cyan", "Brun et jaune",
        ])
    }

    @Test func aThemeOutsideThePaletteReadsAsASystemColor() {
        let unknown = Theme(id: "custom", primary: .red, secondary: .blue)
        #expect(name(of: unknown, in: "en") == "System color")
        #expect(name(of: unknown, in: "fr") == "Couleur du système")
    }
}

struct HueColorTests {
    /// SwiftUI's system colours are the AppKit and UIKit ones, as resolved by `ColorPlatform`.
    @Test(arguments: Hue.allCases)
    func swiftUIHueMatchesThePlatformHue(_ hue: Hue) {
        let resolved = hue.color.resolve(in: EnvironmentValues())
        let platform = RGBA(hue.systemColor, in: .light)
        #expect(abs(Double(resolved.red) - platform.red) < 0.01, "\(hue) red")
        #expect(abs(Double(resolved.green) - platform.green) < 0.01, "\(hue) green")
        #expect(abs(Double(resolved.blue) - platform.blue) < 0.01, "\(hue) blue")
    }
}

@MainActor
struct ThemeViewTests {
    @Test func theThemeIsInTheEnvironmentOnlyOnceSet() throws {
        var values = EnvironmentValues()
        #expect(values.theme == nil)
        let theme = try #require(Palette.standard.theme(id: "mint-cyan"))
        values.theme = theme
        #expect(values.theme == theme)
    }

    private func pixel(of view: some View, x: Int, y: Int, dark: Bool) throws -> RGBA {
        let renderer = ImageRenderer(content: view.environment(\.colorScheme, dark ? .dark : .light))
        renderer.scale = 1
        let image = try #require(renderer.cgImage)
        let data = try #require(image.dataProvider?.data)
        let bytes = CFDataGetBytePtr(data)!
        let offset = y * image.bytesPerRow + x * (image.bitsPerPixel / 8)
        let order = image.bitmapInfo.rawValue & CGBitmapInfo.byteOrderMask.rawValue
        let (r, g, b) = order == CGBitmapInfo.byteOrder32Little.rawValue
            ? (bytes[offset + 2], bytes[offset + 1], bytes[offset]) : (bytes[offset], bytes[offset + 1], bytes[offset + 2])
        return RGBA(red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255)
    }

    /// What the legibility solver measures is what the view draws: the top and the middle of the background are the
    /// gradient's colours at 0 and 0.5 over the plain `.background` the view fills first (which SwiftUI draws a little
    /// lighter than the window background colour in dark, hence rendering it rather than resolving it).
    @Test(arguments: [false, true])
    func theBackgroundDrawsTheGradientTheSolverMeasures(_ dark: Bool) throws {
        let theme = try #require(Palette.standard.theme(id: "orange-pink"))
        let view = GradientBackground(theme: theme).frame(width: 40, height: 201)
        let spec = GradientSpec.standard(isDark: dark)
        let colors = ResolvedColors(theme, in: dark ? .dark : .light)
        let plain = try pixel(of: Rectangle().fill(.background).frame(width: 40, height: 201), x: 20, y: 0, dark: dark)
        for (row, t) in [(0, 0.0), (100, 0.5)] {
            let drawn = try pixel(of: view, x: 20, y: row, dark: dark)
            let expected = spec.color(at: t, primary: colors.primary, secondary: colors.secondary, over: plain)
            #expect(abs(drawn.red - expected.red) < 0.03, "red at \(t): \(drawn) vs \(expected)")
            #expect(abs(drawn.green - expected.green) < 0.03, "green at \(t): \(drawn) vs \(expected)")
            #expect(abs(drawn.blue - expected.blue) < 0.03, "blue at \(t): \(drawn) vs \(expected)")
        }
    }

    @Test func aSwatchRendersItsTwoHues() throws {
        let theme = try #require(Palette.standard.theme(id: "indigo-blue"))
        let corner = try pixel(of: ThemeSwatch(theme, size: 40), x: 8, y: 8, dark: false)
        let opposite = try pixel(of: ThemeSwatch(theme, size: 40), x: 31, y: 31, dark: false)
        #expect(corner != opposite)
    }
}
