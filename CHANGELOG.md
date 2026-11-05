# Changelog

## 0.2.7

Three fixes Oisillon's adoption of 0.2.6 found: a `Banner` cut its message at two lines (issue #30), the sidebar column's
widths did not reach the split view from below a container (issue #28), and a sidebar column with an empty bottom bar
hid every row (issue #29).

### Fixed

- **A `Banner` shows its whole message** (issue #30): the message was cut at 2 lines, so a 3-line error lost its end.
  Every initialiser takes **`messageLineLimit: Int?`**, and it defaults to **`nil`, no limit**: the message shows on as
  many lines as it takes and the banner grows with it. Unlimited rather than the old 2, because the banner carries
  errors whose end is often the part to act on ("…then try again"), a cut message cannot be read anywhere else, and a
  client that wants the old height asks for it with `messageLineLimit: 2`. A message that fits on 1 or 2 lines draws
  what 0.2.6 drew; only longer ones grow. The title keeps its 2 lines. Tested on an offscreen render, light and dark: a
  3-line message is one line taller than with `messageLineLimit: 2`, the same height with no limit as with 3 and 4,
  with a title, with the client's actions and beside the close button.
- **The sidebar column's widths reach the split view** (issue #28): `navigationSplitViewColumnWidth` counts only on the
  root of a `NavigationSplitView` column, so `sidebarColumn` under a container of the client's (a `VStack` in the
  column view's body) set widths the split never saw, and the column opened at 144 pt, the split's default.
  **`SidebarSplitView`** now sets the kit's widths on its sidebar's root itself: the column opens at `Size.columnIdeal`
  (360 pt) wherever `sidebarColumn` sits inside it. In a `NavigationSplitView` of the client's, the widths have one
  place, the column's root: `sidebarColumn` there, or the new **`.sidebarColumnWidth()`** there when the list sits
  deeper. Tested by hosting the split in a 1100 pt window that is never shown and measuring the column: 360 pt with the
  column at the root and under a `VStack`, in `SidebarSplitView` and in a client split with `sidebarColumnWidth()`.
- **An empty bottom bar hides no row** (issue #29): with `bottomBar: { EmptyView() }` every row was drawn invisible,
  though the rows were in the accessibility tree: the bar's height was measured on the `EmptyView`, which took the
  whole column, and the fade mask hid all of it. And a bar that emptied (a `SpaceRail` going from 2 Spaces to 1, which
  hides itself) sent no new height, so the mask kept its last 80 pt of rows hidden. The bar is now measured on a stack
  that is always there and is 0 pt tall when the bar draws nothing, an `EmptyView` bar is not measured at all, and with
  a 0 pt bar the mask is a plain rectangle. A bar that is shown draws and fades the list as in 0.2.6. Tested on a pixel
  render of twelve rows: every row shows with no bar, with an `EmptyView` bar (also with a header), with a bar that is
  empty in its state, and after a bar empties; the bar coming back fades the rows under it again.

### Added

- **`.sidebarColumn()`**: the sidebar column with no bottom bar.
- **`.sidebarColumnWidth()`**: the kit's column widths (`columnMin`, `columnIdeal`, `columnMax`) on a
  `NavigationSplitView` column's root.
- **`.listSelectionPlatterOff()`** (issue #29): turns off the selection platter AppKit draws behind a selected `List`
  row, on its own, without the rest of `sidebarColumn` (no list style, mask, bars or widths). Nothing on iOS.
  `sidebarColumn` uses it.
- **`Banner(…, messageLineLimit:)`**, above.

### Unchanged

- The 2344 legibility cases: the audit's output is the same, line for line, all at their threshold.
- No source-breaking change: every new parameter has a default, every new modifier is additive.

## 0.2.6

The Space rail's emoji and its popovers' focus ring (issue #20), both seen when Safira adopted the rail. Then the column
surface deprecated, since Safira takes Oisillon's system sidebar as it is (issue #21), `ThemeGlyph`'s emoji, for
Oisillon's Spaces (issue #22), and two of the rail's VoiceOver strings (issue #27).

### Changed

- **Emoji glyphs at their own size**: a Space's emoji, quiet or selected, in the rail and in its panel, was drawn in
  `TypeScale.glyphCircle`'s font like an initial and sat small in its circle (the selected 📖 at about half its width).
  It is now that style's size times **`TypeScale.glyphEmojiScale` (1.3)**: 13 pt on macOS, about 15 pt of artwork in the
  24 pt circle where the initial's capital is 7 pt. **`DesignTokens.glyphEmojiSize(textSize:)`** caps it at
  **`DesignTokens.glyphEmojiMaxShare` (0.55)** of `Size.glyphCircle` (13.2 pt), where the corners of a square emoji
  still fall inside the circle; on iOS (caption 12 pt, more under Dynamic Type) the cap applies. Initials and symbols
  are unchanged. Tested on an offscreen render, light and dark: nothing drawn outside the circles, the
  emoji 14 to 16 pt tall against the initial's 7 to 8. (`ThemeGlyph` gains its own emoji below.)
- **No focus ring on a popover opened with the pointer**: clicking the rail's `+` or "+n" drew the kit's focus ring
  around the panel's first row. A panel opened with a click now shows none until the first arrow or Tab key, which
  shows it on that row without moving it; Return and Space pick nothing until then. Opened from the keyboard (Return or
  Space on the rail), or by an assistive technology, the ring starts on the first row as before (the selected Space in
  "+n"). Shift-Tab counts as Tab.
- **The rail's panels take the placement around them** (issue #21): the "+n" and `+` panels forced
  `surfacePlacement` `.column`, so their inks were solved on a column's fill while they sit in a popover. They now
  inherit it like the rail, `.frame` by default, and nothing on the rail's path sets `.column`. What moved: the
  secondary ink is a little more opaque in every Theme (alpha +0.01 to +0.03 in light, +0.10 to +0.14 in dark, +0.01 to
  +0.04 and +0.09 to +0.11 under Increase Contrast), and in light the selection of four bright Themes is heavier
  (orange-pink 0.375 to 0.478, teal-green 0.381 to 0.5, mint-cyan 0.391 to 0.5, brown-yellow 0.300 to 0.317). Nothing
  got lighter. On the popover, bounded by the plain background and that background at half opacity over the gradient
  (the material cannot be drawn without a window), the panels' text reaches 4.72:1 at worst in light (4.62 before),
  5.86 in dark (4.81), 4.70 and 5.51 under Increase Contrast (4.61, 4.73); the focus ring and the marker 3.36:1. So
  `.frame` holds there, and no placement of its own is needed.
- **The rail's VoiceOver strings** (issue #27, from Safira's accessibility pass): the `+` read only "Add" ("Ajouter"),
  not what it opens. It now reads **"Add or Edit a Space or Profile"** ("Ajouter ou modifier un espace ou un profil"),
  also its help. A folded Profile's hint, "opens Home" ("ouvre Home"), read as a fragment after "Profile Default, 1
  Space"; it is now a sentence, **"Opens Home."** ("Ouvre Home."). The caption keeps "1 Space · opens Home". The
  catalog's "Add" entry is replaced, "Opens %@." is new.
- **`DesignTokens.glyphEmojiSize(textSize:circle:)`**: the emoji size for any glyph circle, the same scale with the cap
  a share of that circle. `glyphEmojiSize(textSize:)` is it for `Size.glyphCircle`. The rail and `ThemeGlyph` both
  size their emoji through it, one helper for both.

### Deprecated

Neither app draws the kit's column surface: Safira and Oisillon both use a system `NavigationSplitView` sidebar, flush
with the window's edge (issue #21). These still compile in 0.2.6, with a warning that points at `SidebarSplitView`
(below), and are removed in 0.3:

- **`ColumnSurface`**, **`.columnSurface(side:)`** and **`ColumnLayout`**, which is built on it.
- **`SurfacePlacement.column`**, so **`ColorRoles(…, placement: .column)`**. `SurfacePlacement.allCases` is written
  out (a deprecated case stops Swift from synthesizing it) and still lists both.
- **`ColorRoles.columnEdge`**, **`columnEdgeRGBA`**, **`columnEdgeAlpha(…)`**, **`columnEdgeNeighbours(…)`** and
  **`columnFillOpacity`**.
- **`Spacing.columnInset`**, **`Spacing.columnTop`** and **`Radius.column`**.
- **`DesignTokens.columnSurfaces(in:)`**.

The kit builds with no deprecation warning of its own, so a client that uses none of them sees none.
`ColorRoles.railDivider` keeps the column edge's ink (3.65:1 at least on the frame's gradient and the plain
background), and the legibility audit keeps its column cases (798 legibility cases, the 168 rail cases and 140 + 140
accent cases) until the column is removed. The docs and the README now show
the column as the system sidebar, `SidebarSplitView`: a plain `List` with `.scrollContentBackground(.hidden)`, the kit's
views in `.frame`.

### Added

- **`SpaceRailPanelFocus`**: the panel's keyboard focus as a value (the focused row, whether the ring shows, and what
  ↑, ↓, Tab, Return or Space and Escape do), testable without a window.
- **`SpaceRailPanel(…, showsFocusRing:)`**: `false` for a panel opened with the pointer. The default, `true`, draws what
  0.2.5 drew, so a client that builds a panel itself is unchanged.
- **`SpaceRailModel.accessibilityHint(for:)`**: the hint VoiceOver reads after an item's label ("Opens Home." for a
  folded Profile, empty otherwise), which the rail uses, so it can be tested without a window.
- **`ThemeGlyph(name:symbol:emoji:theme:size:)`** (issue #22): a glyph can be an emoji, at both sizes. It wins over the
  symbol and the initial, keeps its own colours (no ink, no tint) and is drawn at the rail's emoji size for its circle:
  13 pt in the 24 pt circle, 8.8 pt (the cap) in the small 16 pt one. Measured on an offscreen render, light and dark:
  📚 spans 13×14 pt in the standard circle, within a point of the rail's selected emoji, and 9×10 in the small one, the
  same share of the circle; the initial is 7×8 in both (caption and caption2 are both 10 pt on macOS); nothing is drawn
  outside either circle. The glyph stays hidden from VoiceOver: the item it stands for carries the Space's name, never
  the emoji's description. `emoji: nil`, the default, draws what 0.2.5 drew.

### Unchanged

- The 2344 legibility cases: the audit's output is the same, line for line, all at their threshold.
- No source-breaking change: the deprecations warn, nothing is removed.

### Sidebar

The system sidebar, dressed by the kit (issue #24). Two apps put a sidebar beside a detail: a system
`NavigationSplitView` flush with the window's edges, the Theme's gradient behind it, the `SpaceRail` at the column's
bottom. The kit now holds that sidebar, so both apps draw it from one place. It reproduces the sidebar of the first app
to ship one, pixel for pixel, with one change at the bottom bar (below).

#### Added

- **`SidebarSplitView`**: a `NavigationSplitView` on `WindowBackground`, with `sidebarWindowChrome()`.
- **`.sidebarColumn(field:header:bottomBar:)`** (and `sidebarColumn(bottomBar:)`, `sidebarColumn(header:bottomBar:)`):
  the column widths (`columnMin`, `columnIdeal`, `columnMax`), a plain list with no content background and no section
  separators, no AppKit selection platter, an optional head field where the system's sidebar search sits, an optional
  header, and the bottom bar in a `safeAreaBar`.
- **`.sidebarRowCell(state:placement:)`**: a sidebar `List` cell. Its background sits where `listRowCell`'s does; its
  content keeps the `List`'s own margin, 20 pt from the column's edge.
- **`SidebarDetail`**: the detail's card, inset 12 pt from the window's top edge and the column's edges, with an optional
  floating bottom bar.
- **`.sidebarWindowChrome()`**: the toolbar lets the gradient through, shows no title, and slides away in full screen
  until the pointer reaches the top.
- **`NSSplitViewItem.sidebar(hosting:)`** and **`NSSplitViewItem.sidebarToolbarItems`**: the same sidebar in an AppKit
  window, as the system's sidebar split item.
- **Tokens**: `Spacing.barFade` (16), `Spacing.sidebarFieldSide`, `sidebarFieldTop`, `sidebarFieldBottom` (10, 9, 8) and
  `Size.sidebarField` (29).

#### Fixed, compared with the app it comes from

- **No row under the bottom bar.** The list scrolled under the bar down to the window's edge, so a row's text showed
  between the bar's controls and the edge. The list now fades out over the bar's first `barFade` points and shows
  nothing below.

#### Proof

Captured in the background beside the source app's sidebar, in light, dark, and Increase Contrast light and dark (an
inactive window each time): the column's edge, the search field, the sidebar button, the header, the list's top, the
selected row's background, marker and content, the detail's card and its floating bar land on the same pixels; the
sidebar's fill, the gradient and the selection fill match within 1 of 255. `SidebarTests` holds the geometry: the cell's
margins, the fade under the bar, the platter turned off, the AppKit item's widths, the card's inset.

## 0.2.5

Theme-relative accent order (issue #17). `DesignTokens.accents` can name the Theme's own hues, so a client can say "the
Theme's primary and secondary first, then fixed hues", an order that changes with the Theme. Oisillon colours accounts with
`[.primary, .secondary, .hue(.mint), .hue(.yellow)]`, which a fixed `[Hue]` could not express.

### Added

- **`Accent`** (ColorCore): `.primary`, `.secondary` or `.hue(Hue)`. `Accent.hue(in:)` resolves it against a Theme, and
  `[Accent].hues(in:)` resolves a list in order.
- **`DesignTokens.accentHues(in:)`**: `accents` resolved against a Theme, the hues `ColorRoles` and the legibility audit
  solve and draw for it.
- **Resolved per Theme everywhere the list is used**: `ColorRoles` resolves `accents` against its Theme before it reaches
  `ResolvedColors` and the legibility cache, and `accentCases(for:in:placement:)` does the same in the audit. The cache
  keys on the resolved hues, so one Theme's accents never reach another. `accentHue(at:)` still returns a `Hue`, the
  resolved one.
- **Duplicates keep their slots**: when a Theme's primary is also a later `.hue`, both slots keep their place (mint-cyan
  gives mint, cyan, mint, yellow), because the index is the account's.
- **Legibility**: the audit (`DesignKitGallery audit`) also covers every standard Theme with the accent list
  `[.primary, .secondary, .hue(.mint), .hue(.yellow)]`: 280 cases, 10 per Theme and appearance on the gradient and inside a
  list column, the worst of the four accents counted. All 280 reach 4.5:1: the inks reach 4.50 to 9.58:1, where the raw hues
  reach 1.00 to 7.43:1 (262 of them under 4.5:1). Each case is a test, recorded on macOS 27 in
  `Tests/DesignKitTests/RecordedThemeAccentCases.swift`. In the audit's output, their Theme id ends in
  `[primary,secondary,mint,yellow]`.

### Source-breaking changes

- `DesignTokens.accents` is `[Accent]` instead of `[Hue]`. Migration: wrap each hue in `.hue(x)`, so
  `tokens.accents = [.red, .green]` becomes `tokens.accents = [.hue(.red), .hue(.green)]`. Code that read the list as hues
  calls `tokens.accentHues(in: theme)` instead.
- The default is `Hue.allCases.map(Accent.hue)`: the twelve hues in the same order, so `accentHue(at:)` and
  `accentInk(at:)` return what 0.2.4 drew in every Theme. The 2064 legibility cases of 0.2.4 are unchanged (2344 in all
  with the new 280).
- `ColorPlatform` is unchanged: `ResolvedColors(_:accents:in:)` and `Legibility.of`/`fitted(_:accents:…)` still take the
  resolved `[Hue]`.

### What changes visibly for Oisillon

- Nothing, until it sets `accents` to its Theme-relative list and adopts `accentInk(at:)` (#8).

## 0.2.4

Space rail, and the requests Oisillon made when it adopted the kit (issues #4 to #11). A Space selector both apps share
replaces the glass switcher: one quiet row at the bottom of a list column, Profiles folded into dots after a hairline, a
`+` for the app's commands, and a named panel when the row does not fit. The rest is what Oisillon was rebuilding on its
own: motion without its delay, rows that are `List` cells, a glyph size, accent text inks, a banner and a status line with
more states, label-only buttons and a segmented pill.

### Added

- **`SpaceRail`**: the active Profile's Spaces as glyphs, the selected one in its Theme's hue with a marker bar under it
  (`ColorRoles.selectionMarker`). After a hairline, each other Profile is folded into dots in its Spaces' hues, one
  target that switches to it. A trailing `+` opens the app's commands. Hovering or focusing an item shows a caption
  above the row: the name, a detail and the shortcut, with its height always kept. `SpaceRail(spaces:…)` draws an app
  with no Profiles: the Spaces alone, no divider. The app supplies every name, shortcut and command title; the kit writes
  no key. See docs/design-kit.md, "Space rail".
- **Panels scroll**: `SpaceRailPanel` (the `+` and the "+n") is as tall as its rows up to `Size.railPanelMaxHeight`
  (480), then scrolls; ↑ and ↓ bring the focused row into view. 8 + 8 Spaces scrolls instead of growing past the screen.
- **Overflow**: when the row does not fit, the active Profile's last Spaces (never the selected one) give way to a
  trailing "+n", then the folded Profiles too. "+n" opens **`SpaceRailPanel`** in a popover: every Profile under a
  header, every Space with its glyph and shortcut, then the commands. In the ideal column (360) 8 Spaces fit beside a
  folded Profile, and 8 + 8 fits. At `columnMin` (300) the last two of 8 Spaces fold into "+2".
- **Keyboard and VoiceOver**: the row is one focus stop. ← and → move across its items, and Return or Space activates.
  The panels are one focus stop each (↑ ↓, Return, Escape). VoiceOver reads "Space Research, 2 of 3" (plus
  "selected"), "Profile Personal, 3 Spaces" (hint "opens Home"), "All Spaces, 2 more" and "Add", in a group named
  "Spaces and Profiles" ("Spaces" without Profiles). English and French in the kit's string catalog.
- **`SpaceRailModel`**, the rail's logic as a value: `layout(width:hasCommands:)`, `action(for:)`, `caption(for:)`,
  `accessibilityLabel(for:)`, and `SpaceRailLayout.key(movingFrom:by:)`. Also `SpaceRailSpace`, `SpaceRailGlyph`
  (`.emoji`, `.symbol`, `.initial`), `SpaceRailProfile` (`landingSpace`: its last Space, or its first),
  `SpaceRailCommand`, `SpaceRailItem`, `SpaceRailAction`, `SpaceRailCaption`, `SpaceRailLayout`.
- `SpaceRailPreviewState` and `.spaceRailPreviewState(_:)` force a hover or a focus for previews and offscreen renders.
- **Colours**: `ColorRoles.railDot(_:)` / `railDotRGBA(_:)` draw a Space's hue, opaque, mixed with ink until it reaches
  3:1 on every surface solved where it sits. The raw hue falls to 1.16:1 (yellow on a light column). `ColorRoles.railDivider`
  is the column edge's ink, 3.98 to 5.10:1 on the column's fill, where the separator gives 1.24 to 1.34:1.
- **Tokens**: `Spacing.railMarkerGap` (2), `railGroupGap` (4), `railDotGap` (4), `railCaption` (4), `railFoldPadding`
  (4); `Size.railHeight` (`minTarget` + 8: 36 on macOS), `railMarker` (12), `railDivider` (16), `railCount` (16),
  `railDotsMax` (4, a count).
- **Motion**: `MotionRole.profileSwap` (calm · smooth, stagger 0.04 per glyph; the shared fade under Reduce Motion). A
  Profile's glyphs fold while the new Profile's open. A change of Space slides the marker with `themeChange` (immediate
  under Reduce Motion).
- **Legibility**: `DesignTokens.railCases(for:in:)` gives 168 cases inside the column, 6 per standard Theme and
  appearance, all recorded in the tests. A quiet glyph reaches 4.90 to 8.06:1 on the column's fill and its hover disc
  (threshold 4.5; the system secondary label gives 3.55). The marker reaches 4.18 to 7.43:1. A folded Profile's dots, in
  every system hue with the worst counted, reach 3.91 to 6.38:1. The divider reaches 3.98 to 5.10:1. The threshold for
  these is 3. The caption's texts are the column's primary and secondary text, already recorded in 0.2.3. An offscreen
  render reads back the marker, a yellow dot and the divider at 3:1 against the column's fill.
- The gallery renders the rail: `DesignKitGallery rail <folder>` (windows in two palettes, light and dark, left and
  right, 3 and 8 Spaces, with and without Profiles; a sheet of every state per palette and appearance). Its samples now
  use the rail.

- **Motion without its delay (#4)**: `MotionRole.animationWithoutDelay(reduceMotion:)` is the role's animation without
  its delay (content leaving, a skeleton that is already showing), `MotionRole.Spec.settlingSecondsWithoutDelay` the
  settling time without it (`settlingSeconds` is that plus `delay`), and `Spec.animation(includingDelay:)` builds either.
  A CSS export reads `duration`, `delay` and `settlingSecondsWithoutDelay` separately.
- **`ListRowBackground` and `ListRowContent` (#6)**: a `ListRow`'s background (hover, current, selection fill; the bar, or
  the outline under Increase Contrast; the focus ring) as a view for `listRowBackground`, and its content without the
  background. `View.listRowCell(state:placement:)` makes a view a cell: the background, no separator, and the insets that
  put both where they sit in a stack of `ListRow`s. A macOS `List` keeps a margin round a cell's content even with zero
  insets (`Spacing.listCellMargin`, 8 on macOS, 0 on iOS, measured); the modifier cancels it with a negative inset.
  `ListRow` is now `ListRowContent` over `ListRowBackground`, drawn as before.
- **Fill modifiers (#6)**: `View.tileFill(_:)` draws the kit's tile fill behind a client view (a square of the `TileSize`,
  the tile's radius) and `View.badgeFill()` its badge fill (a capsule, `Spacing.badgeHorizontal` and `badgeVertical`
  round the view); both set the view in `ColorRoles.tintText`, 4.5:1 on those fills.
- **`ThemeGlyph(size:)` (#7)**: `GlyphSize` `.standard` (`Size.glyphCircle`, 24) or `.small` (`Size.glyphCircleSmall`, 16, with
  `TypeScale.glyphCircleSmall`).
- **Accent text inks (#8)**: `ColorRoles.accentInk(at:)` / `accentInkRGBA(at:)` and `accentHue(at:)`, by index into
  `DesignTokens.accents` (the twelve system hues in `Hue.allCases` order; an app may set its own list; an index wraps).
  Each ink is the hue mixed with ink until it reaches 4.5:1 on every surface the roles solve, the column's fill included
  (the raw hues fall to 1.0:1 on them). `DesignTokens.accentCases(for:in:placement:)` and `LegibilityCase.Role.accentText`:
  280 new cases (10 per Theme and appearance: the bare surface, hovered, current and selected rows and the panel, on the
  gradient and in the column, the worst of the twelve counted), all recorded. The 1616 of 0.2.3 are unchanged, and so is
  every other ink (the hue's share and the other solved values are what they were).
- **`Banner` (#9)**: `Banner(systemImage:title:message:action:onClose:)` with the kit's own buttons: a title over the
  message (`TypeScale.bannerTitle`, the message in the secondary ink), an action (`BannerAction`) and a close button named
  "Close" (English and French in the string catalog), each optional. `Banner(systemImage:title:message:actions:)` takes a
  title with the client's own actions; the original initialiser is unchanged.
- **`StatusLine` (#9)**: `fillsWhenOpen` fills the line in the current-row fill while it is open (outlined under Increase
  Contrast), and `StatusLine(title:count:isOpen:fillsWhenOpen:state:tile:)` takes any view as its tile, drawn in a
  `Size.statusTile` square. Both default to what 0.2.3 drew.
- **`IconButton` label only (#10)**: `IconButton(_:action:)` shows its title (`TypeScale.buttonLabel`, `Spacing.buttonLabelHorizontal`
  either side, never narrower or lower than the target).
- **`SegmentedPill` (#10)**: a glass capsule of segments (`SegmentedPillItem`, a title and an optional symbol), one selected,
  `Size.segmentedPill` (36 on macOS) high, each segment a target of at least `minTarget`. The selected segment is filled with
  the selection fill, semibold, with a marker bar under its title (`ColorRoles.selectionMarker`, 3:1), an outline under
  Increase Contrast instead; the others are in the secondary ink.
- **Focus and disabled states (#10)**: `IconButton`, a banner's buttons and `SegmentedPill` draw the kit's focus ring on keyboard
  focus (`ColorRoles.focusRing`, 3:1; the system's own effect is off) and dim to `Emphasis.disabled` when disabled.
  `.controlFocusPreview()` forces the ring on every control below for previews and renders.
- **`accessibilityOverrides(fullMotion:)` (#11)**: lifts a Reduce Motion the system has on, as `reduceMotion` forces it. When both are
  set Reduce Motion wins. Increase Contrast now also reaches the kit's views inside a `List`'s cells: AppKit hands a cell the
  system's own value and loses the SwiftUI override, so the kit's views read the override from an environment value of their
  own too.
- **Tokens**: `Spacing.badgeHorizontal` (8), `badgeVertical` (2), `buttonLabelHorizontal` (8), `segmentGap` (2), `segmentPadding` (4),
  `segmentHorizontal` (12), `segmentContent` (4), `segmentMarkerGap` (2), `bannerLines` (2), `listCellMargin`; `Size.glyphCircleSmall`
  (16), `railPanelMaxHeight` (480), `segmentedPill` (`minTarget` + 8), `segmentMarker` (12); `TypeScale.glyphCircleSmall`, `bannerTitle`,
  `buttonLabel`, `segment`, `segmentSelected`; `DesignTokens.accents`.
- The gallery renders the additions: `DesignKitGallery client <folder>` (the controls in light and dark, with and without Increase
  Contrast and Reduce Transparency; a real `List` of rows; a tall panel). `rail` and `client` draw what scrolls or lists in a
  window that is never shown, since `ImageRenderer` draws neither a scroll view nor a `List`.

### Changed

- **Settling factors (#5)**: `MotionCurve.settlingFactor` was rounded down, which left 0.102 % of travel for `snappy` (1.39) and
  `spring` (1.33), above the documented 0.1 %. They are now the measured 1.3933 and 1.3332 rounded up to the hundredth: `snappy` 1.40,
  `spring` 1.34 (`smooth` stays 1.47, 1.4695 measured). A test checks, on `Spring(duration:bounce:)` for every duration, that the
  residual travel at `duration × factor` is at most 0.1 % and that the factor is not larger than the next hundredth.
  `settlingSeconds` of a `snappy` role grows by 0.01 × its duration, a `spring` role's by the same.
- **`ListRow`'s focus ring** is drawn with its background (behind the content instead of over it); nothing overlaps it.

### Deprecated

- **`GlassSwitcher`**: use `SpaceRail`. It still compiles in 0.2.4 and goes in 0.3, with `SwitcherItem`, the
  `switcherItemWidth`, `switcherItemHeight`, `switcherItemGap` and `switcherPadding` tokens, and its legibility case
  (`switcherSelection`).

### Source-breaking changes

- `LegibilityCase.Role` gains `railGlyph`, `railMarker`, `railDot` and `railDivider`, and `MotionRole` gains
  `profileSwap`. An exhaustive `switch` over them needs the new cases or a `default`.
- `StatusLine` is generic over its tile (`StatusLine<Leading>`): a use of the bare type name without its argument, as a stored
  property's type, needs `StatusLine<Tile>`. Calls are unchanged.
- `LegibilityCase.Role` also gains `accentText`: a `switch` needs the case too.
- `IconButton` shows the kit's focus ring and no longer the system's.
- No existing token value changed, and every legibility case of 0.2.3 is recorded unchanged (1616): 2064 in all, with the rail's
  168 and the accents' 280.

### What changes visibly for Oisillon

- `snappy` and `spring` settling times are about 0.7 % longer (the settling factor); an animation itself
  is unchanged.
- Keyboard focus on an `IconButton` is the kit's 3:1 ring instead of the system's.
- A `ListRow`'s focus ring sits behind its content.
- The panels of the rail stop growing at 480 pt and scroll.
- Nothing else is drawn differently until Oisillon adopts a new API: `fillsWhenOpen`, the client tile, the new `Banner`, the label-only
  button, `SegmentedPill`, `ThemeGlyph(size:)`, the fill modifiers, `listRowCell`, `accentInk(at:)` and `fullMotion` all default to off or
  to what 0.2.3 drew.

### Known limits

- A focus ring on a `List` cell is clipped by the cell (it stands 4 pt outside a background that is 2 pt from the cell's top).
- The system's Increase Contrast cannot be switched on for a test, and a window's high-contrast appearance does not set it; the
  List-hosted tests use the kit's override, which reaches the cells.

## 0.2.3

Column surface. A list column now sits on a surface of its own, so it reads apart from the page beside it, the way a
mail client's sidebar column does on its gradient. Colours inside it are solved on that surface. Also in this release:
a token for the gap above the column's first row, and switcher tooltips that show the app's shortcut.

### Added

- **`ColumnSurface(side:)`** (and `.columnSurface(side:)`): the list column's own surface. It is inset from the
  window's top, bottom and outer edges by `Spacing.columnInset` (12) and rounded by `Radius.column` (12, concentric to
  the rows' backgrounds 4 pt inside it). Its fill is the plain window background (`.background`) at
  `Emphasis.columnLight` / `columnDark` (0.5) over the gradient. That makes it darker than the frame in dark and lighter
  in light, with a trace of the Theme left. It has a 1 pt edge in `ColorRoles.columnEdge`, and its content starts
  `Spacing.columnTop` (24) under the window's top edge, clipped to the surface. Under Reduce Transparency the fill is
  opaque `.background` and the edge stays. It is drawn with kit pieces, never `NavigationSplitView`'s sidebar or a
  system sidebar item, which dim their labels in an inactive window. The width comes from the content, or from the split
  item hosting it.
- **Colours solved inside the column.** `SurfacePlacement` (`.frame`, `.column`) and the environment value
  `surfacePlacement`, which `ColumnSurface` sets on its content. Under `.column`, `WithColorRoles` builds
  `ColorRoles(theme:tokens:appearance:placement: .column)`. These roles solve the secondary and tinted inks, the
  selection fill, the selection marker and the focus ring on the column's surfaces (`DesignTokens.columnSurfaces(in:)`),
  not on the bare gradient. The hue keeps the share the frame was solved at (`hueScale`), so the gradient under the
  column and the fills in it are drawn alike.
- **Column edge.** `ColorRoles.columnEdge` / `columnEdgeRGBA` is the label's ink (black in light, white in dark) at the
  smallest alpha that reaches 3:1, at every height, against the bare gradient beside the column and against the
  column's fill (and the opaque fill of Reduce Transparency). `ColorRoles.columnEdgeAlpha(…)` and
  `columnEdgeNeighbours(…)` expose that solve, and `ColorRoles.columnFillOpacity` gives the fill's opacity.
- `ColorCore`: `Surfaces.backdrop` (default 0) is the plain background's opacity over the gradient. Above 0, the plain
  background itself is also sampled. `Surfaces.samples(_:)` returns the places text can sit on before any fill.
  `Legibility.solve(colors:surfaces:hueScale:)` solves at a share fixed by another solve.
- `ColorPlatform`: `Legibility.of(_:accents:surfaces:hueScale:in:)`, cached.
- `DesignKit`: tokens `Spacing.columnInset` (12), `Spacing.columnTop` (24), `Radius.column` (12),
  `Emphasis.columnLight` (0.5), `Emphasis.columnDark` (0.5), `Emphasis.column(isDark:)`. Also
  `DesignTokens.surfaces(in:placement:)`, `LegibilityCase.placement`, `LegibilityCase.Role.columnEdge`,
  `LegibilityCase.SurfaceKind.columnFill`, and `legibilityCases(…, placement:)`.
- `SwitcherItem.shortcut` (optional, default nil) and `SwitcherItem.help`.
- 798 legibility cases inside the column, every standard Theme in the four appearances (1616 in all). The tests read
  back from offscreen renders that the column's edge reaches 3:1 against the gradient and against the fill on either
  side (at least 2.95:1 once rounded to 8-bit pixels), that the fill is opaque under Reduce Transparency, and that a
  selected row's marker reaches 3:1 inside the column.
- The gallery renders the browser's main window under Increase Contrast and Reduce Transparency
  (`browser-main-window-left-contrast-transparency`), and its samples set their switcher items' shortcuts.

### Changed

- **`ColumnLayout`** puts the column on a `ColumnSurface` (`Size.columnIdeal` wide, inset on its outer side). The
  Theme's gradient stays behind the whole window: it shows around the column and around the page's canvas, and inside
  the column only through the column's fill. Both sides (`.left`, `.right`) mirror.
- **`GlassSwitcher` tooltip.** The kit no longer writes "(⌘1)…(⌘9)" after an item's name. The help is the item's name,
  then `SwitcherItem.shortcut` in parentheses when the app gives one ("Work (⌃1)"). Without one, the help is the name
  alone.
- **Motion.** No new role. A change of space is the change of its Theme, so `themeChange` (calm · smooth, nothing under
  Reduce Motion) is the role to use. Oisillon's `spaceChange` has exactly this spec. `ColumnSurface` animates its edge
  with it.

### Source-breaking changes

- `LegibilityCase.Role` gains `columnEdge` and `LegibilityCase.SurfaceKind` gains `columnFill`. An exhaustive `switch`
  over them needs the new cases or a `default`.
- `SwitcherItem` gains a stored `shortcut`. Its initialiser takes it with a default, so existing calls compile. Two
  items that differ only by shortcut are no longer equal.
- The switcher's tooltip changes text (see Changed). Nothing else changes: no existing token value changed, and every
  frame legibility case of 0.2.2 is recorded unchanged.

### Changed values

No existing token value changed. Five tokens are new. Drawn values change only inside a `ColumnLayout` or a
`ColumnSurface`:

| What | 0.2.2 | 0.2.3 |
|---|---|---|
| Column background | the window's gradient | `.background` at 0.5 over the gradient; opaque `.background` under Reduce Transparency |
| Column bounds | the window's edges | inset 12 pt from the top, the bottom and the outer side; rounded 12 pt; 1 pt edge in `columnEdge` |
| Column's first row | at the column's top (apps added their own margin) | 24 pt under the window's top edge (`columnTop`) |
| Column width in `ColumnLayout` | 360 | 360 for the surface, plus its 12 pt outer inset |
| Inks, selection fill, marker, focus ring inside the column | solved on the gradient | solved on the column's fill |
| Switcher tooltip | "Name (⌘N)" for the first nine | "Name (shortcut)" from `SwitcherItem.shortcut`, or "Name" |

Per Theme and appearance: how far the column's fill sets it apart from the gradient ("Column vs gradient", worst to
best height), the edge's ink alpha, then the solved values on the frame → inside the column: the selection fill (an
opacity of the hue), the secondary text's alpha, the tint ink's share, the selection marker and the focus ring.

| Theme | Appearance | Column vs gradient | Edge alpha | Selection | Secondary alpha | Tint ink share | Marker | Focus ring |
|---|---|---|---|---|---|---|---|---|
| indigo-blue | light | 1.03–1.33 | 0.574 | 0.300 → 0.300 | 0.638 → 0.604 | 0.561 → 0.473 | #4C42BF → #564CDA | #004FBC → #005AD6 |
| indigo-blue | dark | 1.04–1.41 | 0.534 | 0.250 → 0.250 | 0.752 → 0.649 | 0.810 → 0.673 | #A0AAFF → #8995FF | #45B9FF → #1AA9FF |
| indigo-blue | light, increased contrast | 1.03–1.33 | 0.574 | 0.540 → 0.540 | 0.703 → 0.665 | 0.689 → 0.620 | #3E369C → #453DAE | #00419A → #0048AB |
| indigo-blue | dark, increased contrast | 1.04–1.40 | 0.531 | 0.444 → 0.444 | 0.847 → 0.756 | 0.916 → 0.812 | #B2BAFF → #A1AAFF | #6DC8FF → #47BAFF |
| orange-pink | light | 1.02–1.18 | 0.512 | 0.478 → 0.375 | 0.593 → 0.576 | 0.568 → 0.531 | #9A5518 → #A85D1A | #005FE0 → #0067F4 |
| orange-pink | dark | 1.04–1.50 | 0.576 | 0.219 → 0.219 | 0.838 → 0.700 | 0.999 → 0.764 | #FFAB5F → #FF9230 | #6AC7FF → #2BAFFF |
| orange-pink | light, increased contrast | 1.02–1.18 | 0.512 | 0.540 → 0.540 | 0.596 → 0.587 | 0.575 → 0.557 | #985418 → #9E5719 | #005DDC → #0061E6 |
| orange-pink | dark, increased contrast | 1.03–1.36 | 0.510 | 0.304 → 0.304 | 0.847 → 0.746 | 0.950 → 0.777 | #FFAC62 → #FF9434 | #6DC8FF → #43B8FF |
| teal-green | light | 1.02–1.17 | 0.512 | 0.500 → 0.381 | 0.589 → 0.575 | 0.570 → 0.539 | #00747C → #007D85 | #0060E3 → #0067F4 |
| teal-green | dark | 1.04–1.48 | 0.560 | 0.188 → 0.188 | 0.832 → 0.692 | 1.000 → 0.723 | #00D2E0 → #00D2E0 | #66C6FF → #25ADFF |
| teal-green | light, increased contrast | 1.02–1.17 | 0.512 | 0.540 → 0.540 | 0.591 → 0.585 | 0.573 → 0.560 | #00737A → #00777F | #005FE1 → #0062E9 |
| teal-green | dark, increased contrast | 1.03–1.34 | 0.499 | 0.265 → 0.265 | 0.846 → 0.741 | 0.959 → 0.752 | #00D2E0 → #00D2E0 | #6BC8FF → #3FB7FF |
| red-orange | light | 1.03–1.31 | 0.568 | 0.300 → 0.300 | 0.623 → 0.599 | 0.580 → 0.528 | #AB2628 → #BE2A2D | #0053C5 → #005CDA |
| red-orange | dark | 1.03–1.41 | 0.521 | 0.250 → 0.250 | 0.748 → 0.642 | 0.822 → 0.692 | #FF8C8E → #FF686B | #3EB6FF → #1AA9FF |
| red-orange | light, increased contrast | 1.03–1.31 | 0.568 | 0.540 → 0.540 | 0.662 → 0.641 | 0.643 → 0.611 | #952123 → #A02326 | #0048AB → #004EB8 |
| red-orange | dark, increased contrast | 1.03–1.40 | 0.519 | 0.446 → 0.446 | 0.847 → 0.753 | 0.922 → 0.825 | #FFA5A6 → #FF8D8E | #69C7FF → #3FB7FF |
| purple-pink | light | 1.04–1.33 | 0.575 | 0.300 → 0.300 | 0.635 → 0.604 | 0.585 → 0.517 | #8E229D → #A126B1 | #0050BD → #005AD5 |
| purple-pink | dark | 1.03–1.39 | 0.511 | 0.250 → 0.250 | 0.724 → 0.629 | 0.790 → 0.673 | #E981F7 → #E35FF5 | #31B2FF → #1AA9FF |
| purple-pink | light, increased contrast | 1.04–1.33 | 0.575 | 0.540 → 0.540 | 0.686 → 0.656 | 0.670 → 0.624 | #791D85 → #841F92 | #0044A0 → #004AAF |
| purple-pink | dark, increased contrast | 1.03–1.39 | 0.511 | 0.450 → 0.450 | 0.822 → 0.736 | 0.890 → 0.803 | #ED9BF9 → #E984F7 | #5EC2FF → #36B4FF |
| mint-cyan | light | 1.02–1.17 | 0.510 | 0.500 → 0.391 | 0.588 → 0.575 | 0.569 → 0.541 | #00766A → #007F72 | #0061E5 → #0067F4 |
| mint-cyan | dark | 1.04–1.47 | 0.556 | 0.181 → 0.181 | 0.830 → 0.690 | 1.000 → 0.704 | #00DAC3 → #00DAC3 | #65C5FF → #24ADFF |
| mint-cyan | light, increased contrast | 1.02–1.17 | 0.510 | 0.540 → 0.540 | 0.589 → 0.583 | 0.572 → 0.559 | #007569 → #00796D | #0060E3 → #0063EA |
| mint-cyan | dark, increased contrast | 1.03–1.34 | 0.497 | 0.257 → 0.257 | 0.847 → 0.741 | 0.961 → 0.740 | #00DAC3 → #00DAC3 | #6CC8FF → #3EB7FF |
| brown-yellow | light | 1.03–1.24 | 0.539 | 0.317 → 0.300 | 0.604 → 0.584 | 0.531 → 0.478 | #7C5B44 → #88654A | #005AD6 → #0063EB |
| brown-yellow | dark | 1.04–1.47 | 0.562 | 0.250 → 0.250 | 0.817 → 0.685 | 0.912 → 0.731 | #D2B69F → #C39E80 | #62C4FF → #24ADFF |
| brown-yellow | light, increased contrast | 1.03–1.24 | 0.539 | 0.540 → 0.540 | 0.634 → 0.617 | 0.596 → 0.561 | #6E513C → #755740 | #0050BE → #0056CB |
| brown-yellow | dark, increased contrast | 1.04–1.37 | 0.517 | 0.376 → 0.376 | 0.847 → 0.747 | 0.922 → 0.788 | #D5BAA5 → #CAA98F | #6EC8FF → #44B9FF |
The edge is the label's ink at that alpha over the column's fill: a mid grey, black at 0.50 to 0.58 in light and white at
0.50 to 0.58 in dark. Texts inside the column need less ink than on the frame, because the fill lies nearer the plain
background: secondary text is drawn at a lower alpha, and tinted text, the marker and the focus ring closer to their
raw hue. The selection fill is raised less in light for the light hues (orange, teal, mint, brown), because the
lighter fill already sets the row apart at 1.3:1.

### What changes in Oisillon's rendering

Oisillon draws its list column in `NavigationSplitView`'s sidebar today. Adopting `ColumnLayout` (or `ColumnSurface` in a
plain split item) replaces that sidebar's system glass with the kit's surface. It keeps the look Oisillon has now: darker
than the page in dark, lighter in light, the Space's colour coming through. Three things change:

- the sidebar's labels no longer dim when the window resigns key;
- the column gains a 3:1 edge and a 12 pt inset from the window's edges;
- the first row sits 24 pt under the window's top edge. The search field and the status line stay where Oisillon puts
  them inside the column.

Rows, pills and the switcher inside the column take inks solved on its fill: secondary text is a little quieter and
tinted text a little nearer the raw hue, and every one still reaches 4.5:1. A selected row's fill is
unchanged in dark and slightly lighter in light for orange-pink, teal-green, mint-cyan and brown-yellow. The marker
and the focus ring keep 3:1. The Space bar's tooltip now shows the shortcut Oisillon passes in each item
(`shortcut: "⌘1"` keeps today's text). Its space-change animation is `themeChange`, the same spec as its `spaceChange`.

### Legibility cases

798 new cases inside the column. For each of the seven Themes in each of the four appearances there are 27 cases:

- primary text on 7 surfaces: the column's fill, the hovered, current and selected rows, the folder panel, glass, and
  the switcher's selection;
- secondary text on 6 and tinted text on 6;
- the tinted glyph on 1;
- the focus ring on 5;
- the column's edge on 2: against the gradient and against the column's fill.

On top of those 27, the selection marker adds 1 case in light and dark, and the selection outline adds 2 under
Increase Contrast. Text or a symbol on the opaque hue is the same in and out of the column, so it stays with the frame's
cases.

"Before" is what the system's default colour reaches on the column's fill: the system's secondary label, the raw hue,
the translucent focus colour, the separator as the edge, and no marker. "After" is the kit's. None is under its
threshold now. Each case is a test (`LegibilityCaseTests`, recorded on macOS 27 in `Tests/DesignKitTests/RecordedCases.swift`;
regenerate with `DesignKitGallery audit`).

| Role | Cases | Under the threshold with the system's colour | With the kit's (lowest) |
|---|---|---|---|
| primary text | 196 | 0 | 0 (5.19:1) |
| secondary text | 168 | 130 | 0 (4.50:1) |
| tinted text | 168 | 149 | 0 (4.50:1) |
| tinted glyph | 28 | 10 | 0 (6.77:1) |
| focus ring | 140 | 140 | 0 (3.00:1) |
| selection marker | 14 | 14 | 0 (3.00:1) |
| selection outline | 28 | 28 | 0 (4.50:1) |
| column edge | 56 | 56 | 0 (3.00:1) |

## 0.2.2

A selected row can be found at 3:1 outside Increase Contrast, and a disabled `IconButton` looks disabled.

### Fixed

- **Selection marker.** 0.2.1 told a selected row apart by its fill (about 1.2 to 1.35:1 against the gradient under it)
  and a semibold title, which is under the 3:1 WCAG 1.4.11 asks of a state indicator. A selected `ListRow` (a
  `FolderRow` too) now draws a 3 pt capsule at the leading edge of its background, 2 pt in from the edge and 8 pt from
  the top and bottom, in `ColorRoles.selectionMarker`: the Theme's primary hue mixed with ink by the share that reaches
  3:1 on every surface a row sits on (the same solving as the focus ring), so it keeps the Theme's colour and stays
  quiet. Under Increase Contrast nothing changes: the selected row keeps its outline (`ColorRoles.outline`, 4.5:1) and
  draws no bar. The current, hovered and plain rows are unchanged.
- **Disabled `IconButton`.** Its plain button style (`PressedOpacityStyle`) kept full ink when disabled. It now draws
  the label at the new token `Emphasis.disabled` (0.4), measured offscreen at 0.4 of the enabled ink. Disabled controls
  have no contrast requirement (WCAG 1.4.3, 1.4.11); the dimming is what says "disabled". Any other button using
  `PressedOpacityStyle` (the `GlassSwitcher` items) dims the same way when disabled.

### Added

- `DesignKit`: `ColorRoles.selectionMarker`, `selectionMarkerRGBA`; tokens `Spacing.selectionMarkerLeading` (2),
  `Spacing.selectionMarkerVertical` (8), `Size.selectionMarker` (3), `Emphasis.disabled` (0.4);
  `LegibilityCase.Role.selectionMarker`.
- 14 legibility cases, `selectionMarker` on `selectedRow`, one per standard Theme in light and dark (Increase Contrast
  has the outline cases instead): 818 cases in all (804 + 14). `before` is how far the fill alone sets the row apart
  from what is under it (1.21 to 1.35:1), `after` the marker's contrast on the selected row's surfaces (3.00 to
  3.22:1). Tests also read the marker back from an offscreen render (at least 2.95:1 once rounded to 8-bit pixels; none
  under Increase Contrast), and the dimming of a disabled `IconButton`.
- The gallery's component sheet shows a disabled `IconButton`.

### Source-breaking changes

- `LegibilityCase.Role` gains `selectionMarker`. An exhaustive `switch` over it needs the new case or a `default`.
  Nothing else changes: no token value changed, no signature changed.

### Changed values

No token value changed; four tokens are new. The values drawn change as follows (0.2.1 → 0.2.2):

| What | 0.2.1 | 0.2.2 |
|---|---|---|
| Selected row, light and dark | fill only | fill and a 3 pt bar, 2 pt from its leading edge, 8 pt from its top and bottom |
| Selected row, Increase Contrast | fill and outline | unchanged |
| Disabled `IconButton` label (and any `PressedOpacityStyle` button) | full ink | ink at 0.4 |

The marker's colour (the primary hue mixed with ink), per Theme:

| Theme | Light | Dark |
|---|---|---|
| indigo-blue | #4C42BF | #A0AAFF |
| orange-pink | #9A5518 | #FFAB5F |
| teal-green | #00747C | #00D2E0 |
| red-orange | #AB2628 | #FF8C8E |
| purple-pink | #8E229D | #E981F7 |
| mint-cyan | #00766A | #00DAC3 |
| brown-yellow | #7C5B44 | #D2B69F |

### What changes in Oisillon's rendering

Nothing in Increase Contrast. Outside it, every selected row (the message list, a selected folder, a selected row in a
panel) gains the bar at its leading edge; the row's size, its content's position and the fills do not move (the bar
sits in the 8 pt between the background's edge and the tile). A disabled icon button, toolbar's back or forward say,
now reads at 0.4 opacity where it read at full ink. If the app draws its own marker, selection outline or disabled
dimming on these views, it can drop it.

## 0.2.1

Legibility fixes. Every text the kit draws reaches 4.5:1 and every glyph, focus ring and selection outline 3:1, on every
surface, for every standard Theme, in light, dark and both Increase Contrast appearances. Where 0.2.0 fell short the kit
now draws different values; no case is exempted.

### Fixed

- **Bright hues in dark.** 0.2.0 left 22 dark cases under 4.5:1 (orange-pink, teal-green, mint-cyan and brown-yellow
  under strong row, badge or tile fills): white text had no room left. `ColorRoles` now solves with the new
  `Legibility.fit`, which keeps the full opacities where every text passes and otherwise draws all of the Theme's hue
  opacities (gradient stops, hover, current, selection, badge and tile fills) at the largest common share that lets
  every text reach 4.5:1 (`ColorRoles.hueScale`). Shrinking every opacity by the same share keeps the order
  hover < current < selection and the gradient's shape. Every Theme keeps its full hue opacities in light; in dark only
  orange-pink, teal-green and mint-cyan are drawn lighter, and under Increase Contrast in dark every Theme but
  purple-pink.
- **Increase Contrast drew what the solver did not see.** The views multiplied the badge and tile fills by 1.8 under
  Increase Contrast, while the solver measured them unraised. Raising a fill under text lowers that text's contrast. So
  the views now draw the badge, tile and folder panel fills, and the switcher's fallback capsule, unraised. Outlines mark
  them instead. Only the row fills (hover, current, the selection's floor) are still raised, as the solver assumes.
- **The folder panel is a surface.** Rows inside an open folder sit on a `.primary` panel, which 0.2.0 did not measure.
  `Surfaces.neutralFills` describes it, so the solver measures the panel and every row fill on top of it.
- **Focus ring**: the system's focus colour drawn translucent fell to 1.5:1 on a tinted frame. `focusRing(_:in:)` now
  draws `ColorRoles.focusRing`, the same colour made opaque and mixed toward the ink until it reaches 3:1 on every
  surface a row sits on.
- **Selection outline** (Increase Contrast): the separator reached 1.2:1. Selected and current rows are now outlined in
  the secondary ink (`ColorRoles.outline`), which reaches 4.5:1 on the row and on the frame around it.
- **Glyphs**: the banner's symbol is drawn in the solved tint ink instead of the raw hue. A symbol on a solid colour (a
  `Tile` symbol, a `ThemeGlyph`, a `FieldPill`'s circle) is white, or black where white stays under 3:1. A
  `ThemeGlyph`'s initial is text, so it switches to black where white stays under 4.5:1. `ThemeGlyph` and the
  `FieldPill` circle are drawn in the flat hue: the system gradient lightens one end by about a quarter, and on indigo,
  blue or purple no ink then reaches 4.5:1 over the whole circle.

### Audited, no change needed

- **Placeholder text** (`FieldPill`) uses the secondary ink on glass. Glass is measured as anything between the plain
  window background (its Reduce Transparency fill) and the gradient under it. The secondary ink reaches 4.5:1 on both.
  `SkeletonRows` draw no text: they are redacted shapes with one VoiceOver label.
- **Disabled text**: the kit draws none. WCAG 2.x sets no contrast requirement for inactive controls (1.4.3, 1.4.11).
  Follow-up: `IconButton` shows no disabled state. Its plain button style keeps full ink when disabled (measured
  offscreen).
- **Inactive window**: the kit's inks are explicit colours and read no window state. A row renders pixel for pixel the
  same with `controlActiveState` key or inactive (`InactiveWindowTests`). The 2.6 to 2.8:1 measured in an inactive
  window on dimmed sidebar titles comes from the system: a sidebar split item (`NSSplitViewItem(sidebarWithViewController:)`)
  and its source list dim their labels when the window resigns key. A kit column should be hosted in a plain split item,
  not a system sidebar, to keep its contrast.
- **Profile or Space band**: `ColorRoles.bandFill` and `bandText` give the band's colour (the primary hue, opaque) and
  its text (white, or black where white stays under 4.5:1; never under 4.58:1). This is the rule an app's own band
  already used.

### Added

- `ColorCore`: `Legibility.fit(colors:surfaces:)`, `Legibility.hueScale`, `Legibility.surfaceLuminances`,
  `Legibility.mix(of:toward:reaching:)`, `Surfaces.neutralFills` (defaults to none), `Surfaces.scaled(by:)`,
  `Contrast.ink(on:minimum:)`.
- `ColorPlatform`: `Legibility.fitted(_:accents:surfaces:in:)` (cached like `of`), `RGBA.keyboardFocus(in:)`,
  `RGBA.separator(in:)`.
- `DesignKit`: `ColorRoles.hueScale`, `currentOpacity`, `tileOpacity`, `badgeOpacity`, `layerOpacity`, `outline`,
  `focusRing`, `focusRingRGBA`, `bandFill`, `bandText`, `primaryGlyph`, `ColorRoles.ink(on:in:minimum:)` (for a hue or
  any `Color`); tokens `Emphasis.nonTextContrast` (3) and `Emphasis.switcherTop` (0.85);
  `DesignTokens.symbolCases(in:)`; `legibilityCases(themeID:colors:focus:separator:in:)` gains the focus and separator
  colours (optional; without them those cases are left out).

### Source-breaking changes

- `LegibilityCase.Role` gains `primaryText`, `tintedGlyph`, `textOnHue`, `symbolOnHue`, `focusRing`,
  `selectionOutline`, and `LegibilityCase.SurfaceKind` gains `layerPanel`, `glass`, `switcherSelection`, `solidHue`.
  An exhaustive `switch` over them needs the new cases or a `default`. Nothing else changes: `Legibility.solve` solves
  as before when there are no neutral fills, and no token value changed.

### Changed values

Token values are unchanged. The values drawn change as follows (0.2.0 → 0.2.1; a single value is unchanged). The
fills below are opacities of the Theme's primary hue. The gradient is primary / secondary / primary.

| Theme | Appearance | Hue scale | Gradient top / middle / bottom | Hover | Current | Selection | Badge | Tile |
|---|---|---|---|---|---|---|---|---|
| indigo-blue | light, increased contrast | 1.000 | 0.380 / 0.160 / 0.050 | 0.180 | 0.288 | 0.540 | 0.252 → 0.140 | 0.450 → 0.250 |
| indigo-blue | dark, increased contrast | 0.986 | 0.420 → 0.414 / 0.180 → 0.178 / 0.060 → 0.059 | 0.180 → 0.178 | 0.288 → 0.284 | 0.450 → 0.444 | 0.252 → 0.138 | 0.450 → 0.247 |
| orange-pink | dark | 0.874 | 0.420 → 0.367 / 0.180 → 0.157 / 0.060 → 0.052 | 0.100 → 0.087 | 0.160 → 0.140 | 0.250 → 0.219 | 0.140 → 0.122 | 0.250 → 0.219 |
| orange-pink | light, increased contrast | 1.000 | 0.380 / 0.160 / 0.050 | 0.180 | 0.288 | 0.540 | 0.252 → 0.140 | 0.450 → 0.250 |
| orange-pink | dark, increased contrast | 0.676 | 0.420 → 0.284 / 0.180 → 0.122 / 0.060 → 0.041 | 0.180 → 0.122 | 0.288 → 0.195 | 0.450 → 0.304 | 0.252 → 0.095 | 0.450 → 0.169 |
| teal-green | dark | 0.752 | 0.420 → 0.316 / 0.180 → 0.135 / 0.060 → 0.045 | 0.100 → 0.075 | 0.160 → 0.120 | 0.250 → 0.188 | 0.140 → 0.105 | 0.250 → 0.188 |
| teal-green | light, increased contrast | 1.000 | 0.380 / 0.160 / 0.050 | 0.180 | 0.288 | 0.540 | 0.252 → 0.140 | 0.450 → 0.250 |
| teal-green | dark, increased contrast | 0.590 | 0.420 → 0.248 / 0.180 → 0.106 / 0.060 → 0.035 | 0.180 → 0.106 | 0.288 → 0.170 | 0.450 → 0.265 | 0.252 → 0.083 | 0.450 → 0.147 |
| red-orange | light, increased contrast | 1.000 | 0.380 / 0.160 / 0.050 | 0.180 | 0.288 | 0.540 | 0.252 → 0.140 | 0.450 → 0.250 |
| red-orange | dark, increased contrast | 0.990 | 0.420 → 0.416 / 0.180 → 0.178 / 0.060 → 0.059 | 0.180 → 0.178 | 0.288 → 0.285 | 0.450 → 0.446 | 0.252 → 0.139 | 0.450 → 0.248 |
| purple-pink | light, increased contrast | 1.000 | 0.380 / 0.160 / 0.050 | 0.180 | 0.288 | 0.540 | 0.252 → 0.140 | 0.450 → 0.250 |
| purple-pink | dark, increased contrast | 1.000 | 0.420 / 0.180 / 0.060 | 0.180 | 0.288 | 0.450 | 0.252 → 0.140 | 0.450 → 0.250 |
| mint-cyan | dark | 0.724 | 0.420 → 0.304 / 0.180 → 0.130 / 0.060 → 0.043 | 0.100 → 0.072 | 0.160 → 0.116 | 0.250 → 0.181 | 0.140 → 0.101 | 0.250 → 0.181 |
| mint-cyan | light, increased contrast | 1.000 | 0.380 / 0.160 / 0.050 | 0.180 | 0.288 | 0.540 | 0.252 → 0.140 | 0.450 → 0.250 |
| mint-cyan | dark, increased contrast | 0.570 | 0.420 → 0.240 / 0.180 → 0.103 / 0.060 → 0.034 | 0.180 → 0.103 | 0.288 → 0.164 | 0.450 → 0.257 | 0.252 → 0.080 | 0.450 → 0.143 |
| brown-yellow | light, increased contrast | 1.000 | 0.380 / 0.160 / 0.050 | 0.180 | 0.288 | 0.540 | 0.252 → 0.140 | 0.450 → 0.250 |
| brown-yellow | dark, increased contrast | 0.835 | 0.420 → 0.351 / 0.180 → 0.150 / 0.060 → 0.050 | 0.180 → 0.150 | 0.288 → 0.240 | 0.450 → 0.376 | 0.252 → 0.117 | 0.450 → 0.209 |

All other Theme and appearance pairs draw their 0.2.0 opacities.

The following also change, in every Theme and appearance:

| What | 0.2.0 | 0.2.1 |
|---|---|---|
| Badge fill, Increase Contrast | 0.14 × 1.8 = 0.252 | 0.14 (times the hue scale) |
| Tile fill, Increase Contrast | 0.25 × 1.8 = 0.45 | 0.25 (times the hue scale) |
| Folder panel (`.primary`), Increase Contrast | 0.06 × 1.8 = 0.108 | 0.06 |
| Switcher's selected capsule without glass, Increase Contrast | 0.35 × 1.8 = 0.63 | 0.35 |
| Selected or current row outline, Increase Contrast | `separatorColor` (label at 9.8 %) | `ColorRoles.outline` (the secondary ink) |
| Focus ring | `keyboardFocusIndicatorColor`, #0067F4 at 49.8 % (light), #1AA9FF at 49.8 % (dark) | that colour opaque, mixed toward the ink: e.g. #004FBC light and #45B9FF dark (indigo-blue), #0061E5 light and #65C5FF dark (mint-cyan) |
| Banner symbol | raw primary hue | `ColorRoles.tintText` |
| `Tile` symbol on a solid colour | white | white; black on orange, teal, green, mint, cyan, yellow (every appearance) |
| `FieldPill` circle | primary hue's gradient, white symbol | flat primary hue; black symbol on orange-pink, teal-green, mint-cyan |
| `ThemeGlyph` | primary hue's gradient, white symbol or initial | flat primary hue; black symbol on orange-pink, teal-green, mint-cyan; black initial on every standard Theme in dark, and on all but indigo-blue in light |

The solver's results per Theme and appearance (0.2.0 → 0.2.1). The secondary alpha and the tint ink share rise a little
in light too, because the folder panel is now one of the surfaces they are solved on:

| Theme | Appearance | Hue scale | Selection | Secondary text alpha | Tint ink share |
|---|---|---|---|---|---|
| indigo-blue | light | 1.000 | 0.300 | 0.619 → 0.638 | 0.512 → 0.561 |
| indigo-blue | dark | 1.000 | 0.250 | 0.691 → 0.752 | 0.731 → 0.810 |
| indigo-blue | light, increased contrast | 1.000 | 0.540 | 0.681 → 0.703 | 0.649 → 0.689 |
| indigo-blue | dark, increased contrast | 1.000 → 0.986 | 0.450 → 0.444 | 0.799 → 0.847 | 0.865 → 0.916 |
| orange-pink | light | 1.000 | 0.478 | 0.583 → 0.593 | 0.548 → 0.568 |
| orange-pink | dark | 1.000 → 0.874 | 0.250 → 0.219 | 0.840 → 0.838 | 1.000 → 0.999 |
| orange-pink | light, increased contrast | 1.000 | 0.540 | 0.587 → 0.596 | 0.557 → 0.575 |
| orange-pink | dark, increased contrast | 1.000 → 0.676 | 0.450 → 0.304 | 0.847 | 1.000 → 0.950 |
| teal-green | light | 1.000 | 0.500 | 0.581 → 0.589 | 0.551 → 0.570 |
| teal-green | dark | 1.000 → 0.752 | 0.250 → 0.188 | 0.847 → 0.832 | 1.000 |
| teal-green | light, increased contrast | 1.000 | 0.540 | 0.583 → 0.591 | 0.556 → 0.573 |
| teal-green | dark, increased contrast | 1.000 → 0.590 | 0.450 → 0.265 | 0.847 → 0.846 | 1.000 → 0.959 |
| red-orange | light | 1.000 | 0.300 | 0.606 → 0.623 | 0.544 → 0.580 |
| red-orange | dark | 1.000 | 0.250 | 0.700 → 0.748 | 0.765 → 0.822 |
| red-orange | light, increased contrast | 1.000 | 0.540 | 0.645 → 0.662 | 0.617 → 0.643 |
| red-orange | dark, increased contrast | 1.000 → 0.990 | 0.450 → 0.446 | 0.811 → 0.847 | 0.887 → 0.922 |
| purple-pink | light | 1.000 | 0.300 | 0.617 → 0.635 | 0.543 → 0.585 |
| purple-pink | dark | 1.000 | 0.250 | 0.679 → 0.724 | 0.734 → 0.790 |
| purple-pink | light, increased contrast | 1.000 | 0.540 | 0.666 → 0.686 | 0.639 → 0.670 |
| purple-pink | dark, increased contrast | 1.000 | 0.450 | 0.784 → 0.822 | 0.850 → 0.890 |
| mint-cyan | light | 1.000 | 0.500 | 0.579 → 0.588 | 0.551 → 0.569 |
| mint-cyan | dark | 1.000 → 0.724 | 0.250 → 0.181 | 0.847 → 0.830 | 1.000 |
| mint-cyan | light, increased contrast | 1.000 | 0.540 | 0.581 → 0.589 | 0.555 → 0.572 |
| mint-cyan | dark, increased contrast | 1.000 → 0.570 | 0.450 → 0.257 | 0.847 | 1.000 → 0.961 |
| brown-yellow | light | 1.000 | 0.317 | 0.590 → 0.604 | 0.496 → 0.531 |
| brown-yellow | dark | 1.000 | 0.250 | 0.748 → 0.817 | 0.823 → 0.912 |
| brown-yellow | light, increased contrast | 1.000 | 0.540 | 0.621 → 0.634 | 0.569 → 0.596 |
| brown-yellow | dark, increased contrast | 1.000 → 0.835 | 0.450 → 0.376 | 0.847 | 0.984 → 0.922 |

### Legibility cases

Each case is one role on one kind of surface, for one standard Theme (or, for a symbol on a solid colour, one system
hue) in one appearance. The ratio is the worst point of the surface. The 0.2.0 column is what 0.2.0 drew there; the
0.2.1 column is what the kit draws now. Thresholds are 4.5:1 for text and 3:1 for glyphs, focus rings and outlines.
Ratios were measured with the system colours of macOS 27 (accent colour blue). Each row is a test case
(`LegibilityCaseTests`, run on macOS 27). `LegibilityInvariantTests` checks every case against its threshold with
whatever colours the system gives.

804 cases: 728 for the seven Themes in four appearances (7 primary text, 6 secondary text, 6 tinted text, 1 tinted
glyph, 1 text on the hue and 5 focus ring cases each), 28 selection outline cases (Increase Contrast only) and 48 symbol
cases (twelve hues in four appearances). 367 were under their threshold as 0.2.0 drew them: the 22 that 0.2.0 listed,
plus 345 in roles and surfaces 0.2.0 did not measure. All 367 are fixed. None is under its threshold now.

| Role | Cases | Under the threshold in 0.2.0 | In 0.2.1 |
|---|---|---|---|
| primary text | 196 | 26 | 0 |
| secondary text | 168 | 51 | 0 |
| tinted text | 168 | 50 | 0 |
| tinted glyph | 28 | 22 | 0 |
| text on the hue | 28 | 26 | 0 |
| symbol on the hue | 48 | 24 | 0 |
| focus ring | 140 | 140 | 0 |
| selection outline | 28 | 28 | 0 |

The 367 cases fixed:

<details>
<summary>Fixed cases (367)</summary>

| Theme or hue | Appearance | Role | Surface | 0.2.0 | 0.2.1 | Threshold |
|---|---|---|---|---|---|---|
| indigo-blue | light | secondary text | selected row | 4.29:1 | 4.51:1 | 4.5:1 |
| indigo-blue | light | tinted text | badge or tile fill | 4.16:1 | 4.50:1 | 4.5:1 |
| indigo-blue | light | tinted glyph | glass | 2.94:1 | 7.64:1 | 3:1 |
| indigo-blue | light | focus ring | window gradient | 1.72:1 | 4.25:1 | 3:1 |
| indigo-blue | light | focus ring | hovered row | 1.61:1 | 3.66:1 | 3:1 |
| indigo-blue | light | focus ring | current row | 1.57:1 | 3.45:1 | 3:1 |
| indigo-blue | light | focus ring | selected row | 1.47:1 | 3.00:1 | 3:1 |
| indigo-blue | light | focus ring | folder panel | 1.69:1 | 4.03:1 | 3:1 |
| indigo-blue | dark | secondary text | current row | 4.35:1 | 4.82:1 | 4.5:1 |
| indigo-blue | dark | secondary text | selected row | 4.08:1 | 4.50:1 | 4.5:1 |
| indigo-blue | dark | tinted text | badge or tile fill | 4.11:1 | 4.50:1 | 4.5:1 |
| indigo-blue | dark | tinted glyph | glass | 2.52:1 | 7.19:1 | 3:1 |
| indigo-blue | dark | text on the hue | the hue, opaque | 3.51:1 | 5.98:1 | 4.5:1 |
| indigo-blue | dark | focus ring | window gradient | 1.90:1 | 4.08:1 | 3:1 |
| indigo-blue | dark | focus ring | hovered row | 1.72:1 | 3.42:1 | 3:1 |
| indigo-blue | dark | focus ring | current row | 1.67:1 | 3.25:1 | 3:1 |
| indigo-blue | dark | focus ring | selected row | 1.60:1 | 3.00:1 | 3:1 |
| indigo-blue | dark | focus ring | folder panel | 1.81:1 | 3.73:1 | 3:1 |
| indigo-blue | light, increased contrast | secondary text | selected row | 4.15:1 | 4.51:1 | 4.5:1 |
| indigo-blue | light, increased contrast | tinted text | badge or tile fill | 3.74:1 | 4.50:1 | 4.5:1 |
| indigo-blue | light, increased contrast | tinted glyph | glass | 2.94:1 | 9.24:1 | 3:1 |
| indigo-blue | light, increased contrast | focus ring | window gradient | 1.72:1 | 5.45:1 | 3:1 |
| indigo-blue | light, increased contrast | focus ring | hovered row | 1.49:1 | 4.34:1 | 3:1 |
| indigo-blue | light, increased contrast | focus ring | current row | 1.42:1 | 3.90:1 | 3:1 |
| indigo-blue | light, increased contrast | focus ring | selected row | 1.27:1 | 3.00:1 | 3:1 |
| indigo-blue | light, increased contrast | focus ring | folder panel | 1.61:1 | 5.17:1 | 3:1 |
| indigo-blue | light, increased contrast | selection outline | current row | 1.22:1 | 5.34:1 | 3:1 |
| indigo-blue | light, increased contrast | selection outline | selected row | 1.20:1 | 4.51:1 | 3:1 |
| indigo-blue | dark, increased contrast | primary text | selected row | 4.19:1 | 4.50:1 | 4.5:1 |
| indigo-blue | dark, increased contrast | secondary text | current row | 4.35:1 | 5.11:1 | 4.5:1 |
| indigo-blue | dark, increased contrast | secondary text | selected row | 3.92:1 | 4.50:1 | 4.5:1 |
| indigo-blue | dark, increased contrast | tinted text | selected row | 4.42:1 | 5.06:1 | 4.5:1 |
| indigo-blue | dark, increased contrast | tinted text | badge or tile fill | 3.72:1 | 4.50:1 | 4.5:1 |
| indigo-blue | dark, increased contrast | tinted glyph | glass | 2.52:1 | 8.18:1 | 3:1 |
| indigo-blue | dark, increased contrast | text on the hue | the hue, opaque | 3.51:1 | 5.98:1 | 4.5:1 |
| indigo-blue | dark, increased contrast | focus ring | window gradient | 1.90:1 | 4.85:1 | 3:1 |
| indigo-blue | dark, increased contrast | focus ring | hovered row | 1.56:1 | 3.79:1 | 3:1 |
| indigo-blue | dark, increased contrast | focus ring | current row | 1.49:1 | 3.45:1 | 3:1 |
| indigo-blue | dark, increased contrast | focus ring | selected row | 1.40:1 | 3.00:1 | 3:1 |
| indigo-blue | dark, increased contrast | focus ring | folder panel | 1.67:1 | 4.43:1 | 3:1 |
| indigo-blue | dark, increased contrast | selection outline | current row | 1.24:1 | 5.11:1 | 3:1 |
| indigo-blue | dark, increased contrast | selection outline | selected row | 1.22:1 | 4.50:1 | 3:1 |
| orange-pink | light | secondary text | selected row | 4.38:1 | 4.50:1 | 4.5:1 |
| orange-pink | light | tinted text | selected row | 4.49:1 | 4.75:1 | 4.5:1 |
| orange-pink | light | tinted text | badge or tile fill | 4.26:1 | 4.50:1 | 4.5:1 |
| orange-pink | light | tinted glyph | glass | 1.68:1 | 6.52:1 | 3:1 |
| orange-pink | light | text on the hue | the hue, opaque | 2.31:1 | 9.09:1 | 4.5:1 |
| orange-pink | light | focus ring | window gradient | 1.98:1 | 4.12:1 | 3:1 |
| orange-pink | light | focus ring | hovered row | 1.87:1 | 3.53:1 | 3:1 |
| orange-pink | light | focus ring | current row | 1.86:1 | 3.44:1 | 3:1 |
| orange-pink | light | focus ring | selected row | 1.82:1 | 3.00:1 | 3:1 |
| orange-pink | light | focus ring | folder panel | 1.89:1 | 3.69:1 | 3:1 |
| orange-pink | dark | primary text | selected row | 4.12:1 | 4.56:1 | 4.5:1 |
| orange-pink | dark | secondary text | selected row | 4.09:1 | 4.50:1 | 4.5:1 |
| orange-pink | dark | tinted text | badge or tile fill | 4.04:1 | 4.50:1 | 4.5:1 |
| orange-pink | dark | text on the hue | the hue, opaque | 2.23:1 | 9.41:1 | 4.5:1 |
| orange-pink | dark | focus ring | window gradient | 1.53:1 | 4.21:1 | 3:1 |
| orange-pink | dark | focus ring | hovered row | 1.41:1 | 3.58:1 | 3:1 |
| orange-pink | dark | focus ring | current row | 1.35:1 | 3.33:1 | 3:1 |
| orange-pink | dark | focus ring | selected row | 1.26:1 | 3.00:1 | 3:1 |
| orange-pink | dark | focus ring | folder panel | 1.53:1 | 4.03:1 | 3:1 |
| orange-pink | light, increased contrast | secondary text | hovered row | 4.48:1 | 4.77:1 | 4.5:1 |
| orange-pink | light, increased contrast | secondary text | current row | 4.42:1 | 4.69:1 | 4.5:1 |
| orange-pink | light, increased contrast | secondary text | selected row | 4.29:1 | 4.50:1 | 4.5:1 |
| orange-pink | light, increased contrast | tinted text | selected row | 4.25:1 | 4.72:1 | 4.5:1 |
| orange-pink | light, increased contrast | tinted text | badge or tile fill | 4.01:1 | 4.50:1 | 4.5:1 |
| orange-pink | light, increased contrast | tinted glyph | glass | 1.68:1 | 6.64:1 | 3:1 |
| orange-pink | light, increased contrast | text on the hue | the hue, opaque | 2.31:1 | 9.09:1 | 4.5:1 |
| orange-pink | light, increased contrast | focus ring | window gradient | 1.98:1 | 4.23:1 | 3:1 |
| orange-pink | light, increased contrast | focus ring | hovered row | 1.79:1 | 3.49:1 | 3:1 |
| orange-pink | light, increased contrast | focus ring | current row | 1.78:1 | 3.33:1 | 3:1 |
| orange-pink | light, increased contrast | focus ring | selected row | 1.77:1 | 3.00:1 | 3:1 |
| orange-pink | light, increased contrast | focus ring | folder panel | 1.81:1 | 3.78:1 | 3:1 |
| orange-pink | light, increased contrast | selection outline | current row | 1.23:1 | 4.69:1 | 3:1 |
| orange-pink | light, increased contrast | selection outline | selected row | 1.23:1 | 4.50:1 | 3:1 |
| orange-pink | dark, increased contrast | primary text | hovered row | 4.09:1 | 5.78:1 | 4.5:1 |
| orange-pink | dark, increased contrast | primary text | current row | 3.68:1 | 5.22:1 | 4.5:1 |
| orange-pink | dark, increased contrast | primary text | selected row | 3.16:1 | 4.50:1 | 4.5:1 |
| orange-pink | dark, increased contrast | primary text | switcher selection | 3.49:1 | 5.99:1 | 4.5:1 |
| orange-pink | dark, increased contrast | secondary text | hovered row | 4.09:1 | 5.78:1 | 4.5:1 |
| orange-pink | dark, increased contrast | secondary text | current row | 3.68:1 | 5.22:1 | 4.5:1 |
| orange-pink | dark, increased contrast | secondary text | selected row | 3.16:1 | 4.50:1 | 4.5:1 |
| orange-pink | dark, increased contrast | tinted text | current row | 4.44:1 | 6.28:1 | 4.5:1 |
| orange-pink | dark, increased contrast | tinted text | selected row | 3.75:1 | 5.33:1 | 4.5:1 |
| orange-pink | dark, increased contrast | tinted text | badge or tile fill | 2.94:1 | 4.50:1 | 4.5:1 |
| orange-pink | dark, increased contrast | text on the hue | the hue, opaque | 2.23:1 | 9.41:1 | 4.5:1 |
| orange-pink | dark, increased contrast | focus ring | window gradient | 1.53:1 | 5.14:1 | 3:1 |
| orange-pink | dark, increased contrast | focus ring | hovered row | 1.27:1 | 3.94:1 | 3:1 |
| orange-pink | dark, increased contrast | focus ring | current row | 1.18:1 | 3.53:1 | 3:1 |
| orange-pink | dark, increased contrast | focus ring | selected row | 1.06:1 | 3.00:1 | 3:1 |
| orange-pink | dark, increased contrast | focus ring | folder panel | 1.44:1 | 4.74:1 | 3:1 |
| orange-pink | dark, increased contrast | selection outline | current row | 1.19:1 | 5.22:1 | 3:1 |
| orange-pink | dark, increased contrast | selection outline | selected row | 1.16:1 | 4.50:1 | 3:1 |
| teal-green | light | secondary text | selected row | 4.39:1 | 4.50:1 | 4.5:1 |
| teal-green | light | tinted text | selected row | 4.46:1 | 4.71:1 | 4.5:1 |
| teal-green | light | tinted text | badge or tile fill | 4.27:1 | 4.51:1 | 4.5:1 |
| teal-green | light | tinted glyph | glass | 1.57:1 | 6.33:1 | 3:1 |
| teal-green | light | text on the hue | the hue, opaque | 2.16:1 | 9.72:1 | 4.5:1 |
| teal-green | light | focus ring | window gradient | 1.86:1 | 4.04:1 | 3:1 |
| teal-green | light | focus ring | hovered row | 1.76:1 | 3.52:1 | 3:1 |
| teal-green | light | focus ring | current row | 1.74:1 | 3.43:1 | 3:1 |
| teal-green | light | focus ring | selected row | 1.63:1 | 3.00:1 | 3:1 |
| teal-green | light | focus ring | folder panel | 1.80:1 | 3.68:1 | 3:1 |
| teal-green | dark | primary text | hovered row | 4.41:1 | 5.44:1 | 4.5:1 |
| teal-green | dark | primary text | current row | 4.09:1 | 5.09:1 | 4.5:1 |
| teal-green | dark | primary text | selected row | 3.67:1 | 4.60:1 | 4.5:1 |
| teal-green | dark | secondary text | hovered row | 4.41:1 | 5.31:1 | 4.5:1 |
| teal-green | dark | secondary text | current row | 4.09:1 | 4.97:1 | 4.5:1 |
| teal-green | dark | secondary text | selected row | 3.67:1 | 4.50:1 | 4.5:1 |
| teal-green | dark | tinted text | selected row | 4.45:1 | 5.71:1 | 4.5:1 |
| teal-green | dark | tinted text | badge or tile fill | 3.50:1 | 4.50:1 | 4.5:1 |
| teal-green | dark | text on the hue | the hue, opaque | 1.86:1 | 11.30:1 | 4.5:1 |
| teal-green | dark | focus ring | window gradient | 1.61:1 | 4.35:1 | 3:1 |
| teal-green | dark | focus ring | hovered row | 1.47:1 | 3.60:1 | 3:1 |
| teal-green | dark | focus ring | current row | 1.41:1 | 3.35:1 | 3:1 |
| teal-green | dark | focus ring | selected row | 1.32:1 | 3.00:1 | 3:1 |
| teal-green | dark | focus ring | folder panel | 1.59:1 | 4.06:1 | 3:1 |
| teal-green | light, increased contrast | secondary text | hovered row | 4.47:1 | 4.74:1 | 4.5:1 |
| teal-green | light, increased contrast | secondary text | current row | 4.41:1 | 4.67:1 | 4.5:1 |
| teal-green | light, increased contrast | secondary text | selected row | 4.31:1 | 4.51:1 | 4.5:1 |
| teal-green | light, increased contrast | tinted text | selected row | 4.23:1 | 4.68:1 | 4.5:1 |
| teal-green | light, increased contrast | tinted text | badge or tile fill | 4.04:1 | 4.50:1 | 4.5:1 |
| teal-green | light, increased contrast | tinted glyph | glass | 1.57:1 | 6.39:1 | 3:1 |
| teal-green | light, increased contrast | text on the hue | the hue, opaque | 2.16:1 | 9.72:1 | 4.5:1 |
| teal-green | light, increased contrast | focus ring | window gradient | 1.86:1 | 4.10:1 | 3:1 |
| teal-green | light, increased contrast | focus ring | hovered row | 1.67:1 | 3.45:1 | 3:1 |
| teal-green | light, increased contrast | focus ring | current row | 1.64:1 | 3.30:1 | 3:1 |
| teal-green | light, increased contrast | focus ring | selected row | 1.58:1 | 3.00:1 | 3:1 |
| teal-green | light, increased contrast | focus ring | folder panel | 1.73:1 | 3.73:1 | 3:1 |
| teal-green | light, increased contrast | selection outline | current row | 1.23:1 | 4.67:1 | 3:1 |
| teal-green | light, increased contrast | selection outline | selected row | 1.23:1 | 4.51:1 | 3:1 |
| teal-green | dark, increased contrast | primary text | hovered row | 3.70:1 | 5.82:1 | 4.5:1 |
| teal-green | dark, increased contrast | primary text | current row | 3.29:1 | 5.25:1 | 4.5:1 |
| teal-green | dark, increased contrast | primary text | selected row | 2.77:1 | 4.51:1 | 4.5:1 |
| teal-green | dark, increased contrast | primary text | switcher selection | 3.00:1 | 5.49:1 | 4.5:1 |
| teal-green | dark, increased contrast | secondary text | hovered row | 3.70:1 | 5.82:1 | 4.5:1 |
| teal-green | dark, increased contrast | secondary text | current row | 3.29:1 | 5.25:1 | 4.5:1 |
| teal-green | dark, increased contrast | secondary text | selected row | 2.77:1 | 4.50:1 | 4.5:1 |
| teal-green | dark, increased contrast | tinted text | hovered row | 4.48:1 | 7.14:1 | 4.5:1 |
| teal-green | dark, increased contrast | tinted text | current row | 3.94:1 | 6.39:1 | 4.5:1 |
| teal-green | dark, increased contrast | tinted text | selected row | 3.28:1 | 5.41:1 | 4.5:1 |
| teal-green | dark, increased contrast | tinted text | badge or tile fill | 2.51:1 | 4.50:1 | 4.5:1 |
| teal-green | dark, increased contrast | text on the hue | the hue, opaque | 1.86:1 | 11.30:1 | 4.5:1 |
| teal-green | dark, increased contrast | focus ring | window gradient | 1.61:1 | 5.28:1 | 3:1 |
| teal-green | dark, increased contrast | focus ring | hovered row | 1.32:1 | 3.96:1 | 3:1 |
| teal-green | dark, increased contrast | focus ring | current row | 1.24:1 | 3.54:1 | 3:1 |
| teal-green | dark, increased contrast | focus ring | selected row | 1.12:1 | 3.00:1 | 3:1 |
| teal-green | dark, increased contrast | focus ring | folder panel | 1.49:1 | 4.77:1 | 3:1 |
| teal-green | dark, increased contrast | selection outline | current row | 1.16:1 | 5.25:1 | 3:1 |
| teal-green | dark, increased contrast | selection outline | selected row | 1.13:1 | 4.50:1 | 3:1 |
| red-orange | light | secondary text | selected row | 4.31:1 | 4.51:1 | 4.5:1 |
| red-orange | light | tinted text | badge or tile fill | 4.17:1 | 4.50:1 | 4.5:1 |
| red-orange | light | tinted glyph | glass | 2.11:1 | 7.02:1 | 3:1 |
| red-orange | light | text on the hue | the hue, opaque | 3.57:1 | 5.88:1 | 4.5:1 |
| red-orange | light | focus ring | window gradient | 1.85:1 | 4.07:1 | 3:1 |
| red-orange | light | focus ring | hovered row | 1.76:1 | 3.56:1 | 3:1 |
| red-orange | light | focus ring | current row | 1.73:1 | 3.38:1 | 3:1 |
| red-orange | light | focus ring | selected row | 1.68:1 | 3.00:1 | 3:1 |
| red-orange | light | focus ring | folder panel | 1.80:1 | 3.88:1 | 3:1 |
| red-orange | dark | secondary text | current row | 4.45:1 | 4.84:1 | 4.5:1 |
| red-orange | dark | secondary text | selected row | 4.15:1 | 4.50:1 | 4.5:1 |
| red-orange | dark | tinted text | badge or tile fill | 4.17:1 | 4.51:1 | 4.5:1 |
| red-orange | dark | tinted glyph | glass | 2.68:1 | 7.32:1 | 3:1 |
| red-orange | dark | text on the hue | the hue, opaque | 3.43:1 | 6.12:1 | 4.5:1 |
| red-orange | dark | focus ring | window gradient | 1.68:1 | 4.11:1 | 3:1 |
| red-orange | dark | focus ring | hovered row | 1.55:1 | 3.43:1 | 3:1 |
| red-orange | dark | focus ring | current row | 1.49:1 | 3.25:1 | 3:1 |
| red-orange | dark | focus ring | selected row | 1.40:1 | 3.00:1 | 3:1 |
| red-orange | dark | focus ring | folder panel | 1.66:1 | 3.74:1 | 3:1 |
| red-orange | light, increased contrast | secondary text | selected row | 4.20:1 | 4.50:1 | 4.5:1 |
| red-orange | light, increased contrast | tinted text | selected row | 4.38:1 | 4.87:1 | 4.5:1 |
| red-orange | light, increased contrast | tinted text | badge or tile fill | 3.92:1 | 4.50:1 | 4.5:1 |
| red-orange | light, increased contrast | tinted glyph | glass | 2.11:1 | 7.96:1 | 3:1 |
| red-orange | light, increased contrast | text on the hue | the hue, opaque | 3.57:1 | 5.88:1 | 4.5:1 |
| red-orange | light, increased contrast | focus ring | window gradient | 1.85:1 | 4.91:1 | 3:1 |
| red-orange | light, increased contrast | focus ring | hovered row | 1.66:1 | 4.00:1 | 3:1 |
| red-orange | light, increased contrast | focus ring | current row | 1.63:1 | 3.66:1 | 3:1 |
| red-orange | light, increased contrast | focus ring | selected row | 1.59:1 | 3.00:1 | 3:1 |
| red-orange | light, increased contrast | focus ring | folder panel | 1.72:1 | 4.68:1 | 3:1 |
| red-orange | light, increased contrast | selection outline | current row | 1.22:1 | 5.01:1 | 3:1 |
| red-orange | light, increased contrast | selection outline | selected row | 1.21:1 | 4.50:1 | 3:1 |
| red-orange | dark, increased contrast | primary text | selected row | 4.24:1 | 4.50:1 | 4.5:1 |
| red-orange | dark, increased contrast | secondary text | selected row | 4.02:1 | 4.50:1 | 4.5:1 |
| red-orange | dark, increased contrast | tinted text | badge or tile fill | 3.76:1 | 4.51:1 | 4.5:1 |
| red-orange | dark, increased contrast | tinted glyph | glass | 2.68:1 | 8.39:1 | 3:1 |
| red-orange | dark, increased contrast | text on the hue | the hue, opaque | 3.43:1 | 6.12:1 | 4.5:1 |
| red-orange | dark, increased contrast | focus ring | window gradient | 1.68:1 | 4.93:1 | 3:1 |
| red-orange | dark, increased contrast | focus ring | hovered row | 1.40:1 | 3.83:1 | 3:1 |
| red-orange | dark, increased contrast | focus ring | current row | 1.31:1 | 3.48:1 | 3:1 |
| red-orange | dark, increased contrast | focus ring | selected row | 1.19:1 | 3.00:1 | 3:1 |
| red-orange | dark, increased contrast | focus ring | folder panel | 1.56:1 | 4.48:1 | 3:1 |
| red-orange | dark, increased contrast | selection outline | current row | 1.22:1 | 5.17:1 | 3:1 |
| red-orange | dark, increased contrast | selection outline | selected row | 1.19:1 | 4.50:1 | 3:1 |
| purple-pink | light | secondary text | selected row | 4.30:1 | 4.51:1 | 4.5:1 |
| purple-pink | light | tinted text | badge or tile fill | 4.17:1 | 4.51:1 | 4.5:1 |
| purple-pink | light | tinted glyph | glass | 2.40:1 | 7.38:1 | 3:1 |
| purple-pink | light | text on the hue | the hue, opaque | 4.17:1 | 5.04:1 | 4.5:1 |
| purple-pink | light | focus ring | window gradient | 1.77:1 | 4.21:1 | 3:1 |
| purple-pink | light | focus ring | hovered row | 1.67:1 | 3.61:1 | 3:1 |
| purple-pink | light | focus ring | current row | 1.64:1 | 3.42:1 | 3:1 |
| purple-pink | light | focus ring | selected row | 1.56:1 | 3.00:1 | 3:1 |
| purple-pink | light | focus ring | folder panel | 1.73:1 | 3.96:1 | 3:1 |
| purple-pink | dark | secondary text | current row | 4.45:1 | 4.83:1 | 4.5:1 |
| purple-pink | dark | secondary text | selected row | 4.16:1 | 4.50:1 | 4.5:1 |
| purple-pink | dark | tinted text | badge or tile fill | 4.17:1 | 4.50:1 | 4.5:1 |
| purple-pink | dark | tinted glyph | glass | 2.61:1 | 7.15:1 | 3:1 |
| purple-pink | dark | text on the hue | the hue, opaque | 3.63:1 | 5.79:1 | 4.5:1 |
| purple-pink | dark | focus ring | window gradient | 1.78:1 | 4.02:1 | 3:1 |
| purple-pink | dark | focus ring | hovered row | 1.64:1 | 3.42:1 | 3:1 |
| purple-pink | dark | focus ring | current row | 1.58:1 | 3.25:1 | 3:1 |
| purple-pink | dark | focus ring | selected row | 1.49:1 | 3.00:1 | 3:1 |
| purple-pink | dark | focus ring | folder panel | 1.74:1 | 3.73:1 | 3:1 |
| purple-pink | light, increased contrast | secondary text | selected row | 4.18:1 | 4.50:1 | 4.5:1 |
| purple-pink | light, increased contrast | tinted text | selected row | 4.44:1 | 4.95:1 | 4.5:1 |
| purple-pink | light, increased contrast | tinted text | badge or tile fill | 3.86:1 | 4.50:1 | 4.5:1 |
| purple-pink | light, increased contrast | tinted glyph | glass | 2.40:1 | 8.56:1 | 3:1 |
| purple-pink | light, increased contrast | text on the hue | the hue, opaque | 4.17:1 | 5.04:1 | 4.5:1 |
| purple-pink | light, increased contrast | focus ring | window gradient | 1.77:1 | 5.19:1 | 3:1 |
| purple-pink | light, increased contrast | focus ring | hovered row | 1.56:1 | 4.14:1 | 3:1 |
| purple-pink | light, increased contrast | focus ring | current row | 1.51:1 | 3.75:1 | 3:1 |
| purple-pink | light, increased contrast | focus ring | selected row | 1.41:1 | 3.00:1 | 3:1 |
| purple-pink | light, increased contrast | focus ring | folder panel | 1.65:1 | 4.89:1 | 3:1 |
| purple-pink | light, increased contrast | selection outline | current row | 1.22:1 | 5.15:1 | 3:1 |
| purple-pink | light, increased contrast | selection outline | selected row | 1.21:1 | 4.50:1 | 3:1 |
| purple-pink | dark, increased contrast | primary text | selected row | 4.44:1 | 4.68:1 | 4.5:1 |
| purple-pink | dark, increased contrast | secondary text | selected row | 4.03:1 | 4.50:1 | 4.5:1 |
| purple-pink | dark, increased contrast | tinted text | badge or tile fill | 3.75:1 | 4.51:1 | 4.5:1 |
| purple-pink | dark, increased contrast | tinted glyph | glass | 2.61:1 | 8.19:1 | 3:1 |
| purple-pink | dark, increased contrast | text on the hue | the hue, opaque | 3.63:1 | 5.79:1 | 4.5:1 |
| purple-pink | dark, increased contrast | focus ring | window gradient | 1.78:1 | 4.82:1 | 3:1 |
| purple-pink | dark, increased contrast | focus ring | hovered row | 1.49:1 | 3.83:1 | 3:1 |
| purple-pink | dark, increased contrast | focus ring | current row | 1.40:1 | 3.47:1 | 3:1 |
| purple-pink | dark, increased contrast | focus ring | selected row | 1.28:1 | 3.00:1 | 3:1 |
| purple-pink | dark, increased contrast | focus ring | folder panel | 1.63:1 | 4.47:1 | 3:1 |
| purple-pink | dark, increased contrast | selection outline | current row | 1.22:1 | 5.16:1 | 3:1 |
| purple-pink | dark, increased contrast | selection outline | selected row | 1.19:1 | 4.50:1 | 3:1 |
| mint-cyan | light | secondary text | selected row | 4.39:1 | 4.51:1 | 4.5:1 |
| mint-cyan | light | tinted text | selected row | 4.46:1 | 4.70:1 | 4.5:1 |
| mint-cyan | light | tinted text | badge or tile fill | 4.28:1 | 4.51:1 | 4.5:1 |
| mint-cyan | light | tinted glyph | glass | 1.55:1 | 6.28:1 | 3:1 |
| mint-cyan | light | text on the hue | the hue, opaque | 2.12:1 | 9.91:1 | 4.5:1 |
| mint-cyan | light | focus ring | window gradient | 1.87:1 | 4.01:1 | 3:1 |
| mint-cyan | light | focus ring | hovered row | 1.77:1 | 3.50:1 | 3:1 |
| mint-cyan | light | focus ring | current row | 1.75:1 | 3.41:1 | 3:1 |
| mint-cyan | light | focus ring | selected row | 1.65:1 | 3.00:1 | 3:1 |
| mint-cyan | light | focus ring | folder panel | 1.81:1 | 3.65:1 | 3:1 |
| mint-cyan | dark | primary text | hovered row | 4.29:1 | 5.46:1 | 4.5:1 |
| mint-cyan | dark | primary text | current row | 3.97:1 | 5.10:1 | 4.5:1 |
| mint-cyan | dark | primary text | selected row | 3.55:1 | 4.62:1 | 4.5:1 |
| mint-cyan | dark | secondary text | hovered row | 4.29:1 | 5.31:1 | 4.5:1 |
| mint-cyan | dark | secondary text | current row | 3.97:1 | 4.97:1 | 4.5:1 |
| mint-cyan | dark | secondary text | selected row | 3.55:1 | 4.50:1 | 4.5:1 |
| mint-cyan | dark | tinted text | selected row | 4.30:1 | 5.72:1 | 4.5:1 |
| mint-cyan | dark | tinted text | badge or tile fill | 3.37:1 | 4.50:1 | 4.5:1 |
| mint-cyan | dark | text on the hue | the hue, opaque | 1.78:1 | 11.82:1 | 4.5:1 |
| mint-cyan | dark | focus ring | window gradient | 1.58:1 | 4.38:1 | 3:1 |
| mint-cyan | dark | focus ring | hovered row | 1.45:1 | 3.60:1 | 3:1 |
| mint-cyan | dark | focus ring | current row | 1.38:1 | 3.35:1 | 3:1 |
| mint-cyan | dark | focus ring | selected row | 1.29:1 | 3.00:1 | 3:1 |
| mint-cyan | dark | focus ring | folder panel | 1.56:1 | 4.07:1 | 3:1 |
| mint-cyan | light, increased contrast | secondary text | hovered row | 4.45:1 | 4.72:1 | 4.5:1 |
| mint-cyan | light, increased contrast | secondary text | current row | 4.40:1 | 4.65:1 | 4.5:1 |
| mint-cyan | light, increased contrast | secondary text | selected row | 4.31:1 | 4.50:1 | 4.5:1 |
| mint-cyan | light, increased contrast | tinted text | current row | 4.49:1 | 5.12:1 | 4.5:1 |
| mint-cyan | light, increased contrast | tinted text | selected row | 4.22:1 | 4.67:1 | 4.5:1 |
| mint-cyan | light, increased contrast | tinted text | badge or tile fill | 4.05:1 | 4.50:1 | 4.5:1 |
| mint-cyan | light, increased contrast | tinted glyph | glass | 1.55:1 | 6.33:1 | 3:1 |
| mint-cyan | light, increased contrast | text on the hue | the hue, opaque | 2.12:1 | 9.91:1 | 4.5:1 |
| mint-cyan | light, increased contrast | focus ring | window gradient | 1.87:1 | 4.07:1 | 3:1 |
| mint-cyan | light, increased contrast | focus ring | hovered row | 1.68:1 | 3.43:1 | 3:1 |
| mint-cyan | light, increased contrast | focus ring | current row | 1.65:1 | 3.29:1 | 3:1 |
| mint-cyan | light, increased contrast | focus ring | selected row | 1.60:1 | 3.00:1 | 3:1 |
| mint-cyan | light, increased contrast | focus ring | folder panel | 1.73:1 | 3.70:1 | 3:1 |
| mint-cyan | light, increased contrast | selection outline | current row | 1.23:1 | 4.65:1 | 3:1 |
| mint-cyan | light, increased contrast | selection outline | selected row | 1.23:1 | 4.50:1 | 3:1 |
| mint-cyan | dark, increased contrast | primary text | hovered row | 3.59:1 | 5.82:1 | 4.5:1 |
| mint-cyan | dark, increased contrast | primary text | current row | 3.19:1 | 5.25:1 | 4.5:1 |
| mint-cyan | dark, increased contrast | primary text | selected row | 2.68:1 | 4.50:1 | 4.5:1 |
| mint-cyan | dark, increased contrast | primary text | folder panel | 4.41:1 | 6.91:1 | 4.5:1 |
| mint-cyan | dark, increased contrast | primary text | switcher selection | 2.90:1 | 5.36:1 | 4.5:1 |
| mint-cyan | dark, increased contrast | secondary text | hovered row | 3.59:1 | 5.82:1 | 4.5:1 |
| mint-cyan | dark, increased contrast | secondary text | current row | 3.19:1 | 5.25:1 | 4.5:1 |
| mint-cyan | dark, increased contrast | secondary text | selected row | 2.68:1 | 4.50:1 | 4.5:1 |
| mint-cyan | dark, increased contrast | secondary text | folder panel | 4.41:1 | 6.91:1 | 4.5:1 |
| mint-cyan | dark, increased contrast | tinted text | hovered row | 4.34:1 | 7.16:1 | 4.5:1 |
| mint-cyan | dark, increased contrast | tinted text | current row | 3.81:1 | 6.40:1 | 4.5:1 |
| mint-cyan | dark, increased contrast | tinted text | selected row | 3.16:1 | 5.42:1 | 4.5:1 |
| mint-cyan | dark, increased contrast | tinted text | badge or tile fill | 2.41:1 | 4.50:1 | 4.5:1 |
| mint-cyan | dark, increased contrast | text on the hue | the hue, opaque | 1.78:1 | 11.82:1 | 4.5:1 |
| mint-cyan | dark, increased contrast | focus ring | window gradient | 1.58:1 | 5.31:1 | 3:1 |
| mint-cyan | dark, increased contrast | focus ring | hovered row | 1.30:1 | 3.97:1 | 3:1 |
| mint-cyan | dark, increased contrast | focus ring | current row | 1.21:1 | 3.54:1 | 3:1 |
| mint-cyan | dark, increased contrast | focus ring | selected row | 1.10:1 | 3.00:1 | 3:1 |
| mint-cyan | dark, increased contrast | focus ring | folder panel | 1.46:1 | 4.78:1 | 3:1 |
| mint-cyan | dark, increased contrast | selection outline | current row | 1.16:1 | 5.25:1 | 3:1 |
| mint-cyan | dark, increased contrast | selection outline | selected row | 1.12:1 | 4.50:1 | 3:1 |
| brown-yellow | light | secondary text | selected row | 4.33:1 | 4.50:1 | 4.5:1 |
| brown-yellow | light | tinted text | badge or tile fill | 4.18:1 | 4.50:1 | 4.5:1 |
| brown-yellow | light | tinted glyph | glass | 2.32:1 | 6.83:1 | 3:1 |
| brown-yellow | light | text on the hue | the hue, opaque | 3.53:1 | 5.95:1 | 4.5:1 |
| brown-yellow | light | focus ring | window gradient | 1.87:1 | 4.00:1 | 3:1 |
| brown-yellow | light | focus ring | hovered row | 1.78:1 | 3.52:1 | 3:1 |
| brown-yellow | light | focus ring | current row | 1.75:1 | 3.37:1 | 3:1 |
| brown-yellow | light | focus ring | selected row | 1.68:1 | 3.00:1 | 3:1 |
| brown-yellow | light | focus ring | folder panel | 1.82:1 | 3.78:1 | 3:1 |
| brown-yellow | dark | secondary text | current row | 4.36:1 | 4.85:1 | 4.5:1 |
| brown-yellow | dark | secondary text | selected row | 4.07:1 | 4.50:1 | 4.5:1 |
| brown-yellow | dark | tinted text | badge or tile fill | 4.13:1 | 4.50:1 | 4.5:1 |
| brown-yellow | dark | tinted glyph | glass | 2.67:1 | 7.54:1 | 3:1 |
| brown-yellow | dark | text on the hue | the hue, opaque | 3.07:1 | 6.84:1 | 4.5:1 |
| brown-yellow | dark | focus ring | window gradient | 1.74:1 | 4.25:1 | 3:1 |
| brown-yellow | dark | focus ring | hovered row | 1.55:1 | 3.45:1 | 3:1 |
| brown-yellow | dark | focus ring | current row | 1.50:1 | 3.26:1 | 3:1 |
| brown-yellow | dark | focus ring | selected row | 1.43:1 | 3.00:1 | 3:1 |
| brown-yellow | dark | focus ring | folder panel | 1.64:1 | 3.79:1 | 3:1 |
| brown-yellow | light, increased contrast | secondary text | selected row | 4.23:1 | 4.50:1 | 4.5:1 |
| brown-yellow | light, increased contrast | tinted text | selected row | 4.42:1 | 4.94:1 | 4.5:1 |
| brown-yellow | light, increased contrast | tinted text | badge or tile fill | 3.83:1 | 4.51:1 | 4.5:1 |
| brown-yellow | light, increased contrast | tinted glyph | glass | 2.32:1 | 7.82:1 | 3:1 |
| brown-yellow | light, increased contrast | text on the hue | the hue, opaque | 3.53:1 | 5.95:1 | 4.5:1 |
| brown-yellow | light, increased contrast | focus ring | window gradient | 1.87:1 | 4.75:1 | 3:1 |
| brown-yellow | light, increased contrast | focus ring | hovered row | 1.68:1 | 3.95:1 | 3:1 |
| brown-yellow | light, increased contrast | focus ring | current row | 1.63:1 | 3.65:1 | 3:1 |
| brown-yellow | light, increased contrast | focus ring | selected row | 1.53:1 | 3.00:1 | 3:1 |
| brown-yellow | light, increased contrast | focus ring | folder panel | 1.75:1 | 4.49:1 | 3:1 |
| brown-yellow | light, increased contrast | selection outline | current row | 1.22:1 | 4.96:1 | 3:1 |
| brown-yellow | light, increased contrast | selection outline | selected row | 1.22:1 | 4.50:1 | 3:1 |
| brown-yellow | dark, increased contrast | primary text | current row | 4.20:1 | 5.10:1 | 4.5:1 |
| brown-yellow | dark, increased contrast | primary text | selected row | 3.76:1 | 4.50:1 | 4.5:1 |
| brown-yellow | dark, increased contrast | primary text | switcher selection | 4.24:1 | 6.47:1 | 4.5:1 |
| brown-yellow | dark, increased contrast | secondary text | current row | 4.20:1 | 5.10:1 | 4.5:1 |
| brown-yellow | dark, increased contrast | secondary text | selected row | 3.76:1 | 4.50:1 | 4.5:1 |
| brown-yellow | dark, increased contrast | tinted text | selected row | 4.46:1 | 5.13:1 | 4.5:1 |
| brown-yellow | dark, increased contrast | tinted text | badge or tile fill | 3.73:1 | 4.50:1 | 4.5:1 |
| brown-yellow | dark, increased contrast | tinted glyph | glass | 2.67:1 | 8.66:1 | 3:1 |
| brown-yellow | dark, increased contrast | text on the hue | the hue, opaque | 3.07:1 | 6.84:1 | 4.5:1 |
| brown-yellow | dark, increased contrast | focus ring | window gradient | 1.74:1 | 5.07:1 | 3:1 |
| brown-yellow | dark, increased contrast | focus ring | hovered row | 1.40:1 | 3.79:1 | 3:1 |
| brown-yellow | dark, increased contrast | focus ring | current row | 1.33:1 | 3.45:1 | 3:1 |
| brown-yellow | dark, increased contrast | focus ring | selected row | 1.24:1 | 3.00:1 | 3:1 |
| brown-yellow | dark, increased contrast | focus ring | folder panel | 1.52:1 | 4.44:1 | 3:1 |
| brown-yellow | dark, increased contrast | selection outline | current row | 1.22:1 | 5.10:1 | 3:1 |
| brown-yellow | dark, increased contrast | selection outline | selected row | 1.20:1 | 4.50:1 | 3:1 |
| orange | light | symbol on the hue | the hue, opaque | 2.31:1 | 9.09:1 | 3:1 |
| teal | light | symbol on the hue | the hue, opaque | 2.16:1 | 9.72:1 | 3:1 |
| green | light | symbol on the hue | the hue, opaque | 2.22:1 | 9.46:1 | 3:1 |
| mint | light | symbol on the hue | the hue, opaque | 2.12:1 | 9.91:1 | 3:1 |
| cyan | light | symbol on the hue | the hue, opaque | 2.16:1 | 9.71:1 | 3:1 |
| yellow | light | symbol on the hue | the hue, opaque | 1.51:1 | 13.89:1 | 3:1 |
| orange | dark | symbol on the hue | the hue, opaque | 2.23:1 | 9.41:1 | 3:1 |
| teal | dark | symbol on the hue | the hue, opaque | 1.86:1 | 11.30:1 | 3:1 |
| green | dark | symbol on the hue | the hue, opaque | 2.02:1 | 10.39:1 | 3:1 |
| mint | dark | symbol on the hue | the hue, opaque | 1.78:1 | 11.82:1 | 3:1 |
| cyan | dark | symbol on the hue | the hue, opaque | 1.76:1 | 11.94:1 | 3:1 |
| yellow | dark | symbol on the hue | the hue, opaque | 1.41:1 | 14.87:1 | 3:1 |
| orange | light, increased contrast | symbol on the hue | the hue, opaque | 2.31:1 | 9.09:1 | 3:1 |
| teal | light, increased contrast | symbol on the hue | the hue, opaque | 2.16:1 | 9.72:1 | 3:1 |
| green | light, increased contrast | symbol on the hue | the hue, opaque | 2.22:1 | 9.46:1 | 3:1 |
| mint | light, increased contrast | symbol on the hue | the hue, opaque | 2.12:1 | 9.91:1 | 3:1 |
| cyan | light, increased contrast | symbol on the hue | the hue, opaque | 2.16:1 | 9.71:1 | 3:1 |
| yellow | light, increased contrast | symbol on the hue | the hue, opaque | 1.51:1 | 13.89:1 | 3:1 |
| orange | dark, increased contrast | symbol on the hue | the hue, opaque | 2.23:1 | 9.41:1 | 3:1 |
| teal | dark, increased contrast | symbol on the hue | the hue, opaque | 1.86:1 | 11.30:1 | 3:1 |
| green | dark, increased contrast | symbol on the hue | the hue, opaque | 2.02:1 | 10.39:1 | 3:1 |
| mint | dark, increased contrast | symbol on the hue | the hue, opaque | 1.78:1 | 11.82:1 | 3:1 |
| cyan | dark, increased contrast | symbol on the hue | the hue, opaque | 1.76:1 | 11.94:1 | 3:1 |
| yellow | dark, increased contrast | symbol on the hue | the hue, opaque | 1.41:1 | 14.87:1 | 3:1 |

</details>

<details>
<summary>All 804 cases</summary>

| Theme or hue | Appearance | Role | Surface | 0.2.0 | 0.2.1 | Threshold |
|---|---|---|---|---|---|---|
| indigo-blue | light | primary text | window gradient | 9.61:1 | 9.61:1 | 4.5:1 |
| indigo-blue | light | primary text | hovered row | 8.48:1 | 8.48:1 | 4.5:1 |
| indigo-blue | light | primary text | current row | 8.06:1 | 8.06:1 | 4.5:1 |
| indigo-blue | light | primary text | selected row | 7.15:1 | 7.15:1 | 4.5:1 |
| indigo-blue | light | primary text | folder panel | 9.19:1 | 9.19:1 | 4.5:1 |
| indigo-blue | light | primary text | glass | 9.61:1 | 9.61:1 | 4.5:1 |
| indigo-blue | light | primary text | switcher selection | 9.35:1 | 9.35:1 | 4.5:1 |
| indigo-blue | light | secondary text | window gradient | 5.04:1 | 5.35:1 | 4.5:1 |
| indigo-blue | light | secondary text | hovered row | 4.72:1 | 4.98:1 | 4.5:1 |
| indigo-blue | light | secondary text | current row | 4.59:1 | 4.84:1 | 4.5:1 |
| indigo-blue | light | secondary text | selected row | 4.29:1 | 4.51:1 | 4.5:1 |
| indigo-blue | light | secondary text | folder panel | 4.92:1 | 5.21:1 | 4.5:1 |
| indigo-blue | light | secondary text | glass | 5.04:1 | 5.35:1 | 4.5:1 |
| indigo-blue | light | tinted text | window gradient | 7.06:1 | 7.64:1 | 4.5:1 |
| indigo-blue | light | tinted text | hovered row | 6.08:1 | 6.58:1 | 4.5:1 |
| indigo-blue | light | tinted text | current row | 5.73:1 | 6.21:1 | 4.5:1 |
| indigo-blue | light | tinted text | selected row | 4.98:1 | 5.39:1 | 4.5:1 |
| indigo-blue | light | tinted text | folder panel | 6.69:1 | 7.24:1 | 4.5:1 |
| indigo-blue | light | tinted text | badge or tile fill | 4.16:1 | 4.50:1 | 4.5:1 |
| indigo-blue | light | tinted glyph | glass | 2.94:1 | 7.64:1 | 3:1 |
| indigo-blue | light | text on the hue | the hue, opaque | 5.09:1 | 5.09:1 | 4.5:1 |
| indigo-blue | light | focus ring | window gradient | 1.72:1 | 4.25:1 | 3:1 |
| indigo-blue | light | focus ring | hovered row | 1.61:1 | 3.66:1 | 3:1 |
| indigo-blue | light | focus ring | current row | 1.57:1 | 3.45:1 | 3:1 |
| indigo-blue | light | focus ring | selected row | 1.47:1 | 3.00:1 | 3:1 |
| indigo-blue | light | focus ring | folder panel | 1.69:1 | 4.03:1 | 3:1 |
| indigo-blue | dark | primary text | window gradient | 6.91:1 | 6.91:1 | 4.5:1 |
| indigo-blue | dark | primary text | hovered row | 5.89:1 | 5.89:1 | 4.5:1 |
| indigo-blue | dark | primary text | current row | 5.61:1 | 5.61:1 | 4.5:1 |
| indigo-blue | dark | primary text | selected row | 5.22:1 | 5.22:1 | 4.5:1 |
| indigo-blue | dark | primary text | folder panel | 6.38:1 | 6.38:1 | 4.5:1 |
| indigo-blue | dark | primary text | glass | 6.91:1 | 6.91:1 | 4.5:1 |
| indigo-blue | dark | primary text | switcher selection | 7.01:1 | 7.01:1 | 4.5:1 |
| indigo-blue | dark | secondary text | window gradient | 5.22:1 | 5.84:1 | 4.5:1 |
| indigo-blue | dark | secondary text | hovered row | 4.54:1 | 5.04:1 | 4.5:1 |
| indigo-blue | dark | secondary text | current row | 4.35:1 | 4.82:1 | 4.5:1 |
| indigo-blue | dark | secondary text | selected row | 4.08:1 | 4.50:1 | 4.5:1 |
| indigo-blue | dark | secondary text | folder panel | 4.87:1 | 5.43:1 | 4.5:1 |
| indigo-blue | dark | secondary text | glass | 5.22:1 | 5.84:1 | 4.5:1 |
| indigo-blue | dark | tinted text | window gradient | 6.57:1 | 7.19:1 | 4.5:1 |
| indigo-blue | dark | tinted text | hovered row | 5.51:1 | 6.03:1 | 4.5:1 |
| indigo-blue | dark | tinted text | current row | 5.23:1 | 5.72:1 | 4.5:1 |
| indigo-blue | dark | tinted text | selected row | 4.84:1 | 5.29:1 | 4.5:1 |
| indigo-blue | dark | tinted text | folder panel | 6.02:1 | 6.59:1 | 4.5:1 |
| indigo-blue | dark | tinted text | badge or tile fill | 4.11:1 | 4.50:1 | 4.5:1 |
| indigo-blue | dark | tinted glyph | glass | 2.52:1 | 7.19:1 | 3:1 |
| indigo-blue | dark | text on the hue | the hue, opaque | 3.51:1 | 5.98:1 | 4.5:1 |
| indigo-blue | dark | focus ring | window gradient | 1.90:1 | 4.08:1 | 3:1 |
| indigo-blue | dark | focus ring | hovered row | 1.72:1 | 3.42:1 | 3:1 |
| indigo-blue | dark | focus ring | current row | 1.67:1 | 3.25:1 | 3:1 |
| indigo-blue | dark | focus ring | selected row | 1.60:1 | 3.00:1 | 3:1 |
| indigo-blue | dark | focus ring | folder panel | 1.81:1 | 3.73:1 | 3:1 |
| indigo-blue | light, increased contrast | primary text | window gradient | 9.61:1 | 9.61:1 | 4.5:1 |
| indigo-blue | light, increased contrast | primary text | hovered row | 7.32:1 | 7.93:1 | 4.5:1 |
| indigo-blue | light, increased contrast | primary text | current row | 6.72:1 | 7.22:1 | 4.5:1 |
| indigo-blue | light, increased contrast | primary text | selected row | 5.46:1 | 5.75:1 | 4.5:1 |
| indigo-blue | light, increased contrast | primary text | folder panel | 8.40:1 | 9.19:1 | 4.5:1 |
| indigo-blue | light, increased contrast | primary text | glass | 9.61:1 | 9.61:1 | 4.5:1 |
| indigo-blue | light, increased contrast | primary text | switcher selection | 6.45:1 | 9.35:1 | 4.5:1 |
| indigo-blue | light, increased contrast | secondary text | window gradient | 6.10:1 | 6.53:1 | 4.5:1 |
| indigo-blue | light, increased contrast | secondary text | hovered row | 5.10:1 | 5.71:1 | 4.5:1 |
| indigo-blue | light, increased contrast | secondary text | current row | 4.81:1 | 5.34:1 | 4.5:1 |
| indigo-blue | light, increased contrast | secondary text | selected row | 4.15:1 | 4.51:1 | 4.5:1 |
| indigo-blue | light, increased contrast | secondary text | folder panel | 5.59:1 | 6.33:1 | 4.5:1 |
| indigo-blue | light, increased contrast | secondary text | glass | 6.10:1 | 6.53:1 | 4.5:1 |
| indigo-blue | light, increased contrast | tinted text | window gradient | 8.74:1 | 9.24:1 | 4.5:1 |
| indigo-blue | light, increased contrast | tinted text | hovered row | 6.35:1 | 7.35:1 | 4.5:1 |
| indigo-blue | light, increased contrast | tinted text | current row | 5.75:1 | 6.60:1 | 4.5:1 |
| indigo-blue | light, increased contrast | tinted text | selected row | 4.54:1 | 5.09:1 | 4.5:1 |
| indigo-blue | light, increased contrast | tinted text | folder panel | 7.45:1 | 8.76:1 | 4.5:1 |
| indigo-blue | light, increased contrast | tinted text | badge or tile fill | 3.74:1 | 4.50:1 | 4.5:1 |
| indigo-blue | light, increased contrast | tinted glyph | glass | 2.94:1 | 9.24:1 | 3:1 |
| indigo-blue | light, increased contrast | text on the hue | the hue, opaque | 5.09:1 | 5.09:1 | 4.5:1 |
| indigo-blue | light, increased contrast | focus ring | window gradient | 1.72:1 | 5.45:1 | 3:1 |
| indigo-blue | light, increased contrast | focus ring | hovered row | 1.49:1 | 4.34:1 | 3:1 |
| indigo-blue | light, increased contrast | focus ring | current row | 1.42:1 | 3.90:1 | 3:1 |
| indigo-blue | light, increased contrast | focus ring | selected row | 1.27:1 | 3.00:1 | 3:1 |
| indigo-blue | light, increased contrast | focus ring | folder panel | 1.61:1 | 5.17:1 | 3:1 |
| indigo-blue | light, increased contrast | selection outline | current row | 1.22:1 | 5.34:1 | 3:1 |
| indigo-blue | light, increased contrast | selection outline | selected row | 1.20:1 | 4.51:1 | 3:1 |
| indigo-blue | dark, increased contrast | primary text | window gradient | 6.91:1 | 6.97:1 | 4.5:1 |
| indigo-blue | dark, increased contrast | primary text | hovered row | 5.00:1 | 5.57:1 | 4.5:1 |
| indigo-blue | dark, increased contrast | primary text | current row | 4.66:1 | 5.11:1 | 4.5:1 |
| indigo-blue | dark, increased contrast | primary text | selected row | 4.19:1 | 4.50:1 | 4.5:1 |
| indigo-blue | dark, increased contrast | primary text | folder panel | 5.63:1 | 6.43:1 | 4.5:1 |
| indigo-blue | dark, increased contrast | primary text | glass | 6.91:1 | 6.97:1 | 4.5:1 |
| indigo-blue | dark, increased contrast | primary text | switcher selection | 4.75:1 | 7.01:1 | 4.5:1 |
| indigo-blue | dark, increased contrast | secondary text | window gradient | 6.36:1 | 6.97:1 | 4.5:1 |
| indigo-blue | dark, increased contrast | secondary text | hovered row | 4.66:1 | 5.57:1 | 4.5:1 |
| indigo-blue | dark, increased contrast | secondary text | current row | 4.35:1 | 5.11:1 | 4.5:1 |
| indigo-blue | dark, increased contrast | secondary text | selected row | 3.92:1 | 4.50:1 | 4.5:1 |
| indigo-blue | dark, increased contrast | secondary text | folder panel | 5.23:1 | 6.43:1 | 4.5:1 |
| indigo-blue | dark, increased contrast | secondary text | glass | 6.36:1 | 6.97:1 | 4.5:1 |
| indigo-blue | dark, increased contrast | tinted text | window gradient | 7.66:1 | 8.18:1 | 4.5:1 |
| indigo-blue | dark, increased contrast | tinted text | hovered row | 5.36:1 | 6.39:1 | 4.5:1 |
| indigo-blue | dark, increased contrast | tinted text | current row | 4.96:1 | 5.82:1 | 4.5:1 |
| indigo-blue | dark, increased contrast | tinted text | selected row | 4.42:1 | 5.06:1 | 4.5:1 |
| indigo-blue | dark, increased contrast | tinted text | folder panel | 6.11:1 | 7.47:1 | 4.5:1 |
| indigo-blue | dark, increased contrast | tinted text | badge or tile fill | 3.72:1 | 4.50:1 | 4.5:1 |
| indigo-blue | dark, increased contrast | tinted glyph | glass | 2.52:1 | 8.18:1 | 3:1 |
| indigo-blue | dark, increased contrast | text on the hue | the hue, opaque | 3.51:1 | 5.98:1 | 4.5:1 |
| indigo-blue | dark, increased contrast | focus ring | window gradient | 1.90:1 | 4.85:1 | 3:1 |
| indigo-blue | dark, increased contrast | focus ring | hovered row | 1.56:1 | 3.79:1 | 3:1 |
| indigo-blue | dark, increased contrast | focus ring | current row | 1.49:1 | 3.45:1 | 3:1 |
| indigo-blue | dark, increased contrast | focus ring | selected row | 1.40:1 | 3.00:1 | 3:1 |
| indigo-blue | dark, increased contrast | focus ring | folder panel | 1.67:1 | 4.43:1 | 3:1 |
| indigo-blue | dark, increased contrast | selection outline | current row | 1.24:1 | 5.11:1 | 3:1 |
| indigo-blue | dark, increased contrast | selection outline | selected row | 1.22:1 | 4.50:1 | 3:1 |
| orange-pink | light | primary text | window gradient | 11.62:1 | 11.62:1 | 4.5:1 |
| orange-pink | light | primary text | hovered row | 10.23:1 | 10.23:1 | 4.5:1 |
| orange-pink | light | primary text | current row | 10.01:1 | 10.01:1 | 4.5:1 |
| orange-pink | light | primary text | selected row | 8.95:1 | 8.95:1 | 4.5:1 |
| orange-pink | light | primary text | folder panel | 10.61:1 | 10.61:1 | 4.5:1 |
| orange-pink | light | primary text | glass | 11.62:1 | 11.62:1 | 4.5:1 |
| orange-pink | light | primary text | switcher selection | 11.25:1 | 11.25:1 | 4.5:1 |
| orange-pink | light | secondary text | window gradient | 4.90:1 | 5.06:1 | 4.5:1 |
| orange-pink | light | secondary text | hovered row | 4.64:1 | 4.78:1 | 4.5:1 |
| orange-pink | light | secondary text | current row | 4.60:1 | 4.74:1 | 4.5:1 |
| orange-pink | light | secondary text | selected row | 4.38:1 | 4.50:1 | 4.5:1 |
| orange-pink | light | secondary text | folder panel | 4.71:1 | 4.86:1 | 4.5:1 |
| orange-pink | light | secondary text | glass | 4.90:1 | 5.06:1 | 4.5:1 |
| orange-pink | light | tinted text | window gradient | 6.17:1 | 6.52:1 | 4.5:1 |
| orange-pink | light | tinted text | hovered row | 5.28:1 | 5.58:1 | 4.5:1 |
| orange-pink | light | tinted text | current row | 5.15:1 | 5.44:1 | 4.5:1 |
| orange-pink | light | tinted text | selected row | 4.49:1 | 4.75:1 | 4.5:1 |
| orange-pink | light | tinted text | folder panel | 5.52:1 | 5.84:1 | 4.5:1 |
| orange-pink | light | tinted text | badge or tile fill | 4.26:1 | 4.50:1 | 4.5:1 |
| orange-pink | light | tinted glyph | glass | 1.68:1 | 6.52:1 | 3:1 |
| orange-pink | light | text on the hue | the hue, opaque | 2.31:1 | 9.09:1 | 4.5:1 |
| orange-pink | light | focus ring | window gradient | 1.98:1 | 4.12:1 | 3:1 |
| orange-pink | light | focus ring | hovered row | 1.87:1 | 3.53:1 | 3:1 |
| orange-pink | light | focus ring | current row | 1.86:1 | 3.44:1 | 3:1 |
| orange-pink | light | focus ring | selected row | 1.82:1 | 3.00:1 | 3:1 |
| orange-pink | light | focus ring | folder panel | 1.89:1 | 3.69:1 | 3:1 |
| orange-pink | dark | primary text | window gradient | 5.56:1 | 6.20:1 | 4.5:1 |
| orange-pink | dark | primary text | hovered row | 4.88:1 | 5.35:1 | 4.5:1 |
| orange-pink | dark | primary text | current row | 4.56:1 | 5.02:1 | 4.5:1 |
| orange-pink | dark | primary text | selected row | 4.12:1 | 4.56:1 | 4.5:1 |
| orange-pink | dark | primary text | folder panel | 5.48:1 | 5.97:1 | 4.5:1 |
| orange-pink | dark | primary text | glass | 5.56:1 | 6.20:1 | 4.5:1 |
| orange-pink | dark | primary text | switcher selection | 5.80:1 | 5.87:1 | 4.5:1 |
| orange-pink | dark | secondary text | window gradient | 5.50:1 | 6.11:1 | 4.5:1 |
| orange-pink | dark | secondary text | hovered row | 4.83:1 | 5.28:1 | 4.5:1 |
| orange-pink | dark | secondary text | current row | 4.52:1 | 4.95:1 | 4.5:1 |
| orange-pink | dark | secondary text | selected row | 4.09:1 | 4.50:1 | 4.5:1 |
| orange-pink | dark | secondary text | folder panel | 5.42:1 | 5.89:1 | 4.5:1 |
| orange-pink | dark | secondary text | glass | 5.50:1 | 6.11:1 | 4.5:1 |
| orange-pink | dark | tinted text | window gradient | 6.99:1 | 7.87:1 | 4.5:1 |
| orange-pink | dark | tinted text | hovered row | 6.06:1 | 6.70:1 | 4.5:1 |
| orange-pink | dark | tinted text | current row | 5.63:1 | 6.24:1 | 4.5:1 |
| orange-pink | dark | tinted text | selected row | 5.04:1 | 5.62:1 | 4.5:1 |
| orange-pink | dark | tinted text | folder panel | 6.87:1 | 7.55:1 | 4.5:1 |
| orange-pink | dark | tinted text | badge or tile fill | 4.04:1 | 4.50:1 | 4.5:1 |
| orange-pink | dark | tinted glyph | glass | 3.13:1 | 7.87:1 | 3:1 |
| orange-pink | dark | text on the hue | the hue, opaque | 2.23:1 | 9.41:1 | 4.5:1 |
| orange-pink | dark | focus ring | window gradient | 1.53:1 | 4.21:1 | 3:1 |
| orange-pink | dark | focus ring | hovered row | 1.41:1 | 3.58:1 | 3:1 |
| orange-pink | dark | focus ring | current row | 1.35:1 | 3.33:1 | 3:1 |
| orange-pink | dark | focus ring | selected row | 1.26:1 | 3.00:1 | 3:1 |
| orange-pink | dark | focus ring | folder panel | 1.53:1 | 4.03:1 | 3:1 |
| orange-pink | light, increased contrast | primary text | window gradient | 11.62:1 | 11.62:1 | 4.5:1 |
| orange-pink | light, increased contrast | primary text | hovered row | 9.21:1 | 9.94:1 | 4.5:1 |
| orange-pink | light, increased contrast | primary text | current row | 8.94:1 | 9.56:1 | 4.5:1 |
| orange-pink | light, increased contrast | primary text | selected row | 8.37:1 | 8.76:1 | 4.5:1 |
| orange-pink | light, increased contrast | primary text | folder panel | 9.69:1 | 10.61:1 | 4.5:1 |
| orange-pink | light, increased contrast | primary text | glass | 11.62:1 | 11.62:1 | 4.5:1 |
| orange-pink | light, increased contrast | primary text | switcher selection | 9.46:1 | 11.25:1 | 4.5:1 |
| orange-pink | light, increased contrast | secondary text | window gradient | 4.96:1 | 5.12:1 | 4.5:1 |
| orange-pink | light, increased contrast | secondary text | hovered row | 4.48:1 | 4.77:1 | 4.5:1 |
| orange-pink | light, increased contrast | secondary text | current row | 4.42:1 | 4.69:1 | 4.5:1 |
| orange-pink | light, increased contrast | secondary text | selected row | 4.29:1 | 4.50:1 | 4.5:1 |
| orange-pink | light, increased contrast | secondary text | folder panel | 4.59:1 | 4.92:1 | 4.5:1 |
| orange-pink | light, increased contrast | secondary text | glass | 4.96:1 | 5.12:1 | 4.5:1 |
| orange-pink | light, increased contrast | tinted text | window gradient | 6.32:1 | 6.64:1 | 4.5:1 |
| orange-pink | light, increased contrast | tinted text | hovered row | 4.77:1 | 5.49:1 | 4.5:1 |
| orange-pink | light, increased contrast | tinted text | current row | 4.60:1 | 5.24:1 | 4.5:1 |
| orange-pink | light, increased contrast | tinted text | selected row | 4.25:1 | 4.72:1 | 4.5:1 |
| orange-pink | light, increased contrast | tinted text | folder panel | 5.07:1 | 5.94:1 | 4.5:1 |
| orange-pink | light, increased contrast | tinted text | badge or tile fill | 4.01:1 | 4.50:1 | 4.5:1 |
| orange-pink | light, increased contrast | tinted glyph | glass | 1.68:1 | 6.64:1 | 3:1 |
| orange-pink | light, increased contrast | text on the hue | the hue, opaque | 2.31:1 | 9.09:1 | 4.5:1 |
| orange-pink | light, increased contrast | focus ring | window gradient | 1.98:1 | 4.23:1 | 3:1 |
| orange-pink | light, increased contrast | focus ring | hovered row | 1.79:1 | 3.49:1 | 3:1 |
| orange-pink | light, increased contrast | focus ring | current row | 1.78:1 | 3.33:1 | 3:1 |
| orange-pink | light, increased contrast | focus ring | selected row | 1.77:1 | 3.00:1 | 3:1 |
| orange-pink | light, increased contrast | focus ring | folder panel | 1.81:1 | 3.78:1 | 3:1 |
| orange-pink | light, increased contrast | selection outline | current row | 1.23:1 | 4.69:1 | 3:1 |
| orange-pink | light, increased contrast | selection outline | selected row | 1.23:1 | 4.50:1 | 3:1 |
| orange-pink | dark, increased contrast | primary text | window gradient | 5.56:1 | 7.36:1 | 4.5:1 |
| orange-pink | dark, increased contrast | primary text | hovered row | 4.09:1 | 5.78:1 | 4.5:1 |
| orange-pink | dark, increased contrast | primary text | current row | 3.68:1 | 5.22:1 | 4.5:1 |
| orange-pink | dark, increased contrast | primary text | selected row | 3.16:1 | 4.50:1 | 4.5:1 |
| orange-pink | dark, increased contrast | primary text | folder panel | 4.90:1 | 6.84:1 | 4.5:1 |
| orange-pink | dark, increased contrast | primary text | glass | 5.56:1 | 7.36:1 | 4.5:1 |
| orange-pink | dark, increased contrast | primary text | switcher selection | 3.49:1 | 5.99:1 | 4.5:1 |
| orange-pink | dark, increased contrast | secondary text | window gradient | 5.56:1 | 7.36:1 | 4.5:1 |
| orange-pink | dark, increased contrast | secondary text | hovered row | 4.09:1 | 5.78:1 | 4.5:1 |
| orange-pink | dark, increased contrast | secondary text | current row | 3.68:1 | 5.22:1 | 4.5:1 |
| orange-pink | dark, increased contrast | secondary text | selected row | 3.16:1 | 4.50:1 | 4.5:1 |
| orange-pink | dark, increased contrast | secondary text | folder panel | 4.90:1 | 6.84:1 | 4.5:1 |
| orange-pink | dark, increased contrast | secondary text | glass | 5.56:1 | 7.36:1 | 4.5:1 |
| orange-pink | dark, increased contrast | tinted text | window gradient | 6.99:1 | 9.14:1 | 4.5:1 |
| orange-pink | dark, increased contrast | tinted text | hovered row | 4.98:1 | 7.01:1 | 4.5:1 |
| orange-pink | dark, increased contrast | tinted text | current row | 4.44:1 | 6.28:1 | 4.5:1 |
| orange-pink | dark, increased contrast | tinted text | selected row | 3.75:1 | 5.33:1 | 4.5:1 |
| orange-pink | dark, increased contrast | tinted text | folder panel | 6.07:1 | 8.43:1 | 4.5:1 |
| orange-pink | dark, increased contrast | tinted text | badge or tile fill | 2.94:1 | 4.50:1 | 4.5:1 |
| orange-pink | dark, increased contrast | tinted glyph | glass | 3.13:1 | 9.14:1 | 3:1 |
| orange-pink | dark, increased contrast | text on the hue | the hue, opaque | 2.23:1 | 9.41:1 | 4.5:1 |
| orange-pink | dark, increased contrast | focus ring | window gradient | 1.53:1 | 5.14:1 | 3:1 |
| orange-pink | dark, increased contrast | focus ring | hovered row | 1.27:1 | 3.94:1 | 3:1 |
| orange-pink | dark, increased contrast | focus ring | current row | 1.18:1 | 3.53:1 | 3:1 |
| orange-pink | dark, increased contrast | focus ring | selected row | 1.06:1 | 3.00:1 | 3:1 |
| orange-pink | dark, increased contrast | focus ring | folder panel | 1.44:1 | 4.74:1 | 3:1 |
| orange-pink | dark, increased contrast | selection outline | current row | 1.19:1 | 5.22:1 | 3:1 |
| orange-pink | dark, increased contrast | selection outline | selected row | 1.16:1 | 4.50:1 | 3:1 |
| teal-green | light | primary text | window gradient | 11.62:1 | 11.62:1 | 4.5:1 |
| teal-green | light | primary text | hovered row | 10.39:1 | 10.39:1 | 4.5:1 |
| teal-green | light | primary text | current row | 10.18:1 | 10.18:1 | 4.5:1 |
| teal-green | light | primary text | selected row | 9.13:1 | 9.13:1 | 4.5:1 |
| teal-green | light | primary text | folder panel | 10.77:1 | 10.77:1 | 4.5:1 |
| teal-green | light | primary text | glass | 11.62:1 | 11.62:1 | 4.5:1 |
| teal-green | light | primary text | switcher selection | 11.44:1 | 11.44:1 | 4.5:1 |
| teal-green | light | secondary text | window gradient | 4.85:1 | 5.00:1 | 4.5:1 |
| teal-green | light | secondary text | hovered row | 4.63:1 | 4.77:1 | 4.5:1 |
| teal-green | light | secondary text | current row | 4.59:1 | 4.72:1 | 4.5:1 |
| teal-green | light | secondary text | selected row | 4.39:1 | 4.50:1 | 4.5:1 |
| teal-green | light | secondary text | folder panel | 4.70:1 | 4.84:1 | 4.5:1 |
| teal-green | light | secondary text | glass | 4.85:1 | 5.00:1 | 4.5:1 |
| teal-green | light | tinted text | window gradient | 6.00:1 | 6.33:1 | 4.5:1 |
| teal-green | light | tinted text | hovered row | 5.23:1 | 5.52:1 | 4.5:1 |
| teal-green | light | tinted text | current row | 5.09:1 | 5.38:1 | 4.5:1 |
| teal-green | light | tinted text | selected row | 4.46:1 | 4.71:1 | 4.5:1 |
| teal-green | light | tinted text | folder panel | 5.46:1 | 5.77:1 | 4.5:1 |
| teal-green | light | tinted text | badge or tile fill | 4.27:1 | 4.51:1 | 4.5:1 |
| teal-green | light | tinted glyph | glass | 1.57:1 | 6.33:1 | 3:1 |
| teal-green | light | text on the hue | the hue, opaque | 2.16:1 | 9.72:1 | 4.5:1 |
| teal-green | light | focus ring | window gradient | 1.86:1 | 4.04:1 | 3:1 |
| teal-green | light | focus ring | hovered row | 1.76:1 | 3.52:1 | 3:1 |
| teal-green | light | focus ring | current row | 1.74:1 | 3.43:1 | 3:1 |
| teal-green | light | focus ring | selected row | 1.63:1 | 3.00:1 | 3:1 |
| teal-green | light | focus ring | folder panel | 1.80:1 | 3.68:1 | 3:1 |
| teal-green | dark | primary text | window gradient | 5.07:1 | 6.45:1 | 4.5:1 |
| teal-green | dark | primary text | hovered row | 4.41:1 | 5.44:1 | 4.5:1 |
| teal-green | dark | primary text | current row | 4.09:1 | 5.09:1 | 4.5:1 |
| teal-green | dark | primary text | selected row | 3.67:1 | 4.60:1 | 4.5:1 |
| teal-green | dark | primary text | folder panel | 5.01:1 | 6.08:1 | 4.5:1 |
| teal-green | dark | primary text | glass | 5.07:1 | 6.45:1 | 4.5:1 |
| teal-green | dark | primary text | switcher selection | 5.19:1 | 5.37:1 | 4.5:1 |
| teal-green | dark | secondary text | window gradient | 5.07:1 | 6.29:1 | 4.5:1 |
| teal-green | dark | secondary text | hovered row | 4.41:1 | 5.31:1 | 4.5:1 |
| teal-green | dark | secondary text | current row | 4.09:1 | 4.97:1 | 4.5:1 |
| teal-green | dark | secondary text | selected row | 3.67:1 | 4.50:1 | 4.5:1 |
| teal-green | dark | secondary text | folder panel | 5.01:1 | 5.93:1 | 4.5:1 |
| teal-green | dark | secondary text | glass | 5.07:1 | 6.29:1 | 4.5:1 |
| teal-green | dark | tinted text | window gradient | 6.36:1 | 8.26:1 | 4.5:1 |
| teal-green | dark | tinted text | hovered row | 5.45:1 | 6.84:1 | 4.5:1 |
| teal-green | dark | tinted text | current row | 5.02:1 | 6.36:1 | 4.5:1 |
| teal-green | dark | tinted text | selected row | 4.45:1 | 5.71:1 | 4.5:1 |
| teal-green | dark | tinted text | folder panel | 6.25:1 | 7.72:1 | 4.5:1 |
| teal-green | dark | tinted text | badge or tile fill | 3.50:1 | 4.50:1 | 4.5:1 |
| teal-green | dark | tinted glyph | glass | 3.42:1 | 8.26:1 | 3:1 |
| teal-green | dark | text on the hue | the hue, opaque | 1.86:1 | 11.30:1 | 4.5:1 |
| teal-green | dark | focus ring | window gradient | 1.61:1 | 4.35:1 | 3:1 |
| teal-green | dark | focus ring | hovered row | 1.47:1 | 3.60:1 | 3:1 |
| teal-green | dark | focus ring | current row | 1.41:1 | 3.35:1 | 3:1 |
| teal-green | dark | focus ring | selected row | 1.32:1 | 3.00:1 | 3:1 |
| teal-green | dark | focus ring | folder panel | 1.59:1 | 4.06:1 | 3:1 |
| teal-green | light, increased contrast | primary text | window gradient | 11.62:1 | 11.62:1 | 4.5:1 |
| teal-green | light, increased contrast | primary text | hovered row | 9.36:1 | 10.11:1 | 4.5:1 |
| teal-green | light, increased contrast | primary text | current row | 9.11:1 | 9.75:1 | 4.5:1 |
| teal-green | light, increased contrast | primary text | selected row | 8.63:1 | 9.02:1 | 4.5:1 |
| teal-green | light, increased contrast | primary text | folder panel | 9.84:1 | 10.77:1 | 4.5:1 |
| teal-green | light, increased contrast | primary text | glass | 11.62:1 | 11.62:1 | 4.5:1 |
| teal-green | light, increased contrast | primary text | switcher selection | 9.72:1 | 11.44:1 | 4.5:1 |
| teal-green | light, increased contrast | secondary text | window gradient | 4.90:1 | 5.04:1 | 4.5:1 |
| teal-green | light, increased contrast | secondary text | hovered row | 4.47:1 | 4.74:1 | 4.5:1 |
| teal-green | light, increased contrast | secondary text | current row | 4.41:1 | 4.67:1 | 4.5:1 |
| teal-green | light, increased contrast | secondary text | selected row | 4.31:1 | 4.51:1 | 4.5:1 |
| teal-green | light, increased contrast | secondary text | folder panel | 4.56:1 | 4.87:1 | 4.5:1 |
| teal-green | light, increased contrast | secondary text | glass | 4.90:1 | 5.04:1 | 4.5:1 |
| teal-green | light, increased contrast | tinted text | window gradient | 6.08:1 | 6.39:1 | 4.5:1 |
| teal-green | light, increased contrast | tinted text | hovered row | 4.67:1 | 5.38:1 | 4.5:1 |
| teal-green | light, increased contrast | tinted text | current row | 4.52:1 | 5.15:1 | 4.5:1 |
| teal-green | light, increased contrast | tinted text | selected row | 4.23:1 | 4.68:1 | 4.5:1 |
| teal-green | light, increased contrast | tinted text | folder panel | 4.97:1 | 5.82:1 | 4.5:1 |
| teal-green | light, increased contrast | tinted text | badge or tile fill | 4.04:1 | 4.50:1 | 4.5:1 |
| teal-green | light, increased contrast | tinted glyph | glass | 1.57:1 | 6.39:1 | 3:1 |
| teal-green | light, increased contrast | text on the hue | the hue, opaque | 2.16:1 | 9.72:1 | 4.5:1 |
| teal-green | light, increased contrast | focus ring | window gradient | 1.86:1 | 4.10:1 | 3:1 |
| teal-green | light, increased contrast | focus ring | hovered row | 1.67:1 | 3.45:1 | 3:1 |
| teal-green | light, increased contrast | focus ring | current row | 1.64:1 | 3.30:1 | 3:1 |
| teal-green | light, increased contrast | focus ring | selected row | 1.58:1 | 3.00:1 | 3:1 |
| teal-green | light, increased contrast | focus ring | folder panel | 1.73:1 | 3.73:1 | 3:1 |
| teal-green | light, increased contrast | selection outline | current row | 1.23:1 | 4.67:1 | 3:1 |
| teal-green | light, increased contrast | selection outline | selected row | 1.23:1 | 4.51:1 | 3:1 |
| teal-green | dark, increased contrast | primary text | window gradient | 5.07:1 | 7.56:1 | 4.5:1 |
| teal-green | dark, increased contrast | primary text | hovered row | 3.70:1 | 5.82:1 | 4.5:1 |
| teal-green | dark, increased contrast | primary text | current row | 3.29:1 | 5.25:1 | 4.5:1 |
| teal-green | dark, increased contrast | primary text | selected row | 2.77:1 | 4.51:1 | 4.5:1 |
| teal-green | dark, increased contrast | primary text | folder panel | 4.52:1 | 6.91:1 | 4.5:1 |
| teal-green | dark, increased contrast | primary text | glass | 5.07:1 | 7.56:1 | 4.5:1 |
| teal-green | dark, increased contrast | primary text | switcher selection | 3.00:1 | 5.49:1 | 4.5:1 |
| teal-green | dark, increased contrast | secondary text | window gradient | 5.07:1 | 7.55:1 | 4.5:1 |
| teal-green | dark, increased contrast | secondary text | hovered row | 3.70:1 | 5.82:1 | 4.5:1 |
| teal-green | dark, increased contrast | secondary text | current row | 3.29:1 | 5.25:1 | 4.5:1 |
| teal-green | dark, increased contrast | secondary text | selected row | 2.77:1 | 4.50:1 | 4.5:1 |
| teal-green | dark, increased contrast | secondary text | folder panel | 4.52:1 | 6.90:1 | 4.5:1 |
| teal-green | dark, increased contrast | secondary text | glass | 5.07:1 | 7.55:1 | 4.5:1 |
| teal-green | dark, increased contrast | tinted text | window gradient | 6.36:1 | 9.51:1 | 4.5:1 |
| teal-green | dark, increased contrast | tinted text | hovered row | 4.48:1 | 7.14:1 | 4.5:1 |
| teal-green | dark, increased contrast | tinted text | current row | 3.94:1 | 6.39:1 | 4.5:1 |
| teal-green | dark, increased contrast | tinted text | selected row | 3.28:1 | 5.41:1 | 4.5:1 |
| teal-green | dark, increased contrast | tinted text | folder panel | 5.58:1 | 8.60:1 | 4.5:1 |
| teal-green | dark, increased contrast | tinted text | badge or tile fill | 2.51:1 | 4.50:1 | 4.5:1 |
| teal-green | dark, increased contrast | tinted glyph | glass | 3.42:1 | 9.51:1 | 3:1 |
| teal-green | dark, increased contrast | text on the hue | the hue, opaque | 1.86:1 | 11.30:1 | 4.5:1 |
| teal-green | dark, increased contrast | focus ring | window gradient | 1.61:1 | 5.28:1 | 3:1 |
| teal-green | dark, increased contrast | focus ring | hovered row | 1.32:1 | 3.96:1 | 3:1 |
| teal-green | dark, increased contrast | focus ring | current row | 1.24:1 | 3.54:1 | 3:1 |
| teal-green | dark, increased contrast | focus ring | selected row | 1.12:1 | 3.00:1 | 3:1 |
| teal-green | dark, increased contrast | focus ring | folder panel | 1.49:1 | 4.77:1 | 3:1 |
| teal-green | dark, increased contrast | selection outline | current row | 1.16:1 | 5.25:1 | 3:1 |
| teal-green | dark, increased contrast | selection outline | selected row | 1.13:1 | 4.50:1 | 3:1 |
| red-orange | light | primary text | window gradient | 9.81:1 | 9.81:1 | 4.5:1 |
| red-orange | light | primary text | hovered row | 8.76:1 | 8.76:1 | 4.5:1 |
| red-orange | light | primary text | current row | 8.39:1 | 8.39:1 | 4.5:1 |
| red-orange | light | primary text | selected row | 7.59:1 | 7.59:1 | 4.5:1 |
| red-orange | light | primary text | folder panel | 9.42:1 | 9.42:1 | 4.5:1 |
| red-orange | light | primary text | glass | 9.81:1 | 9.81:1 | 4.5:1 |
| red-orange | light | primary text | switcher selection | 9.67:1 | 9.67:1 | 4.5:1 |
| red-orange | light | secondary text | window gradient | 4.90:1 | 5.17:1 | 4.5:1 |
| red-orange | light | secondary text | hovered row | 4.64:1 | 4.87:1 | 4.5:1 |
| red-orange | light | secondary text | current row | 4.53:1 | 4.76:1 | 4.5:1 |
| red-orange | light | secondary text | selected row | 4.31:1 | 4.51:1 | 4.5:1 |
| red-orange | light | secondary text | folder panel | 4.80:1 | 5.06:1 | 4.5:1 |
| red-orange | light | secondary text | glass | 4.90:1 | 5.17:1 | 4.5:1 |
| red-orange | light | tinted text | window gradient | 6.50:1 | 7.02:1 | 4.5:1 |
| red-orange | light | tinted text | hovered row | 5.68:1 | 6.13:1 | 4.5:1 |
| red-orange | light | tinted text | current row | 5.39:1 | 5.82:1 | 4.5:1 |
| red-orange | light | tinted text | selected row | 4.79:1 | 5.17:1 | 4.5:1 |
| red-orange | light | tinted text | folder panel | 6.20:1 | 6.69:1 | 4.5:1 |
| red-orange | light | tinted text | badge or tile fill | 4.17:1 | 4.50:1 | 4.5:1 |
| red-orange | light | tinted glyph | glass | 2.11:1 | 7.02:1 | 3:1 |
| red-orange | light | text on the hue | the hue, opaque | 3.57:1 | 5.88:1 | 4.5:1 |
| red-orange | light | focus ring | window gradient | 1.85:1 | 4.07:1 | 3:1 |
| red-orange | light | focus ring | hovered row | 1.76:1 | 3.56:1 | 3:1 |
| red-orange | light | focus ring | current row | 1.73:1 | 3.38:1 | 3:1 |
| red-orange | light | focus ring | selected row | 1.68:1 | 3.00:1 | 3:1 |
| red-orange | light | focus ring | folder panel | 1.80:1 | 3.88:1 | 3:1 |
| red-orange | dark | primary text | window gradient | 7.08:1 | 7.08:1 | 4.5:1 |
| red-orange | dark | primary text | hovered row | 6.02:1 | 6.02:1 | 4.5:1 |
| red-orange | dark | primary text | current row | 5.73:1 | 5.73:1 | 4.5:1 |
| red-orange | dark | primary text | selected row | 5.31:1 | 5.31:1 | 4.5:1 |
| red-orange | dark | primary text | folder panel | 6.53:1 | 6.53:1 | 4.5:1 |
| red-orange | dark | primary text | glass | 7.08:1 | 7.08:1 | 4.5:1 |
| red-orange | dark | primary text | switcher selection | 7.05:1 | 7.05:1 | 4.5:1 |
| red-orange | dark | secondary text | window gradient | 5.35:1 | 5.88:1 | 4.5:1 |
| red-orange | dark | secondary text | hovered row | 4.66:1 | 5.07:1 | 4.5:1 |
| red-orange | dark | secondary text | current row | 4.45:1 | 4.84:1 | 4.5:1 |
| red-orange | dark | secondary text | selected row | 4.15:1 | 4.50:1 | 4.5:1 |
| red-orange | dark | secondary text | folder panel | 5.02:1 | 5.48:1 | 4.5:1 |
| red-orange | dark | secondary text | glass | 5.35:1 | 5.88:1 | 4.5:1 |
| red-orange | dark | tinted text | window gradient | 6.78:1 | 7.32:1 | 4.5:1 |
| red-orange | dark | tinted text | hovered row | 5.66:1 | 6.10:1 | 4.5:1 |
| red-orange | dark | tinted text | current row | 5.36:1 | 5.79:1 | 4.5:1 |
| red-orange | dark | tinted text | selected row | 4.95:1 | 5.34:1 | 4.5:1 |
| red-orange | dark | tinted text | folder panel | 6.16:1 | 6.65:1 | 4.5:1 |
| red-orange | dark | tinted text | badge or tile fill | 4.17:1 | 4.51:1 | 4.5:1 |
| red-orange | dark | tinted glyph | glass | 2.68:1 | 7.32:1 | 3:1 |
| red-orange | dark | text on the hue | the hue, opaque | 3.43:1 | 6.12:1 | 4.5:1 |
| red-orange | dark | focus ring | window gradient | 1.68:1 | 4.11:1 | 3:1 |
| red-orange | dark | focus ring | hovered row | 1.55:1 | 3.43:1 | 3:1 |
| red-orange | dark | focus ring | current row | 1.49:1 | 3.25:1 | 3:1 |
| red-orange | dark | focus ring | selected row | 1.40:1 | 3.00:1 | 3:1 |
| red-orange | dark | focus ring | folder panel | 1.66:1 | 3.74:1 | 3:1 |
| red-orange | light, increased contrast | primary text | window gradient | 9.81:1 | 9.81:1 | 4.5:1 |
| red-orange | light, increased contrast | primary text | hovered row | 7.64:1 | 8.27:1 | 4.5:1 |
| red-orange | light, increased contrast | primary text | current row | 7.13:1 | 7.65:1 | 4.5:1 |
| red-orange | light, increased contrast | primary text | selected row | 6.17:1 | 6.47:1 | 4.5:1 |
| red-orange | light, increased contrast | primary text | folder panel | 8.61:1 | 9.42:1 | 4.5:1 |
| red-orange | light, increased contrast | primary text | glass | 9.81:1 | 9.81:1 | 4.5:1 |
| red-orange | light, increased contrast | primary text | switcher selection | 7.13:1 | 9.67:1 | 4.5:1 |
| red-orange | light, increased contrast | secondary text | window gradient | 5.54:1 | 5.83:1 | 4.5:1 |
| red-orange | light, increased contrast | secondary text | hovered row | 4.79:1 | 5.26:1 | 4.5:1 |
| red-orange | light, increased contrast | secondary text | current row | 4.60:1 | 5.01:1 | 4.5:1 |
| red-orange | light, increased contrast | secondary text | selected row | 4.20:1 | 4.50:1 | 4.5:1 |
| red-orange | light, increased contrast | secondary text | folder panel | 5.14:1 | 5.69:1 | 4.5:1 |
| red-orange | light, increased contrast | secondary text | glass | 5.54:1 | 5.83:1 | 4.5:1 |
| red-orange | light, increased contrast | tinted text | window gradient | 7.57:1 | 7.96:1 | 4.5:1 |
| red-orange | light, increased contrast | tinted text | hovered row | 5.63:1 | 6.49:1 | 4.5:1 |
| red-orange | light, increased contrast | tinted text | current row | 5.19:1 | 5.93:1 | 4.5:1 |
| red-orange | light, increased contrast | tinted text | selected row | 4.38:1 | 4.87:1 | 4.5:1 |
| red-orange | light, increased contrast | tinted text | folder panel | 6.48:1 | 7.58:1 | 4.5:1 |
| red-orange | light, increased contrast | tinted text | badge or tile fill | 3.92:1 | 4.50:1 | 4.5:1 |
| red-orange | light, increased contrast | tinted glyph | glass | 2.11:1 | 7.96:1 | 3:1 |
| red-orange | light, increased contrast | text on the hue | the hue, opaque | 3.57:1 | 5.88:1 | 4.5:1 |
| red-orange | light, increased contrast | focus ring | window gradient | 1.85:1 | 4.91:1 | 3:1 |
| red-orange | light, increased contrast | focus ring | hovered row | 1.66:1 | 4.00:1 | 3:1 |
| red-orange | light, increased contrast | focus ring | current row | 1.63:1 | 3.66:1 | 3:1 |
| red-orange | light, increased contrast | focus ring | selected row | 1.59:1 | 3.00:1 | 3:1 |
| red-orange | light, increased contrast | focus ring | folder panel | 1.72:1 | 4.68:1 | 3:1 |
| red-orange | light, increased contrast | selection outline | current row | 1.22:1 | 5.01:1 | 3:1 |
| red-orange | light, increased contrast | selection outline | selected row | 1.21:1 | 4.50:1 | 3:1 |
| red-orange | dark, increased contrast | primary text | window gradient | 7.08:1 | 7.12:1 | 4.5:1 |
| red-orange | dark, increased contrast | primary text | hovered row | 5.15:1 | 5.67:1 | 4.5:1 |
| red-orange | dark, increased contrast | primary text | current row | 4.77:1 | 5.17:1 | 4.5:1 |
| red-orange | dark, increased contrast | primary text | selected row | 4.24:1 | 4.50:1 | 4.5:1 |
| red-orange | dark, increased contrast | primary text | folder panel | 5.80:1 | 6.56:1 | 4.5:1 |
| red-orange | dark, increased contrast | primary text | glass | 7.08:1 | 7.12:1 | 4.5:1 |
| red-orange | dark, increased contrast | primary text | switcher selection | 4.69:1 | 7.06:1 | 4.5:1 |
| red-orange | dark, increased contrast | secondary text | window gradient | 6.62:1 | 7.12:1 | 4.5:1 |
| red-orange | dark, increased contrast | secondary text | hovered row | 4.87:1 | 5.67:1 | 4.5:1 |
| red-orange | dark, increased contrast | secondary text | current row | 4.51:1 | 5.17:1 | 4.5:1 |
| red-orange | dark, increased contrast | secondary text | selected row | 4.02:1 | 4.50:1 | 4.5:1 |
| red-orange | dark, increased contrast | secondary text | folder panel | 5.47:1 | 6.56:1 | 4.5:1 |
| red-orange | dark, increased contrast | secondary text | glass | 6.62:1 | 7.12:1 | 4.5:1 |
| red-orange | dark, increased contrast | tinted text | window gradient | 7.96:1 | 8.39:1 | 4.5:1 |
| red-orange | dark, increased contrast | tinted text | hovered row | 5.60:1 | 6.52:1 | 4.5:1 |
| red-orange | dark, increased contrast | tinted text | current row | 5.17:1 | 5.92:1 | 4.5:1 |
| red-orange | dark, increased contrast | tinted text | selected row | 4.57:1 | 5.11:1 | 4.5:1 |
| red-orange | dark, increased contrast | tinted text | folder panel | 6.35:1 | 7.62:1 | 4.5:1 |
| red-orange | dark, increased contrast | tinted text | badge or tile fill | 3.76:1 | 4.51:1 | 4.5:1 |
| red-orange | dark, increased contrast | tinted glyph | glass | 2.68:1 | 8.39:1 | 3:1 |
| red-orange | dark, increased contrast | text on the hue | the hue, opaque | 3.43:1 | 6.12:1 | 4.5:1 |
| red-orange | dark, increased contrast | focus ring | window gradient | 1.68:1 | 4.93:1 | 3:1 |
| red-orange | dark, increased contrast | focus ring | hovered row | 1.40:1 | 3.83:1 | 3:1 |
| red-orange | dark, increased contrast | focus ring | current row | 1.31:1 | 3.48:1 | 3:1 |
| red-orange | dark, increased contrast | focus ring | selected row | 1.19:1 | 3.00:1 | 3:1 |
| red-orange | dark, increased contrast | focus ring | folder panel | 1.56:1 | 4.48:1 | 3:1 |
| red-orange | dark, increased contrast | selection outline | current row | 1.22:1 | 5.17:1 | 3:1 |
| red-orange | dark, increased contrast | selection outline | selected row | 1.19:1 | 4.50:1 | 3:1 |
| purple-pink | light | primary text | window gradient | 9.60:1 | 9.60:1 | 4.5:1 |
| purple-pink | light | primary text | hovered row | 8.43:1 | 8.43:1 | 4.5:1 |
| purple-pink | light | primary text | current row | 8.05:1 | 8.05:1 | 4.5:1 |
| purple-pink | light | primary text | selected row | 7.21:1 | 7.21:1 | 4.5:1 |
| purple-pink | light | primary text | folder panel | 9.12:1 | 9.12:1 | 4.5:1 |
| purple-pink | light | primary text | glass | 9.60:1 | 9.60:1 | 4.5:1 |
| purple-pink | light | primary text | switcher selection | 9.30:1 | 9.30:1 | 4.5:1 |
| purple-pink | light | secondary text | window gradient | 5.00:1 | 5.30:1 | 4.5:1 |
| purple-pink | light | secondary text | hovered row | 4.68:1 | 4.93:1 | 4.5:1 |
| purple-pink | light | secondary text | current row | 4.56:1 | 4.80:1 | 4.5:1 |
| purple-pink | light | secondary text | selected row | 4.30:1 | 4.51:1 | 4.5:1 |
| purple-pink | light | secondary text | folder panel | 4.87:1 | 5.15:1 | 4.5:1 |
| purple-pink | light | secondary text | glass | 5.00:1 | 5.30:1 | 4.5:1 |
| purple-pink | light | tinted text | window gradient | 6.82:1 | 7.38:1 | 4.5:1 |
| purple-pink | light | tinted text | hovered row | 5.85:1 | 6.33:1 | 4.5:1 |
| purple-pink | light | tinted text | current row | 5.54:1 | 5.99:1 | 4.5:1 |
| purple-pink | light | tinted text | selected row | 4.87:1 | 5.27:1 | 4.5:1 |
| purple-pink | light | tinted text | folder panel | 6.42:1 | 6.94:1 | 4.5:1 |
| purple-pink | light | tinted text | badge or tile fill | 4.17:1 | 4.51:1 | 4.5:1 |
| purple-pink | light | tinted glyph | glass | 2.40:1 | 7.38:1 | 3:1 |
| purple-pink | light | text on the hue | the hue, opaque | 4.17:1 | 5.04:1 | 4.5:1 |
| purple-pink | light | focus ring | window gradient | 1.77:1 | 4.21:1 | 3:1 |
| purple-pink | light | focus ring | hovered row | 1.67:1 | 3.61:1 | 3:1 |
| purple-pink | light | focus ring | current row | 1.64:1 | 3.42:1 | 3:1 |
| purple-pink | light | focus ring | selected row | 1.56:1 | 3.00:1 | 3:1 |
| purple-pink | light | focus ring | folder panel | 1.73:1 | 3.96:1 | 3:1 |
| purple-pink | dark | primary text | window gradient | 7.27:1 | 7.27:1 | 4.5:1 |
| purple-pink | dark | primary text | hovered row | 6.29:1 | 6.29:1 | 4.5:1 |
| purple-pink | dark | primary text | current row | 5.99:1 | 5.99:1 | 4.5:1 |
| purple-pink | dark | primary text | selected row | 5.55:1 | 5.55:1 | 4.5:1 |
| purple-pink | dark | primary text | folder panel | 6.82:1 | 6.82:1 | 4.5:1 |
| purple-pink | dark | primary text | glass | 7.27:1 | 7.27:1 | 4.5:1 |
| purple-pink | dark | primary text | switcher selection | 7.37:1 | 7.37:1 | 4.5:1 |
| purple-pink | dark | secondary text | window gradient | 5.26:1 | 5.75:1 | 4.5:1 |
| purple-pink | dark | secondary text | hovered row | 4.66:1 | 5.06:1 | 4.5:1 |
| purple-pink | dark | secondary text | current row | 4.45:1 | 4.83:1 | 4.5:1 |
| purple-pink | dark | secondary text | selected row | 4.16:1 | 4.50:1 | 4.5:1 |
| purple-pink | dark | secondary text | folder panel | 5.01:1 | 5.46:1 | 4.5:1 |
| purple-pink | dark | secondary text | glass | 5.26:1 | 5.75:1 | 4.5:1 |
| purple-pink | dark | tinted text | window gradient | 6.62:1 | 7.15:1 | 4.5:1 |
| purple-pink | dark | tinted text | hovered row | 5.64:1 | 6.09:1 | 4.5:1 |
| purple-pink | dark | tinted text | current row | 5.35:1 | 5.78:1 | 4.5:1 |
| purple-pink | dark | tinted text | selected row | 4.94:1 | 5.33:1 | 4.5:1 |
| purple-pink | dark | tinted text | folder panel | 6.14:1 | 6.63:1 | 4.5:1 |
| purple-pink | dark | tinted text | badge or tile fill | 4.17:1 | 4.50:1 | 4.5:1 |
| purple-pink | dark | tinted glyph | glass | 2.61:1 | 7.15:1 | 3:1 |
| purple-pink | dark | text on the hue | the hue, opaque | 3.63:1 | 5.79:1 | 4.5:1 |
| purple-pink | dark | focus ring | window gradient | 1.78:1 | 4.02:1 | 3:1 |
| purple-pink | dark | focus ring | hovered row | 1.64:1 | 3.42:1 | 3:1 |
| purple-pink | dark | focus ring | current row | 1.58:1 | 3.25:1 | 3:1 |
| purple-pink | dark | focus ring | selected row | 1.49:1 | 3.00:1 | 3:1 |
| purple-pink | dark | focus ring | folder panel | 1.74:1 | 3.73:1 | 3:1 |
| purple-pink | light, increased contrast | primary text | window gradient | 9.60:1 | 9.60:1 | 4.5:1 |
| purple-pink | light, increased contrast | primary text | hovered row | 7.32:1 | 7.92:1 | 4.5:1 |
| purple-pink | light, increased contrast | primary text | current row | 6.78:1 | 7.28:1 | 4.5:1 |
| purple-pink | light, increased contrast | primary text | selected row | 5.72:1 | 6.01:1 | 4.5:1 |
| purple-pink | light, increased contrast | primary text | folder panel | 8.33:1 | 9.12:1 | 4.5:1 |
| purple-pink | light, increased contrast | primary text | glass | 9.60:1 | 9.60:1 | 4.5:1 |
| purple-pink | light, increased contrast | primary text | switcher selection | 6.66:1 | 9.30:1 | 4.5:1 |
| purple-pink | light, increased contrast | secondary text | window gradient | 5.84:1 | 6.19:1 | 4.5:1 |
| purple-pink | light, increased contrast | secondary text | hovered row | 4.92:1 | 5.45:1 | 4.5:1 |
| purple-pink | light, increased contrast | secondary text | current row | 4.68:1 | 5.15:1 | 4.5:1 |
| purple-pink | light, increased contrast | secondary text | selected row | 4.18:1 | 4.50:1 | 4.5:1 |
| purple-pink | light, increased contrast | secondary text | folder panel | 5.35:1 | 5.98:1 | 4.5:1 |
| purple-pink | light, increased contrast | secondary text | glass | 5.84:1 | 6.19:1 | 4.5:1 |
| purple-pink | light, increased contrast | tinted text | window gradient | 8.12:1 | 8.56:1 | 4.5:1 |
| purple-pink | light, increased contrast | tinted text | hovered row | 5.90:1 | 6.82:1 | 4.5:1 |
| purple-pink | light, increased contrast | tinted text | current row | 5.40:1 | 6.18:1 | 4.5:1 |
| purple-pink | light, increased contrast | tinted text | selected row | 4.44:1 | 4.95:1 | 4.5:1 |
| purple-pink | light, increased contrast | tinted text | folder panel | 6.87:1 | 8.06:1 | 4.5:1 |
| purple-pink | light, increased contrast | tinted text | badge or tile fill | 3.86:1 | 4.50:1 | 4.5:1 |
| purple-pink | light, increased contrast | tinted glyph | glass | 2.40:1 | 8.56:1 | 3:1 |
| purple-pink | light, increased contrast | text on the hue | the hue, opaque | 4.17:1 | 5.04:1 | 4.5:1 |
| purple-pink | light, increased contrast | focus ring | window gradient | 1.77:1 | 5.19:1 | 3:1 |
| purple-pink | light, increased contrast | focus ring | hovered row | 1.56:1 | 4.14:1 | 3:1 |
| purple-pink | light, increased contrast | focus ring | current row | 1.51:1 | 3.75:1 | 3:1 |
| purple-pink | light, increased contrast | focus ring | selected row | 1.41:1 | 3.00:1 | 3:1 |
| purple-pink | light, increased contrast | focus ring | folder panel | 1.65:1 | 4.89:1 | 3:1 |
| purple-pink | light, increased contrast | selection outline | current row | 1.22:1 | 5.15:1 | 3:1 |
| purple-pink | light, increased contrast | selection outline | selected row | 1.21:1 | 4.50:1 | 3:1 |
| purple-pink | dark, increased contrast | primary text | window gradient | 7.27:1 | 7.27:1 | 4.5:1 |
| purple-pink | dark, increased contrast | primary text | hovered row | 5.38:1 | 5.89:1 | 4.5:1 |
| purple-pink | dark, increased contrast | primary text | current row | 4.99:1 | 5.38:1 | 4.5:1 |
| purple-pink | dark, increased contrast | primary text | selected row | 4.44:1 | 4.68:1 | 4.5:1 |
| purple-pink | dark, increased contrast | primary text | folder panel | 6.06:1 | 6.82:1 | 4.5:1 |
| purple-pink | dark, increased contrast | primary text | glass | 7.27:1 | 7.27:1 | 4.5:1 |
| purple-pink | dark, increased contrast | primary text | switcher selection | 4.91:1 | 7.37:1 | 4.5:1 |
| purple-pink | dark, increased contrast | secondary text | window gradient | 6.46:1 | 6.94:1 | 4.5:1 |
| purple-pink | dark, increased contrast | secondary text | hovered row | 4.86:1 | 5.65:1 | 4.5:1 |
| purple-pink | dark, increased contrast | secondary text | current row | 4.52:1 | 5.16:1 | 4.5:1 |
| purple-pink | dark, increased contrast | secondary text | selected row | 4.03:1 | 4.50:1 | 4.5:1 |
| purple-pink | dark, increased contrast | secondary text | folder panel | 5.45:1 | 6.52:1 | 4.5:1 |
| purple-pink | dark, increased contrast | secondary text | glass | 6.46:1 | 6.94:1 | 4.5:1 |
| purple-pink | dark, increased contrast | tinted text | window gradient | 7.76:1 | 8.19:1 | 4.5:1 |
| purple-pink | dark, increased contrast | tinted text | hovered row | 5.56:1 | 6.50:1 | 4.5:1 |
| purple-pink | dark, increased contrast | tinted text | current row | 5.14:1 | 5.91:1 | 4.5:1 |
| purple-pink | dark, increased contrast | tinted text | selected row | 4.55:1 | 5.10:1 | 4.5:1 |
| purple-pink | dark, increased contrast | tinted text | folder panel | 6.30:1 | 7.59:1 | 4.5:1 |
| purple-pink | dark, increased contrast | tinted text | badge or tile fill | 3.75:1 | 4.51:1 | 4.5:1 |
| purple-pink | dark, increased contrast | tinted glyph | glass | 2.61:1 | 8.19:1 | 3:1 |
| purple-pink | dark, increased contrast | text on the hue | the hue, opaque | 3.63:1 | 5.79:1 | 4.5:1 |
| purple-pink | dark, increased contrast | focus ring | window gradient | 1.78:1 | 4.82:1 | 3:1 |
| purple-pink | dark, increased contrast | focus ring | hovered row | 1.49:1 | 3.83:1 | 3:1 |
| purple-pink | dark, increased contrast | focus ring | current row | 1.40:1 | 3.47:1 | 3:1 |
| purple-pink | dark, increased contrast | focus ring | selected row | 1.28:1 | 3.00:1 | 3:1 |
| purple-pink | dark, increased contrast | focus ring | folder panel | 1.63:1 | 4.47:1 | 3:1 |
| purple-pink | dark, increased contrast | selection outline | current row | 1.22:1 | 5.16:1 | 3:1 |
| purple-pink | dark, increased contrast | selection outline | selected row | 1.19:1 | 4.50:1 | 3:1 |
| mint-cyan | light | primary text | window gradient | 11.68:1 | 11.68:1 | 4.5:1 |
| mint-cyan | light | primary text | hovered row | 10.44:1 | 10.44:1 | 4.5:1 |
| mint-cyan | light | primary text | current row | 10.23:1 | 10.23:1 | 4.5:1 |
| mint-cyan | light | primary text | selected row | 9.22:1 | 9.22:1 | 4.5:1 |
| mint-cyan | light | primary text | folder panel | 10.80:1 | 10.80:1 | 4.5:1 |
| mint-cyan | light | primary text | glass | 11.68:1 | 11.68:1 | 4.5:1 |
| mint-cyan | light | primary text | switcher selection | 11.50:1 | 11.50:1 | 4.5:1 |
| mint-cyan | light | secondary text | window gradient | 4.84:1 | 4.99:1 | 4.5:1 |
| mint-cyan | light | secondary text | hovered row | 4.62:1 | 4.76:1 | 4.5:1 |
| mint-cyan | light | secondary text | current row | 4.58:1 | 4.72:1 | 4.5:1 |
| mint-cyan | light | secondary text | selected row | 4.39:1 | 4.51:1 | 4.5:1 |
| mint-cyan | light | secondary text | folder panel | 4.69:1 | 4.83:1 | 4.5:1 |
| mint-cyan | light | secondary text | glass | 4.84:1 | 4.99:1 | 4.5:1 |
| mint-cyan | light | tinted text | window gradient | 5.96:1 | 6.28:1 | 4.5:1 |
| mint-cyan | light | tinted text | hovered row | 5.19:1 | 5.47:1 | 4.5:1 |
| mint-cyan | light | tinted text | current row | 5.06:1 | 5.34:1 | 4.5:1 |
| mint-cyan | light | tinted text | selected row | 4.46:1 | 4.70:1 | 4.5:1 |
| mint-cyan | light | tinted text | folder panel | 5.42:1 | 5.71:1 | 4.5:1 |
| mint-cyan | light | tinted text | badge or tile fill | 4.28:1 | 4.51:1 | 4.5:1 |
| mint-cyan | light | tinted glyph | glass | 1.55:1 | 6.28:1 | 3:1 |
| mint-cyan | light | text on the hue | the hue, opaque | 2.12:1 | 9.91:1 | 4.5:1 |
| mint-cyan | light | focus ring | window gradient | 1.87:1 | 4.01:1 | 3:1 |
| mint-cyan | light | focus ring | hovered row | 1.77:1 | 3.50:1 | 3:1 |
| mint-cyan | light | focus ring | current row | 1.75:1 | 3.41:1 | 3:1 |
| mint-cyan | light | focus ring | selected row | 1.65:1 | 3.00:1 | 3:1 |
| mint-cyan | light | focus ring | folder panel | 1.81:1 | 3.65:1 | 3:1 |
| mint-cyan | dark | primary text | window gradient | 4.95:1 | 6.51:1 | 4.5:1 |
| mint-cyan | dark | primary text | hovered row | 4.29:1 | 5.46:1 | 4.5:1 |
| mint-cyan | dark | primary text | current row | 3.97:1 | 5.10:1 | 4.5:1 |
| mint-cyan | dark | primary text | selected row | 3.55:1 | 4.62:1 | 4.5:1 |
| mint-cyan | dark | primary text | folder panel | 4.88:1 | 6.10:1 | 4.5:1 |
| mint-cyan | dark | primary text | glass | 4.95:1 | 6.51:1 | 4.5:1 |
| mint-cyan | dark | primary text | switcher selection | 5.03:1 | 5.24:1 | 4.5:1 |
| mint-cyan | dark | secondary text | window gradient | 4.95:1 | 6.33:1 | 4.5:1 |
| mint-cyan | dark | secondary text | hovered row | 4.29:1 | 5.31:1 | 4.5:1 |
| mint-cyan | dark | secondary text | current row | 3.97:1 | 4.97:1 | 4.5:1 |
| mint-cyan | dark | secondary text | selected row | 3.55:1 | 4.50:1 | 4.5:1 |
| mint-cyan | dark | secondary text | folder panel | 4.88:1 | 5.94:1 | 4.5:1 |
| mint-cyan | dark | secondary text | glass | 4.95:1 | 6.33:1 | 4.5:1 |
| mint-cyan | dark | tinted text | window gradient | 6.19:1 | 8.35:1 | 4.5:1 |
| mint-cyan | dark | tinted text | hovered row | 5.28:1 | 6.86:1 | 4.5:1 |
| mint-cyan | dark | tinted text | current row | 4.86:1 | 6.38:1 | 4.5:1 |
| mint-cyan | dark | tinted text | selected row | 4.30:1 | 5.72:1 | 4.5:1 |
| mint-cyan | dark | tinted text | folder panel | 6.08:1 | 7.75:1 | 4.5:1 |
| mint-cyan | dark | tinted text | badge or tile fill | 3.37:1 | 4.50:1 | 4.5:1 |
| mint-cyan | dark | tinted glyph | glass | 3.48:1 | 8.35:1 | 3:1 |
| mint-cyan | dark | text on the hue | the hue, opaque | 1.78:1 | 11.82:1 | 4.5:1 |
| mint-cyan | dark | focus ring | window gradient | 1.58:1 | 4.38:1 | 3:1 |
| mint-cyan | dark | focus ring | hovered row | 1.45:1 | 3.60:1 | 3:1 |
| mint-cyan | dark | focus ring | current row | 1.38:1 | 3.35:1 | 3:1 |
| mint-cyan | dark | focus ring | selected row | 1.29:1 | 3.00:1 | 3:1 |
| mint-cyan | dark | focus ring | folder panel | 1.56:1 | 4.07:1 | 3:1 |
| mint-cyan | light, increased contrast | primary text | window gradient | 11.68:1 | 11.68:1 | 4.5:1 |
| mint-cyan | light, increased contrast | primary text | hovered row | 9.42:1 | 10.16:1 | 4.5:1 |
| mint-cyan | light, increased contrast | primary text | current row | 9.18:1 | 9.82:1 | 4.5:1 |
| mint-cyan | light, increased contrast | primary text | selected row | 8.72:1 | 9.12:1 | 4.5:1 |
| mint-cyan | light, increased contrast | primary text | folder panel | 9.87:1 | 10.80:1 | 4.5:1 |
| mint-cyan | light, increased contrast | primary text | glass | 11.68:1 | 11.68:1 | 4.5:1 |
| mint-cyan | light, increased contrast | primary text | switcher selection | 9.82:1 | 11.50:1 | 4.5:1 |
| mint-cyan | light, increased contrast | secondary text | window gradient | 4.87:1 | 5.01:1 | 4.5:1 |
| mint-cyan | light, increased contrast | secondary text | hovered row | 4.45:1 | 4.72:1 | 4.5:1 |
| mint-cyan | light, increased contrast | secondary text | current row | 4.40:1 | 4.65:1 | 4.5:1 |
| mint-cyan | light, increased contrast | secondary text | selected row | 4.31:1 | 4.50:1 | 4.5:1 |
| mint-cyan | light, increased contrast | secondary text | folder panel | 4.54:1 | 4.85:1 | 4.5:1 |
| mint-cyan | light, increased contrast | secondary text | glass | 4.87:1 | 5.01:1 | 4.5:1 |
| mint-cyan | light, increased contrast | tinted text | window gradient | 6.02:1 | 6.33:1 | 4.5:1 |
| mint-cyan | light, increased contrast | tinted text | hovered row | 4.64:1 | 5.34:1 | 4.5:1 |
| mint-cyan | light, increased contrast | tinted text | current row | 4.49:1 | 5.12:1 | 4.5:1 |
| mint-cyan | light, increased contrast | tinted text | selected row | 4.22:1 | 4.67:1 | 4.5:1 |
| mint-cyan | light, increased contrast | tinted text | folder panel | 4.91:1 | 5.75:1 | 4.5:1 |
| mint-cyan | light, increased contrast | tinted text | badge or tile fill | 4.05:1 | 4.50:1 | 4.5:1 |
| mint-cyan | light, increased contrast | tinted glyph | glass | 1.55:1 | 6.33:1 | 3:1 |
| mint-cyan | light, increased contrast | text on the hue | the hue, opaque | 2.12:1 | 9.91:1 | 4.5:1 |
| mint-cyan | light, increased contrast | focus ring | window gradient | 1.87:1 | 4.07:1 | 3:1 |
| mint-cyan | light, increased contrast | focus ring | hovered row | 1.68:1 | 3.43:1 | 3:1 |
| mint-cyan | light, increased contrast | focus ring | current row | 1.65:1 | 3.29:1 | 3:1 |
| mint-cyan | light, increased contrast | focus ring | selected row | 1.60:1 | 3.00:1 | 3:1 |
| mint-cyan | light, increased contrast | focus ring | folder panel | 1.73:1 | 3.70:1 | 3:1 |
| mint-cyan | light, increased contrast | selection outline | current row | 1.23:1 | 4.65:1 | 3:1 |
| mint-cyan | light, increased contrast | selection outline | selected row | 1.23:1 | 4.50:1 | 3:1 |
| mint-cyan | dark, increased contrast | primary text | window gradient | 4.95:1 | 7.59:1 | 4.5:1 |
| mint-cyan | dark, increased contrast | primary text | hovered row | 3.59:1 | 5.82:1 | 4.5:1 |
| mint-cyan | dark, increased contrast | primary text | current row | 3.19:1 | 5.25:1 | 4.5:1 |
| mint-cyan | dark, increased contrast | primary text | selected row | 2.68:1 | 4.50:1 | 4.5:1 |
| mint-cyan | dark, increased contrast | primary text | folder panel | 4.41:1 | 6.91:1 | 4.5:1 |
| mint-cyan | dark, increased contrast | primary text | glass | 4.95:1 | 7.59:1 | 4.5:1 |
| mint-cyan | dark, increased contrast | primary text | switcher selection | 2.90:1 | 5.36:1 | 4.5:1 |
| mint-cyan | dark, increased contrast | secondary text | window gradient | 4.95:1 | 7.59:1 | 4.5:1 |
| mint-cyan | dark, increased contrast | secondary text | hovered row | 3.59:1 | 5.82:1 | 4.5:1 |
| mint-cyan | dark, increased contrast | secondary text | current row | 3.19:1 | 5.25:1 | 4.5:1 |
| mint-cyan | dark, increased contrast | secondary text | selected row | 2.68:1 | 4.50:1 | 4.5:1 |
| mint-cyan | dark, increased contrast | secondary text | folder panel | 4.41:1 | 6.91:1 | 4.5:1 |
| mint-cyan | dark, increased contrast | secondary text | glass | 4.95:1 | 7.59:1 | 4.5:1 |
| mint-cyan | dark, increased contrast | tinted text | window gradient | 6.19:1 | 9.58:1 | 4.5:1 |
| mint-cyan | dark, increased contrast | tinted text | hovered row | 4.34:1 | 7.16:1 | 4.5:1 |
| mint-cyan | dark, increased contrast | tinted text | current row | 3.81:1 | 6.40:1 | 4.5:1 |
| mint-cyan | dark, increased contrast | tinted text | selected row | 3.16:1 | 5.42:1 | 4.5:1 |
| mint-cyan | dark, increased contrast | tinted text | folder panel | 5.43:1 | 8.63:1 | 4.5:1 |
| mint-cyan | dark, increased contrast | tinted text | badge or tile fill | 2.41:1 | 4.50:1 | 4.5:1 |
| mint-cyan | dark, increased contrast | tinted glyph | glass | 3.48:1 | 9.58:1 | 3:1 |
| mint-cyan | dark, increased contrast | text on the hue | the hue, opaque | 1.78:1 | 11.82:1 | 4.5:1 |
| mint-cyan | dark, increased contrast | focus ring | window gradient | 1.58:1 | 5.31:1 | 3:1 |
| mint-cyan | dark, increased contrast | focus ring | hovered row | 1.30:1 | 3.97:1 | 3:1 |
| mint-cyan | dark, increased contrast | focus ring | current row | 1.21:1 | 3.54:1 | 3:1 |
| mint-cyan | dark, increased contrast | focus ring | selected row | 1.10:1 | 3.00:1 | 3:1 |
| mint-cyan | dark, increased contrast | focus ring | folder panel | 1.46:1 | 4.78:1 | 3:1 |
| mint-cyan | dark, increased contrast | selection outline | current row | 1.16:1 | 5.25:1 | 3:1 |
| mint-cyan | dark, increased contrast | selection outline | selected row | 1.12:1 | 4.50:1 | 3:1 |
| brown-yellow | light | primary text | window gradient | 10.70:1 | 10.70:1 | 4.5:1 |
| brown-yellow | light | primary text | hovered row | 9.63:1 | 9.63:1 | 4.5:1 |
| brown-yellow | light | primary text | current row | 9.29:1 | 9.29:1 | 4.5:1 |
| brown-yellow | light | primary text | selected row | 8.42:1 | 8.42:1 | 4.5:1 |
| brown-yellow | light | primary text | folder panel | 10.22:1 | 10.22:1 | 4.5:1 |
| brown-yellow | light | primary text | glass | 10.70:1 | 10.70:1 | 4.5:1 |
| brown-yellow | light | primary text | switcher selection | 10.64:1 | 10.64:1 | 4.5:1 |
| brown-yellow | light | secondary text | window gradient | 4.84:1 | 5.06:1 | 4.5:1 |
| brown-yellow | light | secondary text | hovered row | 4.61:1 | 4.81:1 | 4.5:1 |
| brown-yellow | light | secondary text | current row | 4.54:1 | 4.73:1 | 4.5:1 |
| brown-yellow | light | secondary text | selected row | 4.33:1 | 4.50:1 | 4.5:1 |
| brown-yellow | light | secondary text | folder panel | 4.74:1 | 4.95:1 | 4.5:1 |
| brown-yellow | light | secondary text | glass | 4.84:1 | 5.06:1 | 4.5:1 |
| brown-yellow | light | tinted text | window gradient | 6.34:1 | 6.83:1 | 4.5:1 |
| brown-yellow | light | tinted text | hovered row | 5.58:1 | 6.02:1 | 4.5:1 |
| brown-yellow | light | tinted text | current row | 5.34:1 | 5.76:1 | 4.5:1 |
| brown-yellow | light | tinted text | selected row | 4.76:1 | 5.13:1 | 4.5:1 |
| brown-yellow | light | tinted text | folder panel | 5.99:1 | 6.46:1 | 4.5:1 |
| brown-yellow | light | tinted text | badge or tile fill | 4.18:1 | 4.50:1 | 4.5:1 |
| brown-yellow | light | tinted glyph | glass | 2.32:1 | 6.83:1 | 3:1 |
| brown-yellow | light | text on the hue | the hue, opaque | 3.53:1 | 5.95:1 | 4.5:1 |
| brown-yellow | light | focus ring | window gradient | 1.87:1 | 4.00:1 | 3:1 |
| brown-yellow | light | focus ring | hovered row | 1.78:1 | 3.52:1 | 3:1 |
| brown-yellow | light | focus ring | current row | 1.75:1 | 3.37:1 | 3:1 |
| brown-yellow | light | focus ring | selected row | 1.68:1 | 3.00:1 | 3:1 |
| brown-yellow | light | focus ring | folder panel | 1.82:1 | 3.78:1 | 3:1 |
| brown-yellow | dark | primary text | window gradient | 6.45:1 | 6.45:1 | 4.5:1 |
| brown-yellow | dark | primary text | hovered row | 5.33:1 | 5.33:1 | 4.5:1 |
| brown-yellow | dark | primary text | current row | 5.07:1 | 5.07:1 | 4.5:1 |
| brown-yellow | dark | primary text | selected row | 4.70:1 | 4.70:1 | 4.5:1 |
| brown-yellow | dark | primary text | folder panel | 5.80:1 | 5.80:1 | 4.5:1 |
| brown-yellow | dark | primary text | glass | 6.45:1 | 6.45:1 | 4.5:1 |
| brown-yellow | dark | primary text | switcher selection | 6.32:1 | 6.32:1 | 4.5:1 |
| brown-yellow | dark | secondary text | window gradient | 5.45:1 | 6.14:1 | 4.5:1 |
| brown-yellow | dark | secondary text | hovered row | 4.57:1 | 5.09:1 | 4.5:1 |
| brown-yellow | dark | secondary text | current row | 4.36:1 | 4.85:1 | 4.5:1 |
| brown-yellow | dark | secondary text | selected row | 4.07:1 | 4.50:1 | 4.5:1 |
| brown-yellow | dark | secondary text | folder panel | 4.95:1 | 5.54:1 | 4.5:1 |
| brown-yellow | dark | secondary text | glass | 5.45:1 | 6.14:1 | 4.5:1 |
| brown-yellow | dark | tinted text | window gradient | 6.92:1 | 7.54:1 | 4.5:1 |
| brown-yellow | dark | tinted text | hovered row | 5.61:1 | 6.12:1 | 4.5:1 |
| brown-yellow | dark | tinted text | current row | 5.30:1 | 5.79:1 | 4.5:1 |
| brown-yellow | dark | tinted text | selected row | 4.88:1 | 5.33:1 | 4.5:1 |
| brown-yellow | dark | tinted text | folder panel | 6.16:1 | 6.72:1 | 4.5:1 |
| brown-yellow | dark | tinted text | badge or tile fill | 4.13:1 | 4.50:1 | 4.5:1 |
| brown-yellow | dark | tinted glyph | glass | 2.67:1 | 7.54:1 | 3:1 |
| brown-yellow | dark | text on the hue | the hue, opaque | 3.07:1 | 6.84:1 | 4.5:1 |
| brown-yellow | dark | focus ring | window gradient | 1.74:1 | 4.25:1 | 3:1 |
| brown-yellow | dark | focus ring | hovered row | 1.55:1 | 3.45:1 | 3:1 |
| brown-yellow | dark | focus ring | current row | 1.50:1 | 3.26:1 | 3:1 |
| brown-yellow | dark | focus ring | selected row | 1.43:1 | 3.00:1 | 3:1 |
| brown-yellow | dark | focus ring | folder panel | 1.64:1 | 3.79:1 | 3:1 |
| brown-yellow | light, increased contrast | primary text | window gradient | 10.70:1 | 10.70:1 | 4.5:1 |
| brown-yellow | light, increased contrast | primary text | hovered row | 8.49:1 | 9.18:1 | 4.5:1 |
| brown-yellow | light, increased contrast | primary text | current row | 8.00:1 | 8.58:1 | 4.5:1 |
| brown-yellow | light, increased contrast | primary text | selected row | 6.92:1 | 7.27:1 | 4.5:1 |
| brown-yellow | light, increased contrast | primary text | folder panel | 9.34:1 | 10.22:1 | 4.5:1 |
| brown-yellow | light, increased contrast | primary text | glass | 10.70:1 | 10.70:1 | 4.5:1 |
| brown-yellow | light, increased contrast | primary text | switcher selection | 8.04:1 | 10.64:1 | 4.5:1 |
| brown-yellow | light, increased contrast | secondary text | window gradient | 5.35:1 | 5.58:1 | 4.5:1 |
| brown-yellow | light, increased contrast | secondary text | hovered row | 4.75:1 | 5.15:1 | 4.5:1 |
| brown-yellow | light, increased contrast | secondary text | current row | 4.60:1 | 4.96:1 | 4.5:1 |
| brown-yellow | light, increased contrast | secondary text | selected row | 4.23:1 | 4.50:1 | 4.5:1 |
| brown-yellow | light, increased contrast | secondary text | folder panel | 4.99:1 | 5.45:1 | 4.5:1 |
| brown-yellow | light, increased contrast | secondary text | glass | 5.35:1 | 5.58:1 | 4.5:1 |
| brown-yellow | light, increased contrast | tinted text | window gradient | 7.40:1 | 7.82:1 | 4.5:1 |
| brown-yellow | light, increased contrast | tinted text | hovered row | 5.61:1 | 6.50:1 | 4.5:1 |
| brown-yellow | light, increased contrast | tinted text | current row | 5.23:1 | 6.00:1 | 4.5:1 |
| brown-yellow | light, increased contrast | tinted text | selected row | 4.42:1 | 4.94:1 | 4.5:1 |
| brown-yellow | light, increased contrast | tinted text | folder panel | 6.28:1 | 7.39:1 | 4.5:1 |
| brown-yellow | light, increased contrast | tinted text | badge or tile fill | 3.83:1 | 4.51:1 | 4.5:1 |
| brown-yellow | light, increased contrast | tinted glyph | glass | 2.32:1 | 7.82:1 | 3:1 |
| brown-yellow | light, increased contrast | text on the hue | the hue, opaque | 3.53:1 | 5.95:1 | 4.5:1 |
| brown-yellow | light, increased contrast | focus ring | window gradient | 1.87:1 | 4.75:1 | 3:1 |
| brown-yellow | light, increased contrast | focus ring | hovered row | 1.68:1 | 3.95:1 | 3:1 |
| brown-yellow | light, increased contrast | focus ring | current row | 1.63:1 | 3.65:1 | 3:1 |
| brown-yellow | light, increased contrast | focus ring | selected row | 1.53:1 | 3.00:1 | 3:1 |
| brown-yellow | light, increased contrast | focus ring | folder panel | 1.75:1 | 4.49:1 | 3:1 |
| brown-yellow | light, increased contrast | selection outline | current row | 1.22:1 | 4.96:1 | 3:1 |
| brown-yellow | light, increased contrast | selection outline | selected row | 1.22:1 | 4.50:1 | 3:1 |
| brown-yellow | dark, increased contrast | primary text | window gradient | 6.45:1 | 7.25:1 | 4.5:1 |
| brown-yellow | dark, increased contrast | primary text | hovered row | 4.53:1 | 5.56:1 | 4.5:1 |
| brown-yellow | dark, increased contrast | primary text | current row | 4.20:1 | 5.10:1 | 4.5:1 |
| brown-yellow | dark, increased contrast | primary text | selected row | 3.76:1 | 4.50:1 | 4.5:1 |
| brown-yellow | dark, increased contrast | primary text | folder panel | 5.15:1 | 6.42:1 | 4.5:1 |
| brown-yellow | dark, increased contrast | primary text | glass | 6.45:1 | 7.25:1 | 4.5:1 |
| brown-yellow | dark, increased contrast | primary text | switcher selection | 4.24:1 | 6.47:1 | 4.5:1 |
| brown-yellow | dark, increased contrast | secondary text | window gradient | 6.45:1 | 7.25:1 | 4.5:1 |
| brown-yellow | dark, increased contrast | secondary text | hovered row | 4.53:1 | 5.56:1 | 4.5:1 |
| brown-yellow | dark, increased contrast | secondary text | current row | 4.20:1 | 5.10:1 | 4.5:1 |
| brown-yellow | dark, increased contrast | secondary text | selected row | 3.76:1 | 4.50:1 | 4.5:1 |
| brown-yellow | dark, increased contrast | secondary text | folder panel | 5.15:1 | 6.42:1 | 4.5:1 |
| brown-yellow | dark, increased contrast | secondary text | glass | 6.45:1 | 7.25:1 | 4.5:1 |
| brown-yellow | dark, increased contrast | tinted text | window gradient | 8.08:1 | 8.66:1 | 4.5:1 |
| brown-yellow | dark, increased contrast | tinted text | hovered row | 5.47:1 | 6.47:1 | 4.5:1 |
| brown-yellow | dark, increased contrast | tinted text | current row | 5.04:1 | 5.89:1 | 4.5:1 |
| brown-yellow | dark, increased contrast | tinted text | selected row | 4.46:1 | 5.13:1 | 4.5:1 |
| brown-yellow | dark, increased contrast | tinted text | folder panel | 6.31:1 | 7.58:1 | 4.5:1 |
| brown-yellow | dark, increased contrast | tinted text | badge or tile fill | 3.73:1 | 4.50:1 | 4.5:1 |
| brown-yellow | dark, increased contrast | tinted glyph | glass | 2.67:1 | 8.66:1 | 3:1 |
| brown-yellow | dark, increased contrast | text on the hue | the hue, opaque | 3.07:1 | 6.84:1 | 4.5:1 |
| brown-yellow | dark, increased contrast | focus ring | window gradient | 1.74:1 | 5.07:1 | 3:1 |
| brown-yellow | dark, increased contrast | focus ring | hovered row | 1.40:1 | 3.79:1 | 3:1 |
| brown-yellow | dark, increased contrast | focus ring | current row | 1.33:1 | 3.45:1 | 3:1 |
| brown-yellow | dark, increased contrast | focus ring | selected row | 1.24:1 | 3.00:1 | 3:1 |
| brown-yellow | dark, increased contrast | focus ring | folder panel | 1.52:1 | 4.44:1 | 3:1 |
| brown-yellow | dark, increased contrast | selection outline | current row | 1.22:1 | 5.10:1 | 3:1 |
| brown-yellow | dark, increased contrast | selection outline | selected row | 1.20:1 | 4.50:1 | 3:1 |
| indigo | light | symbol on the hue | the hue, opaque | 5.09:1 | 5.09:1 | 3:1 |
| blue | light | symbol on the hue | the hue, opaque | 3.52:1 | 3.52:1 | 3:1 |
| orange | light | symbol on the hue | the hue, opaque | 2.31:1 | 9.09:1 | 3:1 |
| pink | light | symbol on the hue | the hue, opaque | 3.65:1 | 3.65:1 | 3:1 |
| teal | light | symbol on the hue | the hue, opaque | 2.16:1 | 9.72:1 | 3:1 |
| green | light | symbol on the hue | the hue, opaque | 2.22:1 | 9.46:1 | 3:1 |
| red | light | symbol on the hue | the hue, opaque | 3.57:1 | 3.57:1 | 3:1 |
| purple | light | symbol on the hue | the hue, opaque | 4.17:1 | 4.17:1 | 3:1 |
| mint | light | symbol on the hue | the hue, opaque | 2.12:1 | 9.91:1 | 3:1 |
| cyan | light | symbol on the hue | the hue, opaque | 2.16:1 | 9.71:1 | 3:1 |
| brown | light | symbol on the hue | the hue, opaque | 3.53:1 | 3.53:1 | 3:1 |
| yellow | light | symbol on the hue | the hue, opaque | 1.51:1 | 13.89:1 | 3:1 |
| indigo | dark | symbol on the hue | the hue, opaque | 3.51:1 | 3.51:1 | 3:1 |
| blue | dark | symbol on the hue | the hue, opaque | 3.23:1 | 3.23:1 | 3:1 |
| orange | dark | symbol on the hue | the hue, opaque | 2.23:1 | 9.41:1 | 3:1 |
| pink | dark | symbol on the hue | the hue, opaque | 3.52:1 | 3.52:1 | 3:1 |
| teal | dark | symbol on the hue | the hue, opaque | 1.86:1 | 11.30:1 | 3:1 |
| green | dark | symbol on the hue | the hue, opaque | 2.02:1 | 10.39:1 | 3:1 |
| red | dark | symbol on the hue | the hue, opaque | 3.43:1 | 3.43:1 | 3:1 |
| purple | dark | symbol on the hue | the hue, opaque | 3.63:1 | 3.63:1 | 3:1 |
| mint | dark | symbol on the hue | the hue, opaque | 1.78:1 | 11.82:1 | 3:1 |
| cyan | dark | symbol on the hue | the hue, opaque | 1.76:1 | 11.94:1 | 3:1 |
| brown | dark | symbol on the hue | the hue, opaque | 3.07:1 | 3.07:1 | 3:1 |
| yellow | dark | symbol on the hue | the hue, opaque | 1.41:1 | 14.87:1 | 3:1 |
| indigo | light, increased contrast | symbol on the hue | the hue, opaque | 5.09:1 | 5.09:1 | 3:1 |
| blue | light, increased contrast | symbol on the hue | the hue, opaque | 3.52:1 | 3.52:1 | 3:1 |
| orange | light, increased contrast | symbol on the hue | the hue, opaque | 2.31:1 | 9.09:1 | 3:1 |
| pink | light, increased contrast | symbol on the hue | the hue, opaque | 3.65:1 | 3.65:1 | 3:1 |
| teal | light, increased contrast | symbol on the hue | the hue, opaque | 2.16:1 | 9.72:1 | 3:1 |
| green | light, increased contrast | symbol on the hue | the hue, opaque | 2.22:1 | 9.46:1 | 3:1 |
| red | light, increased contrast | symbol on the hue | the hue, opaque | 3.57:1 | 3.57:1 | 3:1 |
| purple | light, increased contrast | symbol on the hue | the hue, opaque | 4.17:1 | 4.17:1 | 3:1 |
| mint | light, increased contrast | symbol on the hue | the hue, opaque | 2.12:1 | 9.91:1 | 3:1 |
| cyan | light, increased contrast | symbol on the hue | the hue, opaque | 2.16:1 | 9.71:1 | 3:1 |
| brown | light, increased contrast | symbol on the hue | the hue, opaque | 3.53:1 | 3.53:1 | 3:1 |
| yellow | light, increased contrast | symbol on the hue | the hue, opaque | 1.51:1 | 13.89:1 | 3:1 |
| indigo | dark, increased contrast | symbol on the hue | the hue, opaque | 3.51:1 | 3.51:1 | 3:1 |
| blue | dark, increased contrast | symbol on the hue | the hue, opaque | 3.23:1 | 3.23:1 | 3:1 |
| orange | dark, increased contrast | symbol on the hue | the hue, opaque | 2.23:1 | 9.41:1 | 3:1 |
| pink | dark, increased contrast | symbol on the hue | the hue, opaque | 3.52:1 | 3.52:1 | 3:1 |
| teal | dark, increased contrast | symbol on the hue | the hue, opaque | 1.86:1 | 11.30:1 | 3:1 |
| green | dark, increased contrast | symbol on the hue | the hue, opaque | 2.02:1 | 10.39:1 | 3:1 |
| red | dark, increased contrast | symbol on the hue | the hue, opaque | 3.43:1 | 3.43:1 | 3:1 |
| purple | dark, increased contrast | symbol on the hue | the hue, opaque | 3.63:1 | 3.63:1 | 3:1 |
| mint | dark, increased contrast | symbol on the hue | the hue, opaque | 1.78:1 | 11.82:1 | 3:1 |
| cyan | dark, increased contrast | symbol on the hue | the hue, opaque | 1.76:1 | 11.94:1 | 3:1 |
| brown | dark, increased contrast | symbol on the hue | the hue, opaque | 3.07:1 | 3.07:1 | 3:1 |
| yellow | dark, increased contrast | symbol on the hue | the hue, opaque | 1.41:1 | 14.87:1 | 3:1 |

</details>

## 0.2.0

### Added

- **`DesignKit`**, a new product: one set of design tokens (`DesignTokens.standard`, carried by the environment),
  named motions with their Reduce Motion fallbacks (`MotionRole`), colour roles solved from the Theme (`ColorRoles`,
  `WithColorRoles`), glass surfaces with Reduce Transparency and Increase Contrast fallbacks (`surface(_:in:)`,
  `GlassRendering`), and the views of a themed list column: `WindowBackground`, `ColumnLayout` (column on the left or
  mirrored on the right), `ContentCanvas`, `Tile`, `ListRow`, `FolderRow`, `LayerPanel`, `SectionHeader`,
  `ColumnSeparator`, `StatusLine`, `FieldPill`, `IconButton`, `IconButtonRow`, `ThemeGlyph`, `GlassSwitcher`, `Banner`,
  `SkeletonRows`, `focusRing(_:in:)`. See [docs/design-kit.md](docs/design-kit.md).
- `DesignTokens.legibilityCases(for:in:)` and `LegibilityCase`: every text role on every surface the kit draws text on,
  with the contrast of the system default and of the solved ink.
- `Legibility.solve(colors:surfaces:)`, the solver under the name the documentation uses.
- A gallery package (`Gallery/`, not a product) that renders every view offscreen and prints the legibility audit.

The token values of `DesignTokens.standard` are the reference app's generic token table at its commit `e0f1a89`
(spacing, radii, sizes, emphasis in light and dark, Increase Contrast ×1.8, glass and its fallbacks, motion durations,
curves and roles), so an app already drawn with those values looks the same through the kit. The light window gradient
is 0.38 / 0.16 / 0.05 (the code's values).

### Deprecated

- `Legibility.solve(_:surfaces:)`: renamed `solve(colors:surfaces:)`. The old name still compiles, with a deprecation
  warning, and gives the same result.

### Source-breaking changes

None. `ColorCore`, `ColorPlatform` and `ColorUI` keep every 0.1.0 declaration; the platform floor stays macOS 26 and
iOS 26.

### Legibility defaults

0.1.0 drew no text. In 0.2.0 the kit's views draw secondary text and text in the Theme's colour with the solver's inks
(`ColorRoles.secondaryText`, `ColorRoles.tintText`) instead of the system's defaults (the secondary label colour, the
raw primary hue). The table lists each case: for each standard Theme and appearance, each text role on each surface,
the contrast of the system default (before) and of the kit's ink (after), against the 4.5:1 text threshold. The worst
point of the surface is taken (the gradient sampled from top to bottom; row fills from 10 % of the window height down;
badge and tile fills over all of them). Ratios were measured with the system colours of macOS 27; each row is a test
case (`LegibilityCaseTests`, run on macOS 27).

The system default is under 4.5:1 in all 252 cases. The kit's ink reaches 4.5:1 in 230 of them,
including every light and light increased-contrast case. It stays under the threshold in 22 dark cases, where a
Theme with a bright primary hue (orange-pink, teal-green, mint-cyan, brown-yellow) under a strong fill leaves white text no room: the ink is already the
full label colour, so only a weaker fill would help. Those cases, then the full table:

| Theme | Appearance | Text | Surface | Before | After |
|---|---|---|---|---|---|
| orange-pink | dark | tinted text | badge or tile fill | 1.95:1 | 4.36:1 |
| orange-pink | dark, increased contrast | secondary text | current row | 2.76:1 | 4.34:1 |
| orange-pink | dark, increased contrast | secondary text | selected row | 2.38:1 | 3.56:1 |
| orange-pink | dark, increased contrast | tinted text | selected row | 1.92:1 | 4.29:1 |
| orange-pink | dark, increased contrast | tinted text | badge or tile fill | 1.61:1 | 3.60:1 |
| teal-green | dark | secondary text | selected row | 2.57:1 | 3.99:1 |
| teal-green | dark | tinted text | badge or tile fill | 2.01:1 | 3.74:1 |
| teal-green | dark, increased contrast | secondary text | hovered row | 2.76:1 | 4.40:1 |
| teal-green | dark, increased contrast | secondary text | current row | 2.47:1 | 3.79:1 |
| teal-green | dark, increased contrast | secondary text | selected row | 2.11:1 | 3.07:1 |
| teal-green | dark, increased contrast | tinted text | selected row | 1.98:1 | 3.68:1 |
| teal-green | dark, increased contrast | tinted text | badge or tile fill | 1.64:1 | 3.06:1 |
| mint-cyan | dark | secondary text | current row | 2.76:1 | 4.38:1 |
| mint-cyan | dark | secondary text | selected row | 2.50:1 | 3.86:1 |
| mint-cyan | dark | tinted text | badge or tile fill | 2.02:1 | 3.60:1 |
| mint-cyan | dark, increased contrast | secondary text | hovered row | 2.70:1 | 4.26:1 |
| mint-cyan | dark, increased contrast | secondary text | current row | 2.41:1 | 3.67:1 |
| mint-cyan | dark, increased contrast | tinted text | current row | 2.51:1 | 4.47:1 |
| mint-cyan | dark, increased contrast | secondary text | selected row | 2.05:1 | 2.96:1 |
| mint-cyan | dark, increased contrast | tinted text | selected row | 1.99:1 | 3.54:1 |
| mint-cyan | dark, increased contrast | tinted text | badge or tile fill | 1.65:1 | 2.93:1 |
| brown-yellow | dark, increased contrast | secondary text | selected row | 2.78:1 | 4.31:1 |

<details>
<summary>All 252 cases</summary>

| Theme | Appearance | Text | Surface | Before | After | Threshold |
|---|---|---|---|---|---|---|
| indigo-blue | light | secondary text | window gradient | 3.48:1 | 5.04:1 | 4.5:1 |
| indigo-blue | light | tinted text | window gradient | 2.94:1 | 7.06:1 | 4.5:1 |
| indigo-blue | light | secondary text | hovered row | 3.46:1 | 4.97:1 | 4.5:1 |
| indigo-blue | light | tinted text | hovered row | 2.85:1 | 6.85:1 | 4.5:1 |
| indigo-blue | light | secondary text | current row | 3.39:1 | 4.84:1 | 4.5:1 |
| indigo-blue | light | tinted text | current row | 2.67:1 | 6.42:1 | 4.5:1 |
| indigo-blue | light | secondary text | selected row | 3.24:1 | 4.51:1 | 4.5:1 |
| indigo-blue | light | tinted text | selected row | 2.29:1 | 5.50:1 | 4.5:1 |
| indigo-blue | light | tinted text | badge or tile fill | 1.87:1 | 4.50:1 | 4.5:1 |
| indigo-blue | dark | secondary text | window gradient | 3.94:1 | 5.22:1 | 4.5:1 |
| indigo-blue | dark | tinted text | window gradient | 2.52:1 | 6.57:1 | 4.5:1 |
| indigo-blue | dark | secondary text | hovered row | 3.87:1 | 5.12:1 | 4.5:1 |
| indigo-blue | dark | tinted text | hovered row | 2.47:1 | 6.43:1 | 4.5:1 |
| indigo-blue | dark | secondary text | current row | 3.71:1 | 4.87:1 | 4.5:1 |
| indigo-blue | dark | tinted text | current row | 2.31:1 | 6.03:1 | 4.5:1 |
| indigo-blue | dark | secondary text | selected row | 3.47:1 | 4.50:1 | 4.5:1 |
| indigo-blue | dark | tinted text | selected row | 2.10:1 | 5.48:1 | 4.5:1 |
| indigo-blue | dark | tinted text | badge or tile fill | 1.73:1 | 4.50:1 | 4.5:1 |
| indigo-blue | light, increased contrast | secondary text | window gradient | 3.48:1 | 6.10:1 | 4.5:1 |
| indigo-blue | light, increased contrast | tinted text | window gradient | 2.94:1 | 8.74:1 | 4.5:1 |
| indigo-blue | light, increased contrast | secondary text | hovered row | 3.37:1 | 5.73:1 | 4.5:1 |
| indigo-blue | light, increased contrast | tinted text | hovered row | 2.61:1 | 7.78:1 | 4.5:1 |
| indigo-blue | light, increased contrast | secondary text | current row | 3.25:1 | 5.36:1 | 4.5:1 |
| indigo-blue | light, increased contrast | tinted text | current row | 2.32:1 | 6.91:1 | 4.5:1 |
| indigo-blue | light, increased contrast | secondary text | selected row | 2.95:1 | 4.50:1 | 4.5:1 |
| indigo-blue | light, increased contrast | tinted text | selected row | 1.73:1 | 5.17:1 | 4.5:1 |
| indigo-blue | light, increased contrast | tinted text | badge or tile fill | 1.51:1 | 4.50:1 | 4.5:1 |
| indigo-blue | dark, increased contrast | secondary text | window gradient | 3.94:1 | 6.36:1 | 4.5:1 |
| indigo-blue | dark, increased contrast | tinted text | window gradient | 2.52:1 | 7.66:1 | 4.5:1 |
| indigo-blue | dark, increased contrast | secondary text | hovered row | 3.65:1 | 5.78:1 | 4.5:1 |
| indigo-blue | dark, increased contrast | tinted text | hovered row | 2.27:1 | 6.87:1 | 4.5:1 |
| indigo-blue | dark, increased contrast | secondary text | current row | 3.38:1 | 5.22:1 | 4.5:1 |
| indigo-blue | dark, increased contrast | tinted text | current row | 2.02:1 | 6.13:1 | 4.5:1 |
| indigo-blue | dark, increased contrast | secondary text | selected row | 3.00:1 | 4.50:1 | 4.5:1 |
| indigo-blue | dark, increased contrast | tinted text | selected row | 1.71:1 | 5.18:1 | 4.5:1 |
| indigo-blue | dark, increased contrast | tinted text | badge or tile fill | 1.48:1 | 4.50:1 | 4.5:1 |
| orange-pink | light | secondary text | window gradient | 3.69:1 | 4.90:1 | 4.5:1 |
| orange-pink | light | tinted text | window gradient | 1.68:1 | 6.17:1 | 4.5:1 |
| orange-pink | light | secondary text | hovered row | 3.66:1 | 4.84:1 | 4.5:1 |
| orange-pink | light | tinted text | hovered row | 1.62:1 | 5.95:1 | 4.5:1 |
| orange-pink | light | secondary text | current row | 3.63:1 | 4.78:1 | 4.5:1 |
| orange-pink | light | tinted text | current row | 1.56:1 | 5.76:1 | 4.5:1 |
| orange-pink | light | secondary text | selected row | 3.48:1 | 4.50:1 | 4.5:1 |
| orange-pink | light | tinted text | selected row | 1.31:1 | 4.84:1 | 4.5:1 |
| orange-pink | light | tinted text | badge or tile fill | 1.22:1 | 4.51:1 | 4.5:1 |
| orange-pink | dark | secondary text | window gradient | 3.33:1 | 5.50:1 | 4.5:1 |
| orange-pink | dark | tinted text | window gradient | 3.13:1 | 6.99:1 | 4.5:1 |
| orange-pink | dark | secondary text | hovered row | 3.31:1 | 5.46:1 | 4.5:1 |
| orange-pink | dark | tinted text | hovered row | 3.11:1 | 6.95:1 | 4.5:1 |
| orange-pink | dark | secondary text | current row | 3.12:1 | 5.05:1 | 4.5:1 |
| orange-pink | dark | tinted text | current row | 2.86:1 | 6.38:1 | 4.5:1 |
| orange-pink | dark | secondary text | selected row | 2.86:1 | 4.50:1 | 4.5:1 |
| orange-pink | dark | tinted text | selected row | 2.52:1 | 5.62:1 | 4.5:1 |
| orange-pink | dark | tinted text | badge or tile fill | 1.95:1 | 4.36:1 (not reached) | 4.5:1 |
| orange-pink | light, increased contrast | secondary text | window gradient | 3.69:1 | 4.96:1 | 4.5:1 |
| orange-pink | light, increased contrast | tinted text | window gradient | 1.68:1 | 6.32:1 | 4.5:1 |
| orange-pink | light, increased contrast | secondary text | hovered row | 3.62:1 | 4.83:1 | 4.5:1 |
| orange-pink | light, increased contrast | tinted text | hovered row | 1.55:1 | 5.83:1 | 4.5:1 |
| orange-pink | light, increased contrast | secondary text | current row | 3.57:1 | 4.73:1 | 4.5:1 |
| orange-pink | light, increased contrast | tinted text | current row | 1.46:1 | 5.49:1 | 4.5:1 |
| orange-pink | light, increased contrast | secondary text | selected row | 3.45:1 | 4.50:1 | 4.5:1 |
| orange-pink | light, increased contrast | tinted text | selected row | 1.27:1 | 4.79:1 | 4.5:1 |
| orange-pink | light, increased contrast | tinted text | badge or tile fill | 1.19:1 | 4.50:1 | 4.5:1 |
| orange-pink | dark, increased contrast | secondary text | window gradient | 3.33:1 | 5.56:1 | 4.5:1 |
| orange-pink | dark, increased contrast | tinted text | window gradient | 3.13:1 | 6.99:1 | 4.5:1 |
| orange-pink | dark, increased contrast | secondary text | hovered row | 3.06:1 | 4.98:1 | 4.5:1 |
| orange-pink | dark, increased contrast | tinted text | hovered row | 2.78:1 | 6.20:1 | 4.5:1 |
| orange-pink | dark, increased contrast | secondary text | current row | 2.76:1 | 4.34:1 (not reached) | 4.5:1 |
| orange-pink | dark, increased contrast | tinted text | current row | 2.39:1 | 5.33:1 | 4.5:1 |
| orange-pink | dark, increased contrast | secondary text | selected row | 2.38:1 | 3.56:1 (not reached) | 4.5:1 |
| orange-pink | dark, increased contrast | tinted text | selected row | 1.92:1 | 4.29:1 (not reached) | 4.5:1 |
| orange-pink | dark, increased contrast | tinted text | badge or tile fill | 1.61:1 | 3.60:1 (not reached) | 4.5:1 |
| teal-green | light | secondary text | window gradient | 3.70:1 | 4.85:1 | 4.5:1 |
| teal-green | light | tinted text | window gradient | 1.57:1 | 6.00:1 | 4.5:1 |
| teal-green | light | secondary text | hovered row | 3.68:1 | 4.83:1 | 4.5:1 |
| teal-green | light | tinted text | hovered row | 1.54:1 | 5.89:1 | 4.5:1 |
| teal-green | light | secondary text | current row | 3.65:1 | 4.78:1 | 4.5:1 |
| teal-green | light | tinted text | current row | 1.49:1 | 5.70:1 | 4.5:1 |
| teal-green | light | secondary text | selected row | 3.50:1 | 4.50:1 | 4.5:1 |
| teal-green | light | tinted text | selected row | 1.25:1 | 4.78:1 | 4.5:1 |
| teal-green | light | tinted text | badge or tile fill | 1.18:1 | 4.50:1 | 4.5:1 |
| teal-green | dark | secondary text | window gradient | 3.08:1 | 5.07:1 | 4.5:1 |
| teal-green | dark | tinted text | window gradient | 3.42:1 | 6.36:1 | 4.5:1 |
| teal-green | dark | secondary text | hovered row | 3.01:1 | 4.93:1 | 4.5:1 |
| teal-green | dark | tinted text | hovered row | 3.32:1 | 6.16:1 | 4.5:1 |
| teal-green | dark | secondary text | current row | 2.82:1 | 4.53:1 | 4.5:1 |
| teal-green | dark | tinted text | current row | 3.02:1 | 5.62:1 | 4.5:1 |
| teal-green | dark | secondary text | selected row | 2.57:1 | 3.99:1 (not reached) | 4.5:1 |
| teal-green | dark | tinted text | selected row | 2.64:1 | 4.91:1 | 4.5:1 |
| teal-green | dark | tinted text | badge or tile fill | 2.01:1 | 3.74:1 (not reached) | 4.5:1 |
| teal-green | light, increased contrast | secondary text | window gradient | 3.70:1 | 4.90:1 | 4.5:1 |
| teal-green | light, increased contrast | tinted text | window gradient | 1.57:1 | 6.08:1 | 4.5:1 |
| teal-green | light, increased contrast | secondary text | hovered row | 3.64:1 | 4.80:1 | 4.5:1 |
| teal-green | light, increased contrast | tinted text | hovered row | 1.48:1 | 5.72:1 | 4.5:1 |
| teal-green | light, increased contrast | secondary text | current row | 3.59:1 | 4.71:1 | 4.5:1 |
| teal-green | light, increased contrast | tinted text | current row | 1.39:1 | 5.40:1 | 4.5:1 |
| teal-green | light, increased contrast | secondary text | selected row | 3.48:1 | 4.51:1 | 4.5:1 |
| teal-green | light, increased contrast | tinted text | selected row | 1.23:1 | 4.76:1 | 4.5:1 |
| teal-green | light, increased contrast | tinted text | badge or tile fill | 1.16:1 | 4.50:1 | 4.5:1 |
| teal-green | dark, increased contrast | secondary text | window gradient | 3.08:1 | 5.07:1 | 4.5:1 |
| teal-green | dark, increased contrast | tinted text | window gradient | 3.42:1 | 6.36:1 | 4.5:1 |
| teal-green | dark, increased contrast | secondary text | hovered row | 2.76:1 | 4.40:1 (not reached) | 4.5:1 |
| teal-green | dark, increased contrast | tinted text | hovered row | 2.93:1 | 5.45:1 | 4.5:1 |
| teal-green | dark, increased contrast | secondary text | current row | 2.47:1 | 3.79:1 (not reached) | 4.5:1 |
| teal-green | dark, increased contrast | tinted text | current row | 2.49:1 | 4.64:1 | 4.5:1 |
| teal-green | dark, increased contrast | secondary text | selected row | 2.11:1 | 3.07:1 (not reached) | 4.5:1 |
| teal-green | dark, increased contrast | tinted text | selected row | 1.98:1 | 3.68:1 (not reached) | 4.5:1 |
| teal-green | dark, increased contrast | tinted text | badge or tile fill | 1.64:1 | 3.06:1 (not reached) | 4.5:1 |
| red-orange | light | secondary text | window gradient | 3.51:1 | 4.90:1 | 4.5:1 |
| red-orange | light | tinted text | window gradient | 2.11:1 | 6.50:1 | 4.5:1 |
| red-orange | light | secondary text | hovered row | 3.49:1 | 4.87:1 | 4.5:1 |
| red-orange | light | tinted text | hovered row | 2.07:1 | 6.40:1 | 4.5:1 |
| red-orange | light | secondary text | current row | 3.44:1 | 4.76:1 | 4.5:1 |
| red-orange | light | tinted text | current row | 1.96:1 | 6.04:1 | 4.5:1 |
| red-orange | light | secondary text | selected row | 3.32:1 | 4.50:1 | 4.5:1 |
| red-orange | light | tinted text | selected row | 1.71:1 | 5.29:1 | 4.5:1 |
| red-orange | light | tinted text | badge or tile fill | 1.46:1 | 4.50:1 | 4.5:1 |
| red-orange | dark | secondary text | window gradient | 3.91:1 | 5.35:1 | 4.5:1 |
| red-orange | dark | tinted text | window gradient | 2.68:1 | 6.78:1 | 4.5:1 |
| red-orange | dark | secondary text | hovered row | 3.80:1 | 5.18:1 | 4.5:1 |
| red-orange | dark | tinted text | hovered row | 2.57:1 | 6.49:1 | 4.5:1 |
| red-orange | dark | secondary text | current row | 3.62:1 | 4.90:1 | 4.5:1 |
| red-orange | dark | tinted text | current row | 2.41:1 | 6.09:1 | 4.5:1 |
| red-orange | dark | secondary text | selected row | 3.37:1 | 4.50:1 | 4.5:1 |
| red-orange | dark | tinted text | selected row | 2.18:1 | 5.52:1 | 4.5:1 |
| red-orange | dark | tinted text | badge or tile fill | 1.78:1 | 4.50:1 | 4.5:1 |
| red-orange | light, increased contrast | secondary text | window gradient | 3.51:1 | 5.54:1 | 4.5:1 |
| red-orange | light, increased contrast | tinted text | window gradient | 2.11:1 | 7.57:1 | 4.5:1 |
| red-orange | light, increased contrast | secondary text | hovered row | 3.42:1 | 5.31:1 | 4.5:1 |
| red-orange | light, increased contrast | tinted text | hovered row | 1.92:1 | 6.90:1 | 4.5:1 |
| red-orange | light, increased contrast | secondary text | current row | 3.33:1 | 5.05:1 | 4.5:1 |
| red-orange | light, increased contrast | tinted text | current row | 1.73:1 | 6.22:1 | 4.5:1 |
| red-orange | light, increased contrast | secondary text | selected row | 3.10:1 | 4.50:1 | 4.5:1 |
| red-orange | light, increased contrast | tinted text | selected row | 1.38:1 | 4.95:1 | 4.5:1 |
| red-orange | light, increased contrast | tinted text | badge or tile fill | 1.25:1 | 4.50:1 | 4.5:1 |
| red-orange | dark, increased contrast | secondary text | window gradient | 3.91:1 | 6.62:1 | 4.5:1 |
| red-orange | dark, increased contrast | tinted text | window gradient | 2.68:1 | 7.96:1 | 4.5:1 |
| red-orange | dark, increased contrast | secondary text | hovered row | 3.56:1 | 5.89:1 | 4.5:1 |
| red-orange | dark, increased contrast | tinted text | hovered row | 2.36:1 | 6.99:1 | 4.5:1 |
| red-orange | dark, increased contrast | secondary text | current row | 3.26:1 | 5.29:1 | 4.5:1 |
| red-orange | dark, increased contrast | tinted text | current row | 2.09:1 | 6.22:1 | 4.5:1 |
| red-orange | dark, increased contrast | secondary text | selected row | 2.86:1 | 4.50:1 | 4.5:1 |
| red-orange | dark, increased contrast | tinted text | selected row | 1.76:1 | 5.22:1 | 4.5:1 |
| red-orange | dark, increased contrast | tinted text | badge or tile fill | 1.52:1 | 4.51:1 | 4.5:1 |
| purple-pink | light | secondary text | window gradient | 3.48:1 | 5.00:1 | 4.5:1 |
| purple-pink | light | tinted text | window gradient | 2.40:1 | 6.82:1 | 4.5:1 |
| purple-pink | light | secondary text | hovered row | 3.45:1 | 4.93:1 | 4.5:1 |
| purple-pink | light | tinted text | hovered row | 2.32:1 | 6.59:1 | 4.5:1 |
| purple-pink | light | secondary text | current row | 3.39:1 | 4.81:1 | 4.5:1 |
| purple-pink | light | tinted text | current row | 2.18:1 | 6.20:1 | 4.5:1 |
| purple-pink | light | secondary text | selected row | 3.25:1 | 4.51:1 | 4.5:1 |
| purple-pink | light | tinted text | selected row | 1.89:1 | 5.37:1 | 4.5:1 |
| purple-pink | light | tinted text | badge or tile fill | 1.58:1 | 4.50:1 | 4.5:1 |
| purple-pink | dark | secondary text | window gradient | 3.98:1 | 5.26:1 | 4.5:1 |
| purple-pink | dark | tinted text | window gradient | 2.61:1 | 6.62:1 | 4.5:1 |
| purple-pink | dark | secondary text | hovered row | 3.92:1 | 5.16:1 | 4.5:1 |
| purple-pink | dark | tinted text | hovered row | 2.55:1 | 6.47:1 | 4.5:1 |
| purple-pink | dark | secondary text | current row | 3.73:1 | 4.89:1 | 4.5:1 |
| purple-pink | dark | tinted text | current row | 2.40:1 | 6.07:1 | 4.5:1 |
| purple-pink | dark | secondary text | selected row | 3.47:1 | 4.50:1 | 4.5:1 |
| purple-pink | dark | tinted text | selected row | 2.18:1 | 5.51:1 | 4.5:1 |
| purple-pink | dark | tinted text | badge or tile fill | 1.78:1 | 4.50:1 | 4.5:1 |
| purple-pink | light, increased contrast | secondary text | window gradient | 3.48:1 | 5.84:1 | 4.5:1 |
| purple-pink | light, increased contrast | tinted text | window gradient | 2.40:1 | 8.12:1 | 4.5:1 |
| purple-pink | light, increased contrast | secondary text | hovered row | 3.37:1 | 5.50:1 | 4.5:1 |
| purple-pink | light, increased contrast | tinted text | hovered row | 2.13:1 | 7.23:1 | 4.5:1 |
| purple-pink | light, increased contrast | secondary text | current row | 3.27:1 | 5.19:1 | 4.5:1 |
| purple-pink | light, increased contrast | tinted text | current row | 1.91:1 | 6.47:1 | 4.5:1 |
| purple-pink | light, increased contrast | secondary text | selected row | 3.01:1 | 4.50:1 | 4.5:1 |
| purple-pink | light, increased contrast | tinted text | selected row | 1.48:1 | 5.03:1 | 4.5:1 |
| purple-pink | light, increased contrast | tinted text | badge or tile fill | 1.33:1 | 4.50:1 | 4.5:1 |
| purple-pink | dark, increased contrast | secondary text | window gradient | 3.98:1 | 6.46:1 | 4.5:1 |
| purple-pink | dark, increased contrast | tinted text | window gradient | 2.61:1 | 7.76:1 | 4.5:1 |
| purple-pink | dark, increased contrast | secondary text | hovered row | 3.67:1 | 5.86:1 | 4.5:1 |
| purple-pink | dark, increased contrast | tinted text | hovered row | 2.35:1 | 6.97:1 | 4.5:1 |
| purple-pink | dark, increased contrast | secondary text | current row | 3.37:1 | 5.28:1 | 4.5:1 |
| purple-pink | dark, increased contrast | tinted text | current row | 2.09:1 | 6.20:1 | 4.5:1 |
| purple-pink | dark, increased contrast | secondary text | selected row | 2.95:1 | 4.50:1 | 4.5:1 |
| purple-pink | dark, increased contrast | tinted text | selected row | 1.75:1 | 5.21:1 | 4.5:1 |
| purple-pink | dark, increased contrast | tinted text | badge or tile fill | 1.52:1 | 4.50:1 | 4.5:1 |
| mint-cyan | light | secondary text | window gradient | 3.70:1 | 4.84:1 | 4.5:1 |
| mint-cyan | light | tinted text | window gradient | 1.55:1 | 5.96:1 | 4.5:1 |
| mint-cyan | light | secondary text | hovered row | 3.68:1 | 4.81:1 | 4.5:1 |
| mint-cyan | light | tinted text | hovered row | 1.52:1 | 5.85:1 | 4.5:1 |
| mint-cyan | light | secondary text | current row | 3.66:1 | 4.77:1 | 4.5:1 |
| mint-cyan | light | tinted text | current row | 1.47:1 | 5.67:1 | 4.5:1 |
| mint-cyan | light | secondary text | selected row | 3.51:1 | 4.50:1 | 4.5:1 |
| mint-cyan | light | tinted text | selected row | 1.24:1 | 4.78:1 | 4.5:1 |
| mint-cyan | light | tinted text | badge or tile fill | 1.17:1 | 4.51:1 | 4.5:1 |
| mint-cyan | dark | secondary text | window gradient | 3.02:1 | 4.95:1 | 4.5:1 |
| mint-cyan | dark | tinted text | window gradient | 3.48:1 | 6.19:1 | 4.5:1 |
| mint-cyan | dark | secondary text | hovered row | 2.95:1 | 4.78:1 | 4.5:1 |
| mint-cyan | dark | tinted text | hovered row | 3.35:1 | 5.96:1 | 4.5:1 |
| mint-cyan | dark | secondary text | current row | 2.76:1 | 4.38:1 (not reached) | 4.5:1 |
| mint-cyan | dark | tinted text | current row | 3.05:1 | 5.43:1 | 4.5:1 |
| mint-cyan | dark | secondary text | selected row | 2.50:1 | 3.86:1 (not reached) | 4.5:1 |
| mint-cyan | dark | tinted text | selected row | 2.66:1 | 4.73:1 | 4.5:1 |
| mint-cyan | dark | tinted text | badge or tile fill | 2.02:1 | 3.60:1 (not reached) | 4.5:1 |
| mint-cyan | light, increased contrast | secondary text | window gradient | 3.70:1 | 4.87:1 | 4.5:1 |
| mint-cyan | light, increased contrast | tinted text | window gradient | 1.55:1 | 6.02:1 | 4.5:1 |
| mint-cyan | light, increased contrast | secondary text | hovered row | 3.65:1 | 4.78:1 | 4.5:1 |
| mint-cyan | light, increased contrast | tinted text | hovered row | 1.46:1 | 5.67:1 | 4.5:1 |
| mint-cyan | light, increased contrast | secondary text | current row | 3.60:1 | 4.70:1 | 4.5:1 |
| mint-cyan | light, increased contrast | tinted text | current row | 1.38:1 | 5.36:1 | 4.5:1 |
| mint-cyan | light, increased contrast | secondary text | selected row | 3.50:1 | 4.50:1 | 4.5:1 |
| mint-cyan | light, increased contrast | tinted text | selected row | 1.22:1 | 4.74:1 | 4.5:1 |
| mint-cyan | light, increased contrast | tinted text | badge or tile fill | 1.16:1 | 4.50:1 | 4.5:1 |
| mint-cyan | dark, increased contrast | secondary text | window gradient | 3.02:1 | 4.95:1 | 4.5:1 |
| mint-cyan | dark, increased contrast | tinted text | window gradient | 3.48:1 | 6.19:1 | 4.5:1 |
| mint-cyan | dark, increased contrast | secondary text | hovered row | 2.70:1 | 4.26:1 (not reached) | 4.5:1 |
| mint-cyan | dark, increased contrast | tinted text | hovered row | 2.96:1 | 5.26:1 | 4.5:1 |
| mint-cyan | dark, increased contrast | secondary text | current row | 2.41:1 | 3.67:1 (not reached) | 4.5:1 |
| mint-cyan | dark, increased contrast | tinted text | current row | 2.51:1 | 4.47:1 (not reached) | 4.5:1 |
| mint-cyan | dark, increased contrast | secondary text | selected row | 2.05:1 | 2.96:1 (not reached) | 4.5:1 |
| mint-cyan | dark, increased contrast | tinted text | selected row | 1.99:1 | 3.54:1 (not reached) | 4.5:1 |
| mint-cyan | dark, increased contrast | tinted text | badge or tile fill | 1.65:1 | 2.93:1 (not reached) | 4.5:1 |
| brown-yellow | light | secondary text | window gradient | 3.60:1 | 4.84:1 | 4.5:1 |
| brown-yellow | light | tinted text | window gradient | 2.32:1 | 6.34:1 | 4.5:1 |
| brown-yellow | light | secondary text | hovered row | 3.60:1 | 4.82:1 | 4.5:1 |
| brown-yellow | light | tinted text | hovered row | 2.30:1 | 6.29:1 | 4.5:1 |
| brown-yellow | light | secondary text | current row | 3.55:1 | 4.74:1 | 4.5:1 |
| brown-yellow | light | tinted text | current row | 2.19:1 | 5.99:1 | 4.5:1 |
| brown-yellow | light | secondary text | selected row | 3.43:1 | 4.50:1 | 4.5:1 |
| brown-yellow | light | tinted text | selected row | 1.92:1 | 5.24:1 | 4.5:1 |
| brown-yellow | light | tinted text | badge or tile fill | 1.65:1 | 4.50:1 | 4.5:1 |
| brown-yellow | dark | secondary text | window gradient | 3.75:1 | 5.45:1 | 4.5:1 |
| brown-yellow | dark | tinted text | window gradient | 2.67:1 | 6.92:1 | 4.5:1 |
| brown-yellow | dark | secondary text | hovered row | 3.60:1 | 5.18:1 | 4.5:1 |
| brown-yellow | dark | tinted text | hovered row | 2.51:1 | 6.51:1 | 4.5:1 |
| brown-yellow | dark | secondary text | current row | 3.44:1 | 4.89:1 | 4.5:1 |
| brown-yellow | dark | tinted text | current row | 2.35:1 | 6.09:1 | 4.5:1 |
| brown-yellow | dark | secondary text | selected row | 3.22:1 | 4.50:1 | 4.5:1 |
| brown-yellow | dark | tinted text | selected row | 2.13:1 | 5.51:1 | 4.5:1 |
| brown-yellow | dark | tinted text | badge or tile fill | 1.74:1 | 4.50:1 | 4.5:1 |
| brown-yellow | light, increased contrast | secondary text | window gradient | 3.60:1 | 5.35:1 | 4.5:1 |
| brown-yellow | light, increased contrast | tinted text | window gradient | 2.32:1 | 7.40:1 | 4.5:1 |
| brown-yellow | light, increased contrast | secondary text | hovered row | 3.54:1 | 5.19:1 | 4.5:1 |
| brown-yellow | light, increased contrast | tinted text | hovered row | 2.15:1 | 6.88:1 | 4.5:1 |
| brown-yellow | light, increased contrast | secondary text | current row | 3.45:1 | 4.99:1 | 4.5:1 |
| brown-yellow | light, increased contrast | tinted text | current row | 1.97:1 | 6.28:1 | 4.5:1 |
| brown-yellow | light, increased contrast | secondary text | selected row | 3.23:1 | 4.51:1 | 4.5:1 |
| brown-yellow | light, increased contrast | tinted text | selected row | 1.57:1 | 5.02:1 | 4.5:1 |
| brown-yellow | light, increased contrast | tinted text | badge or tile fill | 1.41:1 | 4.50:1 | 4.5:1 |
| brown-yellow | dark, increased contrast | secondary text | window gradient | 3.75:1 | 6.45:1 | 4.5:1 |
| brown-yellow | dark, increased contrast | tinted text | window gradient | 2.67:1 | 8.08:1 | 4.5:1 |
| brown-yellow | dark, increased contrast | secondary text | hovered row | 3.39:1 | 5.63:1 | 4.5:1 |
| brown-yellow | dark, increased contrast | tinted text | hovered row | 2.30:1 | 6.96:1 | 4.5:1 |
| brown-yellow | dark, increased contrast | secondary text | current row | 3.13:1 | 5.05:1 | 4.5:1 |
| brown-yellow | dark, increased contrast | tinted text | current row | 2.04:1 | 6.18:1 | 4.5:1 |
| brown-yellow | dark, increased contrast | secondary text | selected row | 2.78:1 | 4.31:1 (not reached) | 4.5:1 |
| brown-yellow | dark, increased contrast | tinted text | selected row | 1.72:1 | 5.19:1 | 4.5:1 |
| brown-yellow | dark, increased contrast | tinted text | badge or tile fill | 1.49:1 | 4.50:1 | 4.5:1 |

</details>

## 0.1.0

First release: `ColorCore`, `ColorPlatform`, `ColorUI`.
