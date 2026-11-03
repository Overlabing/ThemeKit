import ColorCore
import Testing

struct PaletteTests {
    @Test func themeIDsAreUniqueAndIndigoLeads() {
        let ids = Palette.standard.themes.map(\.id)
        #expect(Set(ids).count == ids.count)
        #expect(ids.first == "indigo-blue")
    }

    @Test func standardPaletteIsTheSevenPresetsInOrder() {
        let pairs = Palette.standard.themes.map { "\($0.id):\($0.primary.rawValue)+\($0.secondary.rawValue)" }
        #expect(pairs == [
            "indigo-blue:indigo+blue", "orange-pink:orange+pink", "teal-green:teal+green", "red-orange:red+orange",
            "purple-pink:purple+pink", "mint-cyan:mint+cyan", "brown-yellow:brown+yellow",
        ])
    }

    @Test func aThemeIsFoundByItsID() {
        #expect(Palette.standard.theme(id: "teal-green") == Theme(id: "teal-green", primary: .teal, secondary: .green))
        #expect(Palette.standard.theme(id: "nope") == nil)
    }

    @Test func appearancesRoundTripTheirFlags() {
        for appearance in Appearance.allCases {
            #expect(Appearance(isDark: appearance.isDark, isIncreasedContrast: appearance.isIncreasedContrast) == appearance)
        }
        #expect(Appearance.allCases.count == 4)
    }

    @Test func gradientColorAtTheStopsIsTheStopOverTheBackground() {
        let spec = GradientSpec(top: 0.5, middle: 0.25, bottom: 0.1)
        let primary = RGBA(red: 1, green: 0, blue: 0), secondary = RGBA(red: 0, green: 0, blue: 1)
        #expect(spec.color(at: 0, primary: primary, secondary: secondary, over: .white) == primary.opacity(0.5).composited(over: .white))
        #expect(spec.color(at: 0.5, primary: primary, secondary: secondary, over: .white) == secondary.opacity(0.25).composited(over: .white))
        #expect(spec.color(at: 1, primary: primary, secondary: secondary, over: .white) == primary.opacity(0.1).composited(over: .white))
        #expect(GradientSpec.standard(isDark: true) == .dark && GradientSpec.standard(isDark: false) == .light)
    }
}
