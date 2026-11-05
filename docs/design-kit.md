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
| `columnInset` | 12 | **deprecated in 0.2.6, removed in 0.3**, with `ColumnSurface`: a list column's surface from the window's edges (top, bottom, outer side); equal to `canvasInset`, so column and canvas line up |
| `columnTop` | 24 | **deprecated in 0.2.6, removed in 0.3**, with `ColumnSurface`: the window's top edge to the column's first row: `columnInset`, then `listMargin` inside the surface |
| `pillActionGap` | 8 | between icon buttons, and between groups of buttons |
| `pillFloat` | 12 | a floating pill to the edges of what it floats over |
| `headerTracking` | 0.6 | letter spacing of small uppercase group headers |
| `pillLeading`, `pillTrailing`, `pillVertical`, `pillTileToText` | 5, 14, 5, 8 | a field pill around its 32 pt circle |
| `switcherItemGap`, `switcherPadding` | 2, 4 | the glass switcher (deprecated) |
| `switcherBottom` | 8 | the Space rail's (and the glass switcher's) margin to the column's bottom edge |
| `barFade` | 16 | a sidebar's bottom bar: the list fades out over the bar's first points |
| `sidebarFieldSide`, `sidebarFieldTop`, `sidebarFieldBottom` | 10, 9, 8 | a sidebar's own head field: from the column's sides, above it, under it; where the system's sidebar search field sits |
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
| `column` | 12 | **deprecated in 0.2.6, removed in 0.3**, with `ColumnSurface`: a list column's surface (`row` + the 4 pt from its edge to a row's background, concentric) |

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
| `sidebarField` | 29 | a sidebar's head field: the height of the system's sidebar search field, the least the slot gives it |
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
label `.callout` semibold), segments `.callout` (selected semibold), small glyphs `.caption2` bold. An emoji glyph (a
Space's, in the rail and its panel, and `ThemeGlyph`'s) is its circle's style times `glyphEmojiScale` (1.3: 13 pt on
macOS), at most `DesignTokens.glyphEmojiMaxShare` (0.55) of that circle, so its artwork fills the circle the way an
initial does and its corners stay inside it (`DesignTokens.glyphEmojiSize(textSize:circle:)`: 13 pt in the 24 pt
circle, 8.8 pt in `ThemeGlyph`'s small 16 pt one).

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
| `SidebarSplitView` | a system `NavigationSplitView` on the gradient, with `sidebarWindowChrome()` (see "Sidebar" below) |
| `.sidebarColumn(field:header:bottomBar:)` | the sidebar's `List`: the column widths, a plain list on the gradient, no system selection platter, an optional head field and header, the bottom bar in a `safeAreaBar` with the list faded out under it; `.sidebarColumn()` with no bar |
| `.sidebarColumnWidth()` | the column widths (`columnMin`, `columnIdeal`, `columnMax`) on a `NavigationSplitView` column; it counts only on the column's root |
| `.listSelectionPlatterOff()` | no AppKit selection platter behind a selected `List` row, without the rest of `sidebarColumn`; nothing on iOS |
| `.sidebarRowCell(state:placement:)` | a sidebar `List` cell: `ListRowBackground` behind it, the `List`'s own margin kept round its content |
| `SidebarDetail` | the detail beside a sidebar: a card inset 12 pt, from the window's top edge, with an optional floating bottom bar |
| `.sidebarDetailCard()`, `.sidebarDetailInset()` | `SidebarDetail`'s card alone (no padding, no size) and its inset alone, for a detail of several cards: each card gets `sidebarDetailCard()`, spaced `canvasInset`, with `sidebarDetailInset()` round them |
| `.sidebarWindowChrome()` | the window of a sidebar app: transparent toolbar, no title shown, toolbar on hover in full screen |
| `NSSplitViewItem.sidebar(hosting:)` | AppKit: the system's sidebar split item hosting a `sidebarColumn`, at the column widths; `sidebarToolbarItems` for the window's toolbar |
| `ColumnLayout(side:)` | **deprecated in 0.2.6, removed in 0.3**: use `SidebarSplitView` (see "The column" below). A list column on its `ColumnSurface` beside a detail in a `ContentCanvas` on the gradient; `.left` (default) or `.right`, mirrored |
| `ColumnSurface(side:)`, `.columnSurface(side:)` | **deprecated in 0.2.6, removed in 0.3**: use `SidebarSplitView` (see "The column" below). A list column's own surface: inset `columnInset` from the window's edges, rounded `Radius.column`, the plain background at `Emphasis.column` over the gradient, a 1 pt edge in `ColorRoles.columnEdge` (3:1 against the gradient and the fill), content from `columnTop` down, clipped. The views in it solve their colours on its fill (`SurfacePlacement.column`, deprecated with it) |
| `ContentCanvas` | content inset 12 pt, rounded 12 pt, 1 pt separator line |
| `Tile` | a rounded square: a symbol on a colour (white, or black where white stays under 3:1), a tinted symbol, or an initial on the tile fill; four sizes |
| `ListRow` | tile, title and detail lines, trailing accessory; hover, current, selection fills; the selection's marker bar (outside Increase Contrast); focus ring; `RowPlacement` free, inside a panel, or `.stacked` (compact rows with no gap between them) |
| `ListRowBackground`, `ListRowContent`, `.listRowCell(state:)` | a `ListRow` as a `List` cell: the background for `listRowBackground`, the content without it, and the modifier that sets both with the cell's insets (see "Rows as List cells") |
| `ListHover`, `.listHover(_:)`, `.listHoverTracking(id:)` | the hovered row, observed row by row: a cell given its `hoverID` (`listRowCell`, `sidebarRowCell`, `ListRowBackground`) tracks and draws its own hover, and a hover step re-evaluates only the two rows it touches; `sidebarColumn` sets one |
| `.tileFill(_:shape:)`, `.badgeFill()` | the kit's tile and badge fills behind a client view, which is set in the tinted ink (4.5:1 on them); a tile is a rounded square or a `.circle`, at a kit `TileSize`, a `.side(_:)` of the client's, or `.fitting(minimum:)` its content (it grows with the text) |
| `FolderRow` + `LayerPanel` | a folder as a row with a count and a turning chevron; its children on a continuous panel, first level not indented |
| `SectionHeader` | a section title, or a small uppercase group header |
| `ColumnSeparator` | a hairline on the column margin, between groups that have no header |
| `StatusLine` | the one-line state at the top of a column, with its chevron; `fillsWhenOpen` fills it while open (`hoverOverOpenFill` shows the hover fill over it); `chevron:` turns the chevron apart from `isOpen`, `chevronTransition:` sets how it changes, `countPlacement: .trailing` puts the count at the end, `truncationMode:` cuts a long title (`.middle`); at least 38 pt tall, taller with larger text; its tile is a `TileContent` or any view |
| `FieldPill` | a glass capsule with a circle in the Theme's colour, a title (or a placeholder in the secondary ink) and an accessory |
| `IconButton`, `IconButtonRow` | symbol buttons, or label-only (`IconButton("Done") {}`), in at least the minimum target, labelled for VoiceOver; dimmed to `Emphasis.disabled` when disabled; the kit's focus ring on keyboard focus |
| `SegmentedPill` | a glass capsule of segments, one selected (fill, semibold, marker bar; an outline under Increase Contrast); targets of at least `minTarget`; disabled and focus states |
| `SpaceRail`, `SpaceRailPanel` | the Space selector at the bottom of a column (see "Space rail" below) |
| `ThemeGlyph` | a themed item's glyph: its flat hue with an emoji (`emoji:`, in its own colours, at the rail's emoji size for the circle), or a white or black symbol or initial; `size: .standard` (24 pt) or `.small` (16 pt). Hidden from VoiceOver: the item carries the name, never the emoji's description |
| `GlassSwitcher` | **deprecated in 0.2.4, removed in 0.3**: use `SpaceRail`. The glass bar of themed items at the bottom of a column; an item's help is its name and the shortcut the app gives it (`SwitcherItem.shortcut`) |
| `Banner` | a discreet message on glass: a symbol, an optional title, the message, and the client's actions or the kit's (`action:` and `onClose:`). The message shows in full and the banner grows with it; `messageLineLimit:` caps it. Narrower than its actions plus `bannerMessageMin` (160 pt) of text, the actions go under the message; a host breaks at its dots |
| `SkeletonRows` | static placeholder rows while loading, one VoiceOver label; 1 to 3 `lines`, a `placement`, and `style` `.stack`, `.listCells` or `.sidebarCells` (one real `List` cell per row) |
| `.focusRing(_:in:)` | the system focus colour, opaque and at 3:1 at least on the Theme's surfaces, around a custom control |
| `.surface(_:in:)` | glass or a layer fill, with the accessibility fallbacks below |

## The column

The list column is the system's sidebar, flush with the window's edge, as both clients draw it: `SidebarSplitView`
and `.sidebarColumn` (see "Sidebar" below), a `NavigationSplitView` whose `List` is plain with
`.scrollContentBackground(.hidden)`, the Space rail at its bottom. The kit's views in it stay in `.frame`, the default
`surfacePlacement`, so their inks are the frame's; so do the Space rail's popovers, which inherit it. `ColumnSurface`
and `ColumnLayout`, the kit's own inset column surface with its fill and edge, have no client: they, `SurfacePlacement.column`,
`ColorRoles(…placement: .column)`, `columnEdge*`, `columnFillOpacity`, `Spacing.columnInset` and `columnTop`,
`Radius.column` and `DesignTokens.columnSurfaces(in:)` are deprecated in 0.2.6 and removed in 0.3. The legibility audit
keeps its column cases until then.

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

## Sidebar

A sidebar app's window is the system's own: a `NavigationSplitView` flush with the window's edges, the system's sidebar
material over the Theme's gradient, the sidebar button at the column's top trailing corner, and the system's dimming
of an inactive window. The kit adds the gradient, the column's list style, its row geometry, two slots and the detail's
card. It draws no column surface of its own.

```swift
SidebarSplitView {
    List(selection: $selection) {
        ForEach(rows) { row in
            RowContent(row)                                    // a tile, the text, a trailing accessory; no padding
                .tag(row.id)
                .sidebarRowCell(state: RowState(isSelected: selection == row.id))
        }
    }
    .sidebarColumn {
        StatusLine(tile: .tintedSymbol("tray.full"), title: "Work · All", count: 4, isOpen: false)  // optional header
    } bottomBar: {
        SpaceRail(spaces: spaces, selection: current) { current = $0 }
    }
} detail: {
    SidebarDetail {
        Page()
    } bottomBar: {
        Actions()                                              // optional, floats over the card's bottom
    }
}
.searchable(text: $query, placement: .sidebar, prompt: "Search")  // the head field: the system's search
.theme(theme)
```

- **Head field.** The system's sidebar search (`.searchable(text:placement: .sidebar,…)` on the split view) sits under
  the window's controls, full width less 10 pt each side. An app with a field of its own (an address field) passes it
  to `sidebarColumn(field:header:bottomBar:)`. The kit puts it in the same place: `sidebarFieldSide` from the column's
  sides, `sidebarFieldTop` under the window's controls, at least `Size.sidebarField` (29 pt) tall, the header
  `sidebarFieldBottom` under it. The field's look is the app's.
- **Header.** Optional. It sits under the head field, `statusLineToList` above the list.
- **Rows.** `sidebarRowCell` draws the cell's background like `listRowCell` does: 4 pt from the column's edges, the
  selection's marker 2 pt inside it. It keeps the `List`'s own 8 pt margin (`listCellMargin`) round the content, so the
  content starts 20 pt from the column's edge and ends 21 pt from it: 16 pt inside the background, where `listRowCell`
  leaves 8. The cell's insets carry the row's vertical padding, so the content has none of its own.
- **Selection.** `sidebarColumn` turns off the platter AppKit draws behind a selected row. The cell's background is the
  only selection. A `List` outside a sidebar column turns it off alone with `listSelectionPlatterOff()`.
- **Widths.** A `NavigationSplitView` reads a column's widths only from the column's root. `SidebarSplitView` sets the
  kit's there, so `sidebarColumn` can sit anywhere in its sidebar, in a view or a container of the app's. In a
  `NavigationSplitView` of the app's, put `sidebarColumn` on the column's root, or `sidebarColumnWidth()` there when the
  list sits deeper: under a container the split ignores them and opens the column at 144 pt.
- **Bottom bar.** Pinned to the column's bottom edge in a `safeAreaBar` (no spacing): the `SpaceRail`. The list scrolls
  under the bar and fades out over the bar's first `barFade` points, so no row shows between the bar's controls and the
  window's edge. The rail draws no glass, so a row under it would otherwise stay readable under its glyphs. A bar that
  draws nothing (`EmptyView()`, the rail with one Space) takes no height and hides no row; `sidebarColumn()` has none.
- **Detail.** `SidebarDetail` sets its content on the plain background in a card inset `canvasInset` from the detail's
  edges and from the window's top edge (under the transparent toolbar), rounded `Radius.canvas`, with a 1 pt
  `.separator` line centred on its edge. Its optional bottom bar floats `pillFloat` from the card's edges.
- **Inactive window.** The sidebar is the system's, so its labels dim when the window resigns key, as the system's
  sidebars do. The kit keeps that on purpose.

### In an AppKit window

The native way to host the sidebar in an AppKit window is the system's sidebar split item. `NSSplitViewItem.sidebar(hosting:)`
returns `NSSplitViewItem(sidebarWithViewController:)` hosting the column, between `columnMin` and `columnMax` and
`columnIdeal` wide at first. The rest of the window matches what `SidebarSplitView` sets in SwiftUI:

```swift
let split = NSSplitViewController()
split.addSplitViewItem(.sidebar(hosting: list.sidebarColumn(field: { AddressField() }, header: { EmptyView() }, bottomBar: { rail })))
split.addSplitViewItem(NSSplitViewItem(viewController: NSHostingController(rootView: SidebarDetail { page })))
// The window's content: a WindowBackground under split.view, both pinned to the window's edges.
window.styleMask.insert(.fullSizeContentView)
window.titlebarAppearsTransparent = true
window.titleVisibility = .hidden
toolbar.displayMode = .iconOnly                                // its delegate returns NSSplitViewItem.sidebarToolbarItems
window.toolbar = toolbar
```

`.searchable(placement: .sidebar)` needs a `NavigationSplitView`, so an AppKit window passes its own field. Hosting the
whole `SidebarSplitView` in an `NSHostingController` is not the way: the window's toolbar then keeps its background
and has no sidebar button.

## Space rail

One quiet row at the bottom of a list column: the active Profile's Spaces as glyphs, the selected one in its Theme's
hue with a marker bar under it; a hairline; each other Profile folded into dots; a trailing `+` for the app's commands.
The app supplies every word and key: names, shortcuts ("⌃1", "⌘1"), command titles. The kit says only "Space",
"Profile", the `+`'s "Add or Edit a Space or Profile" and a folded Profile's "Opens Home." (in its string catalog,
English and French).

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
  keeps its colours. A hover fill disc on hover. An emoji, quiet or selected, is drawn at its own size (`Type` above):
  about 15 pt of artwork in the 24 pt circle, where the initial's capital is 7 pt.
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
- **Context menus**: `.spaceRailContextMenu(space:profile:)` (or `space:` alone) on the rail or above it gives each
  Space and each Profile a menu the app builds for it: a secondary click on a Space, in the row or in the "+n" panel,
  opens `space(thatSpace)`; on a folded Profile, or on a Profile's header in the panel (the active Profile's too),
  `profile(thatProfile)`. So Edit and Delete reach any Space and Profile, not only the current ones. The "+n" and the
  `+` have none.
  ```swift
  SpaceRail(profiles: profiles, selection: current, …)
      .spaceRailContextMenu { space in
          Button("Edit Space…") { edit(space.id) }
          Button("Delete Space…") { delete(space.id) }
      } profile: { profile in
          Button("Edit Profile…") { editProfile(profile.id) }
      }
  ```
- **No Profiles**: `SpaceRail(spaces:…)`. The row is the Spaces alone: no divider, nothing folded, no panel headers.
- **Keyboard**: the row is one focus stop. ← and → move the focus ring across its items (mirrored right to left),
  Return or Space activates. The `+` and the "+n" open their panel, itself one focus stop: ↑ and ↓ move, Return or Space
  picks, Escape closes. Opened from the keyboard (or by an assistive technology) the panel's focus ring starts on its
  first row (the selected Space in "+n"); opened with a click it shows none until the first arrow or Tab key, which
  shows it there without moving it, as macOS draws a focus ring for keyboard navigation only. Until then Return picks
  nothing (`SpaceRailPanelFocus`; `SpaceRailPanel(showsFocusRing:)`). The app keeps its own shortcuts (⌃1…9, say) working from anywhere.
- **VoiceOver**: the row is a named group. A Space reads "Space Research, 2 of 3", plus "selected" on the selected one;
  a folded Profile "Profile Personal, 3 Spaces", hint "Opens Home."; the overflow "All Spaces, 2 more"; the `+` "Add or
  Edit a Space or Profile" (it opens the app's commands).
  Dots, the divider, the marker and the caption are hidden.
- **Motion**: changing Space slides the marker and recolours the glyph (`themeChange`; immediate under Reduce Motion).
  Changing Profile folds the old group's glyphs while the new group's open, one after the other (`profileSwap`, stagger
  0.04; the shared fade under Reduce Motion). The caption fades in (`overlayFade`).
- **Reduce Transparency**: the rail draws no glass; it sits on what is behind it, the sidebar.
- **Placement**: the rail and its panels take the `surfacePlacement` around them, `.frame` by default. Before 0.2.6 the
  panels forced `.column`, so their inks were solved for a column fill they are not on. On the popover (bounded by the
  plain background and that background at half opacity over the gradient) their text reaches 4.70:1 at worst, their
  focus ring and marker 3.36:1.
- **Previews and renders**: `.spaceRailPreviewState(SpaceRailPreviewState(hovered:focused:panel:panelFocus:))` forces a
  hover and a focus (`ImageRenderer` has neither) and opens a panel (`.spaces` for "+n", `.commands` for `+`), drawn in
  place above the rail rather than in a popover, so that a render or a capture of the window shows it;
  `SpaceRailPanel(model:commands:…)` draws the panel on its own.

## Accessibility

- **Reduce Transparency**: every glass surface becomes an opaque `.background` fill with a 1 pt `.separator` line; the
  (deprecated) glass switcher's selected item becomes a solid tinted capsule; a list column's surface becomes the opaque `.background` (its
  edge stays).
- **Column surface** (deprecated in 0.2.6): inside a `ColumnSurface` every text, the selection fill, the marker, the focus ring and the
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
  hues by default, wrapping), mixed with ink until it reaches 4.5:1 on every surface text sits on, the column's included; draw
  a dot or tile in `accentHue(at:)`. The list is `[Accent]`: `.primary` and `.secondary` follow the Theme
  (`accentHues(in:)`), so `[.primary, .secondary, .hue(.mint), .hue(.yellow)]` puts the Theme's own hues first, and a hue
  listed twice keeps both slots. `accentCases(for:in:placement:)` lists them (280 cases, worst accent counted).
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
  counted) and the divider at 3:1; `accentCases` lists the 280 accent text cases of 0.2.4 (2064 cases in all), and 0.2.5 adds 280 with the Theme's own hues
  first, `[.primary, .secondary, .hue(.mint), .hue(.yellow)]` (2344). Glass is measured as anything between the window background (its Reduce Transparency fill) and
  what is under it; the switcher's capsule over the bottom of the column (`switcherTop`).
- **Inactive window**: the kit's inks are explicit and read no window state, so the kit's text keeps its contrast when
  the window resigns key, in a system sidebar too. The system's own sidebar labels dim there, as in every Mac app.
- **Disabled controls** carry no contrast requirement (WCAG 1.4.3, 1.4.11); the kit draws no disabled text. A disabled
  plain button (`PressedOpacityStyle`, so `IconButton`) draws its label at `Emphasis.disabled` so that it looks disabled.

## Rendering without a window

`ImageRenderer` does not draw Liquid Glass. For previews, snapshots and offscreen renders set
`.environment(\.glassRendering, .material)`: glass surfaces become a system material in the same shapes, with the same
tints and lines. `swift run --package-path Gallery DesignKitGallery <folder>` renders the gallery that way;
`DesignKitGallery audit` prints the legibility cases. A `List`, a scroll view or a popover's content is drawn by a view
hosted in a window that is never shown (`NSHostingView`, `cacheDisplay`), as the gallery's `client` and `rail` commands and
the List tests do: `ImageRenderer` draws neither a `List` nor a scroll view.
