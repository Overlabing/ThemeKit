import ColorCore

extension Surfaces {
    /// A list column's surfaces, as a client would describe its own.
    static func listColumn(in appearance: Appearance) -> Surfaces {
        var surfaces = Surfaces(
            gradient: appearance.isDark
                ? GradientSpec(top: 0.42, middle: 0.18, bottom: 0.06) : GradientSpec(top: 0.38, middle: 0.16, bottom: 0.05),
            contentTop: 0.1, fills: [0.10, 0.16],
            selection: Selection(floor: appearance.isDark ? 0.25 : 0.30, cap: 0.5, visibility: 1.3),
            tintFills: [0.14, 0.25])
        if appearance.isIncreasedContrast {
            surfaces.fills = surfaces.fills.map { min(1, $0 * 1.8) }
            surfaces.selection.floor = min(1, surfaces.selection.floor * 1.8)
        }
        return surfaces
    }
}

extension Theme {
    /// Further hues a client solves text in, after the Theme's own two.
    func accents(plus extra: [Hue]) -> [Hue] { [primary, secondary] + extra }
}
