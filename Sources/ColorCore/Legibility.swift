import Foundation

/// Where text sits, described by the caller: the Theme's gradient, the part of the window the content covers, and the
/// fills drawn in the primary hue on it. The module holds no surfaces of its own; each client states its own, per
/// appearance.
public struct Surfaces: Sendable, Hashable {
    /// The window gradient under everything.
    public var gradient: GradientSpec
    /// Where the content starts, as a share of the window height (0…1). Above it only the bare gradient is sampled;
    /// from there down the fills are sampled on it too.
    public var contentTop: Double
    /// Opacities of fixed fills drawn in the primary hue over the content (hover, current item).
    public var fills: [Double]
    /// The selection fill, which the solver raises until it stands out from the gradient.
    public var selection: Selection
    /// Opacities of the fills a tinted text sits on (a count badge, an initial tile), drawn over every other surface.
    public var tintFills: [Double]

    public init(
        gradient: GradientSpec, contentTop: Double, fills: [Double], selection: Selection, tintFills: [Double]
    ) {
        self.gradient = gradient
        self.contentTop = contentTop
        self.fills = fills
        self.selection = selection
        self.tintFills = tintFills
    }

    /// How the selection fill is solved: from `floor` up to `cap`, the smallest opacity at which the selected item
    /// differs from the gradient under it by `visibility` (a contrast ratio).
    public struct Selection: Sendable, Hashable {
        public var floor: Double
        public var cap: Double
        public var visibility: Double

        public init(floor: Double, cap: Double, visibility: Double) {
            self.floor = floor
            self.cap = cap
            self.visibility = visibility
        }
    }
}

/// System colours resolved in one appearance, the input of `Legibility.solve`.
public struct ResolvedColors: Sendable, Equatable {
    /// Window background (under the gradient).
    public var background: RGBA
    /// The label colour and its secondary: translucent black in light, white in dark.
    public var label: RGBA
    public var secondaryLabel: RGBA
    public var primary: RGBA
    public var secondary: RGBA
    /// Further hues the caller draws text in, by rank (a list of account colours, say).
    public var accents: [RGBA]

    public init(
        background: RGBA, label: RGBA, secondaryLabel: RGBA, primary: RGBA, secondary: RGBA, accents: [RGBA] = []
    ) {
        self.background = background
        self.label = label
        self.secondaryLabel = secondaryLabel
        self.primary = primary
        self.secondary = secondary
        self.accents = accents
    }

    /// What a tinted text darkens (light) or lightens (dark) toward: the label's hue, opaque (black or white). The
    /// label over the background would stop short of it: on a strong selection it gives less than the label itself.
    public var ink: RGBA { RGBA(red: label.red, green: label.green, blue: label.blue) }
}

/// What it takes to draw every text at 4.5:1 at least for one Theme in one appearance, and the ratios reached. Solved
/// from the resolved colours rather than written down: the system hues differ between light, dark and Increase
/// Contrast, and may move with the system.
///
/// The surfaces a text sits on: the gradient sampled from top to bottom, and from `Surfaces.contentTop` down the fills
/// on it (fixed ones, then the selection), plus, for a tinted text, its own `Surfaces.tintFills`.
public struct Legibility: Sendable, Equatable {
    /// Opacity of the selection fill: the floor, raised until the item stands out from the gradient under it by the
    /// requested visibility, capped.
    public let selected: Double
    /// Alpha of the label colour for secondary text: the system's secondary label alpha when it already reaches 4.5:1,
    /// more otherwise.
    public let secondaryAlpha: Double
    /// Share of the ink (`ResolvedColors.ink`) mixed into the primary hue for a text drawn in the tint.
    public let tintMix: Double
    /// The same for each accent hue, by rank.
    public let accentMix: [Double]
    /// Lowest ratios reached, for reports and tests.
    public let worstLabel: Double
    public let worstSecondary: Double
    public let worstTint: Double
    public let worstAccent: Double
    /// The same without the inks, as the system colours draw them: the secondary label, the raw hue.
    public let worstSystemSecondary: Double
    public let worstRawTint: Double
    /// Lowest contrast between a selected item and the gradient under it, and between the gradient's top and the plain
    /// background (how much the gradient shows).
    public let selectionShows: Double
    public let gradientShows: Double

    public static func solve(_ colors: ResolvedColors, surfaces description: Surfaces) -> Legibility {
        let spec = description.gradient
        func gradient(at t: Double) -> RGBA {
            spec.color(at: t, primary: colors.primary, secondary: colors.secondary, over: colors.background)
        }
        let top = stride(from: 0.0, to: description.contentTop, by: 0.02).map(gradient(at:))
        let content = stride(from: description.contentTop, through: 1.0, by: 0.05).map(gradient(at:))

        let selection = description.selection
        let selected = solveMinimum(from: selection.floor, to: selection.cap) { opacity in
            content.map { Contrast.ratio(colors.primary.opacity(opacity).composited(over: $0), $0) }.min() ?? 1
                >= selection.visibility
        }
        let fills = (description.fills + [selected]).flatMap { opacity in
            content.map { colors.primary.opacity(opacity).composited(over: $0) }
        }
        let surfaces = top + content + fills
        let tinted = surfaces + description.tintFills.flatMap { opacity in
            surfaces.map { colors.primary.opacity(opacity).composited(over: $0) }
        }

        let ink = colors.ink
        let surfaceRange = Contrast.luminances(surfaces)
        let tintedRange = Contrast.luminances(tinted)
        let secondaryAlpha = solveMinimum(from: colors.secondaryLabel.alpha, to: colors.label.alpha) {
            Contrast.worst(foreground: colors.label.opacity($0 / colors.label.alpha), on: surfaces) >= Contrast.text
        }
        let tintMix = solveMinimum(from: 0, to: 1) {
            Contrast.worst(opaque: colors.primary.mixed(with: ink, by: $0), onLuminances: tintedRange) >= Contrast.text
        }
        let accentMix = colors.accents.map { hue in
            solveMinimum(from: 0, to: 1) {
                Contrast.worst(opaque: hue.mixed(with: ink, by: $0), onLuminances: surfaceRange) >= Contrast.text
            }
        }
        let secondaryInk = colors.label.opacity(secondaryAlpha / colors.label.alpha)
        return Legibility(
            selected: selected, secondaryAlpha: secondaryAlpha, tintMix: tintMix, accentMix: accentMix,
            worstLabel: Contrast.worst(foreground: colors.label, on: surfaces),
            worstSecondary: Contrast.worst(foreground: secondaryInk, on: surfaces),
            worstTint: Contrast.worst(opaque: colors.primary.mixed(with: ink, by: tintMix), onLuminances: tintedRange),
            worstAccent: zip(colors.accents, accentMix).map { hue, mix in
                Contrast.worst(opaque: hue.mixed(with: ink, by: mix), onLuminances: surfaceRange)
            }.min() ?? 21,
            worstSystemSecondary: Contrast.worst(foreground: colors.secondaryLabel, on: surfaces),
            worstRawTint: Contrast.worst(opaque: colors.primary, onLuminances: tintedRange),
            selectionShows: zip(content, content.map { colors.primary.opacity(selected).composited(over: $0) })
                .map { Contrast.ratio($0, $1) }.min() ?? 1,
            gradientShows: Contrast.ratio(gradient(at: 0), colors.background))
    }

    /// The smallest value in `low…high` that satisfies a monotone `condition`, to 1/1000; `high` when none does (the
    /// ratios then say by how much it falls short).
    public static func solveMinimum(from low: Double, to high: Double, _ condition: (Double) -> Bool) -> Double {
        if condition(low) { return low }
        guard condition(high) else { return high }
        var (lo, hi) = (low, high)
        while hi - lo > 0.001 {
            let mid = (lo + hi) / 2
            if condition(mid) { hi = mid } else { lo = mid }
        }
        return hi
    }
}
