import ColorCore
import ColorUI
import DesignKit
import Foundation
import SwiftUI
import Testing

/// `spaceRailPreviewState` opens a Space's or a Profile's context menu in an offscreen render (issue #51): the client's
/// menu for that item, drawn in place above the rail, hanging above the item and inside the column.
@MainActor
@Suite(.enabled(if: ProcessInfo.processInfo.operatingSystemVersion.majorVersion == 27))
struct RailPreviewContextMenuTests {
    static let margin = Int(DesignTokens.standard.spacing.listMargin)

    /// The rail of `profiles` at the bottom of a `width` × 480 column, with `state`, and with a two-item menu per Space
    /// and per Profile when `menus` is true.
    func render(
        _ state: SpaceRailPreviewState?, profiles: [SpaceRailProfile] = [RailSample.work(3), RailSample.personal],
        width: CGFloat = 360, menus: Bool = true, items: Int = 2, scheme: ColorScheme = .light
    ) throws -> Raster {
        let rail = SpaceRail(profiles: profiles, selection: "w1", selectSpace: { _ in }, selectProfile: { _ in })
        let withMenus = Group {
            if menus {
                rail.spaceRailContextMenu { space in
                    Button("Edit \(space.name)…", systemImage: "pencil") {}
                    if items > 1 { Button("Delete \(space.name)", systemImage: "trash") {} }
                } profile: { profile in
                    Button("Edit \(profile.name)…", systemImage: "pencil") {}
                    if items > 1 { Button("Delete \(profile.name)", systemImage: "trash") {} }
                }
            } else {
                rail
            }
        }
        return try raster(
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                if let state { withMenus.spaceRailPreviewState(state) } else { withMenus }
            }
            .frame(width: width, height: 480)
            .environment(\.glassRendering, .material)
            .theme(RailSample.themes[0])
            .environment(\.colorScheme, scheme))
    }

    /// The first row from the top that draws anything.
    func drawnTop(_ raster: Raster) -> Int {
        (0..<raster.height).first { y in (0..<raster.width).contains { raster.alpha(x: $0, y: y) > 0.05 } } ?? raster.height
    }

    /// Across the menu's middle, the first and the last column that draws anything.
    func drawnSpan(_ raster: Raster, closed: Raster) -> (first: Int, last: Int) {
        let y = (drawnTop(raster) + drawnTop(closed)) / 2
        let drawn = (0..<raster.width).filter { raster.alpha(x: $0, y: y) > 0.05 }
        return (drawn.first ?? -1, drawn.last ?? -1)
    }

    @Test(arguments: [ColorScheme.light, .dark])
    func aSpacesMenuHangsAboveItsItem(_ scheme: ColorScheme) throws {
        let closed = try render(nil, scheme: scheme)
        let first = try render(SpaceRailPreviewState(contextMenu: .space("w1")), scheme: scheme)
        let second = try render(SpaceRailPreviewState(contextMenu: .space("w2")), scheme: scheme)
        let railTop = drawnTop(closed)
        #expect(drawnTop(first) < railTop - 40, "the menu draws above the rail: \(drawnTop(first)) vs \(railTop)")
        // Its leading edge on the item's middle: one item further along for the next Space.
        let model = SpaceRailModel(profiles: [RailSample.work(3), RailSample.personal], selection: "w1")
        let step = Int(model.itemWidth(model.layout(width: 360, hasCommands: false).spaces[0]))
        let a = drawnSpan(first, closed: closed), b = drawnSpan(second, closed: closed)
        #expect(a.first >= Self.margin, "\(a)")
        #expect(abs(b.first - a.first - step) <= 1, "\(a) then \(b), an item of \(step) pt further")
        // The rail's own row draws as before under it.
        for y in (closed.height - 40)..<closed.height {
            for x in stride(from: 0, to: closed.width, by: 4) {
                #expect(abs(closed.alpha(x: x, y: y) - second.alpha(x: x, y: y)) < 0.02)
            }
        }
    }

    /// The folded Profile sits towards the row's trailing end: its menu stays inside the column's margin, moved back
    /// onto it at 300 pt.
    @Test(arguments: [ColorScheme.light, .dark])
    func aProfilesMenuStaysInsideTheColumn(_ scheme: ColorScheme) throws {
        for width in [300, 360] {
            let closed = try render(nil, width: CGFloat(width), scheme: scheme)
            let open = try render(SpaceRailPreviewState(contextMenu: .profile("personal")), width: CGFloat(width), scheme: scheme)
            #expect(drawnTop(open) < drawnTop(closed) - 40)
            let span = drawnSpan(open, closed: closed)
            #expect(span.first >= Self.margin && span.last <= width - Self.margin - 1, "at \(width) pt: \(span)")
            if width == 300 { #expect(span.last == width - Self.margin - 1, "moved back onto the margin: \(span)") }
        }
    }

    /// The menu is the client's: two items draw taller than one.
    @Test func theMenuDrawsTheClientsItems() throws {
        let one = try render(SpaceRailPreviewState(contextMenu: .space("w2")), items: 1)
        let two = try render(SpaceRailPreviewState(contextMenu: .space("w2")), items: 2)
        #expect(drawnTop(one) - drawnTop(two) > 15, "\(drawnTop(one)) vs \(drawnTop(two))")
    }

    /// A Space the row does not show hangs its menu on its folded Profile, or on the "+n" for the active Profile's.
    @Test func aHiddenSpacesMenuHangsOnWhatShowsIt() throws {
        let closed = try render(nil)
        let profile = drawnSpan(try render(SpaceRailPreviewState(contextMenu: .profile("personal")), items: 1), closed: closed)
        let reading = drawnSpan(try render(SpaceRailPreviewState(contextMenu: .space("reading")), items: 1), closed: closed)
        #expect(reading.last == profile.last, "on the folded Profile, kept inside the margin: \(reading) vs \(profile)")

        let many = [RailSample.work(14), RailSample.personal]
        let model = SpaceRailModel(profiles: many, selection: "w1")
        let shown = Set(model.layout(width: 300, hasCommands: false).spaces.map(\.id))
        #expect(!shown.contains(.space("w14")) && !shown.contains(.space("w13")), "the row hides the last Spaces")
        let narrowClosed = try render(nil, profiles: many, width: 300)
        let w13 = try render(SpaceRailPreviewState(contextMenu: .space("w13")), profiles: many, width: 300)
        let w14 = try render(SpaceRailPreviewState(contextMenu: .space("w14")), profiles: many, width: 300)
        let w1 = try render(SpaceRailPreviewState(contextMenu: .space("w1")), profiles: many, width: 300)
        #expect(drawnTop(w14) < drawnTop(narrowClosed) - 40, "a hidden Space's menu draws")
        #expect(drawnSpan(w13, closed: narrowClosed).first == drawnSpan(w14, closed: narrowClosed).first, "both on the +n")
        let hidden = drawnSpan(w14, closed: narrowClosed), first = drawnSpan(w1, closed: narrowClosed)
        #expect(hidden.first > first.first + 50 && hidden.last == 300 - Self.margin - 1, "\(hidden) vs \(first)")
    }

    /// Nothing draws for an item without a menu: no menu given, the "+n", the `+`, an unknown id.
    @Test func nothingDrawsWithoutAMenu() throws {
        let closed = try render(nil, menus: false)
        #expect(try render(SpaceRailPreviewState(contextMenu: .space("w2")), menus: false).matches(closed))
        let closedWithMenus = try render(nil)
        for key in [SpaceRailItem.Key.add, .overflow, .space("nowhere"), .profile("nobody")] {
            #expect(try render(SpaceRailPreviewState(contextMenu: key)).matches(closedWithMenus), "\(key)")
        }
    }

    @Test func thePreviewStateKeepsItsOldInitialisers() {
        let state = SpaceRailPreviewState(hovered: .add, focused: .overflow, panel: .spaces, panelFocus: "w1")
        #expect(state.contextMenu == nil)
        #expect(SpaceRailPreviewState(contextMenu: .profile("p")).contextMenu == .profile("p"))
    }
}
