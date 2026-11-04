# Changelog

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
