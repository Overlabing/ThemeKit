import ColorCore
import Testing

/// A surface of its own over the gradient (a list column): the plain background laid over every sample, and the plain
/// background itself counted once (Reduce Transparency draws the surface opaque).
struct BackdropTests {
    let colors = ResolvedColors(
        background: .white, label: RGBA(red: 0, green: 0, blue: 0, alpha: 0.85),
        secondaryLabel: RGBA(red: 0, green: 0, blue: 0, alpha: 0.5), primary: RGBA(red: 0.2, green: 0.2, blue: 0.8),
        secondary: RGBA(red: 0.2, green: 0.6, blue: 1))

    @Test func noBackdropSamplesTheBareGradient() {
        let surfaces = Surfaces.listColumn(in: .light)
        #expect(surfaces.backdrop == 0)
        let (top, content) = surfaces.samples(colors)
        #expect(top.count == 5)
        #expect(content.count == 19)
        #expect(top[0] == surfaces.gradient.color(at: 0, primary: colors.primary, secondary: colors.secondary, over: .white))
        #expect(!content.contains(.white))
    }

    @Test func aBackdropVeilsEverySampleAndAddsThePlainBackground() {
        var surfaces = Surfaces.listColumn(in: .light)
        surfaces.backdrop = 0.5
        let (top, content) = surfaces.samples(colors)
        #expect(top.count == 5)
        #expect(content.count == 20)
        #expect(content.last == .white)
        let bare = surfaces.gradient.color(at: 0, primary: colors.primary, secondary: colors.secondary, over: .white)
        #expect(top[0] == RGBA.white.opacity(0.5).composited(over: bare))
    }

    @Test func scalingKeepsTheBackdrop() {
        var surfaces = Surfaces.listColumn(in: .dark)
        surfaces.backdrop = 0.5
        #expect(surfaces.scaled(by: 0.8).backdrop == 0.5)
    }

    /// Solving at a fixed share is solving the scaled surfaces, with that share recorded.
    @Test func solvingAtAFixedShare() {
        var surfaces = Surfaces.listColumn(in: .light)
        surfaces.backdrop = 0.5
        let fixed = Legibility.solve(colors: colors, surfaces: surfaces, hueScale: 0.8)
        let scaled = Legibility.solve(colors: colors, surfaces: surfaces.scaled(by: 0.8))
        #expect(fixed.hueScale == 0.8)
        #expect(fixed.selected == scaled.selected)
        #expect(fixed.secondaryAlpha == scaled.secondaryAlpha)
        #expect(fixed.tintMix == scaled.tintMix)
        #expect(fixed.surfaceLuminances == scaled.surfaceLuminances)
        #expect(Legibility.solve(colors: colors, surfaces: surfaces, hueScale: 1) == Legibility.solve(colors: colors, surfaces: surfaces))
    }

    /// The veil lightens the surfaces in light: the darkest place a text sits on is lighter than on the bare gradient.
    @Test func aBackdropLightensTheDarkestSurfaceInLight() {
        let bare = Legibility.solve(colors: colors, surfaces: .listColumn(in: .light))
        var veiled = Surfaces.listColumn(in: .light)
        veiled.backdrop = 0.5
        let column = Legibility.solve(colors: colors, surfaces: veiled)
        #expect(column.surfaceLuminances.upperBound == 1)
        #expect(column.worstLabel > bare.worstLabel)
    }
}
