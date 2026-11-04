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
- **Glass on controls only**: pills, the switcher, banners, floating controls. Never behind a scrolling list.
- **SwiftUI and system components first.** The kit adds a view only where no system one fits; alerts, confirmation
  dialogs, forms and settings stay system views.

## Tokens (`DesignTokens.standard`)

### Spacing (pt)

| Token | Value | Use |
|---|---|---|
| scale `xxs`…`xl` | 2, 4, 8, 12, 16, 24 | the scale |
| `rowGap` | 4 | between the backgrounds of two adjacent rows; they never touch |
| `rowInsetVertical`, `rowInsetHorizontal` | 4, 8 | a row's background around its content |
| `listMargin` | 12 | side margin of a column; rows, pills, banners, the switcher align on it |
| `layerInset` | 4 | a row's background inside a nested panel |
| `layerIndent` | 12 | indent of the second nesting level (none for the first) |
| `sectionHeaderBottom` | 6 | under a section header, before the first row |
| `tileToText`, `compactTileToText` | 10, 8 | tile to text, in a row and in a compact (28 pt tile) row |
| `textLines` | 2 | between text lines, and a row's own vertical padding |
| `glassMerge` | 6 | merge distance of glass shapes in a `GlassEffectContainer` |
| `bannerVertical`, `bannerHorizontal` | 6, 12 | banner insets |
| `canvasInset` | 12 | a content canvas inside its column |
| `pillActionGap` | 8 | between icon buttons, and between groups of buttons |
| `pillFloat` | 12 | a floating pill to the edges of what it floats over |
| `headerTracking` | 0.6 | letter spacing of small uppercase group headers |
| `pillLeading`, `pillTrailing`, `pillVertical`, `pillTileToText` | 5, 14, 5, 8 | a field pill around its 32 pt circle |
| `switcherItemGap`, `switcherPadding`, `switcherBottom` | 2, 4, 8 | the switcher |
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
| `glyphCircle`, `switcherItemWidth`, `switcherItemHeight` | 24, 52, 40 | the switcher |
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
semibold, initials `.callout` bold, switcher names `.callout` semibold, banners `.callout`.

### Motion (`MotionRole`)

Durations: instant 0.12 s, quick 0.2 s, calm 0.35 s, deliberate 0.5 s, cycle 1.2 s. Curves: `smooth` (spring, bounce 0,
settles at ×1.47), `snappy` (0.15, ×1.39), `spring` (0.1, ×1.33), `easeOut`, `easeInOut` (loops only). No visible bounce.

| Role | Duration · curve | Delay / stagger | Reduce Motion |
|---|---|---|---|
| `panelAppear` | calm · spring | | fade |
| `panelContent` | quick · easeOut | delay 0.08 | none |
| `panelDisappear` | calm · easeOut | | fade |
| `rowState` | quick · snappy | | none |
| `rowDeparture` | calm · easeOut | | none |
| `indicatorRotation` | quick · smooth | | none |
| `hoverFill` | instant · easeOut | | none |
| `themeChange` | calm · smooth | | none |
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
| `ColumnLayout(side:)` | a list column beside a detail in a `ContentCanvas`; `.left` (default) or `.right`, mirrored |
| `ContentCanvas` | content inset 12 pt, rounded 12 pt, 1 pt separator line |
| `Tile` | a rounded square: a symbol on a colour (white, or black where white stays under 3:1), a tinted symbol, or an initial on the tile fill; four sizes |
| `ListRow` | tile, title and detail lines, trailing accessory; hover, current, selection fills; the selection's marker bar (outside Increase Contrast); focus ring; `RowPlacement` free or inside a panel |
| `FolderRow` + `LayerPanel` | a folder as a row with a count and a turning chevron; its children on a continuous panel, first level not indented |
| `SectionHeader` | a section title, or a small uppercase group header |
| `ColumnSeparator` | a hairline on the column margin, between groups that have no header |
| `StatusLine` | the one-line state at the top of a column, with its chevron |
| `FieldPill` | a glass capsule with a circle in the Theme's colour, a title (or a placeholder in the secondary ink) and an accessory |
| `IconButton`, `IconButtonRow` | symbol buttons in at least the minimum target, labelled for VoiceOver; dimmed to `Emphasis.disabled` when disabled |
| `ThemeGlyph`, `GlassSwitcher` | the glass bar of themed items (spaces) at the bottom of a column; absent with one item. A glyph is its flat hue with a white or black symbol or initial |
| `Banner` | a discreet message on glass with its actions |
| `SkeletonRows` | static placeholder rows while loading, one VoiceOver label |
| `.focusRing(_:in:)` | the system focus colour, opaque and at 3:1 at least on the Theme's surfaces, around a custom control |
| `.surface(_:in:)` | glass or a layer fill, with the accessibility fallbacks below |

## Accessibility

- **Reduce Transparency**: every glass surface becomes an opaque `.background` fill with a 1 pt `.separator` line; the
  selected switcher item becomes a solid tinted capsule.
- **Increase Contrast**: the row fills (hover, current, the selection's floor) are multiplied by 1.8 (capped at 1);
  badge, tile and panel fills and the glass tint stay, since raising a fill under a text lowers its contrast. The
  selected and current rows get a 1 pt line in the secondary ink (`ColorRoles.outline`, 3:1 at least), nested panels a
  `.separator` line, glass and canvases a `.secondary` line. Text inks are solved again for the raised fills.
- **Selection marker** (outside Increase Contrast): a selected row carries a 3 pt capsule at the leading edge of its
  background, in `ColorRoles.selectionMarker`: the Theme's primary hue mixed with ink until it reaches 3:1 on every
  surface a row sits on, the selection's fill included. The fill alone differs from the gradient by about 1.3:1, which
  is not enough to find the row (WCAG 1.4.11); the semibold title is not either. Increase Contrast draws the outline
  instead, so the bar is not drawn there.
- **Reduce Motion**: each role becomes the shared fade or nothing (table above); the switcher stops morphing.
- **VoiceOver**: rows read their title and details as one element with the button trait, and say "selected"; folders
  say expanded or collapsed; icon buttons read their title; the switcher is a named group; skeletons read one label;
  decorative tiles, glyphs and lines are hidden.
- **Legibility**: every text reaches 4.5:1 and every glyph, focus ring, selection outline and selection marker 3:1, on every surface,
  for every standard Theme in the four appearances. Secondary and tinted text use the inks `ColorRoles` gets from the
  solver (`Legibility.fit`); a symbol or an initial on a solid colour is white, or black where white falls short; the
  focus ring is the system's focus colour made opaque and mixed toward the ink. `DesignTokens.legibilityCases(for:in:)`
  and `symbolCases(in:)` list each role on each surface with the system default's contrast and the kit's; CHANGELOG.md
  records the 804 cases of 0.2.1 and the 14 selection marker cases added in 0.2.2 (818). Glass is measured as anything between the window background (its Reduce
  Transparency fill) and the gradient; the switcher's capsule over the bottom of the column (`switcherTop`).
- **Inactive window**: the kit's inks are explicit and read no window state, so a column keeps its contrast when the
  window resigns key. Host it in a plain split item: a system sidebar (`NSSplitViewItem(sidebarWithViewController:)`,
  a source list) dims its own labels in an inactive window.
- **Disabled controls** carry no contrast requirement (WCAG 1.4.3, 1.4.11); the kit draws no disabled text. A disabled
  plain button (`PressedOpacityStyle`, so `IconButton`) draws its label at `Emphasis.disabled` so that it looks disabled.

## Rendering without a window

`ImageRenderer` does not draw Liquid Glass. For previews, snapshots and offscreen renders set
`.environment(\.glassRendering, .material)`: glass surfaces become a system material in the same shapes, with the same
tints and lines. `swift run --package-path Gallery DesignKitGallery <folder>` renders the gallery that way;
`DesignKitGallery audit` prints the legibility cases.
