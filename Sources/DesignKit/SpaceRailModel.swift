import ColorCore
import Foundation
import SwiftUI

// The Space rail's data, as the app hands it over, and what the rail makes of it: which items show at a given width,
// what a click or Return does, what the hover caption and VoiceOver say. Pure values, testable without a window.

/// What stands for a Space in the rail.
public enum SpaceRailGlyph: Sendable, Hashable {
    /// The user's emoji. It keeps its own colours.
    case emoji(String)
    /// An SF Symbol.
    case symbol(String)
    /// The first letter of the Space's name.
    case initial
}

/// One Space as the app describes it.
public struct SpaceRailSpace: Identifiable, Sendable, Hashable {
    public let id: String
    public let name: String
    public let glyph: SpaceRailGlyph
    public let theme: Theme
    /// The key that selects the Space, as the app binds it ("⌃1", say). The kit writes no key of its own.
    public let shortcut: String?

    public init(id: String, name: String, glyph: SpaceRailGlyph = .initial, theme: Theme, shortcut: String? = nil) {
        self.id = id
        self.name = name
        self.glyph = glyph
        self.theme = theme
        self.shortcut = shortcut
    }

    /// The first letter of the name, upper case.
    public var initial: String { name.first.map { String($0).uppercased() } ?? "" }

    /// The Space's help: its name, then its shortcut in parentheses when it has one.
    public var help: String { shortcut.map { "\(name) (\($0))" } ?? name }
}

/// One Profile as the app describes it: a named group of Spaces.
public struct SpaceRailProfile: Identifiable, Sendable, Hashable {
    public let id: String
    public let name: String
    public let emoji: String?
    public let spaces: [SpaceRailSpace]
    /// The Space the Profile was last on, where a click on the folded Profile lands.
    public let lastSpaceID: String?
    /// The key that switches to the Profile, as the app binds it.
    public let shortcut: String?

    public init(
        id: String, name: String, emoji: String? = nil, spaces: [SpaceRailSpace], lastSpaceID: String? = nil,
        shortcut: String? = nil
    ) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.spaces = spaces
        self.lastSpaceID = lastSpaceID
        self.shortcut = shortcut
    }

    /// Where switching to the Profile lands: its last Space, or its first when the last is unknown.
    public var landingSpace: SpaceRailSpace? { spaces.first { $0.id == lastSpaceID } ?? spaces.first }
}

/// An entry of the rail's `+` menu (and of the overflow panel's foot), supplied by the app: "New Space in Work…",
/// "New Profile…". The rail hands its `id` back when it is chosen.
public struct SpaceRailCommand: Identifiable, Sendable, Hashable {
    public let id: String
    public let title: String
    public let systemImage: String?

    public init(id: String, title: String, systemImage: String? = nil) {
        self.id = id
        self.title = title
        self.systemImage = systemImage
    }
}

/// One target of the rail, in focus order.
public enum SpaceRailItem: Sendable, Hashable, Identifiable {
    /// A Space of the active Profile, at `position` (from 1) of `count`.
    case space(SpaceRailSpace, position: Int, count: Int, isSelected: Bool)
    /// Another Profile folded into its first dots (one per Space, in that Space's Theme), and how many Spaces are left
    /// over as a "+n" count.
    case profile(SpaceRailProfile, dots: [Theme], more: Int)
    /// The trailing "+n" when the row does not fit: `hidden` items are only in the panel it opens.
    case overflow(hidden: Int)
    /// The `+` that opens the app's commands.
    case add

    public enum Key: Sendable, Hashable {
        case space(String)
        case profile(String)
        case overflow
        case add
    }

    public var id: Key {
        switch self {
        case .space(let space, _, _, _): .space(space.id)
        case .profile(let profile, _, _): .profile(profile.id)
        case .overflow: .overflow
        case .add: .add
        }
    }
}

/// What activating an item asks for.
public enum SpaceRailAction: Sendable, Equatable {
    case selectSpace(String)
    /// Switch to the Profile; the app lands on `landing`, its last Space.
    case selectProfile(String, landing: String?)
    /// Open the panel listing every Profile and Space.
    case showPanel
    /// Open the app's commands.
    case showCommands
}

/// The line above the row while an item is hovered or focused: a name, a detail, the shortcut.
public struct SpaceRailCaption: Sendable, Equatable {
    public var emoji: String?
    public var title: String
    public var detail: String?
    public var shortcut: String?

    public init(emoji: String? = nil, title: String, detail: String? = nil, shortcut: String? = nil) {
        self.emoji = emoji
        self.title = title
        self.detail = detail
        self.shortcut = shortcut
    }
}

/// The items that show at one width, with the width each takes.
public struct SpaceRailLayout: Sendable, Equatable {
    /// The active Profile's Spaces that show (the selected one always does).
    public var spaces: [SpaceRailItem]
    /// The hairline between the active Profile's Spaces and the folded Profiles.
    public var showsDivider: Bool
    public var profiles: [SpaceRailItem]
    public var overflow: SpaceRailItem?
    public var showsAdd: Bool
    /// The width the items take, gaps and divider included.
    public var width: CGFloat

    /// Every target in focus order: the Spaces, the folded Profiles, the overflow, the `+`.
    public var items: [SpaceRailItem] {
        spaces + profiles + (overflow.map { [$0] } ?? []) + (showsAdd ? [.add] : [])
    }

    /// The item `step` places after `key` in focus order (before it for a negative step), stopping at either end. From
    /// no item, the selected Space, or the first item.
    public func key(movingFrom key: SpaceRailItem.Key?, by step: Int) -> SpaceRailItem.Key? {
        let keys = items.map(\.id)
        guard !keys.isEmpty else { return nil }
        guard let key, let index = keys.firstIndex(of: key) else { return selectedKey ?? keys[0] }
        return keys[min(max(index + step, 0), keys.count - 1)]
    }

    /// The selected Space's item, when it shows.
    public var selectedKey: SpaceRailItem.Key? {
        spaces.first { if case .space(_, _, _, true) = $0 { true } else { false } }?.id
    }
}

/// The Space rail's state: the Profiles (or the Spaces alone) and the selected Space. The active Profile is the one
/// holding the selected Space, so the two can never disagree.
public struct SpaceRailModel: Sendable, Equatable {
    public let profiles: [SpaceRailProfile]
    /// False when the app has no Profiles: one group with no name, no divider, nothing folded.
    public let hasProfiles: Bool
    public let selection: String?

    public init(profiles: [SpaceRailProfile], selection: String?) {
        self.profiles = profiles
        self.hasProfiles = true
        self.selection = selection
    }

    public init(spaces: [SpaceRailSpace], selection: String?) {
        self.profiles = [SpaceRailProfile(id: "", name: "", spaces: spaces)]
        self.hasProfiles = false
        self.selection = selection
    }

    /// The Profile holding the selected Space, or the first one.
    public var activeProfile: SpaceRailProfile? {
        profiles.first { $0.spaces.contains { $0.id == selection } } ?? profiles.first
    }

    /// The other Profiles, in their order: they show folded.
    public var otherProfiles: [SpaceRailProfile] {
        guard hasProfiles else { return [] }
        return profiles.filter { $0.id != activeProfile?.id }
    }

    // MARK: Layout

    /// The items that fit in `width`, the rail's whole width (the rail insets its row so that the glyphs line up on
    /// `Spacing.listMargin`). Everything shows when it fits. Otherwise the active Profile's last Spaces (never the
    /// selected one) give way to a trailing "+n" that opens the panel; when even one Space does not fit beside the
    /// folded Profiles, those go into the panel too.
    public func layout(width: CGFloat, hasCommands: Bool, tokens: DesignTokens = .standard) -> SpaceRailLayout {
        let available = width - 2 * Self.inset(tokens)
        let spaces = activeProfile?.spaces ?? []
        let others = otherProfiles
        func make(shown: Int, folded: Bool, overflow: Int) -> SpaceRailLayout {
            let visible = Self.visible(spaces, count: shown, keeping: selection)
            let spaceItems = visible.map { index in
                SpaceRailItem.space(
                    spaces[index], position: index + 1, count: spaces.count, isSelected: spaces[index].id == selection)
            }
            let profileItems = folded ? others.map { fold($0, tokens: tokens) } : []
            var result = SpaceRailLayout(
                spaces: spaceItems, showsDivider: !profileItems.isEmpty, profiles: profileItems,
                overflow: overflow > 0 ? .overflow(hidden: overflow) : nil, showsAdd: hasCommands, width: 0)
            result.width = result.items.reduce(0) { $0 + itemWidth($1, tokens: tokens) }
                + (result.showsDivider ? Self.dividerWidth(tokens) : 0)
            return result
        }
        let full = make(shown: spaces.count, folded: true, overflow: 0)
        if full.width <= available { return full }
        for folded in [true, false] where folded || !others.isEmpty {
            for shown in stride(from: spaces.count, through: 1, by: -1) {
                let hidden = spaces.count - shown + (folded ? 0 : others.count)
                guard hidden > 0 else { continue }
                let candidate = make(shown: shown, folded: folded, overflow: hidden)
                if candidate.width <= available { return candidate }
            }
        }
        let shown = min(1, spaces.count)
        return make(shown: shown, folded: false, overflow: spaces.count - shown + others.count)
    }

    /// The indices of the `count` Spaces that show: the first ones, the last of them giving its place to the selected
    /// Space when that one falls beyond.
    static func visible(_ spaces: [SpaceRailSpace], count: Int, keeping selection: String?) -> [Int] {
        var shown = Array(spaces.indices.prefix(count))
        if let selected = spaces.firstIndex(where: { $0.id == selection }), selected >= count, !shown.isEmpty {
            shown[shown.count - 1] = selected
        }
        return shown
    }

    func fold(_ profile: SpaceRailProfile, tokens: DesignTokens) -> SpaceRailItem {
        let dots = Array(profile.spaces.prefix(tokens.size.railDotsMax)).map(\.theme)
        return .profile(profile, dots: dots, more: profile.spaces.count - dots.count)
    }

    /// The row's inset from each side of the rail: the column's margin, less the room a target leaves around its glyph.
    public static func inset(_ tokens: DesignTokens) -> CGFloat {
        tokens.spacing.listMargin - (tokens.size.minTarget - tokens.size.glyphCircle) / 2
    }

    static func dividerWidth(_ tokens: DesignTokens) -> CGFloat {
        2 * tokens.spacing.railGroupGap + tokens.size.stroke
    }

    /// The width `item` takes in the row: a target, or a folded Profile's dots and count with their padding.
    public func itemWidth(_ item: SpaceRailItem, tokens: DesignTokens = .standard) -> CGFloat {
        let target = tokens.size.minTarget
        guard case .profile(_, let dots, let more) = item, !dots.isEmpty else { return target }
        let gap = tokens.spacing.railDotGap
        let count = CGFloat(dots.count)
        let marks = count * tokens.size.dot + (count - 1) * gap + (more > 0 ? gap + tokens.size.railCount : 0)
        return max(target, marks + 2 * tokens.spacing.railFoldPadding)
    }

    // MARK: Interaction

    /// What activating `item` (a click, Return or Space) asks for.
    public func action(for item: SpaceRailItem) -> SpaceRailAction {
        switch item {
        case .space(let space, _, _, _): .selectSpace(space.id)
        case .profile(let profile, _, _): .selectProfile(profile.id, landing: profile.landingSpace?.id)
        case .overflow: .showPanel
        case .add: .showCommands
        }
    }

    /// The item with `key` among every item the rail can show, at any width.
    public func item(_ key: SpaceRailItem.Key) -> SpaceRailItem? {
        let spaces = activeProfile?.spaces ?? []
        switch key {
        case .space(let id):
            guard let index = spaces.firstIndex(where: { $0.id == id }) else { return nil }
            return .space(spaces[index], position: index + 1, count: spaces.count, isSelected: id == selection)
        case .profile(let id):
            return otherProfiles.first { $0.id == id }.map { fold($0, tokens: .standard) }
        case .overflow:
            return .overflow(hidden: 0)
        case .add:
            return .add
        }
    }

    /// The caption of a hovered or focused item: a Space's name and shortcut; a Profile's emoji, name, how many Spaces
    /// it has and where it lands, and its shortcut. None for the overflow and the `+`, whose help names them.
    public func caption(for key: SpaceRailItem.Key) -> SpaceRailCaption? {
        switch item(key) {
        case .space(let space, _, _, _):
            return SpaceRailCaption(title: space.name, shortcut: space.shortcut)
        case .profile(let profile, _, _):
            var detail = Self.spaceCount(profile.spaces.count)
            if let landing = profile.landingSpace {
                detail += " · " + String(localized: "opens \(landing.name)", table: "DesignKit", bundle: .module)
            }
            return SpaceRailCaption(emoji: profile.emoji, title: profile.name, detail: detail, shortcut: profile.shortcut)
        case .overflow, .add, nil:
            return nil
        }
    }

    /// What VoiceOver reads for `item`; the selected Space also carries the selected trait.
    public func accessibilityLabel(for item: SpaceRailItem) -> String {
        switch item {
        case .space(let space, let position, let count, _):
            String(localized: "Space \(space.name), \(position) of \(count)", table: "DesignKit", bundle: .module)
        case .profile(let profile, _, _):
            String(localized: "Profile \(profile.name), \(profile.spaces.count) Spaces", table: "DesignKit", bundle: .module)
        case .overflow(let hidden):
            String(localized: "All Spaces, \(hidden) more", table: "DesignKit", bundle: .module)
        case .add:
            String(localized: "Add", table: "DesignKit", bundle: .module)
        }
    }

    /// The name VoiceOver gives the whole row.
    public var accessibilityGroupLabel: String {
        hasProfiles
            ? String(localized: "Spaces and Profiles", table: "DesignKit", bundle: .module)
            : String(localized: "Spaces", table: "DesignKit", bundle: .module)
    }

    static func spaceCount(_ count: Int) -> String {
        String(localized: "\(count) Spaces", table: "DesignKit", bundle: .module)
    }
}
