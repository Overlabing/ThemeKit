import ColorCore
import ColorPlatform
import DesignKit
import SwiftUI
import Testing

/// 0.2.12's focus ring: none on a selected row (the arrow keys move a list's selection, so the selection shows the
/// focus), a thin ring in the Theme's hue inside any other focused element, never after a click, always while VoiceOver
/// runs.
@MainActor
struct FocusRing0212Tests {
    static let theme = Palette.standard.themes[0]

    static func tracker(_ input: FocusInput?, voiceOver: Bool = false) -> FocusInputTracker {
        let tracker = FocusInputTracker()
        if let input { tracker.record(input) }
        tracker.record(voiceOver: voiceOver)
        return tracker
    }

    /// A 240 × 36 row background with 8 pt around it: its shape starts 12 pt in (8, then the free row's 4 pt side
    /// inset) and 10 pt down (8, then half the 4 pt row gap), 232 × 32.
    func row(
        _ state: RowState, _ tracker: FocusInputTracker, _ scheme: ColorScheme = .light, increased: Bool = false,
        follows: Bool = true
    ) throws -> Raster {
        try freshRaster(
            ListRowBackground(state: state)
                .frame(width: 240, height: 36)
                .padding(8)
                .selectionFollowsFocus(follows)
                .focusInputTracker(tracker)
                .accessibilityOverrides(increaseContrast: increased)
                .theme(Self.theme)
                .environment(\.colorScheme, scheme))
    }

    func freshRaster(_ view: some View) throws -> Raster {
        try hostedRaster(view)
    }

    // MARK: The rule

    @Test func theTrackersRowRule() {
        #expect(Self.tracker(nil).showsFocusRing(isSelected: false))
        #expect(!Self.tracker(nil).showsFocusRing(isSelected: true))
        #expect(Self.tracker(.keyboard).showsFocusRing(isSelected: false))
        #expect(!Self.tracker(.keyboard).showsFocusRing(isSelected: true))
        #expect(!Self.tracker(.pointer).showsFocusRing(isSelected: false))
        #expect(!Self.tracker(.pointer).showsFocusRing(isSelected: true))
        #expect(Self.tracker(.pointer, voiceOver: true).showsFocusRing(isSelected: false))
        #expect(Self.tracker(.pointer, voiceOver: true).showsFocusRing(isSelected: true))
    }

    // MARK: Rows

    nonisolated static let cases: [(ColorScheme, Bool)] = [(.light, false), (.dark, false), (.light, true), (.dark, true)]

    /// A selected row focused from the keyboard draws as the same row unfocused, byte for byte, in light, dark and both
    /// Increase Contrast modes.
    @Test(arguments: cases)
    func aSelectedFocusedRowShowsNoRing(_ scheme: ColorScheme, _ increased: Bool) throws {
        let focused = try row(RowState(isSelected: true, isFocused: true), Self.tracker(.keyboard), scheme, increased: increased)
        let unfocused = try row(RowState(isSelected: true), Self.tracker(.keyboard), scheme, increased: increased)
        #expect(focused.matches(unfocused))
    }

    /// An unselected row focused from the keyboard draws the ring inside its shape: the shape's first column (x 12) is
    /// the ring's colour, the column outside it (x 11) is empty, and a 1.5 pt ring leaves x 14 inside empty too.
    @Test(arguments: cases)
    func anUnselectedFocusedRowShowsAThinInsetRing(_ scheme: ColorScheme, _ increased: Bool) throws {
        let appearance = Appearance(isDark: scheme == .dark, isIncreasedContrast: increased)
        let ring = ColorRoles(theme: Self.theme, tokens: .standard, appearance: appearance).focusRingRGBA
        let ringed = try row(RowState(isFocused: true), Self.tracker(.keyboard), scheme, increased: increased)
        let plain = try row(RowState(), Self.tracker(.keyboard), scheme, increased: increased)
        #expect(plain.alpha(x: 12, y: 26) == 0 && plain.alpha(x: 128, y: 10) == 0, "an idle row draws no edge")
        let y = 26
        #expect(ringed.alpha(x: 11, y: y) == 0, "nothing outside the shape on the left")
        #expect(ringed.alpha(x: 12, y: y) == 1)
        #expect(Contrast.ratio(ringed.color(x: 12, y: y), ring) < 1.02, "the Theme's ring colour")
        #expect(ringed.alpha(x: 13, y: y) > 0.3 && ringed.alpha(x: 13, y: y) < 0.7, "half of the 1.5 pt line")
        #expect(ringed.alpha(x: 14, y: y) == 0, "a thin line")
        #expect(ringed.alpha(x: 244, y: y) == 0, "nothing outside the shape on the right")
        #expect(ringed.alpha(x: 243, y: y) == 1)
        #expect(ringed.alpha(x: 128, y: 9) == 0, "nothing above the shape")
        #expect(ringed.alpha(x: 128, y: 10) == 1)
        #expect(ringed.alpha(x: 128, y: 42) == 0, "nothing below the shape")
        #expect(ringed.alpha(x: 128, y: 41) == 1)
    }

    @Test(arguments: [ColorScheme.light, .dark])
    func aClickedRowShowsNoRing(_ scheme: ColorScheme) throws {
        let plain = try row(RowState(), Self.tracker(.keyboard), scheme)
        #expect(try row(RowState(isFocused: true), Self.tracker(.pointer), scheme).data == plain.data)
    }

    /// While VoiceOver runs the ring shows, after a click and on a selected row.
    @Test func whileVoiceOverRunsTheRingShows() throws {
        let voiceOver = Self.tracker(.pointer, voiceOver: true)
        let selected = try row(RowState(isSelected: true), voiceOver)
        let ringed = try row(RowState(isSelected: true, isFocused: true), voiceOver)
        #expect(!ringed.matches(selected))
        #expect(Contrast.ratio(ringed.color(x: 128, y: 10), ColorRoles(
            theme: Self.theme, tokens: .standard, appearance: .light).focusRingRGBA) < 1.02)
    }

    /// Rows whose focus moves over a selection that stays put (`selectionFollowsFocus(false)`, the rail's panel) show
    /// the ring on a selected row.
    @Test func aSelectedRowShowsTheRingWhenTheSelectionDoesNotFollowTheFocus() throws {
        let keyboard = Self.tracker(.keyboard)
        let selected = try row(RowState(isSelected: true), keyboard, follows: false)
        #expect(!(try row(RowState(isSelected: true, isFocused: true), keyboard, follows: false)).matches(selected))
    }

    // MARK: The colour

    /// The ring is the Theme's primary hue, opaque, mixed with ink to 3:1 on every surface a row sits on, in the four
    /// appearances of every standard Theme, and is no longer the system's focus colour.
    @Test(arguments: Palette.standard.themes)
    func theRingIsTheThemesHueAtThreeToOne(_ theme: Theme) {
        for appearance in Appearance.allCases {
            let roles = ColorRoles(theme: theme, tokens: .standard, appearance: appearance)
            let ring = roles.focusRingRGBA
            let colors = ResolvedColors(theme, in: appearance)
            #expect(ring.alpha == 1)
            #expect(Contrast.worst(opaque: ring, onLuminances: roles.legibility.surfaceLuminances) >= 3,
                    "\(theme.id) \(appearance)")
            let hue = RGBA(red: colors.primary.red, green: colors.primary.green, blue: colors.primary.blue)
            let expected = hue.mixed(with: colors.ink, by: roles.legibility.mix(of: hue, toward: colors.ink, reaching: 3))
            #expect(ring == expected, "\(theme.id) \(appearance)")
            #expect(ring == roles.selectionMarkerRGBA, "the selection marker's colour")
        }
    }

    /// A blue Theme aside, the ring is not the system's blue.
    @Test func theRingIsNotSystemBlue() {
        let theme = Self.theme
        #expect(theme.primary != .blue)
        for appearance in Appearance.allCases {
            let ring = ColorRoles(theme: theme, tokens: .standard, appearance: appearance).focusRingRGBA
            let focus = RGBA.keyboardFocus(in: appearance)
            #expect(abs(ring.blue - focus.blue) + abs(ring.red - focus.red) > 0.1, "\(appearance)")
        }
    }

    /// The audit's focus ring cases hold for every standard Theme, on the frame and in the column, in the four
    /// appearances.
    @Test func theAuditsFocusRingCasesPass() {
        for theme in Palette.standard.themes {
            for appearance in Appearance.allCases {
                for placement in [SurfacePlacement.frame] {
                    let cases = DesignTokens.standard.legibilityCases(for: theme, in: appearance, placement: placement)
                        .filter { $0.role == .focusRing }
                    #expect(cases.count == 5)
                    #expect(cases.allSatisfy { $0.after >= 3 && $0.threshold == 3 }, "\(theme.id) \(appearance)")
                }
            }
        }
    }

    // MARK: The rail

    /// The rail's current Space focused from the keyboard shows the ring: the rail's arrows move the focus, not the
    /// selection.
    @Test func theRailsCurrentSpaceShowsTheRingWhenFocused() throws {
        func rail(_ state: SpaceRailPreviewState) throws -> Raster {
            try freshRaster(
                SpaceRail(profiles: [RailSample.work(3)], selection: "w1", selectSpace: { _ in }, selectProfile: { _ in })
                    .spaceRailPreviewState(state)
                    .focusInputTracker(Self.tracker(.keyboard))
                    .frame(width: 300)
                    .theme(Self.theme)
                    .environment(\.colorScheme, .light))
        }
        #expect(!(try rail(SpaceRailPreviewState(focused: .space("w1")))).matches(try rail(SpaceRailPreviewState())))
    }
}



