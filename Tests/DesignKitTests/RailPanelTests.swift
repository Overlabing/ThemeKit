#if os(macOS)
import AppKit
import ColorCore
import DesignKit
import SwiftUI
import Testing

/// The panels of the Space rail scroll when they are tall: as tall as their rows up to `Size.railPanelMaxHeight`.
@MainActor
struct RailPanelTests {
    func height(of model: SpaceRailModel, commands: [[SpaceRailCommand]] = [], showsSpaces: Bool = true) -> CGFloat {
        let panel = SpaceRailPanel(
            model: model, commands: commands, showsSpaces: showsSpaces, selectSpace: { _ in }, perform: { _ in })
            .theme(Palette.standard.themes[0])
        let hosting = NSHostingView(rootView: panel)
        return hosting.fittingSize.height
    }

    let commands = [
        [SpaceRailCommand(id: "new", title: "New Space", systemImage: "plus")],
        [SpaceRailCommand(id: "edit", title: "Edit Profile…")],
    ]

    @Test func eightAndEightScrollAtTheMaximumHeight() {
        let model = SpaceRailModel(profiles: [RailSample.work(8), RailSample.eight("hobby")], selection: "w1")
        #expect(height(of: model, commands: commands) == DesignTokens.standard.size.railPanelMaxHeight)
    }

    @Test func aShortPanelIsAsTallAsItsRows() {
        let model = SpaceRailModel(profiles: [RailSample.work(2), RailSample.personal], selection: "w1")
        let short = height(of: model, commands: commands)
        #expect(short < DesignTokens.standard.size.railPanelMaxHeight)
        #expect(short > 150)
        let more = height(of: SpaceRailModel(profiles: [RailSample.work(3), RailSample.personal], selection: "w1"), commands: commands)
        #expect(more > short, "the panel grows with its rows until the maximum")
    }

    /// The `+` panel lists the commands alone, and scrolls past the maximum too.
    @Test func theCommandsPanelScrollsWhenItHasManyCommands() {
        let model = SpaceRailModel(profiles: [RailSample.work(2)], selection: "w1")
        let few = height(of: model, commands: commands, showsSpaces: false)
        #expect(few < 200)
        let many = [(1...30).map { SpaceRailCommand(id: "c\($0)", title: "Command \($0)") }]
        #expect(height(of: model, commands: many, showsSpaces: false) == DesignTokens.standard.size.railPanelMaxHeight)
    }

    @Test func thePanelKeepsItsWidth() {
        let model = SpaceRailModel(profiles: [RailSample.work(8), RailSample.eight("hobby")], selection: "w1")
        let panel = SpaceRailPanel(model: model, commands: commands, selectSpace: { _ in }, perform: { _ in })
        #expect(NSHostingView(rootView: panel).fittingSize.width == DesignTokens.standard.size.columnMin)
    }
}
#endif
