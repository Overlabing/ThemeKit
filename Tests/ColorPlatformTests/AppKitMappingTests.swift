#if canImport(AppKit)
import AppKit
import ColorCore
import ColorPlatform
import Testing

struct AppKitMappingTests {
    /// AppKit hands back plain Aqua or Dark Aqua for the high contrast names (measured on macOS 27, the same behaviour
    /// as resolution): the light/dark half always survives the round trip, the contrast half only where the system
    /// keeps it.
    @Test(arguments: Appearance.allCases)
    func anAppearanceNameKeepsItsDarkness(_ appearance: Appearance) throws {
        let ns = try #require(NSAppearance(named: appearance.appearanceName))
        #expect(Appearance(ns).isDark == appearance.isDark)
        if !appearance.isIncreasedContrast { #expect(Appearance(ns) == appearance) }
    }

    @Test func vibrantAppearancesFoldIntoTheirBase() throws {
        #expect(Appearance(try #require(NSAppearance(named: .vibrantDark))) == .dark)
        #expect(Appearance(try #require(NSAppearance(named: .vibrantLight))) == .light)
    }
}
#endif
