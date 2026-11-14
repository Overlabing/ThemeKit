#if os(macOS)
import AppKit
#endif
import ColorCore
import DesignKit
import SwiftUI
import Testing

/// The focus ring shows only when the focus came from the keyboard (0.2.11): a click never draws it, on a row, the Space
/// rail or any view that draws `focusRing(_:in:)`.
@MainActor
struct FocusInputTrackerTests {
    @Test func beforeAnyInputTheRingShows() {
        let tracker = FocusInputTracker()
        #expect(tracker.last == nil)
        #expect(tracker.showsFocusRing)
    }

    @Test func aClickHidesTheRingAndANavigationKeyBringsItBack() {
        let tracker = FocusInputTracker()
        tracker.record(.pointer)
        #expect(!tracker.showsFocusRing)
        tracker.record(.keyboard)
        #expect(tracker.showsFocusRing)
        tracker.record(.pointer)
        #expect(!tracker.showsFocusRing)
    }

    @Test func voiceOverAlwaysShowsTheRing() {
        let tracker = FocusInputTracker()
        tracker.record(.pointer)
        tracker.record(voiceOver: true)
        #expect(tracker.showsFocusRing)
        tracker.record(voiceOver: false)
        #expect(!tracker.showsFocusRing)
    }

    #if os(macOS)
    func key(_ code: UInt16, _ characters: String, _ flags: NSEvent.ModifierFlags = []) -> NSEvent {
        NSEvent.keyEvent(
            with: .keyDown, location: .zero, modifierFlags: flags, timestamp: 0, windowNumber: 0, context: nil,
            characters: characters, charactersIgnoringModifiers: characters, isARepeat: false, keyCode: code)!
    }

    func mouse(_ type: NSEvent.EventType) -> NSEvent {
        NSEvent.mouseEvent(
            with: type, location: .zero, modifierFlags: [], timestamp: 0, windowNumber: 0, context: nil, eventNumber: 0,
            clickCount: 1, pressure: 1)!
    }

    /// Any mouse button down is the pointer; Tab, Shift-Tab and the arrows are the keyboard; a letter, Return and a
    /// Command shortcut move nothing.
    @Test func eventsAreReadAsThePointerOrTheKeyboard() {
        #expect(FocusInputTracker.input(for: mouse(.leftMouseDown)) == .pointer)
        #expect(FocusInputTracker.input(for: mouse(.rightMouseDown)) == .pointer)
        #expect(FocusInputTracker.input(for: mouse(.leftMouseUp)) == nil)
        #expect(FocusInputTracker.input(for: key(48, "\t")) == .keyboard)
        #expect(FocusInputTracker.input(for: key(48, "\t", .shift)) == .keyboard)
        #expect(FocusInputTracker.input(for: key(123, "\u{F702}", .function)) == .keyboard)
        #expect(FocusInputTracker.input(for: key(124, "\u{F703}", .function)) == .keyboard)
        #expect(FocusInputTracker.input(for: key(0, "a")) == nil)
        #expect(FocusInputTracker.input(for: key(36, "\r")) == nil)
        #expect(FocusInputTracker.input(for: key(48, "\t", .command)) == nil)
    }

    @Test func handlingAnEventRecordsIt() {
        let tracker = FocusInputTracker()
        tracker.handle(mouse(.leftMouseDown))
        #expect(tracker.last == .pointer)
        tracker.handle(key(0, "a"))
        #expect(tracker.last == .pointer, "a letter leaves it as it was")
        tracker.handle(key(125, "\u{F701}", .function))
        #expect(tracker.last == .keyboard)
    }
    #endif
}

/// A focused sidebar row read back from an offscreen render: after a click (a pointer selection) it draws no ring,
/// after a navigation key it does. The row asks nothing new of the app: it still passes `isFocused` as it is.
@MainActor
struct FocusRingRenderTests {
    static let theme = Palette.standard.themes[0]

    func row(_ tracker: FocusInputTracker, focused: Bool, _ scheme: ColorScheme) throws -> Raster {
        try raster(
            ListRowBackground(state: RowState(isSelected: true, isFocused: focused))
                .frame(width: 240, height: 36)
                .padding(8)
                .focusInputTracker(tracker)
                .theme(Self.theme)
                .environment(\.colorScheme, scheme))
    }

    @Test(arguments: [ColorScheme.light, .dark])
    func aClickedRowShowsNoRingAndAKeyboardFocusedRowDoes(_ scheme: ColorScheme) throws {
        let clicked = FocusInputTracker()
        clicked.record(.pointer)
        let keyboard = FocusInputTracker()
        keyboard.record(.keyboard)
        let unfocused = try row(FocusInputTracker(), focused: false, scheme)
        #expect(try row(clicked, focused: true, scheme).data == unfocused.data, "a click draws no ring")
        let ringed = try row(keyboard, focused: true, scheme)
        #expect(ringed.data != unfocused.data, "a navigation key draws the ring")
        #expect(ringed.alphaSum > unfocused.alphaSum)
    }
}

/// The caption names the current Space when nothing is hovered or focused from the keyboard, the hovered or focused
/// item while it is, and the current Space again as soon as that ends.
struct SpaceRailCaptionTests {
    let model = SpaceRailModel(profiles: [RailSample.work(3), RailSample.personal], selection: "w2")

    @Test func idleTheCaptionNamesTheCurrentSpace() {
        #expect(model.currentKey == .space("w2"))
        #expect(model.captionKey(hovered: nil, focused: nil) == .space("w2"))
        #expect(model.caption(for: .space("w2")) == SpaceRailCaption(title: "Work 2", shortcut: "⌃2"))
    }

    @Test func aHoverNamesTheHoveredItemThenTheCurrentSpaceAgain() {
        #expect(model.captionKey(hovered: .space("w3"), focused: nil) == .space("w3"))
        #expect(model.captionKey(hovered: .profile("personal"), focused: nil) == .profile("personal"))
        #expect(model.captionKey(hovered: nil, focused: nil) == .space("w2"))
    }

    @Test func aKeyboardFocusNamesTheFocusedItemAndAHoverWins() {
        #expect(model.captionKey(hovered: nil, focused: .space("w1")) == .space("w1"))
        #expect(model.captionKey(hovered: .space("w3"), focused: .space("w1")) == .space("w3"))
        #expect(model.captionKey(hovered: nil, focused: nil) == .space("w2"), "no stale focused name")
    }

    @Test func withNoSelectionTheCaptionIsEmpty() {
        let none = SpaceRailModel(profiles: [RailSample.work(3)], selection: nil)
        #expect(none.currentKey == nil)
        #expect(none.captionKey(hovered: nil, focused: nil) == nil)
    }
}

/// The rail as drawn: the idle caption names the current Space; a rail focused by a click shows neither the ring nor
/// the focused item's name; focused from the keyboard it shows both.
@MainActor
struct SpaceRailFocusRenderTests {
    static let theme = Palette.standard.themes[0]

    func rail(_ state: SpaceRailPreviewState, _ tracker: FocusInputTracker, selection: String = "w1") throws -> Raster {
        try raster(
            SpaceRail(profiles: [RailSample.work(3), RailSample.personal], selection: selection,
                      selectSpace: { _ in }, selectProfile: { _ in })
                .spaceRailPreviewState(state)
                .focusInputTracker(tracker)
                .frame(width: 300)
                .theme(Self.theme)
                .environment(\.colorScheme, .light))
    }

    @Test func aClickedRailShowsNoRingAndTheCurrentSpacesCaption() throws {
        let clicked = FocusInputTracker()
        clicked.record(.pointer)
        let idle = try rail(SpaceRailPreviewState(), clicked)
        #expect(try rail(SpaceRailPreviewState(focused: .space("w2")), clicked).data == idle.data)
        let keyboard = FocusInputTracker()
        keyboard.record(.keyboard)
        #expect(try rail(SpaceRailPreviewState(focused: .space("w2")), keyboard).data != idle.data)
    }

    /// The caption is drawn from the current Space when idle: an idle rail with w2 current differs from one with w1
    /// current above the row (the caption), not only in the row.
    @Test func theIdleCaptionFollowsTheCurrentSpace() throws {
        let tracker = FocusInputTracker()
        let first = try rail(SpaceRailPreviewState(), tracker, selection: "w1")
        let second = try rail(SpaceRailPreviewState(), tracker, selection: "w2")
        let captionRows = 0..<(first.height - 8 - 40)
        func band(_ raster: Raster) -> ArraySlice<UInt8> {
            raster.data[(captionRows.lowerBound * raster.width * 4)..<(captionRows.upperBound * raster.width * 4)]
        }
        #expect(first.height == second.height)
        #expect(band(first) != band(second))
        #expect(band(first).contains { $0 != 0 }, "the idle caption draws")
    }

    @Test func everyItemIsAtLeast28PointsSquare() {
        let tokens = DesignTokens.standard
        let model = SpaceRailModel(profiles: [RailSample.work(3), RailSample.personal], selection: "w1")
        let layout = model.layout(width: 360, hasCommands: true)
        for item in layout.items {
            #expect(model.itemWidth(item, tokens: tokens) >= 28, "\(item.id)")
        }
        #expect(SpaceRailModel.target(tokens) >= 28)
        #expect(tokens.size.railHeight >= SpaceRailModel.target(tokens))
        #expect(tokens.size.railGlyph > tokens.size.glyphCircle, "larger than 0.2.10's 24 pt circle")
    }
}

/// The current Space's circle is its hue solved to 3:1 on every surface of the column, in every standard Theme and the
/// four appearances, with its symbol at 3:1 and its initial at 4.5:1 on it.
struct SpaceRailCurrentLegibilityTests {
    @Test(arguments: Palette.standard.themes)
    @available(*, deprecated, message: "Tests the deprecated column surface, kept until 0.3.")
    func theCurrentCircleReachesThreeToOne(_ theme: Theme) {
        for appearance in Appearance.allCases {
            for placement in SurfacePlacement.allCases {
                let roles = ColorRoles(theme: theme, tokens: .standard, appearance: appearance, placement: placement)
                for hue in Hue.allCases {
                    let fill = roles.railCurrentFillRGBA(hue)
                    #expect(fill.alpha == 1)
                    let ratio = Contrast.worst(opaque: fill, onLuminances: roles.legibility.surfaceLuminances)
                    #expect(ratio >= 3, "\(theme.id) \(appearance) \(placement) \(hue): \(ratio)")
                    #expect(Contrast.ratio(Contrast.ink(on: fill, minimum: 3), fill) >= 3)
                    #expect(Contrast.ratio(Contrast.ink(on: fill, minimum: 4.5), fill) >= 4.5)
                }
            }
        }
    }
}
