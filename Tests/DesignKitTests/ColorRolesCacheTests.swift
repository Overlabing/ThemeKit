import ColorCore
@testable import DesignKit
import Foundation
import Testing

/// `ColorRoles` solves once per Theme, colour tokens, appearance and placement (issue #38): two lookups share what was
/// solved, and what they share is what a fresh solve gives.
@Suite
struct ColorRolesCacheTests {
    static var customTokens: DesignTokens {
        var tokens = DesignTokens.standard
        tokens.accents = [.primary, .secondary, .hue(.mint)]
        tokens.emphasis.hover = 0.2
        return tokens
    }

    @Test func twoLookupsReturnTheCachedValue() {
        let theme = Palette.standard.themes[3]
        let first = ColorRoles(theme: theme, tokens: .standard, appearance: .dark)
        let second = ColorRoles(theme: theme, tokens: .standard, appearance: .dark)
        #expect(first.solved === second.solved)
        let count = ColorRoles.Solved.cachedCount
        _ = ColorRoles(theme: theme, tokens: .standard, appearance: .dark)
        #expect(ColorRoles.Solved.cachedCount == count)
    }

    @Test func tokensOutsideTheColoursShareTheSolve() {
        var tokens = DesignTokens.standard
        tokens.spacing.rowGap = 10
        tokens.size.tile = 40
        let theme = Palette.standard.themes[1]
        let standard = ColorRoles(theme: theme, tokens: .standard, appearance: .light)
        let spaced = ColorRoles(theme: theme, tokens: tokens, appearance: .light)
        #expect(standard.solved === spaced.solved)
        #expect(spaced.tokens == tokens)
    }

    @Test func everyPartOfTheKeyCounts() {
        let theme = Palette.standard.themes[0]
        let base = ColorRoles(theme: theme, tokens: .standard, appearance: .light)
        var accents = DesignTokens.standard
        accents.accents = [.hue(.red)]
        var emphasis = DesignTokens.standard
        emphasis.emphasis.hover = 0.3
        var gradient = DesignTokens.standard
        gradient.gradient.light.top = 0.5
        let others = [
            ColorRoles(theme: Palette.standard.themes[1], tokens: .standard, appearance: .light),
            ColorRoles(theme: theme, tokens: .standard, appearance: .dark),
            ColorRoles(theme: theme, tokens: .standard, appearance: .lightIncreasedContrast),
            ColorRoles(theme: theme, tokens: .standard, appearance: .light, placement: .deprecatedColumn),
            ColorRoles(theme: theme, tokens: accents, appearance: .light),
            ColorRoles(theme: theme, tokens: emphasis, appearance: .light),
            ColorRoles(theme: theme, tokens: gradient, appearance: .light),
        ]
        for other in others { #expect(other.solved !== base.solved) }
    }

    /// The cached roles are the roles: for every Theme, appearance, placement and both sets of tokens, what a lookup
    /// returns equals a solve made from scratch for that key.
    @Test func theCacheReturnsWhatAFreshSolveGives() {
        for tokens in [DesignTokens.standard, Self.customTokens] {
            for theme in Palette.standard.themes {
                for appearance in Appearance.allCases {
                    for placement in SurfacePlacement.allCases {
                        let roles = ColorRoles(theme: theme, tokens: tokens, appearance: appearance, placement: placement)
                        let key = ColorRoles.Solved.Key(
                            theme: theme, tokens: tokens, appearance: appearance, placement: placement)
                        let fresh = ColorRoles.Solved(key, tokens: tokens)
                        #expect(roles.solved.values == fresh.values, "\(theme.id) \(appearance) \(placement)")
                    }
                }
            }
        }
    }

    @Test func lookupsFromManyThreadsAgree() async {
        let theme = Palette.standard.themes[6]
        let tokens = Self.customTokens
        let markers = await withTaskGroup(of: RGBA.self) { group in
            for _ in 0..<32 {
                group.addTask {
                    ColorRoles(theme: theme, tokens: tokens, appearance: .darkIncreasedContrast).selectionMarkerRGBA
                }
            }
            return await group.reduce(into: [RGBA]()) { $0.append($1) }
        }
        #expect(Set(markers).count == 1)
    }
}
