import ColorCore
import ColorPlatform
import DesignKit
import Foundation
import SwiftUI
import Testing

/// Accent text inks by index (`ColorRoles.accentInk(at:)`), as recorded (CHANGELOG 0.2.4): 10 per Theme and appearance,
/// the worst of the twelve accents counted on the bare surface, a hovered, a current and a selected row and the panel,
/// on the gradient and inside a list column.
@Suite(.enabled(if: ProcessInfo.processInfo.operatingSystemVersion.majorVersion == 27))
struct AccentLegibilityTests {
    static let computed: [String: LegibilityCase] = {
        var all: [String: LegibilityCase] = [:]
        for theme in Palette.standard.themes {
            for appearance in Appearance.allCases {
                for placement in SurfacePlacement.allCases {
                    for item in DesignTokens.standard.accentCases(for: theme, in: appearance, placement: placement) {
                        all["\(item.themeID) \(item.appearance) \(item.placement) \(item.role) \(item.surface)"] = item
                    }
                }
            }
        }
        return all
    }()

    @available(*, deprecated, message: "Tests the deprecated column surface, kept until 0.3.")
    @Test func everyAccentCaseIsRecorded() {
        #expect(Self.computed.count == 280)
        #expect(Self.computed.values.filter { $0.placement == .column }.count == 140)
        #expect(Set(Self.computed.keys) == Set(RecordedCase.accent.map(\.key)))
    }

    @Test(arguments: RecordedCase.accent)
    func recorded(_ recorded: RecordedCase) throws {
        let item = try #require(Self.computed[recorded.key])
        #expect((item.before * 100).rounded() / 100 == recorded.before)
        #expect((item.after * 100).rounded() / 100 == recorded.after)
        #expect(item.threshold == recorded.threshold)
        #expect(item.after >= item.threshold)
    }

    @Test(arguments: Palette.standard.themes, SurfacePlacement.allCases)
    func everyAccentCaseReachesTheTextThreshold(_ theme: Theme, _ placement: SurfacePlacement) {
        for appearance in Appearance.allCases {
            let cases = DesignTokens.standard.accentCases(for: theme, in: appearance, placement: placement)
            let bare: LegibilityCase.SurfaceKind = placement == .frame ? .frame : .columnFill
            #expect(cases.map(\.surface) == [bare, .hoveredRow, .currentRow, .selectedRow, .layerPanel])
            for item in cases {
                #expect(item.role == .accentText && item.placement == placement)
                #expect(item.threshold == 4.5)
                #expect(item.after >= 4.5, "\(item)")
                #expect(item.isFixed || item.before >= 4.5, "\(item)")
            }
        }
    }
}

struct AccentInkTests {
    /// Every index, in every Theme, appearance and placement, reaches 4.5:1 on every surface the roles solved: the
    /// bare gradient or column fill, the row fills (hover, current, the selection) and the panel.
    @Test(arguments: Palette.standard.themes, SurfacePlacement.allCases)
    func everyIndexReachesTheTextContrast(_ theme: Theme, _ placement: SurfacePlacement) {
        for appearance in Appearance.allCases {
            let roles = ColorRoles(theme: theme, tokens: .standard, appearance: appearance, placement: placement)
            for index in 0..<DesignTokens.standard.accents.count {
                let ink = roles.accentInkRGBA(at: index)
                #expect(ink.alpha == 1)
                #expect(
                    Contrast.worst(opaque: ink, onLuminances: roles.legibility.surfaceLuminances) >= 4.5,
                    "\(theme.id) \(appearance) \(placement) index \(index)")
            }
        }
    }

    @Test func theIndexesWrapAndCountBackFromTheEnd() {
        let roles = ColorRoles(theme: Palette.standard.themes[0], tokens: .standard, appearance: .light)
        let count = DesignTokens.standard.accents.count
        #expect(roles.accentHue(at: 0) == .indigo)
        #expect(roles.accentHue(at: 1) == .blue)
        #expect(roles.accentHue(at: count) == roles.accentHue(at: 0))
        #expect(roles.accentHue(at: count + 3) == roles.accentHue(at: 3))
        #expect(roles.accentHue(at: -1) == roles.accentHue(at: count - 1))
        #expect(roles.accentInkRGBA(at: -1) == roles.accentInkRGBA(at: count - 1))
        #expect(roles.accentInkRGBA(at: 2 * count + 5) == roles.accentInkRGBA(at: 5))
    }

    @Test func eachIndexIsItsHueMixedTowardTheInk() {
        let roles = ColorRoles(theme: Palette.standard.themes[2], tokens: .standard, appearance: .dark)
        let colors = ResolvedColors(
            Palette.standard.themes[2], accents: DesignTokens.standard.accentHues(in: Palette.standard.themes[2]),
            in: .dark)
        for (index, mix) in roles.legibility.accentMix.enumerated() {
            #expect(roles.accentInkRGBA(at: index) == colors.accents[index].mixed(with: colors.ink, by: mix))
        }
    }

    /// An app that sets its own accents gets inks for them, and with none the Theme's own hue.
    @Test func anAppChoosesItsAccents() {
        var tokens = DesignTokens.standard
        tokens.accents = [.hue(.red), .hue(.green)]
        let roles = ColorRoles(theme: Palette.standard.themes[0], tokens: tokens, appearance: .light)
        #expect(roles.legibility.accentMix.count == 2)
        #expect(roles.accentHue(at: 0) == .red && roles.accentHue(at: 1) == .green && roles.accentHue(at: 2) == .red)
        #expect(Contrast.worst(opaque: roles.accentInkRGBA(at: 3), onLuminances: roles.legibility.surfaceLuminances) >= 4.5)
        tokens.accents = []
        let none = ColorRoles(theme: Palette.standard.themes[0], tokens: tokens, appearance: .light)
        #expect(none.accentHue(at: 4) == .indigo)
        #expect(none.accentInkRGBA(at: 4) == none.tintTextRGBA)
    }

    /// Adding the accents changes nothing the views drew: the hue's share and every other ink are what 0.2.3 solved.
    @Test(arguments: Palette.standard.themes)
    func theAccentsLeaveTheOtherInksAlone(_ theme: Theme) {
        for appearance in Appearance.allCases {
            let colors = ResolvedColors(theme, in: appearance)
            let without = Legibility.fit(colors: colors, surfaces: DesignTokens.standard.surfaces(in: appearance))
            let with = ColorRoles(theme: theme, tokens: .standard, appearance: appearance).legibility
            #expect(with.hueScale == without.hueScale)
            #expect(with.selected == without.selected)
            #expect(with.secondaryAlpha == without.secondaryAlpha)
            #expect(with.tintMix == without.tintMix)
        }
    }
}

/// The Theme's own hues first (issue #17): `.primary` and `.secondary` in `DesignTokens.accents` resolve against the
/// Theme the roles are drawn in, wherever the list reaches the solver, the cache and the audit.
struct ThemeRelativeAccentTests {
    static let themeFirst: [Accent] = [.primary, .secondary, .hue(.mint), .hue(.yellow)]
    static var tokens: DesignTokens {
        var tokens = DesignTokens.standard
        tokens.accents = themeFirst
        return tokens
    }

    /// `.primary` follows the Theme: the same tokens give each Theme's own hues at 0 and 1, and their inks are the
    /// Theme's hues mixed toward the ink, solved for that Theme.
    @Test(arguments: Palette.standard.themes, SurfacePlacement.allCases)
    func primaryFollowsTheTheme(_ theme: Theme, _ placement: SurfacePlacement) {
        for appearance in Appearance.allCases {
            let roles = ColorRoles(theme: theme, tokens: Self.tokens, appearance: appearance, placement: placement)
            #expect(roles.accentHue(at: 0) == theme.primary)
            #expect(roles.accentHue(at: 1) == theme.secondary)
            #expect(roles.accentHue(at: 2) == .mint && roles.accentHue(at: 3) == .yellow)
            #expect(roles.accentHue(at: 4) == theme.primary)
            #expect(roles.legibility.accentMix.count == 4)
            let colors = ResolvedColors(theme, accents: [theme.primary, theme.secondary, .mint, .yellow], in: appearance)
            for index in 0..<4 {
                let ink = roles.accentInkRGBA(at: index)
                #expect(ink == colors.accents[index].mixed(with: colors.ink, by: roles.legibility.accentMix[index]))
                #expect(
                    Contrast.worst(opaque: ink, onLuminances: roles.legibility.surfaceLuminances) >= 4.5,
                    "\(theme.id) \(appearance) \(placement) index \(index)")
            }
        }
    }

    /// Switching Theme changes slot 0's hue and ink with nothing else touched: the cache keys on the resolved hues, so
    /// it never hands one Theme's accents to another.
    @Test func switchingThemeMovesThePrimarySlot() {
        let indigo = ColorRoles(theme: Palette.standard.themes[0], tokens: Self.tokens, appearance: .light)
        let orange = ColorRoles(theme: Palette.standard.themes[1], tokens: Self.tokens, appearance: .light)
        #expect(indigo.accentHue(at: 0) == .indigo && orange.accentHue(at: 0) == .orange)
        #expect(indigo.accentInkRGBA(at: 0) != orange.accentInkRGBA(at: 0))
        #expect(indigo.accentInkRGBA(at: 0) == ColorRoles(
            theme: Palette.standard.themes[0], tokens: Self.tokens, appearance: .light).accentInkRGBA(at: 0))
        // A fixed hue in the same slot does not follow.
        var fixed = Self.tokens
        fixed.accents[0] = .hue(.indigo)
        let fixedOrange = ColorRoles(theme: Palette.standard.themes[1], tokens: fixed, appearance: .light)
        #expect(fixedOrange.accentHue(at: 0) == .indigo)
    }

    /// A Theme whose primary is also a later `.hue` keeps both slots: an index is an account's, so nothing moves.
    @Test func aDuplicateKeepsBothSlots() throws {
        let mintCyan = try #require(Palette.standard.theme(id: "mint-cyan"))
        let roles = ColorRoles(theme: mintCyan, tokens: Self.tokens, appearance: .dark)
        #expect((0..<4).map(roles.accentHue(at:)) == [.mint, .cyan, .mint, .yellow])
        #expect(roles.legibility.accentMix.count == 4)
        #expect(roles.accentInkRGBA(at: 0) == roles.accentInkRGBA(at: 2))
        let brownYellow = try #require(Palette.standard.theme(id: "brown-yellow"))
        let brown = ColorRoles(theme: brownYellow, tokens: Self.tokens, appearance: .light)
        #expect((0..<4).map(brown.accentHue(at:)) == [.brown, .yellow, .mint, .yellow])
        #expect(brown.accentInkRGBA(at: 1) == brown.accentInkRGBA(at: 3))
    }

    /// The default list is the twelve hues in 0.2.4's order, in every Theme.
    @Test(arguments: Palette.standard.themes)
    func theDefaultOrderIsUnchanged(_ theme: Theme) {
        let roles = ColorRoles(theme: theme, tokens: .standard, appearance: .light)
        #expect((0..<Hue.allCases.count).map(roles.accentHue(at:)) == Hue.allCases)
    }
}

/// The legibility audit with the Theme's own hues first, as recorded (CHANGELOG 0.2.5): 10 cases per Theme and
/// appearance, the worst of the four accents counted, every one at the text threshold.
@Suite(.enabled(if: ProcessInfo.processInfo.operatingSystemVersion.majorVersion == 27))
struct ThemeRelativeAccentLegibilityTests {
    static let computed: [String: LegibilityCase] = {
        var all: [String: LegibilityCase] = [:]
        for theme in Palette.standard.themes {
            for appearance in Appearance.allCases {
                for placement in SurfacePlacement.allCases {
                    for item in ThemeRelativeAccentTests.tokens.accentCases(
                        for: theme, in: appearance, placement: placement)
                    {
                        all["\(item.themeID) \(item.appearance) \(item.placement) \(item.role) \(item.surface)"] = item
                    }
                }
            }
        }
        return all
    }()

    @available(*, deprecated, message: "Tests the deprecated column surface, kept until 0.3.")
    @Test func everyCaseIsRecordedAndAtThreshold() {
        #expect(Self.computed.count == 280)
        #expect(Self.computed.values.filter { $0.placement == .column }.count == 140)
        #expect(Set(Self.computed.keys) == Set(RecordedCase.themeFirstAccent.map(\.key)))
        #expect(Self.computed.values.filter { $0.after >= $0.threshold }.count == 280)
    }

    @Test(arguments: RecordedCase.themeFirstAccent)
    func recorded(_ recorded: RecordedCase) throws {
        let item = try #require(Self.computed[recorded.key])
        #expect((item.before * 100).rounded() / 100 == recorded.before)
        #expect((item.after * 100).rounded() / 100 == recorded.after)
        #expect(item.threshold == recorded.threshold && item.threshold == 4.5)
        #expect(item.after >= item.threshold)
    }
}
