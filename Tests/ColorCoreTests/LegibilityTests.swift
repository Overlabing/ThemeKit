import ColorCore
import Foundation
import Testing

/// The surfaces of a list column, as a client describes its own: this is the description the solver was first written
/// for, kept here to prove that a description passed as a parameter solves exactly as the constants it replaced.
extension Surfaces {
    static func listColumn(in appearance: Appearance) -> Surfaces {
        let dark = Surfaces(
            gradient: GradientSpec(top: 0.42, middle: 0.18, bottom: 0.06), contentTop: 0.1,
            fills: [0.10, 0.16], selection: Selection(floor: 0.25, cap: 0.5, visibility: 1.3),
            tintFills: [0.14, 0.25])
        var base = dark
        if !appearance.isDark {
            base.gradient = GradientSpec(top: 0.38, middle: 0.16, bottom: 0.05)
            base.selection.floor = 0.30
        }
        if appearance.isIncreasedContrast {
            base.fills = base.fills.map { min(1, $0 * 1.8) }
            base.selection.floor = min(1, base.selection.floor * 1.8)
        }
        return base
    }
}

struct LegibilityTests {
    @Test func solverFindsTheSmallestPassingValue() {
        #expect(abs(Legibility.solveMinimum(from: 0, to: 1) { $0 >= 0.3 } - 0.3) < 0.002)
        #expect(Legibility.solveMinimum(from: 0.4, to: 1) { $0 >= 0.3 } == 0.4)
        #expect(Legibility.solveMinimum(from: 0, to: 1) { _ in false } == 1)
        #expect(Legibility.solveMinimum(from: 0, to: 1) { $0 >= 0.3 } == 0.30078125)
        #expect(Legibility.solveMinimum(from: 0.1, to: 0.5) { $0 >= 0.33 } == 0.3304687499999999)
    }

    /// The same colours and the same surfaces as the original solver, solved to the same values (28 cases: seven
    /// themes in four appearances; the colours are those the system gave when the expectations were recorded).
    @Test(arguments: Golden.all)
    func solvingMatchesTheOriginalSolver(_ golden: Golden) {
        let solved = Legibility.solve(colors: golden.colors, surfaces: .listColumn(in: golden.appearance))
        let name = "\(golden.theme) \(golden.appearance)"
        #expect(abs(solved.selected - golden.selected) < 1e-12, "selected \(name)")
        #expect(abs(solved.secondaryAlpha - golden.secondaryAlpha) < 1e-12, "secondaryAlpha \(name)")
        #expect(abs(solved.tintMix - golden.tintMix) < 1e-12, "tintMix \(name)")
        #expect(solved.accentMix == golden.accentMix, "accentMix \(name)")
        #expect(abs(solved.worstLabel - golden.worstLabel) < 1e-9, "worstLabel \(name)")
        #expect(abs(solved.worstSecondary - golden.worstSecondary) < 1e-9, "worstSecondary \(name)")
        #expect(abs(solved.worstTint - golden.worstTint) < 1e-9, "worstTint \(name)")
        #expect(abs(solved.worstAccent - golden.worstAccent) < 1e-9, "worstAccent \(name)")
        #expect(abs(solved.worstSystemSecondary - golden.worstSystemSecondary) < 1e-9, "worstSystemSecondary \(name)")
        #expect(abs(solved.worstRawTint - golden.worstRawTint) < 1e-9, "worstRawTint \(name)")
        #expect(abs(solved.selectionShows - golden.selectionShows) < 1e-9, "selectionShows \(name)")
        #expect(abs(solved.gradientShows - golden.gradientShows) < 1e-9, "gradientShows \(name)")
    }

    /// Every text reaches 4.5:1 on every surface in the light appearances (the ones whose inks are solved).
    @Test(arguments: Golden.all.filter { !$0.appearance.isDark })
    func everyTextReachesAAInLight(_ golden: Golden) {
        let solved = Legibility.solve(colors: golden.colors, surfaces: .listColumn(in: golden.appearance))
        let name = "\(golden.theme) \(golden.appearance)"
        #expect(solved.worstLabel >= Contrast.text, "label \(name)")
        #expect(solved.worstSecondary >= Contrast.text, "secondary \(name)")
        #expect(solved.worstTint >= Contrast.text, "tint \(name)")
        #expect(solved.worstAccent >= Contrast.text, "accent \(name)")
    }

    /// The gradient shows against the background, and a selected item stands out from the gradient under it as asked.
    @Test(arguments: Golden.all)
    func gradientAndSelectionShow(_ golden: Golden) {
        let surfaces = Surfaces.listColumn(in: golden.appearance)
        let solved = Legibility.solve(colors: golden.colors, surfaces: surfaces)
        #expect(solved.gradientShows >= 1.3)
        #expect(
            solved.selectionShows >= surfaces.selection.visibility - 0.005 || solved.selected == surfaces.selection.cap)
    }

    /// The surfaces are the caller's: a description with no fills, no tint fills and no accents solves on the bare
    /// gradient alone.
    @Test func aBareDescriptionSolvesOnTheGradientAlone() throws {
        let golden = try #require(Golden.all.first)
        let bare = Surfaces(
            gradient: .light, contentTop: 0, fills: [], selection: .init(floor: 0, cap: 0, visibility: 1), tintFills: [])
        var colors = golden.colors
        colors.accents = []
        let solved = Legibility.solve(colors: colors, surfaces: bare)
        #expect(solved.accentMix.isEmpty)
        #expect(solved.worstAccent == 21)
        #expect(solved.selected == 0)
        #expect(solved.worstLabel >= Contrast.text)
    }

    @Test func descriptionsDifferingInTheirContentTopSolveDifferently() throws {
        let golden = try #require(Golden.all.first)
        var high = Surfaces.listColumn(in: .light)
        var low = high
        high.contentTop = 0.1
        low.contentTop = 0.6
        let a = Legibility.solve(colors: golden.colors, surfaces: high)
        let b = Legibility.solve(colors: golden.colors, surfaces: low)
        #expect(a != b)
    }
}
