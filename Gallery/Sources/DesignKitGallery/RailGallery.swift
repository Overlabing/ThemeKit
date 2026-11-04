import AppKit
import ColorCore
import ColorUI
import DesignKit
import SwiftUI

// The Space rail's gallery: whole windows (two palettes, light and dark, left and right, 3 and 8 Spaces, with and
// without Profiles) and a sheet of its states per palette and appearance. `DesignKitGallery rail <output directory>`.

/// The rail's sample data: Work (💼) and Personal (🏡) Profiles, or the Spaces of an app without Profiles.
struct RailSample {
    var profiles: [SpaceRailProfile]?
    var spaces: [SpaceRailSpace]
    /// The selected Space; nil selects the first Space whose Theme is the window's.
    var selection: String?
    var commands: [[SpaceRailCommand]]

    static let theme = Dictionary(uniqueKeysWithValues: Palette.standard.themes.map { ($0.id, $0) })

    static func work(_ count: Int) -> SpaceRailProfile {
        let all: [(String, String, SpaceRailGlyph, String)] = [
            ("work", "Work", .initial, "indigo-blue"),
            ("research", "Research and long-form reading", .symbol("books.vertical.fill"), "teal-green"),
            ("hiring", "Hiring", .initial, "orange-pink"),
            ("ops", "Ops", .emoji("🚀"), "red-orange"),
            ("design", "Design", .symbol("pencil.and.scribble"), "purple-pink"),
            ("finance", "Finance", .initial, "brown-yellow"),
            ("legal", "Legal", .symbol("building.columns.fill"), "mint-cyan"),
            ("support", "Support", .initial, "indigo-blue"),
        ]
        return SpaceRailProfile(
            id: "work", name: "Work", emoji: "💼",
            spaces: all.prefix(count).enumerated().map { index, item in
                SpaceRailSpace(id: item.0, name: item.1, glyph: item.2, theme: theme[item.3]!, shortcut: "⌃\(index + 1)")
            },
            lastSpaceID: "work", shortcut: "⌃⌥⌘←")
    }

    static let personal = SpaceRailProfile(
        id: "personal", name: "Personal", emoji: "🏡",
        spaces: [
            SpaceRailSpace(id: "home", name: "Home", glyph: .emoji("🏡"), theme: theme["purple-pink"]!, shortcut: "⌃1"),
            SpaceRailSpace(id: "reading", name: "Reading", glyph: .symbol("book.fill"), theme: theme["mint-cyan"]!, shortcut: "⌃2"),
            SpaceRailSpace(id: "family", name: "Family", theme: theme["red-orange"]!, shortcut: "⌃3"),
        ],
        lastSpaceID: "home", shortcut: "⌃⌥⌘→")

    static let personalEight = SpaceRailProfile(
        id: "personal", name: "Personal", emoji: "🏡",
        spaces: personal.spaces + ["Garden", "Music", "Travel", "Cooking", "Sport"].enumerated().map { index, name in
            SpaceRailSpace(id: name.lowercased(), name: name, theme: Palette.standard.themes[index], shortcut: "⌃\(index + 4)")
        },
        lastSpaceID: "home", shortcut: "⌃⌥⌘→")

    static let mail: [SpaceRailSpace] = [
        ("office", "Office", SpaceRailGlyph.symbol("briefcase.fill"), "indigo-blue"),
        ("letters", "Newsletters and long reads", .symbol("newspaper.fill"), "teal-green"),
        ("travel", "Travel", .emoji("✈️"), "orange-pink"),
        ("bills", "Bills", .initial, "brown-yellow"),
        ("club", "Club", .initial, "purple-pink"),
        ("school", "School", .symbol("graduationcap.fill"), "mint-cyan"),
        ("shop", "Shopping", .symbol("bag.fill"), "red-orange"),
        ("family", "Family", .initial, "indigo-blue"),
    ].enumerated().map { index, item in
        SpaceRailSpace(id: item.0, name: item.1, glyph: item.2, theme: theme[item.3]!, shortcut: "⌘\(index + 1)")
    }

    static let profileCommands = [
        [SpaceRailCommand(id: "new-space", title: "New Space in Work…", systemImage: "plus.square.on.square"),
         SpaceRailCommand(id: "new-profile", title: "New Profile…", systemImage: "person.crop.circle.badge.plus")],
        [SpaceRailCommand(id: "edit", title: "Edit Spaces and Profiles…", systemImage: "slider.horizontal.3")],
    ]
    static let spaceCommands = [[SpaceRailCommand(id: "new-space", title: "New Space…", systemImage: "plus.square.on.square")]]

    static func withProfiles(_ count: Int, other: SpaceRailProfile = personal, selection: String? = nil) -> RailSample {
        let work = work(count)
        return RailSample(profiles: [work, other], spaces: work.spaces, selection: selection, commands: profileCommands)
    }

    static func withoutProfiles(_ count: Int, selection: String? = nil) -> RailSample {
        RailSample(profiles: nil, spaces: Array(mail.prefix(count)), selection: selection, commands: spaceCommands)
    }

    static let standard = withProfiles(3)

    var allSpaces: [SpaceRailSpace] { profiles?.flatMap(\.spaces) ?? spaces }

    /// The selected Space for a window of `theme`.
    func selected(in theme: Theme?) -> String? {
        selection ?? spaces.first { $0.theme == theme }?.id ?? spaces.first?.id
    }

    var model: SpaceRailModel {
        profiles.map { SpaceRailModel(profiles: $0, selection: selection) }
            ?? SpaceRailModel(spaces: spaces, selection: selection)
    }

    var rail: some View { RailView(sample: self) }
}

/// The rail of a sample, selecting the Space of the window's Theme unless the sample names one.
struct RailView: View {
    @Environment(\.theme) private var theme
    let sample: RailSample

    var body: some View {
        let selection = sample.selected(in: theme)
        if let profiles = sample.profiles {
            SpaceRail(profiles: profiles, selection: selection, commands: sample.commands,
                      selectSpace: { _ in }, selectProfile: { _ in })
        } else {
            SpaceRail(spaces: sample.spaces, selection: selection, commands: sample.commands, selectSpace: { _ in })
        }
    }
}

/// One state of the rail: the bottom of a list column on its surface, over the window's gradient, with a caption.
struct RailCell<Extra: View>: View {
    @Environment(\.designTokens) private var tokens
    let title: String
    let theme: Theme
    var width: CGFloat = DesignTokens.standard.size.columnIdeal
    let sample: RailSample
    var preview = SpaceRailPreviewState()
    var increaseContrast = false
    var extra: Extra

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.s) {
            Text(title).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.m) {
                extra
                ColumnSurface {
                    VStack(spacing: 0) {
                        Spacer(minLength: 0)
                        sample.rail
                    }
                    .frame(width: width)
                }
                .frame(height: 132, alignment: .bottom)
            }
            .padding(.trailing, tokens.spacing.columnInset)
            .background { WindowBackground() }
            .spaceRailPreviewState(preview)
            .accessibilityOverrides(increaseContrast: increaseContrast, reduceTransparency: increaseContrast)
            .theme(theme)
        }
        .frame(width: DesignTokens.standard.size.columnIdeal + 24, alignment: .leading)
    }
}

extension RailCell where Extra == EmptyView {
    init(_ title: String, theme: Theme, width: CGFloat = DesignTokens.standard.size.columnIdeal, sample: RailSample,
         preview: SpaceRailPreviewState = SpaceRailPreviewState(), increaseContrast: Bool = false) {
        self.init(title: title, theme: theme, width: width, sample: sample, preview: preview,
                  increaseContrast: increaseContrast, extra: EmptyView())
    }
}

/// The panel as the popover shows it, drawn on the popover's material (`ImageRenderer` draws no popover).
struct PanelLookalike: View {
    @Environment(\.designTokens) private var tokens
    let sample: RailSample
    var showsSpaces = true
    var focus: String?

    var body: some View {
        SpaceRailPanel(model: sample.model, commands: sample.commands, showsSpaces: showsSpaces, focus: focus,
                       selectSpace: { _ in }, perform: { _ in })
            .surface(.glass(tint: 0), in: RoundedRectangle(cornerRadius: tokens.radius.layer, style: .continuous))
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.top, tokens.spacing.columnInset)
    }
}

/// Every state, for the palette `theme` (its Space is the selected one) in one appearance.
struct RailStatesSheet: View {
    let theme: Theme
    let isDark: Bool

    var body: some View {
        let selection = RailSample.work(8).spaces.first { $0.theme == theme }?.id ?? "work"
        let other = selection == "work" ? "research" : "work"
        let three = RailSample.withProfiles(3, selection: selection)
        let personal = RailSample.withProfiles(3, selection: "home")
        let mail = RailSample.withoutProfiles(4, selection: selection == "work" ? "office" : "letters")
        let narrow = RailSample.withProfiles(8, selection: selection)
        VStack(alignment: .leading, spacing: DesignTokens.Spacing.xl) {
            Text("Space rail · \(theme.id) · \(isDark ? "dark" : "light")").font(.title3.weight(.semibold))
            HStack(alignment: .top, spacing: DesignTokens.Spacing.xl) {
                RailCell("Closed", theme: theme, sample: three)
                RailCell("Hover a Space: its name and shortcut", theme: theme, sample: three,
                         preview: SpaceRailPreviewState(hovered: .space(other)))
                RailCell("Hover Personal: Spaces, where it lands, shortcut", theme: theme, sample: three,
                         preview: SpaceRailPreviewState(hovered: .profile("personal")))
            }
            HStack(alignment: .top, spacing: DesignTokens.Spacing.xl) {
                RailCell("Click Personal: it opens on Home, Work folds", theme: RailSample.theme["purple-pink"]!,
                         sample: personal)
                RailCell("8 Spaces in Work, hover Ops", theme: theme, sample: RailSample.withProfiles(8, selection: selection),
                         preview: SpaceRailPreviewState(hovered: .space("ops")))
                RailCell("8 + 8: four dots and a count", theme: theme,
                         sample: RailSample.withProfiles(8, other: RailSample.personalEight, selection: selection))
            }
            HStack(alignment: .top, spacing: DesignTokens.Spacing.xl) {
                RailCell("No Profiles: the Spaces alone, ⌘ shortcuts", theme: theme, sample: mail,
                         preview: SpaceRailPreviewState(hovered: .space(mail.selection == "office" ? "letters" : "office")))
                RailCell("Narrowest column (300): the overflow \"+n\"", theme: theme,
                         width: DesignTokens.standard.size.columnMin, sample: narrow,
                         preview: SpaceRailPreviewState(hovered: .overflow))
                RailCell("Increase Contrast, Reduce Transparency, keyboard focus", theme: theme, sample: three,
                         preview: SpaceRailPreviewState(focused: .space(other)), increaseContrast: true)
            }
            HStack(alignment: .top, spacing: DesignTokens.Spacing.xl) {
                RailCell(title: "+: the app's commands (popover)", theme: theme, sample: three,
                         preview: SpaceRailPreviewState(focused: .add), extra: PanelLookalike(sample: three, showsSpaces: false, focus: "new-space"))
                RailCell(title: "\"+n\": every Profile and Space (popover)", theme: theme,
                         width: DesignTokens.standard.size.columnMin, sample: narrow,
                         preview: SpaceRailPreviewState(focused: .overflow), extra: PanelLookalike(sample: narrow))
                RailCell(title: "No Profiles: the panel has no headers", theme: theme, sample: mail,
                         extra: PanelLookalike(sample: RailSample.withoutProfiles(8, selection: mail.selection)))
            }
        }
        .padding(DesignTokens.Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(isDark ? Color(white: 0.11) : Color(white: 0.93))
    }
}

@MainActor
func renderView(_ view: some View, size: CGSize, isDark: Bool, to url: URL) throws {
    let content = view
        .designTokens(.standard)
        .environment(\.glassRendering, .material)
        .environment(\.colorScheme, isDark ? .dark : .light)
        .frame(width: size.width, height: size.height)
    let renderer = ImageRenderer(content: content)
    renderer.scale = 2
    guard let image = renderer.cgImage,
          let data = NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:])
    else { throw CocoaError(.fileWriteUnknown, userInfo: [NSFilePathErrorKey: url.path]) }
    try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    try data.write(to: url)
}

@MainActor
func runRail(output: URL) {
    do {
        var windows: [URL] = []
        var sheets: [URL] = []
        for theme in Sample.themes {
            for isDark in [false, true] {
                let mode = isDark ? "dark" : "light"
                let sheet = output.appending(path: "B1-kit-states-\(theme.id)-\(mode).png")
                try renderView(RailStatesSheet(theme: theme, isDark: isDark).theme(theme),
                               size: CGSize(width: 1260, height: 1640), isDark: isDark, to: sheet)
                sheets.append(sheet)
                print("OK: \(sheet.lastPathComponent)")
                for side in ColumnSide.allCases {
                    for count in [3, 8] {
                        for hasProfiles in [true, false] {
                            let sample = hasProfiles ? RailSample.withProfiles(count) : RailSample.withoutProfiles(count)
                            let name = "B1-kit-window-\(side.rawValue)-\(theme.id)-\(mode)-\(count)-\(hasProfiles ? "profiles" : "spaces").png"
                            let url = output.appending(path: name)
                            try renderView(BrowserSample(side: side, rail: sample).theme(theme),
                                           size: CGSize(width: 1100, height: 700), isDark: isDark, to: url)
                            windows.append(url)
                            print("OK: \(name)")
                        }
                    }
                }
            }
        }
        try overview([Array(sheets.prefix(2)), Array(sheets.suffix(2))], to: output.appending(path: "overview-B1-kit-states.png"))
        print("OK: overview-B1-kit-states.png")
        let rows = stride(from: 0, to: windows.count, by: 4).map { Array(windows[$0..<min($0 + 4, windows.count)]) }
        try overview(rows, to: output.appending(path: "overview-B1-kit-windows.png"))
        print("OK: overview-B1-kit-windows.png")
    } catch {
        print("FAILED: \(error)")
        exit(1)
    }
}
