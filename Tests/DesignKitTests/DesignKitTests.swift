import ColorCore
import ColorPlatform
import ColorUI
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
        #expect(spacing.selectionMarkerLeading == 2)
        #expect(spacing.selectionMarkerVertical == 8)
        #expect(spacing.columnInset == 12)
        #expect(spacing.columnInset == spacing.canvasInset)
        #expect(spacing.columnTop == 24)
        #expect(spacing.columnTop == spacing.columnInset + spacing.listMargin)
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
        #expect(radius.column == 12)
        #expect(radius.column == radius.row + tokens.spacing.listMargin - tokens.spacing.rowInsetHorizontal)
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
        #expect(size.selectionMarker == 3)
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
        #expect(emphasis.switcherTop == 0.85)
        #expect(emphasis.textContrast == 4.5)
        #expect(emphasis.nonTextContrast == 3)
        #expect(emphasis.pressed == 0.6)
        #expect(emphasis.disabled == 0.4)
        #expect(emphasis.columnLight == 0.5)
        #expect(emphasis.columnDark == 0.5)
        #expect(emphasis.column(isDark: true) == 0.5)
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

/// The surfaces the solver sees are the ones the reference app described in 0.1's fixtures, plus the panel that
/// groups an open folder's rows, so `ColorRoles` solves what the views draw.
struct SurfacesTests {
    @Test func lightAndDark() {
        let light = DesignTokens.standard.surfaces(in: .light)
        #expect(light == Surfaces(
            gradient: GradientSpec(top: 0.38, middle: 0.16, bottom: 0.05), contentTop: 0.1, fills: [0.10, 0.16],
            selection: .init(floor: 0.30, cap: 0.5, visibility: 1.3), tintFills: [0.14, 0.25], neutralFills: [0.06]))
        let dark = DesignTokens.standard.surfaces(in: .dark)
        #expect(dark == Surfaces(
            gradient: GradientSpec(top: 0.42, middle: 0.18, bottom: 0.06), contentTop: 0.1, fills: [0.10, 0.16],
            selection: .init(floor: 0.25, cap: 0.5, visibility: 1.3), tintFills: [0.14, 0.25], neutralFills: [0.06]))
    }

    /// Inside a column every surface is the frame's, under the column's backdrop.
    @Test(arguments: Appearance.allCases)
    func theColumnIsTheFrameUnderABackdrop(_ appearance: Appearance) {
        var expected = DesignTokens.standard.surfaces(in: appearance)
        #expect(expected.backdrop == 0)
        expected.backdrop = 0.5
        #expect(DesignTokens.standard.columnSurfaces(in: appearance) == expected)
        #expect(DesignTokens.standard.surfaces(in: appearance, placement: .column) == expected)
        #expect(DesignTokens.standard.surfaces(in: appearance, placement: .frame) == DesignTokens.standard.surfaces(in: appearance))
    }

    @Test func increasedContrastRaisesRowFillsAndTheSelectionFloorOnly() {
        let surfaces = DesignTokens.standard.surfaces(in: .darkIncreasedContrast)
        #expect(surfaces.fills.map { ($0 * 1000).rounded() / 1000 } == [0.18, 0.288])
        #expect(surfaces.selection.floor == 0.45)
        #expect(surfaces.selection.cap == 0.5)
        #expect(surfaces.tintFills == [0.14, 0.25])
        #expect(surfaces.neutralFills == [0.06])
    }
}

/// The views draw the opacities the solver solved on: every hue opacity times `hueScale`, Increase Contrast raising
/// the row fills only.
@Suite(.enabled(if: ProcessInfo.processInfo.operatingSystemVersion.majorVersion == 27))
struct ColorRolesTests {
    @Test(arguments: Palette.standard.themes)
    func rolesDrawWhatTheSolverSaw(_ theme: Theme) {
        for appearance in Appearance.allCases {
            let roles = ColorRoles(theme: theme, tokens: .standard, appearance: appearance)
            let described = DesignTokens.standard.surfaces(in: appearance).scaled(by: roles.hueScale)
            let solved = Legibility.fit(colors: ResolvedColors(theme, in: appearance), surfaces: DesignTokens.standard.surfaces(in: appearance))
            #expect(roles.legibility == solved)
            #expect(roles.hoverOpacity == described.fills[0])
            #expect(roles.currentOpacity == described.fills[1])
            #expect(roles.badgeOpacity == described.tintFills[0])
            #expect(roles.tileOpacity == described.tintFills[1])
            #expect(roles.layerOpacity == described.neutralFills[0])
            #expect(roles.selectionOpacity == solved.selected)
            #expect(roles.selectionOpacity >= described.selection.floor - 0.001)
            #expect(roles.secondaryTextRGBA.alpha == solved.secondaryAlpha)
        }
    }

    /// The Themes whose full opacities leave a text under 4.5:1 are drawn lighter, by these shares; the others keep
    /// every opacity.
    @Test func hueScales() {
        let expected: [String: [Appearance: Double]] = [
            "indigo-blue": [.darkIncreasedContrast: 0.986],
            "orange-pink": [.dark: 0.874, .darkIncreasedContrast: 0.676],
            "teal-green": [.dark: 0.752, .darkIncreasedContrast: 0.590],
            "red-orange": [.darkIncreasedContrast: 0.990],
            "mint-cyan": [.dark: 0.724, .darkIncreasedContrast: 0.570],
            "brown-yellow": [.darkIncreasedContrast: 0.835],
        ]
        for theme in Palette.standard.themes {
            for appearance in Appearance.allCases {
                let scale = ColorRoles(theme: theme, tokens: .standard, appearance: appearance).hueScale
                #expect((scale * 1000).rounded() / 1000 == expected[theme.id]?[appearance] ?? 1, "\(theme.id) \(appearance)")
            }
        }
    }

    /// Inside a column the roles are solved on the column's surfaces, at the frame's share of the hue, so the
    /// gradient under the column and the fills in it are drawn alike.
    @Test(arguments: Palette.standard.themes)
    func columnRolesAreSolvedOnTheColumnFill(_ theme: Theme) {
        for appearance in Appearance.allCases {
            let frame = ColorRoles(theme: theme, tokens: .standard, appearance: appearance)
            let column = ColorRoles(theme: theme, tokens: .standard, appearance: appearance, placement: .column)
            let colors = ResolvedColors(theme, in: appearance)
            #expect(frame.placement == .frame)
            #expect(column.hueScale == frame.hueScale)
            #expect(column.legibility == Legibility.solve(
                colors: colors, surfaces: DesignTokens.standard.columnSurfaces(in: appearance), hueScale: frame.hueScale))
            #expect(column.hoverOpacity == frame.hoverOpacity)
            #expect(column.frameStops == frame.frameStops)
            #expect(column.columnFillOpacity == 0.5)
            let solved = column.legibility
            #expect(min(solved.worstLabel, solved.worstSecondary, solved.worstTint) >= 4.5, "\(theme.id) \(appearance)")
            #expect(Contrast.worst(opaque: column.focusRingRGBA, onLuminances: solved.surfaceLuminances) >= 3)
            #expect(Contrast.worst(opaque: column.selectionMarkerRGBA, onLuminances: solved.surfaceLuminances) >= 3)
        }
    }

    /// The column's edge: the label's ink, translucent, at 3:1 against the gradient beside the column and against the
    /// column's fill, with or without Reduce Transparency.
    @Test(arguments: Palette.standard.themes)
    func theColumnEdgeReachesThreeToOne(_ theme: Theme) {
        for appearance in Appearance.allCases {
            let roles = ColorRoles(theme: theme, tokens: .standard, appearance: appearance, placement: .column)
            let colors = ResolvedColors(theme, in: appearance)
            let edge = roles.columnEdgeRGBA
            #expect(edge.alpha > 0.45 && edge.alpha < 0.6, "\(theme.id) \(appearance) \(edge.alpha)")
            #expect(edge.red == colors.ink.red)
            let neighbours = ColorRoles.columnEdgeNeighbours(
                colors: colors, frame: DesignTokens.standard.surfaces(in: appearance),
                column: DesignTokens.standard.columnSurfaces(in: appearance), hueScale: roles.hueScale)
            #expect(neighbours.count == 102)
            for (fill, outside) in neighbours {
                let line = edge.composited(over: fill)
                #expect(Contrast.ratio(line, outside) >= 3)
                #expect(Contrast.ratio(line, fill) >= 3)
            }
        }
    }

    @Test func focusRingIsOpaqueAndReachesThreeToOne() {
        for theme in Palette.standard.themes {
            for appearance in Appearance.allCases {
                let roles = ColorRoles(theme: theme, tokens: .standard, appearance: appearance)
                let ring = roles.focusRingRGBA
                #expect(ring.alpha == 1)
                #expect(Contrast.worst(opaque: ring, onLuminances: roles.legibility.surfaceLuminances) >= 3)
            }
        }
    }
}

/// Every text and glyph role on every surface, for every standard Theme and appearance, and a symbol on every system
/// hue, as recorded (CHANGELOG 0.2.1, 0.2.2 and, inside a list column, 0.2.3). The system's colours were resolved on macOS 27, so the comparison runs there.
@Suite(.enabled(if: ProcessInfo.processInfo.operatingSystemVersion.majorVersion == 27))
struct LegibilityCaseTests {
    static let computed: [String: LegibilityCase] = {
        var all: [String: LegibilityCase] = [:]
        var cases: [LegibilityCase] = []
        for appearance in Appearance.allCases {
            for theme in Palette.standard.themes {
                for placement in SurfacePlacement.allCases {
                    cases += DesignTokens.standard.legibilityCases(for: theme, in: appearance, placement: placement)
                }
            }
            cases += DesignTokens.standard.symbolCases(in: appearance)
        }
        for item in cases {
            all["\(item.themeID) \(item.appearance) \(item.placement) \(item.role) \(item.surface)"] = item
        }
        return all
    }()

    /// 818 on the frame (as 0.2.2), 798 in the column: 27 per Theme and appearance, plus the marker (light, dark) or
    /// the two outlines (Increase Contrast).
    @Test func everyCaseIsRecorded() {
        #expect(Self.computed.count == 1616)
        #expect(Self.computed.values.filter { $0.placement == .column }.count == 798)
        #expect(Self.computed.count == RecordedCase.all.count)
        #expect(Set(Self.computed.keys) == Set(RecordedCase.all.map(\.key)))
    }

    @Test(arguments: RecordedCase.all)
    func recorded(_ recorded: RecordedCase) throws {
        let item = try #require(Self.computed[recorded.key])
        #expect((item.before * 100).rounded() / 100 == recorded.before)
        #expect((item.after * 100).rounded() / 100 == recorded.after)
        #expect(item.threshold == recorded.threshold)
        #expect(item.after >= item.threshold)
    }
}

struct LegibilityInvariantTests {
    /// With whatever colours the system gives, every text and glyph role reaches its threshold on every surface, in
    /// every appearance.
    @Test(arguments: Palette.standard.themes, SurfacePlacement.allCases)
    func everyCaseReachesItsThreshold(_ theme: Theme, _ placement: SurfacePlacement) {
        for appearance in Appearance.allCases {
            for item in DesignTokens.standard.legibilityCases(for: theme, in: appearance, placement: placement) {
                #expect(item.placement == placement)
                #expect(item.after >= item.threshold, "\(item)")
            }
        }
    }

    /// Inside a column: the frame's roles on the column's fill instead of the frame, no text or symbol on the opaque
    /// hue (nothing under it changes), and the column's edge against the gradient and against the fill.
    @Test(arguments: Appearance.allCases)
    func theColumnHasItsOwnCases(_ appearance: Appearance) {
        let cases = DesignTokens.standard.legibilityCases(for: Palette.standard.themes[0], in: appearance, placement: .column)
        #expect(cases.count == (appearance.isIncreasedContrast ? 29 : 28))
        #expect(!cases.contains { $0.surface == .frame && $0.role != .columnEdge })
        #expect(!cases.contains { $0.role == .textOnHue })
        #expect(cases.filter { $0.surface == .columnFill }.map(\.role)
            == [.primaryText, .secondaryText, .tintedText, .focusRing, .columnEdge])
        let edge = cases.filter { $0.role == .columnEdge }
        #expect(edge.map(\.surface) == [.frame, .columnFill])
        #expect(edge.allSatisfy { $0.threshold == 3 && $0.after >= 3 && $0.isFixed })
        let frame = DesignTokens.standard.legibilityCases(for: Palette.standard.themes[0], in: appearance)
        #expect(!frame.contains { $0.role == .columnEdge || $0.surface == .columnFill })
    }

    @Test func aSymbolOnAnySystemHueReachesThreeToOne() {
        for appearance in Appearance.allCases {
            for item in DesignTokens.standard.symbolCases(in: appearance) {
                #expect(item.after >= 3, "\(item)")
            }
        }
    }

    /// The thresholds: 4.5:1 for text, 3:1 for glyphs, focus rings, outlines and the selection marker.
    @Test func thresholds() {
        let cases = DesignTokens.standard.legibilityCases(for: Palette.standard.themes[0], in: .darkIncreasedContrast)
        let column = DesignTokens.standard.legibilityCases(
            for: Palette.standard.themes[0], in: .darkIncreasedContrast, placement: .column)
        let text: Set<LegibilityCase.Role> = [.primaryText, .secondaryText, .tintedText, .textOnHue]
        for item in cases + column {
            #expect(item.threshold == (text.contains(item.role) ? 4.5 : 3), "\(item)")
        }
        #expect(Set(cases.map(\.role))
            == Set(LegibilityCase.Role.allCases).subtracting([.symbolOnHue, .selectionMarker, .columnEdge]))
        #expect(Set(column.map(\.role))
            == Set(LegibilityCase.Role.allCases).subtracting([.symbolOnHue, .selectionMarker, .textOnHue]))
    }

    /// The marker stands where the outline does not: outside Increase Contrast, one case per Theme and appearance.
    @Test(arguments: Palette.standard.themes, [Appearance.light, .dark])
    func theMarkerHasOneCaseOutsideIncreaseContrast(_ theme: Theme, _ appearance: Appearance) throws {
        let cases = DesignTokens.standard.legibilityCases(for: theme, in: appearance).filter { $0.role == .selectionMarker }
        let marker = try #require(cases.first)
        #expect(cases.count == 1)
        #expect(marker.surface == .selectedRow)
        #expect(marker.threshold == 3)
        #expect(marker.before < 1.4)
        #expect(marker.after >= 3)
        #expect(marker.isFixed)
    }

    @Test(arguments: Palette.standard.themes, [Appearance.lightIncreasedContrast, .darkIncreasedContrast])
    func increaseContrastKeepsItsOutlineAndHasNoMarker(_ theme: Theme, _ appearance: Appearance) {
        let roles = Set(DesignTokens.standard.legibilityCases(for: theme, in: appearance).map(\.role))
        #expect(roles.contains(.selectionOutline))
        #expect(!roles.contains(.selectionMarker))
    }
}

/// The switcher's help names the item and the shortcut the app gives it; the kit writes no key of its own.
struct SwitcherItemTests {
    let theme = Palette.standard.themes[0]

    @Test func theHelpCarriesTheAppsShortcut() {
        #expect(SwitcherItem(id: "a", name: "Work", theme: theme, shortcut: "⌃1").help == "Work (⌃1)")
        #expect(SwitcherItem(id: "a", name: "Work", theme: theme, shortcut: "⌘3").help == "Work (⌘3)")
    }

    @Test func withoutAShortcutTheHelpIsTheName() {
        let item = SwitcherItem(id: "a", name: "Work", theme: theme)
        #expect(item.shortcut == nil)
        #expect(item.help == "Work")
    }
}

/// The kit's colours are explicit: the window's state does not change them, so a column in an inactive window keeps
/// the contrast it has in the key window.
@MainActor
struct InactiveWindowTests {
    @Test(arguments: [ColorScheme.light, .dark])
    func aRowDrawsTheSameInAnInactiveWindow(_ scheme: ColorScheme) throws {
        func pixels(_ state: ControlActiveState) throws -> Data {
            let row = ListRow("Title", details: ["Detail"], state: RowState(isSelected: true)) { Tile(.initial("T")) }
                trailing: { Image(systemName: "chevron.right") }
                .frame(width: 320)
                .background { WindowBackground() }
                .theme(Palette.standard.themes[5])
                .environment(\.colorScheme, scheme)
                .environment(\.controlActiveState, state)
            let image = try #require(ImageRenderer(content: row).cgImage)
            let context = try #require(CGContext(
                data: nil, width: image.width, height: image.height, bitsPerComponent: 8, bytesPerRow: image.width * 4,
                space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
            context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
            let bytes = try #require(context.data)
            return Data(bytes: bytes, count: image.width * image.height * 4)
        }
        _ = try pixels(.key)  // The first render in a process differs from the next ones: warm up.
        #expect(try pixels(.key) == pixels(.inactive))
    }
}

/// What the views draw, read back from an offscreen render: the selected row's marker at 3:1 on its own fill, none
/// under Increase Contrast, a disabled icon button dimmed, and the column on its own surface.
@MainActor
@Suite(.enabled(if: ProcessInfo.processInfo.operatingSystemVersion.majorVersion == 27))
struct RenderedViewsTests {
    struct Pixels {
        let width: Int
        let height: Int
        let data: [UInt8]

        func color(x: Int, y: Int) -> RGBA {
            let offset = (y * width + x) * 4
            return RGBA(
                red: Double(data[offset]) / 255, green: Double(data[offset + 1]) / 255, blue: Double(data[offset + 2]) / 255)
        }

        var alphaSum: Int { stride(from: 3, to: data.count, by: 4).reduce(0) { $0 + Int(data[$1]) } }
    }

    func render(_ view: some View) throws -> Pixels {
        let renderer = ImageRenderer(content: view)
        renderer.scale = 1
        let image = try #require(renderer.cgImage)
        var data = [UInt8](repeating: 0, count: image.width * image.height * 4)
        let drawn = data.withUnsafeMutableBytes { buffer in
            guard let context = CGContext(
                data: buffer.baseAddress, width: image.width, height: image.height, bitsPerComponent: 8,
                bytesPerRow: image.width * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return false }
            context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
            return true
        }
        #expect(drawn)
        return Pixels(width: image.width, height: image.height, data: data)
    }

    func selectedRow(_ theme: Theme, _ scheme: ColorScheme, increased: Bool) throws -> Pixels {
        let row = ListRow("Title", details: ["Detail"], state: RowState(isSelected: true)) { Tile(.initial("T")) }
            .frame(width: 320)
            .background { WindowBackground() }
            .theme(theme)
            .accessibilityOverrides(increaseContrast: increased)
            .environment(\.colorScheme, scheme)
        _ = try render(row)  // The first render in a process differs from the next ones: warm up.
        return try render(row)
    }

    /// The row's background starts at 4 pt (the list margin less the row's inset); the bar is 2 pt in and 3 pt wide;
    /// the tile starts 8 pt into the background. 8-bit pixels bring the ratio of a marker solved to 3.00 down by up to
    /// 0.05: the exact 3:1 is the recorded cases' (`LegibilityCaseTests`).
    @Test(arguments: Palette.standard.themes, [ColorScheme.light, .dark])
    func theMarkerReachesThreeToOneOnTheSelectedFill(_ theme: Theme, _ scheme: ColorScheme) throws {
        let pixels = try selectedRow(theme, scheme, increased: false)
        let middle = pixels.height / 2
        let marker = pixels.color(x: 7, y: middle)
        let fill = pixels.color(x: 10, y: middle)
        #expect(Contrast.ratio(marker, fill) >= 2.95, "\(theme.id) \(scheme)")
    }

    @Test(arguments: [ColorScheme.light, .dark])
    func increaseContrastDrawsNoMarker(_ scheme: ColorScheme) throws {
        let pixels = try selectedRow(Palette.standard.themes[0], scheme, increased: true)
        let middle = pixels.height / 2
        #expect(Contrast.ratio(pixels.color(x: 7, y: middle), pixels.color(x: 10, y: middle)) < 1.05)
    }

    func layout(_ side: ColumnSide, _ theme: Theme, _ scheme: ColorScheme, reduceTransparency: Bool = false) throws -> Pixels {
        let view = ColumnLayout(side: side) { Color.clear.frame(height: 10) } detail: { Color.clear }
            .frame(width: 600, height: 400)
            .theme(theme)
            .accessibilityOverrides(reduceTransparency: reduceTransparency)
            .environment(\.colorScheme, scheme)
        _ = try render(view)
        return try render(view)
    }

    /// Halfway down, the column's edge (1 pt, 12 pt in from the window's side) reaches 3:1 against the gradient
    /// beside it and against the column's fill, on either side; the fill differs from the gradient. 8-bit pixels may
    /// take up to 0.05 off a ratio solved to 3.00.
    @Test(arguments: [Palette.standard.themes[0], Palette.standard.themes[2]], [ColorScheme.light, .dark])
    func theColumnStandsOnItsOwnSurface(_ theme: Theme, _ scheme: ColorScheme) throws {
        for side in ColumnSide.allCases {
            let pixels = try layout(side, theme, scheme)
            #expect(pixels.width == 600)
            let y = pixels.height / 2
            func x(_ fromOuterEdge: Int) -> Int { side == .left ? fromOuterEdge : pixels.width - 1 - fromOuterEdge }
            let outside = pixels.color(x: x(6), y: y)
            let edge = pixels.color(x: x(12), y: y)
            let fill = pixels.color(x: x(40), y: y)
            #expect(Contrast.ratio(edge, outside) >= 2.95, "\(theme.id) \(scheme) \(side)")
            #expect(Contrast.ratio(edge, fill) >= 2.95, "\(theme.id) \(scheme) \(side)")
            #expect(Contrast.ratio(fill, outside) > 1.02, "\(theme.id) \(scheme) \(side)")
            #expect(Contrast.ratio(pixels.color(x: x(11), y: y), outside) < 1.02, "\(theme.id) \(scheme) \(side)")
        }
    }

    /// Under Reduce Transparency the column is the plain window background, opaque: nothing of the gradient shows.
    @Test(arguments: [ColorScheme.light, .dark])
    func reduceTransparencyMakesTheColumnOpaque(_ scheme: ColorScheme) throws {
        let pixels = try layout(.left, Palette.standard.themes[0], scheme, reduceTransparency: true)
        let background = ResolvedColors(Palette.standard.themes[0], in: scheme == .dark ? .dark : .light).background
        let fill = pixels.color(x: 40, y: pixels.height / 2)
        #expect(Contrast.ratio(fill, background) < 1.01, "\(fill) \(background)")
    }

    /// A row inside the column solves on the column's fill: its marker reaches 3:1 on its own fill there.
    @Test(arguments: [Palette.standard.themes[0], Palette.standard.themes[2]], [ColorScheme.light, .dark])
    func theMarkerReachesThreeToOneInTheColumn(_ theme: Theme, _ scheme: ColorScheme) throws {
        let view = ColumnSurface {
            ListRow("Title", details: ["Detail"], state: RowState(isSelected: true)) { Tile(.initial("T")) }
                .frame(width: 320)
        }
        .background { WindowBackground() }
        .theme(theme)
        .environment(\.colorScheme, scheme)
        _ = try render(view)
        let pixels = try render(view)
        let middle = 24 + (pixels.height - 36) / 2
        let marker = pixels.color(x: 19, y: middle)
        let fill = pixels.color(x: 22, y: middle)
        #expect(Contrast.ratio(marker, fill) >= 2.95, "\(theme.id) \(scheme)")
    }

    @Test(arguments: [ColorScheme.light, .dark])
    func aDisabledIconButtonIsDimmed(_ scheme: ColorScheme) throws {
        func button(enabled: Bool) -> some View {
            IconButton("Back", systemImage: "arrow.left") {}
                .disabled(!enabled)
                .theme(Palette.standard.themes[0])
                .environment(\.colorScheme, scheme)
        }
        _ = try render(button(enabled: true))
        let enabled = try render(button(enabled: true)).alphaSum
        let disabled = try render(button(enabled: false)).alphaSum
        #expect(enabled > 0)
        let share = Double(disabled) / Double(enabled)
        #expect(share < 0.5 && share > 0.3, "disabled ink is \(share) of the enabled ink")
    }
}
