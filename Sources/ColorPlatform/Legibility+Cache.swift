#if canImport(AppKit) || canImport(UIKit)
import ColorCore
import Synchronization

extension Legibility {
    /// Solved once per Theme, accent hues, surfaces and appearance: system colours do not change while the app runs (a
    /// new system does).
    public static func of(
        _ theme: Theme, accents: [Hue] = [], surfaces: Surfaces, in appearance: Appearance
    ) -> Legibility {
        cached(theme, accents: accents, surfaces: surfaces, appearance: appearance, fitting: false)
    }

    /// `fit(colors:surfaces:)` with the system colours, cached the same way: the surfaces' hue opacities shrink by
    /// `hueScale` when the full ones leave a text under 4.5:1.
    public static func fitted(
        _ theme: Theme, accents: [Hue] = [], surfaces: Surfaces, in appearance: Appearance
    ) -> Legibility {
        cached(theme, accents: accents, surfaces: surfaces, appearance: appearance, fitting: true)
    }

    /// `solve(colors:surfaces:hueScale:)` with the system colours, cached the same way: surfaces drawn over a gradient
    /// whose share another solve fixed (a list column).
    public static func of(
        _ theme: Theme, accents: [Hue] = [], surfaces: Surfaces, hueScale: Double, in appearance: Appearance
    ) -> Legibility {
        cached(theme, accents: accents, surfaces: surfaces, appearance: appearance, fitting: false, hueScale: hueScale)
    }

    private static func cached(
        _ theme: Theme, accents: [Hue], surfaces: Surfaces, appearance: Appearance, fitting: Bool,
        hueScale: Double = 1
    ) -> Legibility {
        cache.withLock { cache in
            let key = CacheKey(
                theme: theme, accents: accents, surfaces: surfaces, appearance: appearance, fitting: fitting,
                hueScale: hueScale)
            if let known = cache[key] { return known }
            let colors = ResolvedColors(theme, accents: accents, in: appearance)
            let solved = fitting
                ? fit(colors: colors, surfaces: surfaces)
                : solve(colors: colors, surfaces: surfaces, hueScale: hueScale)
            cache[key] = solved
            return solved
        }
    }

    private struct CacheKey: Hashable {
        let theme: Theme
        let accents: [Hue]
        let surfaces: Surfaces
        let appearance: Appearance
        let fitting: Bool
        let hueScale: Double
    }

    private static let cache = Mutex<[CacheKey: Legibility]>([:])
}
#endif
