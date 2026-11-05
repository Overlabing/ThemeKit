import ColorCore
import ColorUI
import DesignKit
import Foundation
import SwiftUI
import Testing

/// `spaceRailPreviewState` opens the rail's panels in an offscreen render (issue #37): drawn in place above the rail.
@MainActor
@Suite(.enabled(if: ProcessInfo.processInfo.operatingSystemVersion.majorVersion == 27))
struct RailPreviewPanelTests {
    static let commands = [
        [SpaceRailCommand(id: "space", title: "New Space…", systemImage: "plus")],
        [SpaceRailCommand(id: "edit", title: "Edit Spaces…", systemImage: "pencil")],
    ]

    /// The rail at the bottom of a 360 × 640 column, with `state`.
    func render(_ state: SpaceRailPreviewState?, scheme: ColorScheme = .light) throws -> Raster {
        let rail = SpaceRail(
            profiles: [RailSample.work(3), RailSample.personal], selection: "w1", commands: Self.commands,
            selectSpace: { _ in }, selectProfile: { _ in })
        return try raster(
            VStack(spacing: 0) {
                Spacer(minLength: 0)
                if let state { rail.spaceRailPreviewState(state) } else { rail }
            }
            .frame(width: 360, height: 640)
            .environment(\.glassRendering, .material)
            .theme(RailSample.themes[0])
            .environment(\.colorScheme, scheme))
    }

    /// The rows from the top down to the first that draws anything, and the height drawn above the rail's own rows.
    func drawnTop(_ raster: Raster) -> Int {
        (0..<raster.height).first { y in (0..<raster.width).contains { raster.alpha(x: $0, y: y) > 0.05 } } ?? raster.height
    }

    @Test(arguments: [ColorScheme.light, .dark])
    func eachPanelOpensAboveTheRail(_ scheme: ColorScheme) throws {
        let closed = try render(nil, scheme: scheme)
        let commands = try render(SpaceRailPreviewState(panel: .commands), scheme: scheme)
        let spaces = try render(SpaceRailPreviewState(panel: .spaces), scheme: scheme)
        let railTop = drawnTop(closed)
        #expect(railTop > 500, "closed, only the rail draws, at the bottom: \(railTop)")
        #expect(drawnTop(commands) < railTop - 40, "the commands panel draws above it: \(drawnTop(commands))")
        #expect(drawnTop(spaces) < drawnTop(commands), "the spaces panel lists the Spaces too, so it is taller")
        // The rail's own rows draw as before under an open panel.
        let bottom = closed.height - 60
        for y in bottom..<closed.height {
            for x in stride(from: 0, to: closed.width, by: 4) {
                #expect(abs(closed.alpha(x: x, y: y) - commands.alpha(x: x, y: y)) < 0.02)
            }
        }
    }

    @Test func aPanelRowCanShowTheFocusRing() throws {
        let plain = try render(SpaceRailPreviewState(panel: .commands))
        let focused = try render(SpaceRailPreviewState(panel: .commands, panelFocus: "space"))
        #expect(!focused.matches(plain))
    }

    @Test func thePreviewStateKeepsItsOldInitialiser() {
        let state = SpaceRailPreviewState(hovered: .add, focused: .overflow)
        #expect(state.panel == nil && state.panelFocus == nil)
        #expect(state == SpaceRailPreviewState(hovered: .add, focused: .overflow, panel: nil))
    }
}
