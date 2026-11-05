import ColorCore
import ColorUI
import DesignKit
import Foundation
import SwiftUI
import Testing
#if os(macOS)
import AppKit
#endif

/// A context menu per Space and per Profile in the rail (issue #36): the client builds it for the item it was opened on,
/// whichever is current.
@MainActor
@Suite
struct RailContextMenuTests {
    static let model = SpaceRailModel(profiles: [RailSample.work(3), RailSample.personal], selection: "w1")

    static let menus = SpaceRailContextMenus(
        space: { AnyView(Button("Delete \($0.name)") {}) }, profile: { AnyView(Button("Edit \($0.name)") {}) })

    @Test func eachSpaceAndFoldedProfileGetsItsOwnMenu() {
        let layout = Self.model.layout(width: 360, hasCommands: true)
        var spaces: [String] = []
        var profiles: [String] = []
        let recording = SpaceRailContextMenus(
            space: { spaces.append($0.id); return AnyView(EmptyView()) },
            profile: { profiles.append($0.id); return AnyView(EmptyView()) })
        for item in layout.items {
            let menu = recording.menu(for: item)
            switch item {
            case .space, .profile: #expect(menu != nil)
            case .overflow, .add: #expect(menu == nil)
            }
        }
        #expect(spaces == ["w1", "w2", "w3"])
        #expect(profiles == ["personal"])
        #expect(SpaceRailContextMenus().menu(for: layout.items[0]) == nil)
        #expect(SpaceRailContextMenus(space: { _ in AnyView(EmptyView()) }).menu(for: layout.profiles[0]) == nil)
    }

    @Test func theModifierHandsTheMenusToTheRail() throws {
        var seen: SpaceRailContextMenus?
        let probe = Probe { seen = $0 }.spaceRailContextMenu { space in Text(space.name) } profile: { _ in EmptyView() }
        _ = ImageRenderer(content: probe.frame(width: 10, height: 10)).cgImage
        let menus = try #require(seen)
        #expect(menus.space != nil)
        #expect(menus.profile != nil)
        var spacesOnly: SpaceRailContextMenus?
        _ = ImageRenderer(content: Probe { spacesOnly = $0 }.spaceRailContextMenu { _ in EmptyView() }.frame(width: 10, height: 10)).cgImage
        #expect(spacesOnly?.space != nil)
        #expect(spacesOnly?.profile == nil)
    }

    /// The menus draw nothing: the rail looks the same with them, to the render's own noise.
    @Test(arguments: [ColorScheme.light, .dark])
    func theMenusChangeNoPixel(_ scheme: ColorScheme) throws {
        func rail(_ menus: Bool) -> some View {
            SpaceRail(
                profiles: Self.model.profiles, selection: "w1", commands: [[SpaceRailCommand(id: "new", title: "New")]],
                selectSpace: { _ in }, selectProfile: { _ in })
                .environment(\.spaceRailContextMenus, menus ? Self.menus : SpaceRailContextMenus())
                .frame(width: 360)
                .theme(RailSample.themes[0])
                .environment(\.colorScheme, scheme)
        }
        #expect(try raster(rail(true)).matches(raster(rail(false))))
    }

    #if os(macOS)
    /// In a window that is never shown, a secondary click on the second Space and on the folded Profile opens the
    /// client's menu for that item, not for the current Space.
    @Test func aSecondaryClickOpensTheItemsMenu() throws {
        let tokens = DesignTokens.standard
        let rail = SpaceRail(
            profiles: Self.model.profiles, selection: "w1", selectSpace: { _ in }, selectProfile: { _ in })
            .spaceRailContextMenu { space in Button("Delete \(space.name)") {} } profile: { profile in
                Button("Edit \(profile.name)") {}
            }
            .theme(RailSample.themes[0])
        let size = CGSize(width: 360, height: 120)
        let hosting = NSHostingView(rootView: rail.frame(width: size.width, height: size.height, alignment: .bottom))
        hosting.frame = CGRect(origin: .zero, size: size)
        let window = NSWindow(contentRect: hosting.frame, styleMask: [.borderless], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.contentView = hosting
        defer { window.contentView = nil }
        hosting.layoutSubtreeIfNeeded()
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.3))
        // The targets' centres, from the window's bottom edge: the rail's bottom padding, then its row, targets on top.
        let y = tokens.spacing.switcherBottom + tokens.size.railHeight - tokens.size.minTarget / 2
        let inset = SpaceRailModel.inset(tokens)
        func menuTitles(atX x: CGFloat) -> [String] {
            let event = NSEvent.mouseEvent(
                with: .rightMouseDown, location: CGPoint(x: x, y: y), modifierFlags: [], timestamp: 0,
                windowNumber: window.windowNumber, context: nil, eventNumber: 0, clickCount: 1, pressure: 1)
            guard let event, let menu = hosting.menu(for: event) else { return [] }
            return menu.items.map(\.title)
        }
        let second = inset + tokens.size.minTarget * 1.5
        let folded = inset + tokens.size.minTarget * 3 + (2 * tokens.spacing.railGroupGap + tokens.size.stroke) + 10
        #expect(menuTitles(atX: second) == ["Delete Work 2"])
        #expect(menuTitles(atX: folded) == ["Edit Personal"])
    }

    /// In the "+n" panel every Space's row has its Space menu and every Profile's header its Profile menu, the active
    /// Profile's too.
    @Test func thePanelsRowsAndHeadersOpenTheirMenus() throws {
        let panel = SpaceRailPanel(model: Self.model, commands: [], selectSpace: { _ in }, perform: { _ in })
            .spaceRailContextMenu { space in Button("Delete \(space.name)") {} } profile: { profile in
                Button("Edit \(profile.name)") {}
            }
            .theme(RailSample.themes[0])
        let size = CGSize(width: DesignTokens.standard.size.columnMin, height: 400)
        let hosting = NSHostingView(rootView: panel.frame(width: size.width, height: size.height, alignment: .top))
        hosting.frame = CGRect(origin: .zero, size: size)
        let window = NSWindow(contentRect: hosting.frame, styleMask: [.borderless], backing: .buffered, defer: false)
        window.isReleasedWhenClosed = false
        window.contentView = hosting
        defer { window.contentView = nil }
        hosting.layoutSubtreeIfNeeded()
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.3))
        var titles: [String] = []
        for y in stride(from: size.height, through: 0, by: -2) {
            let event = NSEvent.mouseEvent(
                with: .rightMouseDown, location: CGPoint(x: 60, y: y), modifierFlags: [], timestamp: 0,
                windowNumber: window.windowNumber, context: nil, eventNumber: 0, clickCount: 1, pressure: 1)
            for title in (event.flatMap { hosting.menu(for: $0) }?.items.map(\.title) ?? []) where titles.last != title {
                titles.append(title)
            }
        }
        #expect(titles == [
            "Edit Work", "Delete Work 1", "Delete Work 2", "Delete Work 3",
            "Edit Personal", "Delete Home", "Delete Reading", "Delete Family",
        ])
    }
    #endif
}

/// Reads the rail's menus from the environment while it draws.
private struct Probe: View {
    @Environment(\.spaceRailContextMenus) private var menus
    let read: (SpaceRailContextMenus) -> Void

    var body: some View {
        read(menus)
        return Color.clear
    }
}
