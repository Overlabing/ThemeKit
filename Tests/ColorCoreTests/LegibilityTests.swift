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

struct FitTests {
    private func worstText(_ solved: Legibility) -> Double {
        min(solved.worstLabel, solved.worstSecondary, solved.worstTint, solved.worstAccent)
    }

    /// Where every text already reaches 4.5:1 at full opacity, fitting solves exactly as `solve`.
    @Test(arguments: Golden.all.filter { !$0.appearance.isDark })
    func fitKeepsFullOpacitiesWhereEveryTextPasses(_ golden: Golden) {
        let surfaces = Surfaces.listColumn(in: golden.appearance)
        let fitted = Legibility.fit(colors: golden.colors, surfaces: surfaces)
        #expect(fitted == Legibility.solve(colors: golden.colors, surfaces: surfaces))
        #expect(fitted.hueScale == 1)
    }

    /// In every appearance the fitted surfaces bring every text to 4.5:1, at the largest share (to 1/1000) that does.
    @Test(arguments: Golden.all)
    func fitReachesAAAtTheLargestShare(_ golden: Golden) {
        let surfaces = Surfaces.listColumn(in: golden.appearance)
        let fitted = Legibility.fit(colors: golden.colors, surfaces: surfaces)
        #expect(worstText(fitted) >= Contrast.text)
        #expect(fitted == Legibility.fit(colors: golden.colors, surfaces: surfaces))
        if fitted.hueScale < 1 {
            let more = Legibility.solve(colors: golden.colors, surfaces: surfaces.scaled(by: fitted.hueScale + 0.001))
            #expect(worstText(more) < Contrast.text)
        }
    }

    /// The dark cases 0.2.0 left under 4.5:1 are the ones fitting draws lighter.
    @Test func brightHuesInDarkAreDrawnLighter() throws {
        let mint = try #require(Golden.all.first { $0.theme == "mint-cyan" && $0.appearance == .dark })
        let fitted = Legibility.fit(colors: mint.colors, surfaces: .listColumn(in: .dark))
        #expect(fitted.hueScale < 1)
        #expect(fitted.hueScale > 0.5)
        let indigo = try #require(Golden.all.first { $0.theme == "indigo-blue" && $0.appearance == .dark })
        #expect(Legibility.fit(colors: indigo.colors, surfaces: .listColumn(in: .dark)).hueScale == 1)
    }

    @Test func scalingMultipliesTheHueOpacitiesOnly() {
        let surfaces = Surfaces(
            gradient: GradientSpec(top: 0.4, middle: 0.2, bottom: 0.1), contentTop: 0.1, fills: [0.1, 0.2],
            selection: .init(floor: 0.3, cap: 0.5, visibility: 1.3), tintFills: [0.2], neutralFills: [0.06])
        #expect(surfaces.scaled(by: 0.5) == Surfaces(
            gradient: GradientSpec(top: 0.2, middle: 0.1, bottom: 0.05), contentTop: 0.1, fills: [0.05, 0.1],
            selection: .init(floor: 0.15, cap: 0.25, visibility: 1.3), tintFills: [0.1], neutralFills: [0.06]))
        #expect(surfaces.scaled(by: 1) == surfaces)
    }

    /// A neutral panel under the fills is a surface too: in light it darkens them, so secondary text needs more ink.
    @Test func neutralFillsAreSurfaces() throws {
        let golden = try #require(Golden.all.first)
        var surfaces = Surfaces.listColumn(in: .light)
        let without = Legibility.solve(colors: golden.colors, surfaces: surfaces)
        surfaces.neutralFills = [0.06]
        let with = Legibility.solve(colors: golden.colors, surfaces: surfaces)
        #expect(with.secondaryAlpha > without.secondaryAlpha)
        #expect(with.worstLabel < without.worstLabel)
        #expect(with.selected == without.selected)
        #expect(with.worstSecondary >= Contrast.text)
    }

    @Test func aColourMixedTowardTheInkReachesTheMinimumOnEverySurface() throws {
        let golden = try #require(Golden.all.first { $0.theme == "mint-cyan" && $0.appearance == .dark })
        let solved = Legibility.fit(colors: golden.colors, surfaces: .listColumn(in: .dark))
        let focus = RGBA(red: 0.102, green: 0.663, blue: 1)
        let share = solved.mix(of: focus, toward: golden.colors.ink, reaching: Contrast.nonText)
        #expect(share > 0)
        #expect(Contrast.worst(opaque: focus.mixed(with: golden.colors.ink, by: share), onLuminances: solved.surfaceLuminances) >= 3)
        #expect(Contrast.worst(opaque: focus.mixed(with: golden.colors.ink, by: share - 0.002), onLuminances: solved.surfaceLuminances) < 3)
    }
}

struct InkTests {
    @Test func whiteWhereItReachesTheMinimumBlackOtherwise() {
        #expect(Contrast.ink(on: .white, minimum: 4.5) == .black)
        #expect(Contrast.ink(on: .black, minimum: 4.5) == .white)
        let indigo = RGBA(red: 0.380, green: 0.333, blue: 0.961)
        #expect(Contrast.ink(on: indigo, minimum: 4.5) == .white)
        let orange = RGBA(red: 1, green: 0.553, blue: 0.157)
        #expect(Contrast.ink(on: orange, minimum: 3) == .black)
        let red = RGBA(red: 1, green: 0.220, blue: 0.235)
        #expect(Contrast.ink(on: red, minimum: 3) == .white)
        #expect(Contrast.ink(on: red, minimum: 4.5) == .black)
    }

    /// On any opaque colour one of the two inks reaches 4.58:1.
    @Test func oneOfTheTwoAlwaysReachesText() {
        for value in stride(from: 0.0, through: 1.0, by: 0.01) {
            let gray = RGBA(red: value, green: value, blue: value)
            #expect(Contrast.ratio(Contrast.ink(on: gray, minimum: 4.5), gray) >= 4.5)
        }
    }
}
