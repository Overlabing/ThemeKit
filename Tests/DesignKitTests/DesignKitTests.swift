import ColorCore
import ColorPlatform
import DesignKit
import Foundation
import SwiftUI
import Testing

/// `standard` is the reference app's generic token table (its commit e0f1a89), value for value: adopting the kit must
/// change nothing on its screens.
struct StandardTokensTests {
    let tokens = DesignTokens.standard

    @Test func spacing() {
        let spacing = tokens.spacing
        #expect(DesignTokens.Spacing.scale == [2, 4, 8, 12, 16, 24])
        #expect(spacing.rowGap == 4)
        #expect(spacing.rowInsetVertical == 4)
        #expect(spacing.rowInsetHorizontal == 8)
        #expect(spacing.listMargin == 12)
        #expect(spacing.layerInset == 4)
        #expect(spacing.layerIndent == 12)
        #expect(spacing.sectionHeaderBottom == 6)
        #expect(spacing.tileToText == 10)
        #expect(spacing.compactTileToText == 8)
        #expect(spacing.textLines == 2)
        #expect(spacing.glassMerge == 6)
        #expect(spacing.bannerVertical == 6)
        #expect(spacing.bannerHorizontal == 12)
        #expect(spacing.canvasInset == 12)
        #expect(spacing.pillActionGap == 8)
        #expect(spacing.pillFloat == 12)
        #expect(spacing.headerTracking == 0.6)
    }

    @Test func radii() {
        let radius = tokens.radius
        #expect(radius.tile == 8)
        #expect(radius.compactTile == 7)
        #expect(radius.smallTile == 6)
        #expect(radius.statusTile == 5)
        #expect(radius.row == 8)
        #expect(radius.layer == 12)
        #expect(radius.layer == radius.row + tokens.spacing.layerInset)
        #expect(radius.banner == 12)
        #expect(radius.canvas == 12)
    }

    @Test func sizes() {
        let size = tokens.size
        #expect(size.minTarget == 28)
        #expect(size.tile == 32)
        #expect(size.compactTile == 28)
        #expect(size.smallTile == 22)
        #expect(size.statusTile == 20)
        #expect(size.compactRow == 40)
        #expect(size.statusLine == 38)
        #expect(size.dot == 8)
        #expect(size.stroke == 1)
        #expect(size.floatingPill == 56)
        #expect(size.pillButton == 36)
        #expect(size.pillSymbol == 20)
        #expect(size.pillDivider == 22)
        #expect(size.toolbarButton == 28)
        #expect(size.swatch == 14)
    }

    @Test func emphasis() {
        let emphasis = tokens.emphasis
        #expect(tokens.gradient.dark == GradientSpec(top: 0.42, middle: 0.18, bottom: 0.06))
        #expect(tokens.gradient.light == GradientSpec(top: 0.38, middle: 0.16, bottom: 0.05))
        #expect(emphasis.selectedDark == 0.25)
        #expect(emphasis.selectedLight == 0.30)
        #expect(emphasis.selectionVisibility == 1.3)
        #expect(emphasis.selectionCap == 0.5)
        #expect(emphasis.hover == 0.10)
        #expect(emphasis.current == 0.16)
        #expect(emphasis.badgeFill == 0.14)
        #expect(emphasis.tileFill == 0.25)
        #expect(emphasis.glassTint == 0.35)
        #expect(emphasis.layer == 0.06)
        #expect(emphasis.discreet == 0.5)
        #expect(emphasis.lightBackgroundLuminance == 0.4)
        #expect(emphasis.increasedContrastFactor == 1.8)
        #expect(emphasis.contentTop == 0.1)
        #expect(emphasis.textContrast == 4.5)
    }

    @Test func increaseContrastRaisesByOnePointEightCappedAtOne() {
        #expect(tokens.emphasis.contrasted(0.25, true) == 0.45)
        #expect(tokens.emphasis.contrasted(0.25, false) == 0.25)
        #expect(tokens.emphasis.contrasted(0.6, true) == 1)
    }
}

struct MotionTests {
    @Test func durations() {
        #expect(MotionDuration.allCases.map(\.rawValue) == [0.12, 0.2, 0.35, 0.5, 1.2])
    }

    @Test func curves() {
        #expect(MotionCurve.allCases.map(\.bounce) == [0, 0.15, 0.1, nil, nil])
        #expect(MotionCurve.allCases.map(\.settlingFactor) == [1.47, 1.39, 1.33, 1, 1])
    }

    @Test func roles() {
        typealias Row = (MotionRole, MotionDuration, MotionCurve, Double, Double, ReducedMotion)
        let table: [Row] = [
            (.panelAppear, .calm, .spring, 0, 0, .fade),
            (.panelContent, .quick, .easeOut, 0.08, 0, .none),
            (.panelDisappear, .calm, .easeOut, 0, 0, .fade),
            (.rowState, .quick, .snappy, 0, 0, .none),
            (.rowDeparture, .calm, .easeOut, 0, 0, .none),
            (.indicatorRotation, .quick, .smooth, 0, 0, .none),
            (.hoverFill, .instant, .easeOut, 0, 0, .none),
            (.themeChange, .calm, .smooth, 0, 0, .none),
            (.pullToOpen, .calm, .spring, 0, 0.04, .fade),
            (.contentReveal, .calm, .smooth, 0, 0, .none),
            (.scrollFollow, .deliberate, .smooth, 0, 0, .none),
            (.overlayFade, .instant, .easeOut, 0, 0, .none),
            (.placeholderFade, .instant, .easeOut, 0.1, 0, .none),
            (.loadingPulse, .cycle, .easeInOut, 0, 0, .none),
        ]
        #expect(table.map(\.0) == MotionRole.allCases)
        for (role, duration, curve, delay, stagger, reduced) in table {
            #expect(role.spec == MotionRole.Spec(
                duration: duration, curve: curve, delay: delay, stagger: stagger, reduced: reduced))
        }
    }

    @Test func reduceMotionIsTheSharedFadeOrNothing() {
        #expect(MotionRole.reducedFade == MotionRole.Spec(duration: .quick, curve: .easeOut, reduced: .fade))
        #expect(MotionRole.panelAppear.resolved(reduceMotion: true) == MotionRole.reducedFade)
        #expect(MotionRole.pullToOpen.resolved(reduceMotion: true) == MotionRole.reducedFade)
        #expect(MotionRole.hoverFill.resolved(reduceMotion: true) == nil)
        #expect(MotionRole.hoverFill.animation(reduceMotion: true) == nil)
    }

    @Test func aSpringSettlesAfterItsPerceptualDuration() {
        #expect(abs(MotionRole.panelAppear.spec.settlingSeconds - 0.4655) < 0.0001)
        #expect(MotionRole.hoverFill.spec.settlingSeconds == 0.12)
    }
}

/// The surfaces the solver sees are the ones the reference app described in 0.1's fixtures, so `ColorRoles` solves
/// what it already solved.
struct SurfacesTests {
    @Test func lightAndDark() {
        let light = DesignTokens.standard.surfaces(in: .light)
        #expect(light == Surfaces(
            gradient: GradientSpec(top: 0.38, middle: 0.16, bottom: 0.05), contentTop: 0.1, fills: [0.10, 0.16],
            selection: .init(floor: 0.30, cap: 0.5, visibility: 1.3), tintFills: [0.14, 0.25]))
        let dark = DesignTokens.standard.surfaces(in: .dark)
        #expect(dark == Surfaces(
            gradient: GradientSpec(top: 0.42, middle: 0.18, bottom: 0.06), contentTop: 0.1, fills: [0.10, 0.16],
            selection: .init(floor: 0.25, cap: 0.5, visibility: 1.3), tintFills: [0.14, 0.25]))
    }

    @Test func increasedContrastRaisesRowFillsAndTheSelectionFloorNotTheTintFills() {
        let surfaces = DesignTokens.standard.surfaces(in: .darkIncreasedContrast)
        #expect(surfaces.fills.map { ($0 * 1000).rounded() / 1000 } == [0.18, 0.288])
        #expect(surfaces.selection.floor == 0.45)
        #expect(surfaces.selection.cap == 0.5)
        #expect(surfaces.tintFills == [0.14, 0.25])
    }
}

/// Every text role on every surface, for every standard Theme and appearance, as recorded (CHANGELOG 0.2.0). The
/// system's colours were resolved on macOS 27, so the comparison runs there; the invariant below runs everywhere.
@Suite(.enabled(if: ProcessInfo.processInfo.operatingSystemVersion.majorVersion == 27))
struct LegibilityCaseTests {
    static let computed: [String: LegibilityCase] = {
        var all: [String: LegibilityCase] = [:]
        for theme in Palette.standard.themes {
            for appearance in Appearance.allCases {
                for item in DesignTokens.standard.legibilityCases(for: theme, in: appearance) {
                    all["\(item.themeID) \(appearance) \(item.role) \(item.surface)"] = item
                }
            }
        }
        return all
    }()

    @Test func everyCaseIsRecorded() {
        #expect(Self.computed.count == RecordedCase.all.count)
    }

    @Test(arguments: RecordedCase.all)
    func recorded(_ recorded: RecordedCase) throws {
        let key = "\(recorded.theme) \(recorded.appearance) \(recorded.role) \(recorded.surface)"
        let item = try #require(Self.computed[key])
        #expect((item.before * 100).rounded() / 100 == recorded.before)
        #expect((item.after * 100).rounded() / 100 == recorded.after)
        #expect(item.threshold == 4.5)
        #expect(item.after >= item.before)
    }
}

struct LegibilityInvariantTests {
    /// The solved inks never do worse than the system's default, and in light (with or without Increase Contrast)
    /// every text role reaches 4.5:1 on every surface.
    @Test(arguments: Palette.standard.themes)
    func inksNeverWorseAndLightAlwaysPasses(_ theme: Theme) {
        for appearance in Appearance.allCases {
            for item in DesignTokens.standard.legibilityCases(for: theme, in: appearance) {
                #expect(item.after >= item.before - 0.001, "\(item)")
                if !appearance.isDark { #expect(item.after >= item.threshold, "\(item)") }
            }
        }
    }

    @Test func colorRolesUseTheSolvedValues() {
        let theme = Palette.standard.themes[0]
        let roles = ColorRoles(theme: theme, tokens: .standard, appearance: .light)
        let solved = Legibility.of(theme, surfaces: DesignTokens.standard.surfaces(in: .light), in: .light)
        #expect(roles.selectionOpacity == solved.selected)
        #expect(roles.secondaryTextRGBA.alpha == solved.secondaryAlpha)
    }
}
