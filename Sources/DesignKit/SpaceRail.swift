import ColorCore
import ColorUI
import SwiftUI

/// The Space selector at the bottom of a list column: one quiet row. The active Profile's Spaces are glyphs, the
/// selected one in its Theme's colour with a marker bar under it (`ColorRoles.selectionMarker`, 3:1). After a hairline
/// (`ColorRoles.railDivider`), each other Profile is folded into dots in its Spaces' colours (`ColorRoles.railDot`, 3:1),
/// one target that switches to it. A trailing `+` opens the app's commands. When the row does not fit, a trailing "+n"
/// opens a panel naming every Profile and Space (`SpaceRailPanel`). Without Profiles the row is the Spaces alone.
///
/// Hovering or focusing an item shows a caption above the row, its height always kept. The row is one stop in the
/// focus order: ← and → move between its items, Return or Space activates. Changing Space slides the marker
/// (`themeChange`, immediate under Reduce Motion). Changing Profile folds one group while the other opens
/// (`profileSwap`, a fade under Reduce Motion). The rail draws no glass, so Reduce Transparency changes nothing in it.
/// Under Increase Contrast the selected glyph is outlined in `ColorRoles.outline`.
public struct SpaceRail: View {
    @Environment(\.designTokens) private var tokens
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.kitContrast) private var contrast
    @Environment(\.layoutDirection) private var layoutDirection
    @Environment(\.spaceRailPreviewState) private var preview
    @Namespace private var namespace
    @FocusState private var isFocused: Bool
    @State private var hovered: SpaceRailItem.Key?
    @State private var focused: SpaceRailItem.Key?
    @State private var showsPanel = false
    @State private var showsCommands = false
    private let model: SpaceRailModel
    private let commands: [[SpaceRailCommand]]
    private let label: String?
    private let selectSpace: (String) -> Void
    private let selectProfile: (String) -> Void
    private let perform: (String) -> Void

    /// A rail of Profiles. `selection` is the selected Space's id; the active Profile is the one holding it.
    /// `selectSpace` receives a Space's id (from the panel, possibly another Profile's), `selectProfile` a folded
    /// Profile's id (land on its last Space), `perform` a command's id. `commands` are the `+` menu's sections.
    public init(
        profiles: [SpaceRailProfile], selection: String?, commands: [[SpaceRailCommand]] = [], label: String? = nil,
        selectSpace: @escaping (String) -> Void, selectProfile: @escaping (String) -> Void,
        perform: @escaping (String) -> Void = { _ in }
    ) {
        self.model = SpaceRailModel(profiles: profiles, selection: selection)
        self.commands = commands
        self.label = label
        self.selectSpace = selectSpace
        self.selectProfile = selectProfile
        self.perform = perform
    }

    /// A rail of Spaces with no Profiles: no divider, nothing folded.
    public init(
        spaces: [SpaceRailSpace], selection: String?, commands: [[SpaceRailCommand]] = [], label: String? = nil,
        selectSpace: @escaping (String) -> Void, perform: @escaping (String) -> Void = { _ in }
    ) {
        self.model = SpaceRailModel(spaces: spaces, selection: selection)
        self.commands = commands
        self.label = label
        self.selectSpace = selectSpace
        self.selectProfile = { _ in }
        self.perform = perform
    }

    public var body: some View {
        WithColorRoles { roles in
            VStack(alignment: .leading, spacing: tokens.spacing.railCaption) {
                caption(roles)
                GeometryReader { proxy in
                    row(model.layout(width: proxy.size.width, hasCommands: !commands.isEmpty, tokens: tokens), roles)
                }
                .frame(height: tokens.size.railHeight)
            }
            .padding(.bottom, tokens.spacing.switcherBottom)
        }
    }

    // MARK: Caption

    private var captionKey: SpaceRailItem.Key? {
        if let preview { return preview.hovered ?? preview.focused }
        return hovered ?? (isFocused ? focused : nil)
    }

    private func caption(_ roles: ColorRoles) -> some View {
        let caption = captionKey.flatMap(model.caption(for:))
        return HStack(spacing: tokens.spacing.pillTileToText) {
            if let emoji = caption?.emoji { Text(emoji).role(tokens.type.switcherLabel) }
            Text(caption?.title ?? " ").role(tokens.type.switcherLabel).lineLimit(1).truncationMode(.tail)
                .layoutPriority(1)
            if let detail = caption?.detail {
                Text(detail).role(tokens.type.count).foregroundStyle(roles.secondaryText).lineLimit(1)
            }
            Spacer(minLength: 0)
            if let shortcut = caption?.shortcut {
                Text(shortcut).role(tokens.type.count).foregroundStyle(roles.secondaryText).lineLimit(1)
            }
        }
        .opacity(caption == nil ? 0 : 1)
        .animation(MotionRole.overlayFade.animation(reduceMotion: reduceMotion), value: caption)
        .padding(.horizontal, tokens.spacing.listMargin)
        .accessibilityHidden(true)
    }

    // MARK: Row

    private func row(_ layout: SpaceRailLayout, _ roles: ColorRoles) -> some View {
        let showsFocus = preview?.focused != nil || isFocused
        let focusKey = preview?.focused ?? focused
        let profileAnimation = MotionRole.profileSwap.animation(reduceMotion: reduceMotion)
        return HStack(alignment: .top, spacing: 0) {
            ForEach(Array(layout.spaces.enumerated()), id: \.element.id) { index, item in
                itemView(item, roles, isFocused: showsFocus && focusKey == item.id)
                    .transition(MotionRole.profileSwap.transition(
                        AnyTransition.scale(scale: tokens.size.dot / tokens.size.glyphCircle).combined(with: .opacity),
                        reduceMotion: reduceMotion)
                        .animation(profileAnimation?.delay(MotionRole.profileSwap.spec.stagger * Double(index))))
            }
            if layout.showsDivider {
                Rectangle()
                    .fill(roles.railDivider)
                    .frame(width: tokens.size.stroke, height: tokens.size.railDivider)
                    .frame(height: tokens.size.minTarget)
                    .padding(.horizontal, tokens.spacing.railGroupGap)
                    .accessibilityHidden(true)
            }
            ForEach(layout.profiles + (layout.overflow.map { [$0] } ?? [])) { item in
                itemView(item, roles, isFocused: showsFocus && focusKey == item.id)
                    .transition(MotionRole.profileSwap.transition(.opacity, reduceMotion: reduceMotion))
            }
            Spacer(minLength: 0)
            if layout.showsAdd {
                itemView(.add, roles, isFocused: showsFocus && focusKey == .add)
            }
        }
        .animation(MotionRole.themeChange.animation(reduceMotion: reduceMotion), value: model.selection)
        .animation(profileAnimation, value: model.activeProfile?.id)
        .padding(.horizontal, SpaceRailModel.inset(tokens))
        .contentShape(.rect)
        .focusable()
        .focused($isFocused)
        .focusEffectDisabled()
        .onChange(of: isFocused) { _, focusedNow in
            if focusedNow, focused == nil || !layout.items.contains(where: { $0.id == focused }) {
                focused = layout.selectedKey ?? layout.items.first?.id
            }
        }
        .onKeyPress(keys: [.leftArrow, .rightArrow, .return, .space]) { press in
            switch press.key {
            case .leftArrow, .rightArrow:
                let forward = (press.key == .rightArrow) == (layoutDirection == .leftToRight)
                focused = layout.key(movingFrom: focused, by: forward ? 1 : -1)
            default:
                guard let item = layout.items.first(where: { $0.id == focused }) else { return .ignored }
                run(model.action(for: item))
            }
            return .handled
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(label ?? model.accessibilityGroupLabel)
    }

    private func run(_ action: SpaceRailAction) {
        switch action {
        case .selectSpace(let id): selectSpace(id)
        case .selectProfile(let id, _): selectProfile(id)
        case .showPanel: showsPanel = true
        case .showCommands: showsCommands = true
        }
    }

    @ViewBuilder
    private func itemView(_ item: SpaceRailItem, _ roles: ColorRoles, isFocused: Bool) -> some View {
        let isHovered = (preview?.hovered ?? hovered) == item.id
        let isSelected = if case .space(_, _, _, true) = item { true } else { false }
        let target = tokens.size.minTarget
        let glyph = tokens.size.glyphCircle
        let base = itemContent(item, roles, isHovered: isHovered)
            .focusRing(isFocused, in: Capsule(style: .continuous))
            .frame(width: model.itemWidth(item, tokens: tokens), height: target)
            .frame(height: tokens.size.railHeight, alignment: .top)
            .overlay(alignment: .top) {
                if isSelected {
                    Capsule(style: .continuous)
                        .fill(roles.selectionMarker)
                        .frame(width: tokens.size.railMarker, height: tokens.size.selectionMarker)
                        .matchedGeometryEffect(id: "marker", in: namespace)
                        .padding(.top, (target + glyph) / 2 + tokens.spacing.railMarkerGap)
                        .accessibilityHidden(true)
                }
            }
            .contentShape(.rect)
            .onHover { inside in
                if inside { hovered = item.id } else if hovered == item.id { hovered = nil }
            }
            .onTapGesture { run(model.action(for: item)) }
            .help(help(item))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(model.accessibilityLabel(for: item))
            .accessibilityHint(hint(item))
            .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : .isButton)
            .accessibilityAction { run(model.action(for: item)) }
        switch item {
        case .overflow:
            base.popover(isPresented: $showsPanel, arrowEdge: .top) {
                SpaceRailPanel(model: model, commands: commands, selectSpace: { id in
                    showsPanel = false
                    selectSpace(id)
                }, perform: { id in
                    showsPanel = false
                    perform(id)
                })
            }
        case .add:
            base.popover(isPresented: $showsCommands, arrowEdge: .top) {
                SpaceRailPanel(model: model, commands: commands, showsSpaces: false, selectSpace: { _ in }, perform: { id in
                    showsCommands = false
                    perform(id)
                })
            }
        default:
            base
        }
    }

    @ViewBuilder
    private func itemContent(_ item: SpaceRailItem, _ roles: ColorRoles, isHovered: Bool) -> some View {
        let glyph = tokens.size.glyphCircle
        let hover = isHovered ? roles.hoverFill : .clear
        switch item {
        case .space(let space, _, _, let isSelected):
            SpaceRailGlyphView(space: space, isSelected: isSelected)
                .background { Circle().fill(isSelected ? .clear : hover) }
                .frame(width: glyph, height: glyph)
        case .profile(let profile, let dots, let more):
            HStack(spacing: tokens.spacing.railDotGap) {
                if dots.isEmpty {
                    Text(profile.name.first.map { String($0).uppercased() } ?? "")
                        .role(tokens.type.glyphCircle).foregroundStyle(roles.secondaryText)
                }
                ForEach(Array(dots.enumerated()), id: \.offset) { _, theme in
                    Circle().fill(roles.railDot(theme.primary)).frame(width: tokens.size.dot, height: tokens.size.dot)
                }
                if more > 0 {
                    Text(verbatim: "+\(more)").role(tokens.type.count).foregroundStyle(roles.secondaryText)
                        .lineLimit(1).fixedSize().frame(width: tokens.size.railCount)
                }
            }
            .padding(.horizontal, tokens.spacing.railFoldPadding)
            .frame(minWidth: glyph, minHeight: glyph)
            .background { Capsule(style: .continuous).fill(hover) }
        case .overflow(let hidden):
            Text(verbatim: "+\(hidden)").role(tokens.type.glyphCircle).foregroundStyle(roles.secondaryText)
                .lineLimit(1).fixedSize()
                .frame(minWidth: glyph, minHeight: glyph)
                .background { Capsule(style: .continuous).fill(hover) }
        case .add:
            Image(systemName: "plus")
                .font(tokens.type.rowTitle.font)
                .foregroundStyle(roles.secondaryText)
                .frame(width: glyph, height: glyph)
                .background { Circle().fill(hover) }
        }
    }

    private func help(_ item: SpaceRailItem) -> String {
        switch item {
        case .space(let space, _, _, _): space.help
        case .profile(let profile, _, _): profile.shortcut.map { "\(profile.name) (\($0))" } ?? profile.name
        case .overflow, .add: model.accessibilityLabel(for: item)
        }
    }

    private func hint(_ item: SpaceRailItem) -> String {
        guard case .profile(let profile, _, _) = item, let landing = profile.landingSpace else { return "" }
        return String(localized: "opens \(landing.name)", table: "DesignKit", bundle: .module)
    }
}

/// A Space's glyph in the rail. The selected Space is its Theme's hue in a circle (`Size.glyphCircle`), with its symbol
/// or initial in white, or black where white falls short (ThemeGlyph's rule); under Increase Contrast the circle is
/// outlined in `ColorRoles.outline`. Every other Space is quiet: its symbol or initial alone in the secondary ink. An
/// emoji keeps its own colours either way.
struct SpaceRailGlyphView: View {
    @Environment(\.designTokens) private var tokens
    @Environment(\.colorScheme) private var scheme
    @Environment(\.kitContrast) private var contrast
    let space: SpaceRailSpace
    let isSelected: Bool

    var body: some View {
        WithColorRoles { roles in
            let appearance = Appearance(isDark: scheme == .dark, isIncreasedContrast: contrast == .increased)
            let hue = space.theme.primary
            let symbolInk = ColorRoles.ink(on: hue, in: appearance, minimum: tokens.emphasis.nonTextContrast)
            let letterInk = ColorRoles.ink(on: hue, in: appearance, minimum: tokens.emphasis.textContrast)
            Group {
                switch space.glyph {
                case .emoji(let emoji):
                    Text(emoji)
                case .symbol(let name):
                    Image(systemName: name).foregroundStyle(isSelected ? symbolInk : roles.secondaryText)
                case .initial:
                    Text(space.initial).foregroundStyle(isSelected ? letterInk : roles.secondaryText)
                }
            }
            .font(tokens.type.glyphCircle.font)
            .frame(width: tokens.size.glyphCircle, height: tokens.size.glyphCircle)
            .background {
                if isSelected {
                    Circle().fill(hue.color)
                        .overlay {
                            if contrast == .increased {
                                Circle().strokeBorder(roles.outline, lineWidth: tokens.size.stroke)
                            }
                        }
                }
            }
            .accessibilityHidden(true)
        }
    }
}

/// The panel the rail's "+n" opens (B3's): every Profile under a small header, each of its Spaces as a row with its
/// glyph, name and shortcut, the selected one selected; then the app's commands. Without Profiles there are no headers.
/// With `showsSpaces` false it lists the commands alone (the rail's `+`). One focus stop: ↑ and ↓ move between rows
/// (scrolling the focused one into view), Return or Space picks, Escape closes. Taller than `Size.railPanelMaxHeight`
/// it scrolls; shorter it is as tall as its rows. Its colours are solved like the column's, on the plain background.
public struct SpaceRailPanel: View {
    @Environment(\.designTokens) private var tokens
    @Environment(\.dismiss) private var dismiss
    @FocusState private var isFocused: Bool
    @State private var focused: String?
    private let model: SpaceRailModel
    private let commands: [[SpaceRailCommand]]
    private let showsSpaces: Bool
    private let selectSpace: (String) -> Void
    private let perform: (String) -> Void
    private let initialFocus: String?

    /// `focus` (a Space's or a command's id) is for previews and renders; the panel otherwise starts on the selected
    /// Space.
    public init(
        model: SpaceRailModel, commands: [[SpaceRailCommand]], showsSpaces: Bool = true, focus: String? = nil,
        selectSpace: @escaping (String) -> Void, perform: @escaping (String) -> Void
    ) {
        self.model = model
        self.commands = commands
        self.showsSpaces = showsSpaces
        self.selectSpace = selectSpace
        self.perform = perform
        self.initialFocus = focus
    }

    private enum Entry: Hashable {
        case space(String)
        case command(String)

        var id: String {
            switch self {
            case .space(let id), .command(let id): id
            }
        }
    }

    private var entries: [Entry] {
        let spaces = showsSpaces ? model.profiles.flatMap(\.spaces).map { Entry.space($0.id) } : []
        return spaces + commands.flatMap { $0.map { Entry.command($0.id) } }
    }

    public var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                content
            }
            .scrollBounceBehavior(.basedOnSize)
            .frame(maxHeight: tokens.size.railPanelMaxHeight)
            .fixedSize(horizontal: false, vertical: true)
            .frame(width: tokens.size.columnMin)
            .onChange(of: focused) { _, id in
                guard let entry = entries.first(where: { $0.id == id }) else { return }
                proxy.scrollTo(entry, anchor: nil)
            }
        }
        .environment(\.surfacePlacement, .column)
        .focusable()
        .focused($isFocused)
        .focusEffectDisabled()
        .onAppear {
            isFocused = true
            focused = initialFocus ?? (showsSpaces ? model.selection : nil) ?? entries.first?.id
        }
        .onKeyPress(keys: [.upArrow, .downArrow, .return, .space, .escape]) { press in
            let ids = entries.map(\.id)
            switch press.key {
            case .upArrow, .downArrow:
                guard !ids.isEmpty else { return .ignored }
                let index = focused.flatMap { ids.firstIndex(of: $0) } ?? 0
                let step = press.key == .downArrow ? 1 : -1
                focused = ids[min(max(index + step, 0), ids.count - 1)]
            case .escape:
                dismiss()
            default:
                guard let entry = entries.first(where: { $0.id == focused }) else { return .ignored }
                switch entry {
                case .space(let id): selectSpace(id)
                case .command(let id): perform(id)
                }
            }
            return .handled
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(model.accessibilityGroupLabel)
    }

    private var content: some View {
        let current = focused ?? initialFocus
        return VStack(alignment: .leading, spacing: 0) {
            if showsSpaces {
                ForEach(model.profiles) { profile in
                    if model.hasProfiles {
                        SectionHeader(
                            [profile.emoji, profile.name].compactMap { $0 }.joined(separator: " "), isGroupHeader: true)
                            .padding(.top, tokens.spacing.sectionHeaderBottom)
                    }
                    ForEach(Array(profile.spaces.enumerated()), id: \.element.id) { index, space in
                        WithColorRoles { roles in
                            ListRow(
                                space.name,
                                state: RowState(isSelected: space.id == model.selection, isFocused: current == space.id),
                                placement: .free(firstInSection: model.hasProfiles && index == 0)
                            ) {
                                SpaceRailGlyphView(space: space, isSelected: true)
                            } trailing: {
                                if let shortcut = space.shortcut {
                                    Text(shortcut).role(tokens.type.count).foregroundStyle(roles.secondaryText)
                                }
                            }
                        }
                        .id(Entry.space(space.id))
                        .onTapGesture { selectSpace(space.id) }
                        .accessibilityAction { selectSpace(space.id) }
                    }
                }
            }
            ForEach(Array(commands.enumerated()), id: \.offset) { index, section in
                if showsSpaces || index > 0 { ColumnSeparator() }
                ForEach(section) { command in
                    WithColorRoles { roles in
                        ListRow(command.title, state: RowState(isFocused: current == command.id)) {
                            Image(systemName: command.systemImage ?? "circle")
                                .foregroundStyle(roles.secondaryText)
                                .opacity(command.systemImage == nil ? 0 : 1)
                                .frame(width: tokens.size.glyphCircle, height: tokens.size.glyphCircle)
                                .accessibilityHidden(true)
                        }
                    }
                    .id(Entry.command(command.id))
                    .onTapGesture { perform(command.id) }
                    .accessibilityAction { perform(command.id) }
                }
            }
        }
        .padding(.vertical, tokens.spacing.layerInset)
    }
}

/// Hover and keyboard focus forced on the rail's items, for previews and offscreen renders (`ImageRenderer` has no
/// pointer and no focus). Never in shipping UI.
public struct SpaceRailPreviewState: Sendable, Equatable {
    public var hovered: SpaceRailItem.Key?
    public var focused: SpaceRailItem.Key?

    public init(hovered: SpaceRailItem.Key? = nil, focused: SpaceRailItem.Key? = nil) {
        self.hovered = hovered
        self.focused = focused
    }
}

extension EnvironmentValues {
    @Entry public var spaceRailPreviewState: SpaceRailPreviewState? = nil
}

extension View {
    /// Draws the Space rails below with `state` hovered and focused, for previews and renders.
    public func spaceRailPreviewState(_ state: SpaceRailPreviewState) -> some View {
        environment(\.spaceRailPreviewState, state)
    }
}
