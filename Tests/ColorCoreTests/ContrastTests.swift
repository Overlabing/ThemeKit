import ColorCore
import Foundation
import Testing

struct ContrastTests {
    @Test func contrastRatiosMatchWCAGReferences() {
        #expect(abs(Contrast.ratio(.black, .white) - 21) < 0.001)
        #expect(Contrast.ratio(.white, .white) == 1)
        // #767676 is the classic lightest grey that passes 4.5:1 on white.
        let grey = RGBA(red: 0x76 / 255.0, green: 0x76 / 255.0, blue: 0x76 / 255.0)
        #expect(abs(Contrast.ratio(grey, .white) - 4.54) < 0.01)
        // Translucent black at 50 % on white is the #808080 grey: under 4.5:1.
        #expect(Contrast.ratio(foreground: RGBA.black.opacity(0.5), on: .white) < Contrast.text)
    }

    @Test func literalRatiosAndLuminances() {
        #expect(RGBA(red: 1, green: 0, blue: 0).relativeLuminance == 0.2126)
        #expect(abs(RGBA(red: 0.5, green: 0.5, blue: 0.5).relativeLuminance - 0.21404114048223255) < 1e-12)
        // Below the sRGB linear threshold: 0.02 / 12.92 per channel.
        #expect(abs(RGBA(red: 0.02, green: 0.02, blue: 0.02).relativeLuminance - 0.0015479876160990713) < 1e-12)
        #expect(abs(Contrast.ratio(RGBA(red: 1, green: 0, blue: 0), .white) - 3.9984767707539985) < 1e-12)
        #expect(abs(Contrast.ratio(foreground: RGBA.black.opacity(0.5), on: .white) - 3.976653024912438) < 1e-12)
    }

    /// For an opaque text, the worst surface is the nearer luminance extreme: outside the range the shortcut equals the
    /// surface-by-surface measure; inside, it answers 1, never more than the measure (conservative).
    @Test func opaqueWorstCaseFromTheLuminanceRange() {
        let surfaces = stride(from: 0.3, through: 0.95, by: 0.05).map { RGBA(red: $0, green: $0 * 0.9, blue: 1) }
        let range = Contrast.luminances(surfaces)
        for v in stride(from: 0.0, through: 1.0, by: 0.05) {
            let text = RGBA(red: v, green: v, blue: v)
            let shortcut = Contrast.worst(opaque: text, onLuminances: range)
            let measured = Contrast.worst(foreground: text, on: surfaces)
            if range.contains(text.relativeLuminance) {
                #expect(shortcut == 1 && measured >= 1)
            } else {
                #expect(abs(shortcut - measured) < 1e-9)
            }
        }
    }

    @Test func literalWorstCaseFromTheLuminanceRange() {
        let range = 0.7...0.9
        #expect(abs(Contrast.worst(opaque: RGBA(red: 0.5, green: 0.5, blue: 0.5), onLuminances: range) - 2.840466446366027) < 1e-12)
        #expect(Contrast.worst(opaque: .black, onLuminances: range) == 15)
        #expect(abs(Contrast.worst(opaque: .white, onLuminances: 0.1...0.3) - 3.0000000000000004) < 1e-12)
        #expect(Contrast.worst(foreground: .black, on: []) == 21)
    }
}

struct RGBAArithmeticTests {
    @Test func compositingAndMixing() {
        let half = RGBA.black.opacity(0.5).composited(over: .white)
        #expect(abs(half.red - 0.5) < 0.0001 && half.alpha == 1)
        #expect(RGBA.black.mixed(with: .white, by: 0.25) == RGBA(red: 0.25, green: 0.25, blue: 0.25))
        #expect(RGBA.black.mixed(with: .white, by: 2) == .white)
    }

    @Test func literalCompositingMixingAndInterpolation() {
        let composited = RGBA(red: 1, green: 0.5, blue: 0, alpha: 0.4).composited(over: RGBA(red: 0, green: 0.25, blue: 1))
        expectEqual(composited, RGBA(red: 0.4, green: 0.35, blue: 0.6, alpha: 1))
        let mixed = RGBA(red: 0.2, green: 0.4, blue: 0.6, alpha: 0.5).mixed(with: .white, by: 0.25)
        expectEqual(mixed, RGBA(red: 0.4, green: 0.55, blue: 0.7, alpha: 0.625))
        let interpolated = RGBA(red: 1, green: 0, blue: 0, alpha: 0.5)
            .interpolatedPremultiplied(to: RGBA(red: 0, green: 0, blue: 1, alpha: 1), by: 0.5)
        expectEqual(interpolated, RGBA(red: 1.0 / 3, green: 0, blue: 2.0 / 3, alpha: 0.75))
        #expect(RGBA(red: 1, green: 1, blue: 1, alpha: 0).interpolatedPremultiplied(to: RGBA(red: 0, green: 0, blue: 0, alpha: 0), by: 0.3) == RGBA(red: 0, green: 0, blue: 0, alpha: 0))
    }

    private func expectEqual(_ a: RGBA, _ b: RGBA, sourceLocation: SourceLocation = #_sourceLocation) {
        #expect(
            abs(a.red - b.red) < 1e-12 && abs(a.green - b.green) < 1e-12 && abs(a.blue - b.blue) < 1e-12
                && abs(a.alpha - b.alpha) < 1e-12,
            "\(a) is not \(b)", sourceLocation: sourceLocation)
    }
}
