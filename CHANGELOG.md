# Changelog

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
