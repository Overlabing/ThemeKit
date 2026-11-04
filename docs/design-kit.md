# Design kit

`DesignKit` is the shared look of the apps that use ThemeKit: a window coloured by its Theme, a list column of rows on
that colour, glass only on controls, calm motion. This page lists its tokens, its views and the rules that come with
them.

## Rules

- **No raw number in a view.** Every spacing, radius, size, opacity and duration is a token. A new value becomes a
  token first (in `DesignTokens` or `MotionRole`), then the view uses it. Exceptions: `0`, line limits, gradient stop
  positions.
- **One set of tokens.** `DesignTokens.standard` is the only preset. It travels in the environment
  (`.designTokens(_:)`, `@Environment(\.designTokens)`); an app that needs a different value adjusts a copy rather
  than defining a second design.
- **Colours come from roles.** Views ask `ColorRoles` (through `WithColorRoles`) for a fill or an ink; they never pick
  a hue and an opacity themselves. Text colours are solved, not the system's secondary label. No text or glyph is
  drawn in the raw hue.
- **Motion comes from roles.** A view asks `MotionRole.x.animation(reduceMotion:)` or `.transition(_:reduceMotion:)`;
  it never writes a duration or a curve. A new motion becomes a role first.
- **Glass on controls only**: pills, banners, floating controls. Never behind a scrolling list.
- **SwiftUI and system components first.** The kit adds a view only where no system one fits; alerts, confirmation
  dialogs, forms and settings stay system views.

## Tokens (`DesignTokens.standard`)

### Spacing (pt)

| Token | Value | Use |
|---|---|---|
| scale `xxs`…`xl` | 2, 4, 8, 12, 16, 24 | the scale |
| `rowGap` | 4 | between the backgrounds of two adjacent rows; they never touch |
| `rowInsetVertical`, `rowInsetHorizontal` | 4, 8 | a row's background around its content |
| `listMargin` | 12 | side margin of a column; rows, pills, banners and the Space rail's glyphs align on it |
| `layerInset` | 4 | a row's background inside a nested panel |
| `layerIndent` | 12 | indent of the second nesting level (none for the first) |
| `sectionHeaderBottom` | 6 | under a section header, before the first row |
| `tileToText`, `compactTileToText` | 10, 8 | tile to text, in a row and in a compact (28 pt tile) row |
| `textLines` | 2 | between text lines, and a row's own vertical padding |
| `glassMerge` | 6 | merge distance of glass shapes in a `GlassEffectContainer` |
| `bannerVertical`, `bannerHorizontal` | 6, 12 | banner insets |
| `canvasInset` | 12 | a content canvas inside its column |
| `columnInset` | 12 | a list column's surface from the window's edges (top, bottom, outer side); equal to `canvasInset`, so column and canvas line up |
| `columnTop` | 24 | the window's top edge to the column's first row: `columnInset`, then `listMargin` inside the surface |
| `pillActionGap` | 8 | between icon buttons, and between groups of buttons |
| `pillFloat` | 12 | a floating pill to the edges of what it floats over |
| `headerTracking` | 0.6 | letter spacing of small uppercase group headers |
| `pillLeading`, `pillTrailing`, `pillVertical`, `pillTileToText` | 5, 14, 5, 8 | a field pill around its 32 pt circle |
| `switcherItemGap`, `switcherPadding` | 2, 4 | the glass switcher (deprecated) |
| `switcherBottom` | 8 | the Space rail's (and the glass switcher's) margin to the column's bottom edge |
| `railMarkerGap` | 2 | the Space rail: a glyph to its marker |
| `railGroupGap` | 4 | the Space rail: either side of the divider |
| `railDotGap` | 4 | the Space rail: between a folded Profile's dots, and before its count |
| `railCaption` | 4 | the Space rail: its caption to its row |
| `railFoldPadding` | 4 | the Space rail: inside a folded Profile's target, either side |
| `badgeHorizontal`, `badgeVertical` | 8, 2 | `badgeFill()`: the capsule round the view |
| `buttonLabelHorizontal` | 8 | a label-only `IconButton` (and a banner's action): label to the edge of its target |
| `segmentGap`, `segmentPadding`, `segmentHorizontal` | 2, 4, 12 | a `SegmentedPill`: between segments, from them to the pill's edge, a title to its segment's edge |
| `segmentContent`, `segmentMarkerGap` | 4, 2 | a segment's symbol to its title; its marker bar to the segment's bottom |
| `bannerLines` | 2 | between a banner's title and message |
| `listCellMargin` | 8 (macOS), 0 (iOS) | what a `List` keeps round a cell's content; `listRowCell` cancels it |
| `statusLineToList` | 10 | status line (or what sits in its place) to the list |
| `focusRingOffset` | 2 | a focus ring outside its shape |
| `selectionMarkerLeading`, `selectionMarkerVertical` | 2, 8 | the selected row's marker: from the leading edge of the row's background, and from its top and bottom |

### Radii (pt, always `.continuous`)

| Token | Value | Use |
|---|---|---|
| `tile`, `compactTile`, `smallTile`, `statusTile` | 8, 7, 6, 5 | tiles of 32, 28, 22, 20 pt |
| `row` | 8 | a row's background |
| `layer` | 12 | a panel holding rows (`row + layerInset`, concentric) |
| `banner` | 12 | a banner |
| `canvas` | 12 | a content canvas |
| `column` | 12 | a list column's surface (`row` + the 4 pt from its edge to a row's background, concentric) |

### Sizes (pt)

| Token | Value | Use |
|---|---|---|
| `minTarget` | 28 (macOS), 44 (iOS) | smallest hit target |
| `tile`, `compactTile`, `smallTile`, `statusTile` | 32, 28, 22, 20 | row tiles |
| `compactRow`, `statusLine` | 40, 38 | a compact row, the status line |
| `dot` | 8 | unread or status dot |
| `stroke`, `hairline`, `focusRing` | 1, 0.5, 2 | lines |
| `selectionMarker` | 3 | width of the selected row's marker bar |
| `floatingPill`, `pillButton`, `pillSymbol`, `pillDivider` | 56, 36, 20, 22 | a floating pill |
| `toolbarButton` | 28 | a toolbar icon button |
| `swatch`, `swatchRing` | 14, 1.5 | a palette swatch |
| `pill` | 42 | a field pill |
| `glyphCircle`, `glyphCircleSmall` | 24, 16 | a Space's glyph circle (the Space rail, `ThemeGlyph`), and `ThemeGlyph`'s small size |
| `segmentedPill`, `segmentMarker` | 36 (macOS), 52 (iOS); 12 | a `SegmentedPill`'s height (`minTarget` plus `2 × segmentPadding`), the marker bar under the selected title |
| `railPanelMaxHeight` | 480 | how tall a Space rail panel grows before it scrolls |
| `switcherItemWidth`, `switcherItemHeight` | 52, 40 | the glass switcher (deprecated) |
| `railHeight` | 36 (macOS), 52 (iOS) | the Space rail's row: `minTarget` plus `Spacing.s` for the marker |
| `railMarker` | 12 | length of the selected Space's marker (thickness `selectionMarker`) |
| `railDivider` | 16 | height of the hairline before the folded Profiles |
| `railCount` | 16 | width kept for a folded Profile's "+n" |
| `railDotsMax` | 4 (a count) | dots a folded Profile shows before its "+n" |
| `columnMin`, `columnIdeal`, `columnMax` | 300, 360, 480 | a list column |
| `disclosureDegrees` | 90 | an open folder's chevron |

### Emphasis (opacity of the Theme's primary hue unless noted)

| Token | Light | Dark | Use |
|---|---|---|---|
| window gradient | 0.38 / 0.16 / 0.05 | 0.42 / 0.18 / 0.06 | top (primary), middle (secondary), bottom (primary) |
| `selectedLight`, `selectedDark` | 0.30 | 0.25 | the selection's floor; raised by the solver until the row differs from the gradient by `selectionVisibility` 1.3:1, capped at `selectionCap` 0.5 |
| `hover` | 0.10 | 0.10 | a hovered row |
| `current` | 0.16 | 0.16 | the current item inside an open group |
| `badgeFill` | 0.14 | 0.14 | a small badge |
| `tileFill` | 0.25 | 0.25 | a tile with no icon (an initial) |
| `glassTint` | 0.35 | 0.35 | the selected glass capsule |
| `layer` | 0.06 | 0.06 | a nested panel, in `.primary` |
| `columnLight`, `columnDark` | 0.5 | 0.5 | a list column's own fill: the plain window background (`.background`, not the hue) over the gradient; 1 under Reduce Transparency |
| `discreet` | 0.5 | 0.5 | a discreet item |
| `lightBackgroundLuminance` | 0.4 | 0.4 | above it, a background counts as light |
| `increasedContrastFactor` | 1.8 | 1.8 | Increase Contrast multiplies the row fills (hover, current, the selection's floor), capped at 1; badge, tile and panel fills and the glass tint stay |
| `contentTop` | 0.1 | 0.1 | where row content starts, as a share of the window height (solver) |
| `switcherTop` | 0.85 | 0.85 | where the switcher's zone starts, as a share of the window height (solver) |
| `textContrast` | 4.5 | 4.5 | the contrast every text reaches |
| `nonTextContrast` | 3 | 3 | the contrast every glyph, focus ring, outline and selection marker reaches |
| `pressed` | 0.6 | 0.6 | a pressed plain control (`PressedOpacityStyle`) |
| `disabled` | 0.4 | 0.4 | a disabled plain control: its label, `IconButton` included |

Every opacity of the Theme's hue above (gradient, hover, current, selection, badge, tile) is drawn times
`ColorRoles.hueScale`: 1, or less where a bright hue would leave a text under 4.5:1 (orange-pink, teal-green and
mint-cyan in dark, most Themes in dark with Increase Contrast; CHANGELOG 0.2.1 lists the values). All of them shrink by
the same share, so their order and the gradient's shape stay.

### Type

Text styles on the system font, never point sizes: rows `.body` (selected semibold), detail lines `.caption`, group
headers `.caption` semibold uppercase, section headers `.subheadline` semibold, counts `.caption`, pill titles `.body`
semibold, initials `.callout` bold, switcher names `.callout` semibold, banners `.callout` (their title and a button's
label `.callout` semibold), segments `.callout` (selected semibold), small glyphs `.caption2` bold.

### Motion (`MotionRole`)

Durations: instant 0.12 s, quick 0.2 s, calm 0.35 s, deliberate 0.5 s, cycle 1.2 s. Curves: `smooth` (spring, bounce 0,
settles at ×1.47), `snappy` (0.15, ×1.40), `spring` (0.1, ×1.34), `easeOut`, `easeInOut` (loops only). No visible bounce.
A settling factor is the time a spring needs to be within 0.1 % of its target, as a multiple of its duration, measured on
`Spring(duration:bounce:)` and rounded up to the hundredth (1.4695, 1.3933, 1.3332).

`role.animation(reduceMotion:)` includes the role's delay; `role.animationWithoutDelay(reduceMotion:)` is the same animation
without it. `spec.settlingSeconds` is the delay plus `spec.settlingSecondsWithoutDelay` (duration × factor); a consumer that
takes them apart (a CSS export) reads `spec.duration`, `spec.delay` and `spec.settlingSecondsWithoutDelay`.

| Role | Duration · curve | Delay / stagger | Reduce Motion |
|---|---|---|---|
| `panelAppear` | calm · spring | | fade |
| `panelContent` | quick · easeOut | delay 0.08 | none |
| `panelDisappear` | calm · easeOut | | fade |
| `rowState` | quick · snappy | | none |
| `rowDeparture` | calm · easeOut | | none |
| `indicatorRotation` | quick · smooth | | none |
| `hoverFill` | instant · easeOut | | none |
| `themeChange` | calm · smooth | | none (also a change of space: there is no separate space role) |
| `profileSwap` | calm · smooth | stagger 0.04 per glyph | fade |
| `pullToOpen` | calm · spring | stagger 0.04 per group | fade |
| `contentReveal` | calm · smooth | | none |
| `scrollFollow` | deliberate · smooth | | none |
| `overlayFade` | instant · easeOut | | none |
| `placeholderFade` | instant · easeOut | delay 0.1 | none |
| `loadingPulse` | cycle · easeInOut | | none |

"Fade" is the shared reduced motion: 0.2 s ease-out, no delay, no movement, no change of size. "None": the change is
immediate.

## Views

| View | What it is |
|---|---|
| `WindowBackground` | `.background`, then the Theme's vertical gradient, behind the whole window |
| `ColumnLayout(side:)` | a list column on its `ColumnSurface` beside a detail in a `ContentCanvas` on the gradient; `.left` (default) or `.right`, mirrored |
| `ColumnSurface(side:)`, `.columnSurface(side:)` | a list column's own surface: inset `columnInset` from the window's edges, rounded `Radius.column`, the plain background at `Emphasis.column` over the gradient, a 1 pt edge in `ColorRoles.columnEdge` (3:1 against the gradient and the fill), content from `columnTop` down, clipped. The views in it solve their colours on its fill (`SurfacePlacement.column`). Kit pieces, never a system sidebar |
| `ContentCanvas` | content inset 12 pt, rounded 12 pt, 1 pt separator line |
| `Tile` | a rounded square: a symbol on a colour (white, or black where white stays under 3:1), a tinted symbol, or an initial on the tile fill; four sizes |
| `ListRow` | tile, title and detail lines, trailing accessory; hover, current, selection fills; the selection's marker bar (outside Increase Contrast); focus ring; `RowPlacement` free or inside a panel |
| `ListRowBackground`, `ListRowContent`, `.listRowCell(state:)` | a `ListRow` as a `List` cell: the background for `listRowBackground`, the content without it, and the modifier that sets both with the cell's insets (see "Rows as List cells") |
| `.tileFill(_:)`, `.badgeFill()` | the kit's tile and badge fills behind a client view, which is set in the tinted ink (4.5:1 on them) |
| `FolderRow` + `LayerPanel` | a folder as a row with a count and a turning chevron; its children on a continuous panel, first level not indented |
| `SectionHeader` | a section title, or a small uppercase group header |
| `ColumnSeparator` | a hairline on the column margin, between groups that have no header |
| `StatusLine` | the one-line state at the top of a column, with its chevron; `fillsWhenOpen` fills it while open; its tile is a `TileContent` or any view |
| `FieldPill` | a glass capsule with a circle in the Theme's colour, a title (or a placeholder in the secondary ink) and an accessory |
| `IconButton`, `IconButtonRow` | symbol buttons, or label-only (`IconButton("Done") {}`), in at least the minimum target, labelled for VoiceOver; dimmed to `Emphasis.disabled` when disabled; the kit's focus ring on keyboard focus |
| `SegmentedPill` | a glass capsule of segments, one selected (fill, semibold, marker bar; an outline under Increase Contrast); targets of at least `minTarget`; disabled and focus states |
| `SpaceRail`, `SpaceRailPanel` | the Space selector at the bottom of a column (see "Space rail" below) |
| `ThemeGlyph` | a themed item's glyph: its flat hue with a white or black symbol or initial; `size: .standard` (24 pt) or `.small` (16 pt) |
| `GlassSwitcher` | **deprecated in 0.2.4, removed in 0.3**: use `SpaceRail`. The glass bar of themed items at the bottom of a column; an item's help is its name and the shortcut the app gives it (`SwitcherItem.shortcut`) |
| `Banner` | a discreet message on glass: a symbol, an optional title, the message, and the client's actions or the kit's (`action:` and `onClose:`) |
| `SkeletonRows` | static placeholder rows while loading, one VoiceOver label |
| `.focusRing(_:in:)` | the system focus colour, opaque and at 3:1 at least on the Theme's surfaces, around a custom control |
| `.surface(_:in:)` | glass or a layer fill, with the accessibility fallbacks below |

## Rows as List cells

A `List` draws a cell's background itself, so a row in a `List` is two views: the cell's content and its background.

```swift
List {
    ForEach(rows) { row in
        ListRowContent(row.title, details: [row.detail], state: state(of: row)) {
            Tile(.initial(row.initial))        // or a client view: Text(row.initial).tileFill()
        } trailing: {
            Text("\(row.unread)").badgeFill()
        }
        .listRowCell(state: state(of: row))   // ListRowBackground, no separator, the cell's insets
    }
}
```

`listRowCell` is `listRowBackground(ListRowBackground(state:placement:))`, `listRowSeparator(.hidden)` and
`listRowInsets` with a negative inset of `Spacing.listCellMargin` each side. A macOS `List` keeps 8 pt round a cell's
content even with zero insets; the negative inset cancels it, so the background (4 pt from the cell's edge), the tile and
the bar sit on the same pixels as in a column of `ListRow`s (a test compares them). Do not put a `ListRow` in a cell: it
draws a background of its own. Increase Contrast reaches the background: a selected or current cell is outlined in
`ColorRoles.outline`, and the bar is not drawn. A `List` hands each cell the system's own Increase Contrast and colour
scheme, so `accessibilityOverrides(increaseContrast:)` is carried to the kit's views by an environment value of the kit's
own as well. A focus ring on a cell is clipped by the cell's bounds.

## Space rail

One quiet row at the bottom of a list column: the active Profile's Spaces as glyphs, the selected one in its Theme's
hue with a marker bar under it; a hairline; each other Profile folded into dots; a trailing `+` for the app's commands.
The app supplies every word and key: names, shortcuts ("⌃1", "⌘1"), command titles. The kit says only "Space",
"Profile" and "Add" (in its string catalog).

```swift
SpaceRail(
    profiles: [SpaceRailProfile],          // in their order; or SpaceRail(spaces:selection:…) with no Profiles
    selection: String?,                    // the selected Space's id; the active Profile is the one holding it
    commands: [[SpaceRailCommand]] = [],   // the + menu's sections ("New Space in Work…", "New Profile…" | "Edit…")
    label: String? = nil,                  // VoiceOver name; default "Spaces and Profiles" / "Spaces"
    selectSpace: (String) -> Void,         // a Space's id, from the row or the panel (maybe another Profile's)
    selectProfile: (String) -> Void,       // a folded Profile's id: land on its last Space
    perform: (String) -> Void = { _ in })  // a command's id

SpaceRailSpace(id:name:glyph:theme:shortcut:)      // glyph: .emoji("🚀"), .symbol("books.vertical"), .initial
SpaceRailProfile(id:name:emoji:spaces:lastSpaceID:shortcut:)
SpaceRailCommand(id:title:systemImage:)
```

`SpaceRailModel` is the rail's logic as a value, testable without a window: `layout(width:hasCommands:)` says which
items show at a width, `action(for:)` what activating one asks for, `caption(for:)` and `accessibilityLabel(for:)` what
the caption and VoiceOver say, `SpaceRailLayout.key(movingFrom:by:)` where an arrow moves the focus.

- **Selected Space**: its hue in a `glyphCircle` circle, the symbol or initial in white or black (`ThemeGlyph`'s rule),
  and a `railMarker` × `selectionMarker` bar in `ColorRoles.selectionMarker` `railMarkerGap` under it, so it is never
  shown by colour alone. Under Increase Contrast the circle is also outlined in `ColorRoles.outline`.
- **Other Spaces of the active Profile**: quiet. The symbol or initial alone in `ColorRoles.secondaryText`; an emoji
  keeps its colours. A hover fill disc on hover.
- **Folded Profiles**, after a `railDivider` hairline in `ColorRoles.railDivider`: one target per Profile, its first
  `railDotsMax` Spaces as `dot` dots in `ColorRoles.railDot(_:)` (each Space's own hue, mixed with ink to 3:1), then
  "+n". A click asks the app to switch Profile; the caption says "🏡 Personal · 3 Spaces · opens Home · ⌃⌥⌘→".
- **Caption**: one line above the row for the hovered or focused item: the name (`switcherLabel`), a detail and the
  shortcut (`count`, secondary ink). Its height is always kept, so nothing moves; a long name truncates at the tail.
- **Overflow**: when the items do not fit (`layout(width:)`: a 28 pt target per Space, the divider, each folded
  Profile, the `+`), the active Profile's last Spaces (never the selected one) give way to a trailing "+n". When not one
  Space fits beside the folded Profiles, those go too. "+n" opens `SpaceRailPanel` in a popover: every Profile under a
  header, every Space as a row with its glyph and shortcut, then the commands. A panel is as tall as its rows up to
  `Size.railPanelMaxHeight` (480), then scrolls (↑ and ↓ scroll the focused row into view); 8 + 8 Spaces scrolls. 8 Spaces and a folded Profile of 3 fit
  the ideal column (360, 301 pt of 340); at `columnMin` (300) the last two Spaces fold into "+2". 8 + 8 fits at 360.
- **No Profiles**: `SpaceRail(spaces:…)`. The row is the Spaces alone: no divider, nothing folded, no panel headers.
- **Keyboard**: the row is one focus stop. ← and → move the focus ring across its items (mirrored right to left),
  Return or Space activates. The `+` and the "+n" open their panel, itself one focus stop: ↑ and ↓ move, Return or Space
  picks, Escape closes. The app keeps its own shortcuts (⌃1…9, say) working from anywhere.
- **VoiceOver**: the row is a named group. A Space reads "Space Research, 2 of 3", plus "selected" on the selected one;
  a folded Profile "Profile Personal, 3 Spaces", hint "opens Home"; the overflow "All Spaces, 2 more"; the `+` "Add".
  Dots, the divider, the marker and the caption are hidden.
- **Motion**: changing Space slides the marker and recolours the glyph (`themeChange`; immediate under Reduce Motion).
  Changing Profile folds the old group's glyphs while the new group's open, one after the other (`profileSwap`, stagger
  0.04; the shared fade under Reduce Motion). The caption fades in (`overlayFade`).
- **Reduce Transparency**: the rail draws no glass; it sits on the column's surface, which turns opaque.
- **Previews and renders**: `.spaceRailPreviewState(SpaceRailPreviewState(hovered:focused:))` forces a hover and a
  focus (`ImageRenderer` has neither); `SpaceRailPanel(model:commands:…)` draws the panel outside its popover.

## Accessibility

- **Reduce Transparency**: every glass surface becomes an opaque `.background` fill with a 1 pt `.separator` line; the
  (deprecated) glass switcher's selected item becomes a solid tinted capsule; a list column's surface becomes the opaque `.background` (its
  edge stays).
- **Column surface**: inside a `ColumnSurface` every text, the selection fill, the marker, the focus ring and the
  tinted text are solved on the column's fill (the plain background over the gradient, or alone under Reduce
  Transparency) instead of the bare gradient (`ColorRoles(placement: .column)`, set by the surface through
  `surfacePlacement`). The hue keeps the frame's `hueScale`, so the gradient under the column and the fills in it are
  drawn alike. The fill differs from the gradient by 1.02 to 1.50:1; its 1 pt edge, the label's ink at 0.50 to 0.58
  alpha, reaches 3:1 against the gradient beside it and against the fill, which is what sets the column apart.
- **Increase Contrast**: the row fills (hover, current, the selection's floor) are multiplied by 1.8 (capped at 1);
  badge, tile and panel fills and the glass tint stay, since raising a fill under a text lowers its contrast. The
  selected and current rows get a 1 pt line in the secondary ink (`ColorRoles.outline`, 3:1 at least), nested panels a
  `.separator` line, glass and canvases a `.secondary` line. Text inks are solved again for the raised fills.
- **Selection marker** (outside Increase Contrast): a selected row carries a 3 pt capsule at the leading edge of its
  background, in `ColorRoles.selectionMarker`: the Theme's primary hue mixed with ink until it reaches 3:1 on every
  surface a row sits on, the selection's fill included. The fill alone differs from the gradient by about 1.3:1, which
  is not enough to find the row (WCAG 1.4.11); the semibold title is not either. Increase Contrast draws the outline
  instead, so the bar is not drawn there.
- **Reduce Motion**: each role becomes the shared fade or nothing (table above); the Space rail's marker jumps, its
  Profile change fades. `accessibilityOverrides(reduceMotion: true)` simulates it in previews and renders and
  `accessibilityOverrides(fullMotion: true)` lifts a Reduce Motion the system has on (Reduce Motion wins if both are set).
- **Accent inks**: `ColorRoles.accentInk(at: index)` is text in the `index`th hue of `DesignTokens.accents` (the twelve system
  hues, wrapping), mixed with ink until it reaches 4.5:1 on every surface text sits on, the column's included; draw a dot or
  tile in `accentHue(at:)`. `accentCases(for:in:placement:)` lists them (280 cases, worst accent counted).
- **Focus and disabled**: `IconButton`, a banner's buttons and `SegmentedPill` draw the kit's focus ring on keyboard focus
  (their own, the system's effect is off) and are dimmed to `Emphasis.disabled` when disabled; `controlFocusPreview()` forces
  the ring for renders.
- **VoiceOver**: rows read their title and details as one element with the button trait, and say "selected"; folders
  say expanded or collapsed; icon buttons read their title; the Space rail is a named group (see above); skeletons read one label;
  decorative tiles, glyphs and lines are hidden.
- **Legibility**: every text reaches 4.5:1 and every glyph, focus ring, selection outline and selection marker 3:1, on every surface,
  for every standard Theme in the four appearances. Secondary and tinted text use the inks `ColorRoles` gets from the
  solver (`Legibility.fit`); a symbol or an initial on a solid colour is white, or black where white falls short; the
  focus ring is the system's focus colour made opaque and mixed toward the ink. `DesignTokens.legibilityCases(for:in:)`
  and `symbolCases(in:)` list each role on each surface with the system default's contrast and the kit's;
  `legibilityCases(for:in:placement: .column)` does the same inside a list column, with the column's edge. CHANGELOG.md
  records the 804 cases of 0.2.1, the 14 selection marker cases added in 0.2.2 (818 on the frame) and the 798 column
  cases of 0.2.3 (1616). `railCases(for:in:)` lists the Space rail's marks on the column's fill (168 in 0.2.4): a quiet
  glyph at 4.5:1 on the fill and its hover disc, the marker, a folded Profile's dots (every system hue, the worst
  counted) and the divider at 3:1; `accentCases` lists the 280 accent text cases of 0.2.4 (2064 cases in all). Glass is measured as anything between the window background (its Reduce Transparency fill) and
  what is under it; the switcher's capsule over the bottom of the column (`switcherTop`).
- **Inactive window**: the kit's inks are explicit and read no window state, so a column keeps its contrast when the
  window resigns key. Draw it with `ColumnSurface` in a plain split item: a system sidebar (`NSSplitViewItem(sidebarWithViewController:)`,
  a source list) dims its own labels in an inactive window.
- **Disabled controls** carry no contrast requirement (WCAG 1.4.3, 1.4.11); the kit draws no disabled text. A disabled
  plain button (`PressedOpacityStyle`, so `IconButton`) draws its label at `Emphasis.disabled` so that it looks disabled.

## Rendering without a window

`ImageRenderer` does not draw Liquid Glass. For previews, snapshots and offscreen renders set
`.environment(\.glassRendering, .material)`: glass surfaces become a system material in the same shapes, with the same
tints and lines. `swift run --package-path Gallery DesignKitGallery <folder>` renders the gallery that way;
`DesignKitGallery audit` prints the legibility cases. A `List`, a scroll view or a popover's content is drawn by a view
hosted in a window that is never shown (`NSHostingView`, `cacheDisplay`), as the gallery's `client` and `rail` commands and
the List tests do: `ImageRenderer` draws neither a `List` nor a scroll view.
