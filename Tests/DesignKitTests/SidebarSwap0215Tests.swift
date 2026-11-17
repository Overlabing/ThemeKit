@testable import DesignKit
import Foundation
import SwiftUI
import Testing
#if os(macOS)
import AppKit
#endif

/// 0.2.15's sidebar swap: the column gives way to grouped sections with a back arrow, the detail to the chosen
/// section's pane, and the app's content comes back as it was.
@MainActor
@Suite struct SidebarSwap0215Tests {
    enum Pane: String, Hashable, Sendable {
        case engine, spaces, general, shortcuts, debug
    }

    static let groups = [
        SidebarSwapGroup(id: "profile", title: "This Profile", sections: [
            SidebarSwapSection(Pane.engine, title: "Search Engine", systemImage: "magnifyingglass"),
            SidebarSwapSection(Pane.spaces, title: "Spaces", systemImage: "square.stack"),
        ]),
        SidebarSwapGroup(id: "app", title: "App", sections: [
            SidebarSwapSection(Pane.general, title: "General", subtitle: "Updates.", systemImage: "gearshape"),
            SidebarSwapSection(Pane.shortcuts, title: "Shortcuts", systemImage: "keyboard"),
            SidebarSwapSection(Pane.debug, title: "Debug", systemImage: "ladybug"),
        ]),
    ]

    static var appGroupOnly: [SidebarSwapGroup<Pane>] { [groups[1]] }

    @Test func itStartsHiddenOnTheFirstSectionOrTheOneGiven() {
        let first = SidebarSwapModel(groups: Self.groups)
        #expect(!first.isPresented)
        #expect(first.selection == .engine)
        #expect(first.sections.map(\.id) == [.engine, .spaces, .general, .shortcuts, .debug])
        #expect(SidebarSwapModel(groups: Self.groups, selection: .shortcuts).selection == .shortcuts)
        #expect(SidebarSwapModel(groups: Self.appGroupOnly, selection: .spaces).selection == .general)
    }

    @Test func emptyGroupsAreLeftOut() {
        let model = SidebarSwapModel(groups: [SidebarSwapGroup<Pane>(id: "none", title: "None", sections: [])] + Self.appGroupOnly)
        #expect(model.groups.map(\.id) == ["app"])
    }

    @Test func presentShowsTheAskedSectionOrTheLastOne() {
        let model = SidebarSwapModel(groups: Self.groups)
        model.present(.shortcuts)
        #expect(model.isPresented)
        #expect(model.current.title == "Shortcuts")
        model.dismiss()
        #expect(!model.isPresented)
        model.present()
        #expect(model.selection == .shortcuts)
    }

    @Test func theSameCommandAgainReturns() {
        let model = SidebarSwapModel(groups: Self.groups)
        #expect(model.toggle() == true)
        #expect(model.toggle() == false)
        #expect(model.toggle(.debug) == true)
        // Another section's command switches the pane instead of returning.
        #expect(model.toggle(.spaces) == true)
        #expect(model.selection == .spaces)
        #expect(model.toggle(.spaces) == false)
        #expect(model.selection == .spaces)
    }

    @Test func selectingStoresTheSectionOnlyWhenItChanges() {
        let model = SidebarSwapModel(groups: Self.groups)
        var stored: [Pane] = []
        model.onSelect = { stored.append($0) }
        #expect(model.select(.general))
        #expect(model.select(.general))
        #expect(model.select(.debug))
        #expect(stored == [.general, .debug])
    }

    @Test func aSectionTheColumnDoesNotListIsNotSelected() {
        let model = SidebarSwapModel(groups: Self.appGroupOnly)
        #expect(!model.select(.engine))
        model.present(.engine)
        #expect(model.isPresented)
        #expect(model.selection == .general)
    }

    @Test func arrowKeysCrossTheGroupsAndStopAtTheEnds() {
        let model = SidebarSwapModel(groups: Self.groups, selection: .spaces)
        #expect(model.selectAdjacent(1))
        #expect(model.selection == .general)
        #expect(model.group(of: model.selection)?.title == "App")
        #expect(model.selectAdjacent(-2))
        #expect(model.selection == .engine)
        #expect(!model.selectAdjacent(-1))
        model.select(.debug)
        #expect(!model.selectAdjacent(1))
    }

    @Test func fewerGroupsKeepTheSelectionWhenItIsStillListed() {
        let model = SidebarSwapModel(groups: Self.groups, selection: .shortcuts)
        var stored: [Pane] = []
        model.onSelect = { stored.append($0) }
        model.setGroups(Self.appGroupOnly)
        #expect(model.selection == .shortcuts)
        let other = SidebarSwapModel(groups: Self.groups, selection: .spaces)
        other.onSelect = { stored.append($0) }
        other.setGroups(Self.appGroupOnly)
        #expect(other.selection == .general)
        #expect(stored.isEmpty)
    }

    #if os(macOS)
    /// Counts how often SwiftUI makes the app's content: made again, a web view would reload.
    @MainActor
    final class Makes {
        var count = 0
    }

    struct AppContent: NSViewRepresentable {
        let makes: Makes

        func makeNSView(context: Context) -> NSView {
            makes.count += 1
            return NSView()
        }

        func updateNSView(_ view: NSView, context: Context) {}
    }

    @MainActor
    final class Host {
        let window: NSWindow

        init(_ view: some View) {
            window = NSWindow(contentRect: CGRect(x: -20000, y: -20000, width: 900, height: 600),
                              styleMask: [.titled, .fullSizeContentView], backing: .buffered, defer: false)
            window.isReleasedWhenClosed = false
            window.contentViewController = NSHostingController(rootView: view)
        }

        func settle() async {
            for _ in 0..<4 {
                window.layoutIfNeeded()
                try? await Task.sleep(for: .milliseconds(30))
            }
        }

    }

    /// The views on screen, by name: a view's name is in it from its `onAppear` to its `onDisappear`.
    @MainActor
    final class Shown {
        var names: Set<String> = []
    }

    struct Probe: ViewModifier {
        let name: String
        let shown: Shown

        func body(content: Content) -> some View {
            content
                .onAppear { shown.names.insert(name) }
                .onDisappear { shown.names.remove(name) }
        }
    }

    @Test func theDetailKeepsTheAppsContentAliveUnderThePane() async {
        let model = SidebarSwapModel(groups: Self.groups)
        let makes = Makes()
        let shown = Shown()
        let host = Host(SidebarSwapDetail(model) { AppContent(makes: makes) } pane: { section in
            Text(verbatim: section.title).modifier(Probe(name: "pane of \(section.title)", shown: shown))
        })
        await host.settle()
        #expect(makes.count == 1)
        #expect(shown.names.isEmpty)
        model.present(.shortcuts)
        await host.settle()
        #expect(shown.names == ["pane of Shortcuts"])
        model.select(.debug)
        await host.settle()
        #expect(shown.names == ["pane of Debug"])
        model.dismiss()
        await host.settle()
        #expect(makes.count == 1)
        #expect(shown.names.isEmpty)
    }

    @Test func theColumnSwapsToTheSectionsAndBack() async {
        let model = SidebarSwapModel(groups: Self.groups)
        let shown = Shown()
        let host = Host(
            Text(verbatim: "the app's column").modifier(Probe(name: "column", shown: shown))
                .sidebarSwap(model) {
                    SidebarSwapList(model, title: "Settings") { EmptyView() } header: {
                        Text(verbatim: "Work").modifier(Probe(name: "header", shown: shown))
                    }
                })
        await host.settle()
        #expect(shown.names == ["column"])
        model.present()
        await host.settle()
        #expect(shown.names == ["header"])
        model.dismiss()
        await host.settle()
        #expect(shown.names == ["column"])
    }
    #endif

    @Test func theCatalogTranslatesTheBackArrow() throws {
        let url = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appending(path: "Sources/DesignKit/Resources/DesignKit.xcstrings")
        let catalog = try JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any]
        let strings = try #require(catalog?["strings"] as? [String: Any])
        func value(_ key: String, _ language: String) -> String? {
            let entry = strings[key] as? [String: Any]
            let localization = (entry?["localizations"] as? [String: Any])?[language] as? [String: Any]
            return (localization?["stringUnit"] as? [String: Any])?["value"] as? String
        }
        #expect(value("Back", "fr") == "Retour")
        #expect(value("Back (Esc)", "fr") == "Retour (Échap)")
    }
}
