import ColorCore
import ColorPlatform
import ColorUI
import DesignKit
import Foundation
import SwiftUI
import Testing

// Oisillon's requests of 0.2.4 (issues #4 to #11 of the kit): motion without its delay, the settling factors, the new
// tokens, the glyph size, the fill modifiers, the banner, the status line, the buttons and the pill.

// MARK: Motion (#4, #5)

struct MotionRequestTests {
    /// #5: a spring is within 0.1 % of its target at `duration × settlingFactor`, whatever the duration, and the factor
    /// is not rounded up further than the next hundredth.
    @Test(arguments: [MotionCurve.smooth, .snappy, .spring], MotionDuration.allCases)
    func theResidualTravelAtTheSettlingTimeIsAtMostATenthOfAPercent(_ curve: MotionCurve, _ duration: MotionDuration) throws {
        let bounce = try #require(curve.bounce)
        let spring = Spring(duration: duration.rawValue, bounce: bounce)
        func residual(_ factor: Double) -> Double {
            abs(1 - spring.value(target: 1, initialVelocity: 0, time: duration.rawValue * factor))
        }
        #expect(residual(curve.settlingFactor) <= 0.001, "\(curve) \(duration)")
        #expect(residual(curve.settlingFactor - 0.01) > 0.001, "\(curve) \(duration): rounded up too far")
    }

    /// #5: the documented factors, as measured (1.4695, 1.3933, 1.3332) rounded up to the hundredth.
    @Test func theFactorsAreTheMeasuredOnesRoundedUp() {
        #expect(MotionCurve.smooth.settlingFactor == 1.47)
        #expect(MotionCurve.snappy.settlingFactor == 1.40)
        #expect(MotionCurve.spring.settlingFactor == 1.34)
        #expect(MotionCurve.easeOut.settlingFactor == 1)
        #expect(MotionCurve.easeInOut.settlingFactor == 1)
    }

    /// #4: a role with a delay has an animation without it, and its settling time splits into the delay and the rest.
    @Test func aRoleKeepsItsAnimationWithoutItsDelay() {
        #expect(MotionRole.panelContent.animation(reduceMotion: false) == Animation.easeOut(duration: 0.2).delay(0.08))
        #expect(MotionRole.panelContent.animationWithoutDelay(reduceMotion: false) == Animation.easeOut(duration: 0.2))
        #expect(MotionRole.placeholderFade.animation(reduceMotion: false) == Animation.easeOut(duration: 0.12).delay(0.1))
        #expect(MotionRole.placeholderFade.animationWithoutDelay(reduceMotion: false) == Animation.easeOut(duration: 0.12))
        #expect(MotionRole.themeChange.animationWithoutDelay(reduceMotion: false) == Animation.spring(duration: 0.35, bounce: 0))
    }

    @Test func aRoleWithoutADelayIsTheSameEitherWay() {
        for role in MotionRole.allCases where role.spec.delay == 0 {
            #expect(role.animationWithoutDelay(reduceMotion: false) == role.animation(reduceMotion: false), "\(role)")
            #expect(role.animationWithoutDelay(reduceMotion: true) == role.animation(reduceMotion: true), "\(role)")
        }
    }

    /// Under Reduce Motion the shared fade has no delay and the others do not move: both accessors agree.
    @Test func reduceMotionHasNoDelayToDrop() {
        for role in MotionRole.allCases {
            #expect(role.animationWithoutDelay(reduceMotion: true) == role.animation(reduceMotion: true), "\(role)")
        }
        #expect(MotionRole.panelContent.animationWithoutDelay(reduceMotion: true) == nil)
        #expect(MotionRole.panelAppear.animationWithoutDelay(reduceMotion: true) == Animation.easeOut(duration: 0.2))
    }

    @Test func theSettlingTimeSplitsIntoTheDelayAndTheRest() {
        let panelContent = MotionRole.panelContent.spec
        #expect(abs(panelContent.settlingSecondsWithoutDelay - 0.2) < 1e-9)
        #expect(abs(panelContent.settlingSeconds - 0.28) < 1e-9)
        let placeholder = MotionRole.placeholderFade.spec
        #expect(abs(placeholder.settlingSecondsWithoutDelay - 0.12) < 1e-9)
        #expect(abs(placeholder.settlingSeconds - 0.22) < 1e-9)
        let panel = MotionRole.panelAppear.spec
        #expect(abs(panel.settlingSecondsWithoutDelay - 0.469) < 1e-9)
        #expect(panel.settlingSeconds == panel.settlingSecondsWithoutDelay)
        for role in MotionRole.allCases {
            let spec = role.spec
            #expect(abs(spec.settlingSeconds - (spec.delay + spec.settlingSecondsWithoutDelay)) < 1e-12, "\(role)")
        }
    }

    @Test func aSpecAnimatesWithOrWithoutItsDelay() {
        let spec = MotionRole.Spec(duration: .quick, curve: .snappy, delay: 0.3, reduced: .none)
        #expect(spec.animation() == Animation.spring(duration: 0.2, bounce: 0.15).delay(0.3))
        #expect(spec.animation(includingDelay: false) == Animation.spring(duration: 0.2, bounce: 0.15))
    }
}

// MARK: accessibilityOverrides (#11)

@MainActor
struct AccessibilityOverridesTests {
    final class Box { var reduceMotion: Bool? }

    struct Probe: View {
        let box: Box
        @Environment(\.accessibilityReduceMotion) private var reduceMotion
        var body: some View {
            let _ = { box.reduceMotion = reduceMotion }()
            Color.clear.frame(width: 1, height: 1)
        }
    }

    /// What the probe sees below `overrides`, when the system says `system`.
    func seen(system: Bool, reduceMotion: Bool = false, fullMotion: Bool = false) throws -> Bool {
        let box = Box()
        let view = Probe(box: box)
            .accessibilityOverrides(reduceMotion: reduceMotion, fullMotion: fullMotion)
            .transformEnvironment(\._accessibilityReduceMotion) { $0 = system }
        _ = try raster(view)
        return try #require(box.reduceMotion as Bool?)
    }

    @Test func withoutAnOverrideTheSystemDecides() throws {
        #expect(try seen(system: false) == false)
        #expect(try seen(system: true) == true)
    }

    @Test func reduceMotionIsForced() throws {
        #expect(try seen(system: false, reduceMotion: true) == true)
        #expect(try seen(system: true, reduceMotion: true) == true)
    }

    @Test func fullMotionLiftsTheSystemsReduceMotion() throws {
        #expect(try seen(system: true, fullMotion: true) == false)
        #expect(try seen(system: false, fullMotion: true) == false)
    }

    @Test func whenBothAreSetReduceMotionWins() throws {
        #expect(try seen(system: false, reduceMotion: true, fullMotion: true) == true)
        #expect(try seen(system: true, reduceMotion: true, fullMotion: true) == true)
    }

    /// Full motion is the role's own animation: it does not turn Reduce Motion's fade into a spring by itself, the
    /// views read the environment value that the override sets.
    @Test func theRolesFollowTheOverriddenValue() throws {
        #expect(MotionRole.panelAppear.animation(reduceMotion: try seen(system: true, fullMotion: true))
            == Animation.spring(duration: 0.35, bounce: 0.1))
        #expect(MotionRole.panelAppear.animation(reduceMotion: try seen(system: false, reduceMotion: true))
            == Animation.easeOut(duration: 0.2))
    }
}

// MARK: Tokens

struct NewTokenTests {
    let tokens = DesignTokens.standard

    @Test func theNewValuesComeFromTheScale() {
        #expect(tokens.spacing.listCellMargin == 8)
        let scale = DesignTokens.Spacing.scale
        for value in [
            tokens.spacing.badgeHorizontal, tokens.spacing.badgeVertical, tokens.spacing.buttonLabelHorizontal,
            tokens.spacing.segmentGap, tokens.spacing.segmentPadding, tokens.spacing.segmentHorizontal,
            tokens.spacing.segmentContent, tokens.spacing.segmentMarkerGap, tokens.spacing.bannerLines,
        ] {
            #expect(scale.contains(value), "\(value)")
        }
        #expect(tokens.spacing.badgeHorizontal == 8)
        #expect(tokens.spacing.badgeVertical == 2)
        #expect(tokens.spacing.segmentPadding == 4)
        #expect(tokens.spacing.segmentHorizontal == 12)
    }

    @Test func theNewSizes() {
        #expect(tokens.size.glyphCircle == 24)
        #expect(tokens.size.glyphCircleSmall == 16)
        #expect(tokens.size.railPanelMaxHeight == 480)
        #expect(tokens.size.segmentedPill == 36)
        #expect(tokens.size.segmentMarker == 12)
    }

    /// A segment is a target: the pill less its padding above and below is never under the minimum.
    @Test func aSegmentIsNeverUnderTheMinimumTarget() {
        #expect(tokens.size.segmentedPill - 2 * tokens.spacing.segmentPadding >= tokens.size.minTarget)
    }

    @Test func theNewTypeRoles() {
        #expect(tokens.type.glyphCircleSmall == TextRole(.caption2, .bold))
        #expect(tokens.type.bannerTitle == TextRole(.callout, .semibold))
        #expect(tokens.type.buttonLabel == TextRole(.callout, .semibold))
        #expect(tokens.type.segment == TextRole(.callout))
        #expect(tokens.type.segmentSelected == TextRole(.callout, .semibold))
    }

    @Test func theAccentsAreTheTwelveHues() {
        #expect(tokens.accents == Hue.allCases.map(Accent.hue))
        #expect(tokens.accents.count == 12)
        for theme in Palette.standard.themes {
            #expect(tokens.accentHues(in: theme) == Hue.allCases)
        }
    }
}

// MARK: Views

@MainActor
@Suite(.enabled(if: ProcessInfo.processInfo.operatingSystemVersion.majorVersion == 27))
struct ClientViewTests {
    let theme = Palette.standard.themes[0]

    func column<V: View>(_ view: V, scheme: ColorScheme = .light, increaseContrast: Bool = false) -> some View {
        view
            .environment(\.glassRendering, .material)
            .accessibilityOverrides(increaseContrast: increaseContrast)
            .theme(theme)
            .environment(\.colorScheme, scheme)
    }

    /// The Theme's fill over a white page, as the render has it.
    func over(_ opacity: Double, scheme: ColorScheme = .light) -> RGBA {
        let colors = ResolvedColors(theme, in: scheme == .dark ? .dark : .light)
        return colors.primary.opacity(opacity).composited(over: colors.background)
    }

    // #7
    @Test func aGlyphHasTwoSizes() throws {
        let standard = try raster(ThemeGlyph(name: "Work").theme(theme))
        #expect((standard.width, standard.height) == (24, 24))
        let small = try raster(ThemeGlyph(name: "Work", size: .small).theme(theme))
        #expect((small.width, small.height) == (16, 16))
        let symbol = try raster(ThemeGlyph(name: "Work", symbol: "briefcase", size: .small).theme(theme))
        #expect((symbol.width, symbol.height) == (16, 16))
        #expect(GlyphSize.allCases == [.standard, .small])
    }

    @Test(arguments: [ColorScheme.light, .dark])
    func aSmallGlyphIsTheThemesHueAndKeepsItsInk(_ scheme: ColorScheme) throws {
        let appearance: Appearance = scheme == .dark ? .dark : .light
        let hue = RGBA(theme.primary.systemColor, in: appearance)
        for size in GlyphSize.allCases {
            let glyph = try raster(ThemeGlyph(name: "W", theme: theme, size: size).environment(\.colorScheme, scheme))
            let edge = glyph.color(x: 1, y: glyph.height / 2)
            #expect(Contrast.ratio(edge, hue) < 1.04, "\(size) \(scheme)")
            let ink = ColorRoles.ink(on: theme.primary, in: appearance, minimum: 4.5)
            #expect(ink == .white || ink == .black)
            let lit = (0..<glyph.width).flatMap { x in (0..<glyph.height).map { y in glyph.color(x: x, y: y) } }
                .contains { Contrast.ratio($0, hue) > 3 }
            #expect(lit, "the initial shows in \(size) \(scheme)")
        }
    }

    // #6
    @Test(arguments: TileSize.allCasesForTests)
    func theTileFillIsTheKitsTile(_ size: TileSize) throws {
        let side: Int = switch size {
        case .standard: 32
        case .compact: 28
        case .small: 22
        case .status: 20
        }
        let filled = try raster(Text("A").tileFill(size).background(Color.white).theme(theme))
        #expect((filled.width, filled.height) == (side, side))
        let expected = over(DesignTokens.standard.emphasis.tileFill)
        let inside = filled.color(x: side / 2, y: 2)
        #expect(Contrast.ratio(inside, expected) < 1.02, "\(size)")
        let reference = try raster(Tile(.initial("A"), size: size).background(Color.white).theme(theme))
        #expect(Contrast.ratio(reference.color(x: side / 2, y: 2), inside) < 1.01, "\(size)")
        #expect(filled.alpha(x: 0, y: 0) == 1)
    }

    @Test func theBadgeFillWrapsItsContentInACapsule() throws {
        let content = Color.clear.frame(width: 10, height: 10)
        let badge = try raster(content.badgeFill().background(Color.white).theme(theme))
        #expect((badge.width, badge.height) == (26, 14))
        let expected = over(DesignTokens.standard.emphasis.badgeFill)
        #expect(Contrast.ratio(badge.color(x: 13, y: 3), expected) < 1.02)
        #expect(Contrast.ratio(badge.color(x: 0, y: 0), RGBA.white) < 1.01, "the corner is outside the capsule")
    }

    /// The fill modifiers colour the client's text in the tinted ink, 4.5:1 on the fill.
    @Test(arguments: [ColorScheme.light, .dark])
    func theTextOnAFillIsTheTintedInk(_ scheme: ColorScheme) throws {
        let roles = ColorRoles(theme: theme, tokens: .standard, appearance: scheme == .dark ? .dark : .light)
        let colors = ResolvedColors(theme, in: scheme == .dark ? .dark : .light)
        let fill = colors.primary.opacity(roles.badgeOpacity).composited(over: colors.background)
        #expect(Contrast.ratio(roles.tintTextRGBA, fill) >= 4.5)
        let rendered = try raster(
            Rectangle().frame(width: 20, height: 12).badgeFill().background(Color(.sRGB, red: colors.background.red, green: colors.background.green, blue: colors.background.blue))
                .theme(theme).environment(\.colorScheme, scheme))
        #expect(rendered.contrast((18, 7), (3, 7)) >= 4.4, "the content takes the tinted ink: \(rendered.contrast((18, 7), (3, 7)))")
    }

    // #9
    @Test func aStatusLineTakesAnyTile() throws {
        let line = StatusLine(title: "Inbox", isOpen: false) { Color(red: 1, green: 0, blue: 0) }
            .frame(width: 320)
        let rendered = try raster(column(line))
        #expect(rendered.height == 38)
        let center = rendered.color(x: 12 + 8 + 10, y: 19)
        #expect(center.red > 0.95 && center.green < 0.05 && center.blue < 0.05, "the client's tile is drawn: \(center)")
        let corner = rendered.color(x: 12 + 8 + 20 + 2, y: 19)
        #expect(corner.red < 0.95 || corner.green > 0.05, "and clipped to the status tile's 20 pt")
    }

    @Test func aStatusLineFillsWhenOpenIfAsked() throws {
        func line(_ isOpen: Bool, fills: Bool, increased: Bool = false, scheme: ColorScheme = .light) throws -> Raster {
            try raster(column(
                StatusLine(tile: .initial("A"), title: "All", isOpen: isOpen, fillsWhenOpen: fills).frame(width: 320),
                scheme: scheme, increaseContrast: increased).background(Color.white))
        }
        let roles = ColorRoles(theme: theme, tokens: .standard, appearance: .light)
        let plain = try line(true, fills: false)
        let closed = try line(false, fills: true)
        let open = try line(true, fills: true)
        let expected = over(roles.currentOpacity)
        // The fill starts 4 pt in, the tile 8 pt further: sample between them, and well after the title.
        #expect(Contrast.ratio(open.color(x: 8, y: 19), expected) < 1.02)
        #expect(Contrast.ratio(open.color(x: 8, y: 19), plain.color(x: 8, y: 19)) > 1.05)
        #expect(Contrast.ratio(closed.color(x: 8, y: 19), plain.color(x: 8, y: 19)) < 1.01, "a closed line is not filled")
        #expect(Contrast.ratio(plain.color(x: 8, y: 19), plain.color(x: 1, y: 19)) < 1.01, "the default is unchanged")
    }

    @Test func anOpenFilledStatusLineIsOutlinedUnderIncreaseContrast() throws {
        let rendered = try raster(column(
            StatusLine(tile: .initial("A"), title: "All", isOpen: true, fillsWhenOpen: true).frame(width: 320),
            increaseContrast: true).background(Color.white))
        #expect(rendered.contrast((4, 19), (8, 19)) >= 3, "outline \(rendered.contrast((4, 19), (8, 19)))")
    }

    // #9
    @Test func aBannerTakesATitleAnActionAndAClose() throws {
        let plain = try raster(column(Banner(systemImage: "wifi", message: "Offline") { EmptyView() }.frame(width: 320)))
        let titled = try raster(column(
            Banner(systemImage: "wifi", title: "Offline", message: "Changes are kept and sent later.") { EmptyView() }
                .frame(width: 320)))
        let full = try raster(column(
            Banner(systemImage: "wifi", title: "Offline", message: "Changes are kept and sent later.",
                   action: BannerAction("Retry") {}, onClose: {})
                .frame(width: 320)))
        #expect(titled.height > plain.height)
        #expect(full.height >= titled.height)
        #expect(full.alphaSum != titled.alphaSum)
    }

    @Test func theBannersButtonsAreOptional() throws {
        let none = try raster(column(Banner(systemImage: "info.circle", message: "Saved", action: nil, onClose: nil).frame(width: 320)))
        let action = try raster(column(
            Banner(systemImage: "info.circle", message: "Saved", action: BannerAction("Undo") {}).frame(width: 320)))
        let close = try raster(column(Banner(systemImage: "info.circle", message: "Saved", onClose: {}).frame(width: 320)))
        let both = try raster(column(
            Banner(systemImage: "info.circle", message: "Saved", action: BannerAction("Undo") {}, onClose: {}).frame(width: 320)))
        #expect(Set([none.data, action.data, close.data, both.data]).count == 4)
    }

    /// The old initialiser still reads as it did, with a trailing closure of actions and none of the new ones.
    @Test func theOriginalBannerStillTakesItsOwnActions() throws {
        let original = Banner(systemImage: "wifi", message: "Offline") { Button("Retry") {} }
        let empty = Banner(systemImage: "wifi", message: "Offline") {}
        let titled = Banner(systemImage: "wifi", title: "Offline", message: "Later") { Button("Retry") {} }
        _ = try raster(column(VStack { original; empty; titled }.frame(width: 320)))
    }

    // #10
    @Test func aLabelOnlyIconButtonIsATargetWithItsTitle() throws {
        let short = try raster(column(IconButton("OK") {}))
        #expect(short.height == 28 && short.width >= 28)
        let long = try raster(column(IconButton("Mark all as read") {}))
        #expect(long.height == 28)
        #expect(long.width > 28 + 2 * 8)
        #expect(long.alphaSum > 0)
    }

    @Test(arguments: [ColorScheme.light, .dark])
    func aDisabledLabelOnlyButtonIsDimmed(_ scheme: ColorScheme) throws {
        func button(enabled: Bool) -> some View { column(IconButton("Done") {}.disabled(!enabled), scheme: scheme) }
        let enabled = try raster(button(enabled: true)).alphaSum
        let disabled = try raster(button(enabled: false)).alphaSum
        let share = Double(disabled) / Double(enabled)
        #expect(share < 0.5 && share > 0.3, "disabled ink is \(share) of the enabled ink")
    }

    /// Keyboard focus draws the kit's ring, opaque and 3:1 on the surfaces, 2 pt wide at 2 pt from the target.
    @Test(arguments: [ColorScheme.light, .dark])
    func aFocusedButtonShowsTheKitsRing(_ scheme: ColorScheme) throws {
        let appearance: Appearance = scheme == .dark ? .dark : .light
        let ring = ColorRoles(theme: theme, tokens: .standard, appearance: appearance).focusRingRGBA
        for button in [IconButton("Done") {}, IconButton("Back", systemImage: "arrow.left") {}] {
            let focused = try raster(column(button.padding(10).controlFocusPreview(), scheme: scheme))
            let plain = try raster(column(button.padding(10), scheme: scheme))
            let y = focused.height / 2
            // The target starts 10 pt in; its ring is 2 pt wide, from 4 to 2 pt outside it.
            #expect(focused.alpha(x: 7, y: y) == 1)
            #expect(Contrast.ratio(focused.color(x: 7, y: y), ring) < 1.02, "the ring is the kit's")
            #expect(plain.alpha(x: 7, y: y) == 0, "and absent unfocused")
        }
    }

    // #10
    func pill(_ selection: String, increased: Bool = false, scheme: ColorScheme = .light, focused: Bool = false) throws -> Raster {
        let view = SegmentedPill(
            [SegmentedPillItem(id: "list", title: "List"), SegmentedPillItem(id: "grid", title: "Grid", systemImage: "square.grid.2x2"),
             SegmentedPillItem(id: "map", title: "Map")],
            selection: .constant(selection), label: "View")
            .controlFocusPreview(focused)
            .padding(10)
        return try raster(column(view, scheme: scheme, increaseContrast: increased).background(Color.white))
    }

    @Test func aPillIs36PointsHighAndItsSegmentsAreTargets() throws {
        let rendered = try pill("list")
        #expect(rendered.height == 36 + 20)
        #expect(rendered.width > 28 * 3)
    }

    /// The first segment starts 4 pt inside the pill (10 pt of padding in the render): its fill is the selection fill,
    /// and the same place in the pill with another segment selected is the glass.
    @Test(arguments: [ColorScheme.light, .dark])
    func theSelectedSegmentIsFilled(_ scheme: ColorScheme) throws {
        let first = try pill("list", scheme: scheme)
        let last = try pill("map", scheme: scheme)
        let inside = (10 + 4 + 6, 10 + 18)
        let selected = first.color(x: inside.0, y: inside.1)
        let glass = last.color(x: inside.0, y: inside.1)
        let distance = max(abs(selected.red - glass.red), abs(selected.green - glass.green), abs(selected.blue - glass.blue))
        #expect(distance > 0.05, "\(scheme): the selected segment differs from the same place unselected")
    }

    /// The bar is 12 × 3 under the title, centred in the segment (about 49 pt wide here), 2 pt above the segment's bottom:
    /// its row, 38 pt down in the render, has two abrupt edges outside Increase Contrast and none under it.
    @Test func theSelectionMarkerStandsUnderTheSelectedTitleOutsideIncreaseContrast() throws {
        func edges(_ raster: Raster) -> [Int] {
            (30...48).filter { Contrast.ratio(raster.color(x: $0, y: 38), raster.color(x: $0 - 1, y: 38)) >= 2 }
        }
        #expect(edges(try pill("list")).count == 2, "a bar under the selected title")
        #expect(edges(try pill("list", increased: true)).isEmpty, "no bar under Increase Contrast")
    }

    /// Under Increase Contrast the selected segment is outlined: its edge differs from the fill inside by 3:1.
    @Test func theSelectedSegmentIsOutlinedUnderIncreaseContrast() throws {
        let increased = try pill("list", increased: true)
        let edge = (10 + 4, 10 + 18)
        let fill = (10 + 4 + 4, 10 + 18)
        #expect(increased.contrast(edge, fill) >= 3, "\(increased.contrast(edge, fill))")
    }

    @Test func aFocusedPillShowsTheKitsRing() throws {
        let focused = try pill("list", focused: true)
        let plain = try pill("list")
        #expect(focused.data != plain.data)
        let ring = ColorRoles(theme: theme, tokens: .standard, appearance: .light).focusRingRGBA
        // Around the first segment: 4 pt in plus 2 pt out is 4 pt left of the segment's edge, inside the pill's padding.
        let found = (0..<focused.width).contains { x in Contrast.ratio(focused.color(x: x, y: 10 + 18), ring) < 1.03 }
        #expect(found)
    }
}

extension TileSize {
    static let allCasesForTests: [TileSize] = [.standard, .compact, .small, .status]
}
