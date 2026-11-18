@testable import DesignKit
import Foundation
import SwiftUI
import Testing
#if os(macOS)
import AppKit
#endif

/// 0.2.15's Library: a rail of items on the window's chrome, the item's content beside it with no card, the page's card
/// pushed toward the trailing edge with a strip of it in sight, and the page alive all along.
@MainActor
@Suite struct Library0215Tests {
    enum Item: String, Hashable, Sendable {
        case downloads, routing, extensions, settings
    }

    static let items = [
        LibraryItem(Item.downloads, title: "Downloads", systemImage: "arrow.down.circle"),
        LibraryItem(Item.routing, title: "Link Rules", systemImage: "arrow.triangle.branch"),
        LibraryItem(Item.extensions, title: "Extensions", systemImage: "puzzlepiece"),
        LibraryItem(Item.settings, title: "Settings", systemImage: "gearshape"),
    ]

    @Test func itStartsClosedOnTheFirstItemOrTheOneGiven() {
        #expect(!LibraryModel(items: Self.items).isPresented)
        #expect(LibraryModel(items: Self.items).selection == .downloads)
        #expect(LibraryModel(items: Self.items, selection: .settings).selection == .settings)
        #expect(LibraryModel(items: Array(Self.items.prefix(2)), selection: .settings).selection == .downloads)
    }

    @Test func openingShowsTheAskedItemOrTheLastOne() {
        let model = LibraryModel(items: Self.items)
        model.present(.settings)
        #expect(model.isPresented)
        #expect(model.current.title == "Settings")
        model.dismiss()
        model.present()
        #expect(model.selection == .settings)
    }

    @Test func theSameCommandAgainCloses() {
        let model = LibraryModel(items: Self.items)
        #expect(model.toggle(.settings))
        #expect(model.toggle(.downloads))
        #expect(model.selection == .downloads)
        #expect(!model.toggle(.downloads))
        #expect(model.toggle())
        #expect(!model.toggle())
    }

    @Test func selectingStoresOnlyAChange() {
        let model = LibraryModel(items: Self.items)
        var stored: [Item] = []
        model.onSelect = { stored.append($0) }
        model.select(.downloads)
        model.select(.extensions)
        #expect(model.select(.settings))
        #expect(stored == [.extensions, .settings])
    }

    @Test func arrowKeysStopAtTheEnds() {
        let model = LibraryModel(items: Self.items, selection: .routing)
        #expect(model.selectAdjacent(-1))
        #expect(!model.selectAdjacent(-1))
        #expect(model.selectAdjacent(3))
        #expect(model.selection == .settings)
        #expect(!model.selectAdjacent(1))
    }

    @Test func fewerItemsKeepTheSelectionWhenItIsStillListed() {
        let model = LibraryModel(items: Self.items, selection: .settings)
        model.setItems([Self.items[0], Self.items[3]])
        #expect(model.selection == .settings)
        model.setItems([Self.items[0]])
        #expect(model.selection == .downloads)
        #expect(!model.select(.routing))
    }

    /// The card keeps its size and moves by the Library's width less the sidebar's: 96 pt of it stays in sight.
    @Test func thePushLeavesAStripOfThePageInSight() {
        let push = LibraryPush(windowWidth: 1200, sidebarWidth: 300)
        #expect(DesignTokens.standard.size.libraryPeek == 96)
        #expect(push.libraryWidth == 1104)
        #expect(push.detailOffset(0) == 0)
        #expect(push.detailOffset(1) == 804)
        #expect(push.detailOffset(0.5) == 402)
        #expect(push.libraryOffset(0) == -1104)
        #expect(push.libraryOffset(1) == 0)
        // The card's leading edge, beside the 300 pt sidebar, ends 96 pt from the window's trailing edge.
        #expect(1200 - (300 + push.detailOffset(1)) == 96)
    }

    @Test func theSidebarIsGoneAThirdOfTheWayIn() {
        let push = LibraryPush(windowWidth: 1200, sidebarWidth: 300)
        #expect(push.sidebarOpacity(0) == 1)
        #expect(abs(push.sidebarOpacity(1.0 / 6) - 0.5) < 0.0001)
        #expect(push.sidebarOpacity(1.0 / 3) == 0)
        #expect(push.sidebarOpacity(1) == 0)
        #expect(abs(push.sidebarScale(1) - 0.96) < 0.0001)
        #expect(push.detailOffset(2) == push.detailOffset(1))
    }

    @Test func aNarrowWindowStillShowsTheRail() {
        let push = LibraryPush(windowWidth: 120, sidebarWidth: 300)
        #expect(push.libraryWidth == DesignTokens.standard.size.libraryRail)
        #expect(push.detailOffset(1) == 0)
    }

    #if os(macOS)
    @MainActor
    final class Makes {
        var count = 0
    }

    struct Page: NSViewRepresentable {
        let makes: Makes

        func makeNSView(context: Context) -> NSView {
            makes.count += 1
            return NSView()
        }

        func updateNSView(_ view: NSView, context: Context) {}
    }

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

    @MainActor
    final class Host {
        let window: NSWindow

        init(_ view: some View) {
            window = NSWindow(contentRect: CGRect(x: -20000, y: -20000, width: 1200, height: 700),
                              styleMask: [.titled, .fullSizeContentView], backing: .buffered, defer: false)
            window.isReleasedWhenClosed = false
            window.contentViewController = NSHostingController(rootView: view)
        }

        func settle() async {
            for _ in 0..<8 {
                window.layoutIfNeeded()
                try? await Task.sleep(for: .milliseconds(60))
            }
        }
    }

    @Test func theLayoutKeepsThePageAliveAndShowsTheLibraryOnlyWhileOpen() async {
        let model = LibraryModel(items: Self.items)
        let makes = Makes()
        let shown = Shown()
        let host = Host(LibraryLayout(model, sidebarWidth: 300) {
            Color.clear.modifier(Probe(name: "sidebar", shown: shown))
        } detail: {
            Page(makes: makes)
        } library: {
            HStack(spacing: 0) {
                LibraryRail(model, title: "Library")
                LibraryPane(title: model.current.title) { Color.clear }
            }
            .modifier(Probe(name: "library", shown: shown))
        })
        await host.settle()
        #expect(shown.names == ["sidebar"])
        model.present(.settings)
        await host.settle()
        #expect(shown.names == ["sidebar", "library"])
        model.dismiss()
        await host.settle()
        #expect(shown.names == ["sidebar"])
        #expect(makes.count == 1)
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
