import ColorCore
import ColorPlatform
import ColorUI
import DesignKit
import Foundation
import SwiftUI
import Testing

/// Sample Profiles: Work has `workCount` Spaces (w1…), Personal three (Home, Reading, Family), last on Reading.
enum RailSample {
    static let themes = Palette.standard.themes

    static func work(_ count: Int) -> SpaceRailProfile {
        SpaceRailProfile(
            id: "work", name: "Work", emoji: "💼",
            spaces: (1...count).map { index in
                SpaceRailSpace(id: "w\(index)", name: "Work \(index)", theme: themes[index % themes.count], shortcut: "⌃\(index)")
            },
            shortcut: "⌃⌥⌘←")
    }

    static let personal = SpaceRailProfile(
        id: "personal", name: "Personal", emoji: "🏡",
        spaces: [
            SpaceRailSpace(id: "home", name: "Home", glyph: .emoji("🏡"), theme: themes[4]),
            SpaceRailSpace(id: "reading", name: "Reading", glyph: .symbol("books.vertical"), theme: themes[2]),
            SpaceRailSpace(id: "family", name: "Family", theme: themes[1]),
        ],
        lastSpaceID: "reading", shortcut: "⌃⌥⌘→")

    static func eight(_ id: String) -> SpaceRailProfile {
        SpaceRailProfile(
            id: id, name: id.capitalized,
            spaces: (1...8).map { SpaceRailSpace(id: "\(id)\($0)", name: "\(id) \($0)", theme: themes[$0 % themes.count]) })
    }
}

struct SpaceRailTokenTests {
    let tokens = DesignTokens.standard

    @Test func railTokensComeFromTheScale() {
        #expect(tokens.size.railHeight == 36)
        #expect(tokens.size.railHeight == tokens.size.minTarget + DesignTokens.Spacing.s)
        #expect(tokens.size.railMarker == 12)
        #expect(tokens.size.railDivider == 16)
        #expect(tokens.size.railCount == 16)
        #expect(tokens.size.railDotsMax == 4)
        #expect(tokens.spacing.railMarkerGap == 2)
        #expect(tokens.spacing.railGroupGap == 4)
        #expect(tokens.spacing.railDotGap == 4)
        #expect(tokens.spacing.railCaption == 4)
        #expect(tokens.spacing.railFoldPadding == 4)
    }

    /// The row is inset so that a glyph's edge lies on the column's margin.
    @Test func theGlyphsLineUpOnTheMargin() {
        let inset = SpaceRailModel.inset(tokens)
        #expect(inset == 10)
        #expect(inset + (tokens.size.minTarget - tokens.size.glyphCircle) / 2 == tokens.spacing.listMargin)
    }

    @Test func profileSwapFoldsOneGlyphAfterTheOtherAndFadesUnderReduceMotion() {
        #expect(MotionRole.profileSwap.spec == MotionRole.Spec(duration: .calm, curve: .smooth, stagger: 0.04, reduced: .fade))
        #expect(MotionRole.profileSwap.resolved(reduceMotion: true) == MotionRole.reducedFade)
        #expect(MotionRole.themeChange.resolved(reduceMotion: true) == nil)
    }
}

struct SpaceRailSelectionTests {
    @Test func theActiveProfileIsTheOneHoldingTheSelectedSpace() {
        let model = SpaceRailModel(profiles: [RailSample.work(3), RailSample.personal], selection: "reading")
        #expect(model.activeProfile?.id == "personal")
        #expect(model.otherProfiles.map(\.id) == ["work"])
        let layout = model.layout(width: 360, hasCommands: true)
        #expect(layout.spaces == [
            .space(RailSample.personal.spaces[0], position: 1, count: 3, isSelected: false),
            .space(RailSample.personal.spaces[1], position: 2, count: 3, isSelected: true),
            .space(RailSample.personal.spaces[2], position: 3, count: 3, isSelected: false),
        ])
        #expect(layout.selectedKey == .space("reading"))
    }

    @Test func anUnknownSelectionOpensTheFirstProfileWithNothingSelected() {
        let model = SpaceRailModel(profiles: [RailSample.work(3), RailSample.personal], selection: "gone")
        #expect(model.activeProfile?.id == "work")
        #expect(model.layout(width: 360, hasCommands: false).selectedKey == nil)
    }

    @Test func activatingAnItemAsksForItsAction() {
        let model = SpaceRailModel(profiles: [RailSample.work(3), RailSample.personal], selection: "w1")
        let layout = model.layout(width: 360, hasCommands: true)
        #expect(layout.items.map(model.action(for:)) == [
            .selectSpace("w1"), .selectSpace("w2"), .selectSpace("w3"),
            .selectProfile("personal", landing: "reading"),
            .showCommands,
        ])
        #expect(model.action(for: .overflow(hidden: 2)) == .showPanel)
    }

    @Test func aProfileLandsOnItsLastSpaceOrItsFirst() {
        #expect(RailSample.personal.landingSpace?.id == "reading")
        #expect(RailSample.work(3).landingSpace?.id == "w1")
        let gone = SpaceRailProfile(id: "p", name: "P", spaces: RailSample.personal.spaces, lastSpaceID: "deleted")
        #expect(gone.landingSpace?.id == "home")
        #expect(SpaceRailProfile(id: "e", name: "Empty", spaces: []).landingSpace == nil)
    }
}

struct SpaceRailFoldingTests {
    @Test func everyOtherProfileFoldsIntoItsDotsAfterTheDivider() {
        let model = SpaceRailModel(profiles: [RailSample.work(3), RailSample.personal], selection: "w2")
        let layout = model.layout(width: 360, hasCommands: true)
        #expect(layout.showsDivider)
        #expect(layout.profiles == [.profile(RailSample.personal, dots: RailSample.personal.spaces.map(\.theme), more: 0)])
        #expect(layout.overflow == nil)
        #expect(layout.showsAdd)
    }

    @Test func aFoldedProfileShowsFourDotsThenACount() {
        let model = SpaceRailModel(profiles: [RailSample.work(3), RailSample.eight("hobby")], selection: "w1")
        let profiles = model.layout(width: 360, hasCommands: false).profiles
        #expect(profiles == [.profile(RailSample.eight("hobby"), dots: RailSample.eight("hobby").spaces.prefix(4).map(\.theme), more: 4)])
        // 4 dots of 8 and 3 gaps of 4, a gap and the 16 pt count, 4 pt padding either side.
        #expect(model.itemWidth(profiles[0]) == 72)
    }

    @Test func aFoldedTargetIsNeverUnderTheMinimumTarget() {
        let one = SpaceRailProfile(id: "one", name: "One", spaces: [RailSample.personal.spaces[0]])
        let model = SpaceRailModel(profiles: [RailSample.work(3), one], selection: "w1")
        #expect(model.itemWidth(.profile(one, dots: [one.spaces[0].theme], more: 0)) == 28)
        #expect(model.itemWidth(.profile(RailSample.personal, dots: RailSample.personal.spaces.map(\.theme), more: 0)) == 40)
        #expect(model.itemWidth(.add) == 28)
        #expect(model.itemWidth(.overflow(hidden: 3)) == 28)
    }
}

/// The row has the rail's width less 10 pt either side: 340 pt in the ideal column (360), 280 in the narrowest (300).
struct SpaceRailOverflowTests {
    @Test func eightSpacesAndAFoldedProfileFitTheIdealColumn() {
        let model = SpaceRailModel(profiles: [RailSample.work(8), RailSample.personal], selection: "w1")
        let layout = model.layout(width: 360, hasCommands: true)
        #expect(layout.spaces.count == 8)
        #expect(layout.overflow == nil)
        // 8 targets of 28, the divider (4 + 1 + 4), Personal's 40, the + 28.
        #expect(layout.width == 301)
    }

    @Test func eightAndEightStillFitTheIdealColumn() {
        let model = SpaceRailModel(profiles: [RailSample.work(8), RailSample.eight("hobby")], selection: "w1")
        let layout = model.layout(width: 360, hasCommands: true)
        #expect(layout.width == 333)
        #expect(layout.spaces.count == 8)
        #expect(layout.overflow == nil)
    }

    /// The proposal's case: at the narrowest column the row is 21 pt too wide, so the last Spaces go behind a "+n".
    @Test func theNarrowestColumnFoldsTheLastSpacesIntoATrailingCount() {
        let model = SpaceRailModel(profiles: [RailSample.work(8), RailSample.personal], selection: "w1")
        let layout = model.layout(width: 300, hasCommands: true)
        #expect(layout.spaces.map(\.id) == (1...6).map { .space("w\($0)") })
        #expect(layout.overflow == .overflow(hidden: 2))
        #expect(layout.profiles.count == 1)
        #expect(layout.width == 273)
        #expect(layout.items.last == .add)
    }

    @Test func theThresholdIsTheRowsWidth() {
        let model = SpaceRailModel(profiles: [RailSample.work(8), RailSample.personal], selection: "w1")
        #expect(model.layout(width: 321, hasCommands: true).overflow == nil)
        #expect(model.layout(width: 320.5, hasCommands: true).overflow == .overflow(hidden: 2))
    }

    @Test func theSelectedSpaceAlwaysShows() {
        let model = SpaceRailModel(profiles: [RailSample.work(8), RailSample.personal], selection: "w8")
        let layout = model.layout(width: 300, hasCommands: true)
        #expect(layout.spaces.map(\.id) == [1, 2, 3, 4, 5, 8].map { .space("w\($0)") })
        #expect(layout.selectedKey == .space("w8"))
        guard case .space(_, let position, let count, true) = layout.spaces.last else {
            Issue.record("the selected Space is not last")
            return
        }
        #expect(position == 8)
        #expect(count == 8)
    }

    /// Too narrow for one Space beside the folded Profiles: they go into the panel too, counted in the "+n".
    @Test func aVeryNarrowRowPutsTheFoldedProfilesInThePanel() {
        let model = SpaceRailModel(profiles: [RailSample.work(3), RailSample.personal], selection: "w2")
        let layout = model.layout(width: 150, hasCommands: true)
        #expect(layout.profiles.isEmpty)
        #expect(!layout.showsDivider)
        #expect(layout.spaces.map(\.id) == [.space("w1"), .space("w2")])
        #expect(layout.overflow == .overflow(hidden: 2))
    }
}

struct SpaceRailWithoutProfilesTests {
    let spaces = RailSample.work(8).spaces.map {
        SpaceRailSpace(id: $0.id, name: $0.name, glyph: $0.glyph, theme: $0.theme, shortcut: "⌘\($0.id.dropFirst())")
    }

    @Test func theRowIsTheSpacesAloneWithNoDivider() {
        let model = SpaceRailModel(spaces: Array(spaces.prefix(3)), selection: "w2")
        #expect(!model.hasProfiles)
        #expect(model.otherProfiles.isEmpty)
        let layout = model.layout(width: 360, hasCommands: true)
        #expect(!layout.showsDivider)
        #expect(layout.profiles.isEmpty)
        #expect(layout.items.map(\.id) == [.space("w1"), .space("w2"), .space("w3"), .add])
        #expect(model.accessibilityGroupLabel == "Spaces")
        #expect(model.caption(for: .space("w2")) == SpaceRailCaption(title: "Work 2", shortcut: "⌘2"))
    }

    @Test func eightSpacesFitTheNarrowestColumn() {
        let model = SpaceRailModel(spaces: spaces, selection: "w1")
        let layout = model.layout(width: 300, hasCommands: true)
        #expect(layout.spaces.count == 8)
        #expect(layout.width == 252)
        #expect(model.layout(width: 200, hasCommands: true).overflow == .overflow(hidden: 4))
    }
}

struct SpaceRailKeyboardTests {
    let layout = SpaceRailModel(profiles: [RailSample.work(3), RailSample.personal], selection: "w2")
        .layout(width: 360, hasCommands: true)

    @Test func arrowsMoveAcrossEveryItemAndStopAtTheEnds() {
        #expect(layout.key(movingFrom: nil, by: 1) == .space("w2"))
        #expect(layout.key(movingFrom: .space("w2"), by: 1) == .space("w3"))
        #expect(layout.key(movingFrom: .space("w3"), by: 1) == .profile("personal"))
        #expect(layout.key(movingFrom: .profile("personal"), by: 1) == .add)
        #expect(layout.key(movingFrom: .add, by: 1) == .add)
        #expect(layout.key(movingFrom: .space("w1"), by: -1) == .space("w1"))
        #expect(layout.key(movingFrom: .space("gone"), by: 1) == .space("w2"))
    }
}

struct SpaceRailWordingTests {
    let model = SpaceRailModel(
        profiles: [RailSample.work(3), RailSample.personal, SpaceRailProfile(id: "solo", name: "Solo", spaces: [RailSample.personal.spaces[0]])],
        selection: "w2")

    @Test func voiceOverNamesEachItem() {
        let layout = model.layout(width: 360, hasCommands: true)
        #expect(layout.items.map(model.accessibilityLabel(for:)) == [
            "Space Work 1, 1 of 3", "Space Work 2, 2 of 3", "Space Work 3, 3 of 3",
            "Profile Personal, 3 Spaces", "Profile Solo, 1 Space", "Add",
        ])
        #expect(model.accessibilityLabel(for: .overflow(hidden: 2)) == "All Spaces, 2 more")
        #expect(model.accessibilityGroupLabel == "Spaces and Profiles")
    }

    @Test func theCaptionSaysWhereAProfileLands() {
        #expect(model.caption(for: .profile("personal")) == SpaceRailCaption(
            emoji: "🏡", title: "Personal", detail: "3 Spaces · opens Reading", shortcut: "⌃⌥⌘→"))
        #expect(model.caption(for: .profile("solo"))?.detail == "1 Space · opens Home")
        #expect(model.caption(for: .space("w3")) == SpaceRailCaption(title: "Work 3", shortcut: "⌃3"))
        #expect(model.caption(for: .add) == nil)
        #expect(model.caption(for: .space("home")) == nil)
    }
}

/// The rail's marks on the column's fill, as recorded (CHANGELOG 0.2.4).
@Suite(.enabled(if: ProcessInfo.processInfo.operatingSystemVersion.majorVersion == 27))
struct SpaceRailLegibilityTests {
    static let computed: [String: LegibilityCase] = {
        var all: [String: LegibilityCase] = [:]
        for theme in Palette.standard.themes {
            for appearance in Appearance.allCases {
                for item in DesignTokens.standard.railCases(for: theme, in: appearance) {
                    all["\(item.themeID) \(item.appearance) \(item.placement) \(item.role) \(item.surface)"] = item
                }
            }
        }
        return all
    }()

    /// 6 per Theme and appearance: the quiet glyph twice, the marker, the dots twice, the divider.
    @Test func everyRailCaseIsRecorded() {
        #expect(Self.computed.count == 168)
        #expect(Set(Self.computed.keys) == Set(RecordedCase.rail.map(\.key)))
    }

    @Test(arguments: RecordedCase.rail)
    func recorded(_ recorded: RecordedCase) throws {
        let item = try #require(Self.computed[recorded.key])
        #expect((item.before * 100).rounded() / 100 == recorded.before)
        #expect((item.after * 100).rounded() / 100 == recorded.after)
        #expect(item.threshold == recorded.threshold)
        #expect(item.after >= item.threshold)
    }
}

struct SpaceRailLegibilityInvariantTests {
    @Test(arguments: Palette.standard.themes)
    func everyRailMarkReachesItsThreshold(_ theme: Theme) {
        for appearance in Appearance.allCases {
            let cases = DesignTokens.standard.railCases(for: theme, in: appearance)
            #expect(cases.map(\.role) == [.railGlyph, .railGlyph, .railMarker, .railDot, .railDot, .railDivider])
            for item in cases {
                #expect(item.placement == .column)
                #expect(item.threshold == (item.role == .railGlyph ? 4.5 : 3), "\(item)")
                #expect(item.after >= item.threshold, "\(item)")
            }
        }
    }

    /// The separator fails as the divider, and in light the raw hues fail as dots (yellow, mint); the kit's colours
    /// do not. In dark every raw hue already reaches 3:1 on the column's fill.
    @Test(arguments: [Appearance.light, .dark])
    func theSystemDefaultsFallShort(_ appearance: Appearance) {
        let cases = DesignTokens.standard.railCases(for: Palette.standard.themes[0], in: appearance)
        #expect(cases.filter { $0.role == .railDivider }.map(\.isFixed) == [true])
        let dots = cases.filter { $0.role == .railDot }
        #expect(dots.map(\.isFixed) == (appearance.isDark ? [false, false] : [true, true]))
    }

    /// A dot in any system hue reaches 3:1 on every surface solved in the column, whatever the column's Theme.
    @Test(arguments: Palette.standard.themes)
    func aDotOfAnyHueReachesThreeToOne(_ theme: Theme) {
        for appearance in Appearance.allCases {
            let roles = ColorRoles(theme: theme, tokens: .standard, appearance: appearance, placement: .column)
            for hue in Hue.allCases {
                let dot = roles.railDotRGBA(hue)
                #expect(dot.alpha == 1)
                #expect(Contrast.worst(opaque: dot, onLuminances: roles.legibility.surfaceLuminances) >= 3, "\(hue) \(appearance)")
            }
        }
    }
}

/// What the rail draws, read back from an offscreen render on the column's fill: the marker under the selected glyph
/// and a yellow dot of a folded Profile reach 3:1 against the fill (less up to 0.05 for 8-bit pixels).
@MainActor
@Suite(.enabled(if: ProcessInfo.processInfo.operatingSystemVersion.majorVersion == 27))
struct SpaceRailRenderTests {
    static let yellow = Theme(id: "yellow-orange", primary: .yellow, secondary: .orange)

    func pixels(_ theme: Theme, _ scheme: ColorScheme) throws -> (width: Int, height: Int, data: [UInt8]) {
        let profiles = [
            RailSample.work(3),
            SpaceRailProfile(id: "y", name: "Yellow", spaces: [SpaceRailSpace(id: "y1", name: "Sun", theme: Self.yellow)]),
        ]
        let view = SpaceRail(profiles: profiles, selection: "w1", commands: [[SpaceRailCommand(id: "new", title: "New")]],
                             selectSpace: { _ in }, selectProfile: { _ in })
            .frame(width: 360)
            .environment(\.surfacePlacement, .column)
            .background { Rectangle().fill(.background.opacity(0.5)) }
            .background { WindowBackground() }
            .theme(theme)
            .environment(\.colorScheme, scheme)
        func render() throws -> (Int, Int, [UInt8]) {
            let renderer = ImageRenderer(content: view)
            renderer.scale = 1
            let image = try #require(renderer.cgImage)
            var data = [UInt8](repeating: 0, count: image.width * image.height * 4)
            data.withUnsafeMutableBytes { buffer in
                let context = CGContext(
                    data: buffer.baseAddress, width: image.width, height: image.height, bitsPerComponent: 8,
                    bytesPerRow: image.width * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
                context?.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
            }
            return (image.width, image.height, data)
        }
        _ = try render()  // The first render in a process differs from the next ones: warm up.
        return try render()
    }

    /// The row is the bottom 36 pt above an 8 pt margin; the first target spans 10…38, its glyph's circle 2…26 from
    /// the row's top, the marker 28…31 under it. Three Spaces (84) and the divider (9) put Yellow's one-dot target at
    /// 103…131, its dot at 113…121.
    @Test(arguments: [Palette.standard.themes[0], Palette.standard.themes[2], Palette.standard.themes[5]], [ColorScheme.light, .dark])
    func theMarkerAndTheDotsReachThreeToOne(_ theme: Theme, _ scheme: ColorScheme) throws {
        let (width, height, data) = try pixels(theme, scheme)
        func color(_ x: Int, _ y: Int) -> RGBA {
            let offset = (y * width + x) * 4
            return RGBA(red: Double(data[offset]) / 255, green: Double(data[offset + 1]) / 255, blue: Double(data[offset + 2]) / 255)
        }
        #expect(width == 360)
        let top = height - 8 - 36
        let fill = color(24, top + 34)
        #expect(Contrast.ratio(color(24, top + 29), fill) >= 2.95, "marker \(theme.id) \(scheme)")
        #expect(Contrast.ratio(color(117, top + 14), color(117, top + 34)) >= 2.95, "dot \(theme.id) \(scheme)")
        #expect(Contrast.ratio(color(98, top + 14), color(98, top + 34)) >= 2.95, "divider \(theme.id) \(scheme)")
    }
}
