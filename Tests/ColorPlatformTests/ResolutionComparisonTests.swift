#if canImport(AppKit)
import ColorCore
import ColorPlatform
import Foundation
import Testing

/// Resolution gives the colours the original implementation gave, in the same appearances. System colours belong to
/// the system: the expectations were recorded on macOS 27, so the comparison runs there (the 4.5:1 invariants in
/// `SystemLegibilityTests` run everywhere).
@Suite(.enabled(if: ProcessInfo.processInfo.operatingSystemVersion.majorVersion == 27))
struct ResolutionComparisonTests {
    private func expectClose(_ a: RGBA, _ b: RGBA, _ name: String, sourceLocation: SourceLocation = #_sourceLocation) {
        let tolerance = 0.002
        #expect(
            abs(a.red - b.red) < tolerance && abs(a.green - b.green) < tolerance && abs(a.blue - b.blue) < tolerance
                && abs(a.alpha - b.alpha) < tolerance,
            "\(name): \(a) is not \(b)", sourceLocation: sourceLocation)
    }

    @Test(arguments: NativeGolden.all.map(\.appearance))
    func hueAndLabelColorsMatch(_ appearance: Appearance) throws {
        let golden = try #require(NativeGolden.all.first { $0.appearance == appearance })
        for hue in Hue.allCases {
            expectClose(RGBA(hue.systemColor, in: appearance), try #require(golden.hues[hue]), "\(hue) \(appearance)")
        }
        let theme = Theme(id: "any", primary: .indigo, secondary: .blue)
        let colors = ResolvedColors(theme, in: appearance)
        expectClose(colors.background, golden.background, "background \(appearance)")
        expectClose(colors.label, golden.label, "label \(appearance)")
        expectClose(colors.secondaryLabel, golden.secondaryLabel, "secondaryLabel \(appearance)")
    }

    @Test func increasedContrastResolvesLikeItsBaseOnAppKit() throws {
        let light = try #require(NativeGolden.all.first { $0.appearance == .light })
        let increased = try #require(NativeGolden.all.first { $0.appearance == .lightIncreasedContrast })
        #expect(light.hues == increased.hues)
    }
}
#endif
