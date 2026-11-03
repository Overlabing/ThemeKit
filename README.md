# ThemeKit

Themes for Apple-platform apps: a gradient and a tint chosen from a Palette of preset system-color pairs, resolved in
light, dark and Increase Contrast, with a solver that tells you what it takes to keep text legible on them.

The code is extracted from an existing app's theming code and generalized. It speaks of **Themes** and **Palettes**
only.

- macOS 26 and iOS 26, Swift 6 language mode, no dependencies.
- MIT licensed.

## Products

| Product | Depends on | What it holds |
|---|---|---|
| `ColorCore` | Foundation only | `RGBA`, WCAG `Contrast`, `Appearance`, `Hue`, `Theme`, `Palette`, `GradientSpec`, and the `Legibility` solver |
| `ColorPlatform` | `ColorCore`, AppKit or UIKit | System-color resolution per `Appearance`, `NativeColor` alias, cached `Legibility.of(…)` |
| `ColorUI` | `ColorCore`, `ColorPlatform`, SwiftUI | `GradientBackground`, `View.theme(_:)` with the `\.theme` environment value, `ThemeSwatch`, localized `Theme.displayName` |

## Install

```swift
.package(url: "https://github.com/Overlabing/ThemeKit", exact: "0.1.0")
```

## Use

```swift
import ColorUI

struct Root: View {
    let theme = Palette.standard.themes[0]

    var body: some View {
        ContentView()
            .background { GradientBackground(theme: theme).ignoresSafeArea() }
            .theme(theme)   // tints the view and sets \.theme below it
    }
}
```

### Legibility

The solver does not know your layout. You describe the surfaces text sits on, per appearance, and it answers with the
opacity, alpha and ink mixes that reach 4.5:1 on all of them.

```swift
import ColorCore
import ColorPlatform

let surfaces = Surfaces(
    gradient: .light,                  // opacities of the Theme's gradient
    contentTop: 0.1,                   // share of the window height where your content starts
    fills: [0.10, 0.16],               // fixed fills in the primary hue (hover, current item)
    selection: .init(floor: 0.30, cap: 0.5, visibility: 1.3),
    tintFills: [0.14, 0.25])           // fills a tinted text (a badge, a tile) sits on

let legibility = Legibility.of(theme, accents: [.mint], surfaces: surfaces, in: .light)
legibility.secondaryAlpha   // alpha of the label colour for secondary text
legibility.tintMix          // share of ink to mix into the primary hue for a tinted text
legibility.worstTint        // lowest ratio reached
```

`Legibility.solve(_:surfaces:)` in `ColorCore` takes already-resolved `ResolvedColors`, so it runs and tests without a
window.

## Not in 0.1

Free-color Themes and a picker.

## Tests

`swift test` on macOS. The solver is compared with the original implementation: the tests carry the colors it resolved
and the values it solved for them (recorded on macOS 27.0.1), and require identical results. Comparisons that depend
on the system's own colors run only on macOS 27; the 4.5:1 invariants run everywhere. The package also builds for iOS
(`xcodebuild -scheme ThemeKit-Package -destination 'generic/platform=iOS Simulator' build`).

## License

MIT, see [LICENSE](LICENSE).
