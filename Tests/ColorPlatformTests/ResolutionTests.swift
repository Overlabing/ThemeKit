#if canImport(AppKit) || canImport(UIKit)
import ColorCore
import ColorPlatform
import Foundation
import Testing
#if !canImport(AppKit)
import UIKit
#endif

/// The aliases and the per-appearance colours built on them, on macOS and on the iOS simulator alike.
struct ResolutionTests {
    @Test func sRGBComponentsSurviveTheNativeColor() {
        let rgba = RGBA(.sRGB(red: 0.2, green: 0.4, blue: 0.6, alpha: 0.5), in: .light)
        #expect(abs(rgba.red - 0.2) < 0.001)
        #expect(abs(rgba.green - 0.4) < 0.001)
        #expect(abs(rgba.blue - 0.6) < 0.001)
        #expect(abs(rgba.alpha - 0.5) < 0.001)
        #expect(RGBA(RGBA.black.nativeColor, in: .dark) == .black)
    }

    @Test(arguments: Appearance.allCases)
    func aDynamicColorFollowsTheAppearance(_ appearance: Appearance) {
        let color = NativeColor.dynamic { resolved in
            .sRGB(red: resolved.isDark ? 1 : 0, green: resolved.isIncreasedContrast ? 1 : 0, blue: 0)
        }
        let rgba = RGBA(color, in: appearance)
        #expect(rgba.red == (appearance.isDark ? 1 : 0))
        // AppKit answers plain Aqua when asked for a high contrast appearance by name (measured on macOS 27): only the
        // system's own choice of appearance reaches a dynamic colour there.
        #if !canImport(AppKit)
        #expect(rgba.green == (appearance.isIncreasedContrast ? 1 : 0))
        #endif
    }

    /// The label is the one thing the legibility solver cannot do without: dark text in light, light text in dark.
    @Test(arguments: Appearance.allCases)
    func theSystemColorsResolveInEachAppearance(_ appearance: Appearance) throws {
        let theme = try #require(Palette.standard.themes.first)
        let colors = ResolvedColors(theme, accents: theme.accents(plus: [.mint, .yellow]), in: appearance)
        #expect(colors.background.alpha == 1)
        #expect(colors.ink == (appearance.isDark ? .white : .black))
        #expect(Contrast.ratio(colors.ink, colors.background) >= Contrast.text)
        #expect(colors.accents.count == 4)
        #expect(ResolvedColors(theme, in: appearance).accents.isEmpty)
    }

    @Test func everyHueHasASystemColor() {
        let hues = Set(Hue.allCases.map { RGBA($0.systemColor, in: .light).relativeLuminance })
        #expect(hues.count == Hue.allCases.count)
    }

    #if !canImport(AppKit)
    @Test(arguments: Appearance.allCases)
    func traitsRoundTrip(_ appearance: Appearance) {
        #expect(Appearance(appearance.traits) == appearance)
    }

    /// Traits not settled yet (a view off screen) read as the default appearance.
    @Test func unspecifiedTraitsAreLight() {
        #expect(Appearance(UITraitCollection()) == .light)
    }
    #endif
}

/// Every text reaches 4.5:1 on every surface it sits on, in the light appearances, with the system colours of the
/// system running the tests; and the solved description is the cached one on the second ask.
struct SystemLegibilityTests {
    @Test(arguments: [Appearance.light, .lightIncreasedContrast])
    func everyTextReachesAAOnEveryTheme(_ appearance: Appearance) {
        for theme in Palette.standard.themes {
            let solved = Legibility.of(
                theme, accents: theme.accents(plus: [.mint, .yellow]), surfaces: .listColumn(in: appearance),
                in: appearance)
            let name = "\(theme.id) \(appearance)"
            #expect(solved.worstSecondary >= Contrast.text, "secondary \(name): \(solved.worstSecondary)")
            #expect(solved.worstTint >= Contrast.text, "tint \(name): \(solved.worstTint)")
            #expect(solved.worstAccent >= Contrast.text, "accent \(name): \(solved.worstAccent)")
            #expect(solved.worstLabel >= Contrast.text, "label \(name): \(solved.worstLabel)")
        }
    }

    @Test(arguments: Appearance.allCases)
    func solvingTwiceAnswersTheSame(_ appearance: Appearance) throws {
        let theme = try #require(Palette.standard.theme(id: "orange-pink"))
        let surfaces = Surfaces.listColumn(in: appearance)
        let first = Legibility.of(theme, surfaces: surfaces, in: appearance)
        let again = Legibility.of(theme, surfaces: surfaces, in: appearance)
        #expect(first == again)
        #expect(first == Legibility.solve(colors: ResolvedColors(theme, in: appearance), surfaces: surfaces))
    }

    @Test func differentSurfacesAreNotServedFromTheSameCacheEntry() throws {
        let theme = try #require(Palette.standard.theme(id: "teal-green"))
        var other = Surfaces.listColumn(in: .light)
        other.contentTop = 0.5
        let a = Legibility.of(theme, surfaces: .listColumn(in: .light), in: .light)
        let b = Legibility.of(theme, surfaces: other, in: .light)
        #expect(a != b)
    }

    @Test func solvingEveryThemeIsCheap() {
        let clock = ContinuousClock()
        let elapsed = clock.measure {
            for appearance in [Appearance.light, .lightIncreasedContrast] {
                for theme in Palette.standard.themes {
                    _ = Legibility.solve(
                        colors: ResolvedColors(theme, accents: theme.accents(plus: [.mint, .yellow]), in: appearance),
                        surfaces: .listColumn(in: appearance))
                }
            }
        }
        #expect(elapsed < .milliseconds(200), "14 solves took \(elapsed)")
    }
}
#endif
